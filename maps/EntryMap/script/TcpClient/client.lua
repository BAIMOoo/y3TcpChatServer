local Client = {}

function Client.create(host, port, loginData)
    local client = {}
    
    client.host = host or '127.0.0.1'
    client.port = port or 25897
    client.connected = false
    client.network = nil
    client.playerId = loginData.playerId
    client.playerName = loginData.playerName
    client.requestIdCounter = 0 -- 用于生成请求ID
    
    -- 连接服务器
    function client:connect()
        -- 使用Y3的网络API连接服务器
        self.network = y3.network.connect(self.host, self.port, {
            update_interval = 0.05,
            timeout = 10,
        })
        
        -- 连接成功回调
        self.network:on_connected(function(network)
            print("已连接到服务器")
            client.connected = true
            
            -- 发送玩家加入消息
            local joinMessage = {
                type = "join",
                playerId = self:getPlayerId(),
                playerName = self:getPlayerName()
            }
            self:sendMessage(joinMessage)
        end)
        
        -- 断开连接回调
        self.network:on_disconnected(function(network)
            print("与服务器断开连接")
            client.connected = false
        end)
        
        -- 错误回调
        self.network:on_error(function(network, error)
            print("聊天服务器连接错误:", error)
            client.connected = false
        end)
        
        -- 数据接收回调
        self.network:data_reader(function(read)
            -- 读取包头，4字节大端序表示包体长度
            local head = read(4)
            local len = string.unpack('>I4', head)
            -- 读取包体，JSON格式
            local jsonStr = read(len)
            client:handleMessage(jsonStr)
        end)
    end
    
    -- 获取玩家ID
    function client:getPlayerId()
        return self.playerId
    end
    
    -- 获取玩家名称
    function client:getPlayerName()
        return self.playerName
    end
    
    -- 生成请求ID
    function client:generateRequestId()
        self.requestIdCounter = self.requestIdCounter + 1
        return "req_" .. self.requestIdCounter
    end
    
    -- 发送消息
    function client:sendMessage(message)
        if not self.connected then
            print("未连接到服务器，无法发送消息")
            return
        end
        
        -- 确保消息中的表被正确序列化
        local function prepareMessage(obj)
            if type(obj) == "table" then
                -- 检查是否是空表
                local isEmpty = true
                for k, v in pairs(obj) do
                    isEmpty = false
                    break
                end
                
                -- 对于空表，确保它是对象而不是数组
                if isEmpty then
                    return {}
                end
                
                local newObj = {}
                for k, v in pairs(obj) do
                    newObj[k] = prepareMessage(v)
                end
                return newObj
            else
                return obj
            end
        end
        
        local preparedMessage = prepareMessage(message)
        
        -- 将消息转换为JSON格式
        local jsonStr = y3.json.encode(preparedMessage)
        -- 添加4字节包头表示包体长度（大端序）
        local packet = string.pack('>s4', jsonStr)
        
        self.network:send(packet)
    end

    -- 发送聊天消息
    function client:sendChatMessage(content)
        local message = {
            type = "chat",
            playerId = self:getPlayerId(),
            playerName = self:getPlayerName(),
            content = content
        }
        self:sendMessage(message)
    end

    
    -- MongoDB 查询操作
    function client:findDocuments(collection, filter, options, callback)
        local requestId = self:generateRequestId()
        
        -- 确保filter和options是表类型
        if type(filter) ~= "table" then
            filter = {}
        end
        
        if type(options) ~= "table" then
            options = {}
        end
        
        local message = {
            service = "mongodb",
            type = "find",
            collection = collection,
            filter = filter,
            options = options,
            requestId = requestId
        }
        
        -- 存储回调函数
        if callback then
            self.pendingRequests = self.pendingRequests or {}
            self.pendingRequests[requestId] = callback
        end
        
        self:sendMessage(message)
        return requestId
    end
    
    -- MongoDB 插入操作
    function client:insertDocuments(collection, document, callback)
        local requestId = self:generateRequestId()
        
        local message = {
            service = "mongodb",
            type = "insert",
            collection = collection,
            document = document,
            requestId = requestId
        }
        
        -- 存储回调函数
        if callback then
            self.pendingRequests = self.pendingRequests or {}
            self.pendingRequests[requestId] = callback
        end
        
        self:sendMessage(message)
        return requestId
    end
    
    -- MongoDB 更新操作
    function client:updateDocuments(collection, filter, update, options, callback)
        local requestId = self:generateRequestId()
        
        -- 处理可选参数
        if type(options) == "function" then
            callback = options
            options = {}
        end
        
        local message = {
            service = "mongodb",
            type = "update",
            collection = collection,
            filter = filter,
            update = update,
            options = options or {},
            requestId = requestId
        }
        
        -- 存储回调函数
        if callback then
            self.pendingRequests = self.pendingRequests or {}
            self.pendingRequests[requestId] = callback
        end
        
        self:sendMessage(message)
        return requestId
    end
    
    -- MongoDB 删除操作
    function client:deleteDocuments(collection, filter, options, callback)
        local requestId = self:generateRequestId()
        
        -- 处理可选参数
        if type(options) == "function" then
            callback = options
            options = {}
        end
        
        local message = {
            service = "mongodb",
            type = "delete",
            collection = collection,
            filter = filter,
            options = options or {},
            requestId = requestId
        }
        
        -- 存储回调函数
        if callback then
            self.pendingRequests = self.pendingRequests or {}
            self.pendingRequests[requestId] = callback
        end
        
        self:sendMessage(message)
        return requestId
    end

    ---判断玩家是否和本地玩家在同一个房间
    ---@param playerName string 玩家名称
    ---@return boolean
    local function checkIsSameRoom(playerName)
        local player_group = y3.player_group:get_neutral_player_group():pick()
        for _, player in pairs(player_group) do
            if player:get_state() == 1 and GameAPI.get_player_full_nick_name(player.handle) == playerName then
                return true
            end
        end
        return false
    end

    -- 处理接收到的消息
    function client:handleMessage(jsonStr)
        local success, message = pcall(function()
            return y3.json.decode(jsonStr)
        end)
        
        if not success then
            print("解析消息失败:", jsonStr)
            return
        end
        
        -- 处理聊天消息
        if message.service == nil or message.service == "chat" then
            --- 如果是同一个房间也不需要展示接受到的消息
            if message.type == "chat" and not checkIsSameRoom(message.playerName) then
                y3.player.with_local(function (local_player)
                    --- 不重复给自己发消息
                    if local_player:get_platform_id() ~= message.playerId then
                        local_player:display_info("[" .. message.playerName .. "]: " .. message.content)
                    end
                end)
            elseif message.type == "system" then
                print("[系统]: " .. message.content)
            end
        -- 处理MongoDB响应
        elseif message.service == "mongodb" then
            -- 处理MongoDB操作结果
            if message.type == "findResult" or 
               message.type == "insertResult" or 
               message.type == "updateResult" or 
               message.type == "deleteResult" then
               
                -- 检查是否有对应的回调函数
                if self.pendingRequests and self.pendingRequests[message.requestId] then
                    local callback = self.pendingRequests[message.requestId]
                    self.pendingRequests[message.requestId] = nil
                    callback(message)
                else
                    print("收到MongoDB响应，但没有对应的回调函数:", message.type, message.requestId)
                end
            elseif message.type == "error" then
                print("MongoDB操作错误:", message.error)
                -- 如果有对应的回调函数，调用它并传递错误信息
                if self.pendingRequests and self.pendingRequests[message.requestId] then
                    local callback = self.pendingRequests[message.requestId]
                    self.pendingRequests[message.requestId] = nil
                    callback(nil, message.error)
                end
            end
        end
    end
    
    -- 断开连接
    function client:disconnect()
        if self.network and self.connected then
            -- 发送离开消息
            local leaveMessage = {
                type = "leave",
                playerId = self:getPlayerId(),
                playerName = self:getPlayerName()
            }
            self:sendMessage(leaveMessage)
            
            -- 断开网络连接
            self.network:remove()
            self.connected = false
        end
    end
    
    return client
end

return Client
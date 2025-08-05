local ChatClient = {}

function ChatClient.create(host, port, loginData)
    local client = {}
    
    client.host = host or '10.222.238.224'
    client.port = port or 25897
    client.connected = false
    client.network = nil
    client.playerId = loginData.playerId
    client.playerName = loginData.playerName
    
    -- 连接服务器
    function client:connect()
        print("正在连接聊天服务器:", self.host, self.port)
        
        -- 使用Y3的网络API连接服务器
        self.network = y3.network.connect(self.host, self.port, {
            update_interval = 0.05,
            timeout = 10,
        })
        
        -- 连接成功回调
        self.network:on_connected(function(network)
            print("已连接到聊天服务器")
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
            print("与聊天服务器断开连接")
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
    
    -- 获取玩家ID（示例实现）
    function client:getPlayerId()
        return self.playerId
    end
    
    -- 获取玩家名称（示例实现）
    function client:getPlayerName()
        return self.playerName
    end
    
    -- 发送消息
    function client:sendMessage(message)
        if not self.connected then
            print("未连接到服务器，无法发送消息")
            return
        end
        
        -- 将消息转换为JSON格式
        local jsonStr = y3.json.encode(message)
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
            content = content,
            timestamp = y3.game.get_current_server_time().timestamp
        }
        self:sendMessage(message)
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
        
        if message.type == "chat"then
            y3.player.with_local(function (local_player)
                if local_player:get_platform_id() ~= message.playerId then
                    local_player:display_info("[" .. message.playerName .. "]: " .. message.content)
                end
            end)
        elseif message.type == "system" then
            print("[系统]: " .. message.content)
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

return ChatClient
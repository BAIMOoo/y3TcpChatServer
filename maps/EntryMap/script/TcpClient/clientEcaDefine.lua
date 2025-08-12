local Client = require 'TcpClient.client'

--- 创建并链接客户端
--- @param ip string
--- @param port integer
function EcaCreateClient(ip, port)
    Client = Client.create(ip, port, {
        playerId = y3.player.get_local():get_platform_id(),
        playerName = GameAPI.get_player_full_nick_name(y3.player.get_local().handle)
    })
    Client:connect()
end

--- 查询指定集合下的所有文档
--- @param collection string
--- @return string
function EcaQueryAllDocuments(collection)
    --- filter为{}时，查询会返回指定集合下的所有文档
    local filter = {}
    local options = {}
    -- 查询用户集合中的所有文档
    local reqId = Client:findDocuments(collection, filter, options, function(result, error)
        if error then
            log.debug("查询失败:", error)
        else
            -- GameAPI.set_trigger_variable_table_save('__mgdb__'..collection, result)
            y3.eca.call('[回调]本地玩家查询指定集合下的所有文档', result.data, result.requestId)
        end
    end)
    return reqId
end

--- 查询指定集合下，指定key的文档
--- @param collection string
--- @param key string
--- @return string
function EcaQueryDocumentsByKey(collection, key)
    local filter = {
        key = key
    }
    local options = {}
    
    local reqId = Client:findDocuments(collection, filter, options, function(result, error)
        if error then
            log.debug("查询失败:", error)
        else
            y3.eca.call('[回调]本地玩家查询指定集合下指定key的文档', result.data, result.requestId)
        end
    end)
    return reqId
end

--- 查询指定集合下，指定_id的文档
--- @param collection string
--- @param id string
--- @return string
function EcaQueryDocumentsById(collection, id)
    local filter = {
        _id = id
    }
    local options = {}
    
    local reqId = Client:findDocuments(collection, filter, options, function(result, error)
        if error then
            log.debug("查询失败:", error)
        else
            y3.eca.call('[回调]本地玩家查询指定集合下指定id的文档', result.data, result.requestId)
        end
    end)
    return reqId
end

---在指定集合中插入文档
---@param collection string
---@param document table
---@return string
function EcaInsertDocument(collection, document)     
    local t = y3.helper.as_lua(document, true)
    local reqId = Client:insertDocuments(collection, t, function(result, error)
        if error then
            log.debug("插入失败:", error)
            y3.eca.call('[回调]在指定集合中插入文档', false, result.requestId)
        else
            y3.eca.call('[回调]在指定集合中插入文档', true, result.requestId)
        end
    end)
    return reqId
end

--- 更新指定集合下的指定key的文档
--- @param collection string
--- @param key string
--- @param document table
--- @return string
function EcaUpdateDocumentByKey(collection, key, document)
    local t = y3.helper.as_lua(document, true)  
    -- 定义过滤条件，查找需要更新的文档
    local filter = {
        key = key
    }
    
    -- 定义更新操作
    local update = {
        ["$set"] = t,
        ["$inc"] = {
            update_count = 1  -- 增加更新次数字段
        }
    }
    
    local options = {
        upsert = false  -- 如果没有匹配的文档，不创建新文档
    }
    
    -- 执行更新操作
    local reqId = Client:updateDocuments(collection, filter, update, options, function(result, error)
        if error then
            log.debug("更新失败:", error)
            y3.eca.call('[回调]更新指定集合下的指定key的文档', false, result.requestId)
        else      
            if result.matchedCount == 0 then
                log.debug("没有找到匹配的文档")
                y3.eca.call('[回调]更新指定集合下的指定key的文档', false, result.requestId)
            elseif result.modifiedCount == 0 then
                log.debug("找到了匹配的文档，但没有修改（可能是新值与旧值相同）")
                y3.eca.call('[回调]更新指定集合下的指定key的文档', false, result.requestId)
            else
                y3.eca.call('[回调]更新指定集合下的指定key的文档', true, result.requestId)
            end
        end
    end)
    return reqId
end


--- 更新指定集合下的指定_id的文档
--- @param collection string
--- @param id string
--- @param document table
--- @return string
function EcaUpdateDocumentById(collection, id, document)
    -- 定义过滤条件，查找需要更新的文档
    local filter = {
        _id = id
    }
    
    -- 定义更新操作
    local update = {
        ["$set"] = y3.helper.as_lua(document, true),
        ["$inc"] = {
            update_count = 1  -- 增加更新次数字段
        }
    }
    
    local options = {
        upsert = false  -- 如果没有匹配的文档，不创建新文档
    }
    
    -- 执行更新操作
    local reqId = Client:updateDocuments(collection, filter, update, options, function(result, error)
        if error then
            log.debug("更新失败:", error)
            y3.eca.call('[回调]更新指定集合下的指定id的文档', false, result.requestId)
        else      
            if result.matchedCount == 0 then
                log.debug("没有找到匹配的文档")
                y3.eca.call('[回调]更新指定集合下的指定id的文档', false, result.requestId)
            elseif result.modifiedCount == 0 then
                log.debug("找到了匹配的文档，但没有修改（可能是新值与旧值相同）")
                y3.eca.call('[回调]更新指定集合下的指定id的文档', false, result.requestId)
            else
                y3.eca.call('[回调]更新指定集合下的指定id的文档', true, result.requestId)
            end
        end
    end)
    return reqId
end

--- 删除指定集合下的指定key的文档
--- @param collection string
--- @param key string
--- @return string
function EcaDeleteDocumentByKey(collection, key)
    -- 定义过滤条件，删除特定的文档
    local filter = {
        key = key
    }
    
    -- 定义选项（可选）
    local options = {
        -- 默认只删除第一个匹配的文档
    }
    
    -- 执行删除操作
    local reqId = Client:deleteDocuments(collection, filter, options, function(result, error)
        if error then
            log.debug("删除失败:", error)
            y3.eca.call('[回调]删除指定集合下的指定key的文档', false, result.requestId)
        else
            if result.deletedCount == 0 then
                log.debug("没有找到匹配的文档进行删除")
                y3.eca.call('[回调]删除指定集合下的指定key的文档', false, result.requestId)
            else
                y3.eca.call('[回调]删除指定集合下的指定key的文档', true, result.requestId)
            end
        end
    end)
    return reqId
end

--- 删除指定集合下的指定id的文档
--- @param collection string
--- @param id string
--- @return string
function EcaDeleteDocumentById(collection, id)
    -- 定义过滤条件，删除特定的文档
    local filter = {
        _id = id
    }
    
    -- 定义选项（可选）
    local options = {
        -- 默认只删除第一个匹配的文档
    }
    
    -- 执行删除操作
    local reqId = Client:deleteDocuments(collection, filter, options, function(result, error)
        if error then
            log.debug("删除失败:", error)
            y3.eca.call('[回调]删除指定集合下的指定id的文档', false, result.requestId)
        else
            if result.deletedCount == 0 then
                log.debug("没有找到匹配的文档进行删除")
                y3.eca.call('[回调]删除指定集合下的指定id的文档', false, result.requestId)
            else
                y3.eca.call('[回调]删除指定集合下的指定id的文档', true, result.requestId)
            end
        end
    end)
    return reqId
end

local chatT = y3.game:event("玩家-发送消息", function(trg, data)
    -- 全服聊天
    if data.player == y3.player.get_local() then
        print('[聊天]', data.str1)
        Client:sendChatMessage(data.str1)
    end
end)

---comment
function EcaEnableChat()
    if chatT then
        chatT:enable()
    end 
end

---comment
function EcaDisableChat()
    if chatT then
        chatT:disable()
    end 
end
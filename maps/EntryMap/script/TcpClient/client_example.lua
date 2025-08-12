local Client = require 'Client'
-- 创建聊天客户端实例
local Client = Client.create('60.205.162.211', 25897, {
    playerId = y3.player.get_local():get_platform_id(),
    playerName = GameAPI.get_player_full_nick_name(y3.player.get_local().handle)
})

-- 连接到聊天服务器
Client:connect()

-- 监听游戏内事件来发送聊天消息
-- 例如：玩家按下回车键发送消息
y3.game:event("玩家-发送消息", function(trg, data)
    -- 断开链接 
    if data.str1 == 'lv' then
        Client:disconnect()
        return
    end

    -- 查询全局字符串存档测试
    if data.str1 == 'search' then
        --- filter为{}时，查询会返回指定集合下的所有文档
        local filter = {key = '地图1全局字符串'}
        local options = {}
        
        -- 查询用户集合中的所有文档
        Client:findDocuments("TESTCOL", filter, options, function(result, error)
            if error then
                print("查询失败:", error)
            else
                print("查询结果:")
                if result.data and type(result.data) == "table" then
                    for i, doc in ipairs(result.data) do
                        print(i, y3.json.encode(doc))
                    end
                else
                    print("没有找到数据或数据格式不正确")
                end
            end
        end)

        return
    end

    -- 插入单个文档测试
    if data.str1 == 'insert_one' then
        local document = {
            playerId = Client:getPlayerId(),
            playerName = Client:getPlayerName(),
            score = 100,
            level = 1,
            timestamp = 101010
        }
        
        Client:insertDocuments("TESTCOL", document, function(result, error)
            if error then
                print("插入失败:", error)
            else
                print("插入成功:")
                print("插入数量:", result.insertedCount)
                if result.insertedIds then
                    for k, v in pairs(result.insertedIds) do
                        print("插入ID:", k, v)
                    end
                end
            end
        end)
        
        return
    end

    -- 插入多个文档测试
    if data.str1 == 'insert_many' then
        local documents = {
            {
                playerId = Client:getPlayerId(),
                playerName = Client:getPlayerName(),
                itemType = "sword",
                level = 5,
                timestamp = y3.game.get_current_server_time().timestamp
            },
            {
                playerId = Client:getPlayerId(),
                playerName = Client:getPlayerName(),
                itemType = "shield",
                level = 3,
                timestamp = y3.game.get_current_server_time().timestamp
            },
            {
                playerId = Client:getPlayerId(),
                playerName = Client:getPlayerName(),
                itemType = "potion",
                count = 10,
                timestamp = y3.game.get_current_server_time().timestamp
            }
        }
        
        Client:insertDocuments("TESTCOL", documents, function(result, error)
            if error then
                print("批量插入失败:", error)
            else
                print("批量插入成功:")
                print("插入数量:", result.insertedCount)
                if result.insertedIds then
                    for k, v in pairs(result.insertedIds) do
                        print("插入ID:", k, v)
                    end
                end
            end
        end)
        
        return
    end

    -- 插入全局字符串数据测试
    if data.str1 == 'insert_global' then
        local document = {
            global_string = "This is a global string value",
            created_by = Client:getPlayerName(),
            created_at = y3.game.get_current_server_time().timestamp,
            type = "global_config"
        }
        
        Client:insertDocuments("TESTCOL", document, function(result, error)
            if error then
                print("插入全局字符串失败:", error)
            else
                print("插入全局字符串成功:")
                print("插入数量:", result.insertedCount)
                if result.insertedIds then
                    for k, v in pairs(result.insertedIds) do
                        print("插入ID:", k, v)
                    end
                end
            end
        end)
        
        return
    end
    -- 更新文档测试
    if data.str1 == 'update_test' then
        -- 定义过滤条件，查找需要更新的文档
        local filter = {
            key = '地图1全局字符串'
        }
        
        -- 定义更新操作
        local update = {
            ["$set"] = {
                score = 200,
                level = 2,
                value = '我是地图111',
                last_updated = 232323
            },
            ["$inc"] = {
                update_count = 1  -- 增加更新次数字段
            }
        }
        
        -- 定义选项（可选）
        local options = {
            upsert = false  -- 如果没有匹配的文档，不创建新文档
        }
        
        -- 执行更新操作
        Client:updateDocuments("TESTCOL", filter, update, options, function(result, error)
            if error then
                print("更新失败:", error)
            else
                print("更新操作完成:")
                print("匹配的文档数量:", result.matchedCount)
                print("修改的文档数量:", result.modifiedCount)
                
                if result.matchedCount == 0 then
                    print("没有找到匹配的文档")
                elseif result.modifiedCount == 0 then
                    print("找到了匹配的文档，但没有修改（可能是新值与旧值相同）")
                else
                    print("成功更新了", result.modifiedCount, "个文档")
                end
            end
        end)
        
        return
    end

    -- 批量更新测试
    if data.str1 == 'update_many' then
        -- 定义过滤条件，查找多个需要更新的文档
        local filter = {
            playerId = Client:getPlayerId()
        }
        
        -- 定义更新操作
        local update = {
            ["$set"] = {
                last_login = y3.game.get_current_server_time().timestamp,
                status = "active"
            }
        }
        
        -- 定义选项，启用批量更新
        local options = {
            multi = true,  -- 更新所有匹配的文档
            upsert = false
        }
        
        -- 执行批量更新操作
        Client:updateDocuments("TESTCOL", filter, update, options, function(result, error)
            if error then
                print("批量更新失败:", error)
            else
                print("批量更新操作完成:")
                print("匹配的文档数量:", result.matchedCount)
                print("修改的文档数量:", result.modifiedCount)
                print("成功更新了", result.modifiedCount, "个文档")
            end
        end)
        
        return
    end

    -- 更新或插入测试 (upsert)
    if data.str1 == 'upsert_test' then
        -- 定义过滤条件
        local filter = {
            playerId = Client:getPlayerId(),
            playerName = Client:getPlayerName(),
            type = "player_profile"
        }
        
        -- 定义更新操作
        local update = {
            ["$set"] = {
                playerName = Client:getPlayerName(),
                last_seen = y3.game.get_current_server_time().timestamp,
                login_count = 1
            },
            ["$setOnInsert"] = {
                created_at = y3.game.get_current_server_time().timestamp,
                login_count = 0
            }
        }
        
        -- 定义选项，启用upsert
        local options = {
            upsert = true  -- 如果没有匹配的文档，则创建新文档
        }
        
        -- 执行upsert操作
        Client:updateDocuments("TESTCOL", filter, update, options, function(result, error)
            if error then
                print("Upsert操作失败:", error)
            else
                print("Upsert操作完成:")
                print("匹配的文档数量:", result.matchedCount)
                print("修改的文档数量:", result.modifiedCount)
                
                -- 如果matchedCount为0但没有报错，说明执行了插入操作
                if result.matchedCount == 0 then
                    print("执行了插入操作（upsert）")
                else
                    print("执行了更新操作")
                end
            end
        end)
        
        return
    end

    -- 更新特定字段测试
    if data.str1 == 'update_field' then
        -- 查找特定的global_string文档
        local filter = {
            global_string = {["$exists"] = true}
        }
        
        -- 更新global_string字段
        local update = {
            ["$set"] = {
                global_string = "Updated global string value",
                updated_by = Client:getPlayerName(),
                updated_at = 202301
            }
        }
        
        local options = {
            multi = false  -- 只更新第一个匹配的文档
        }
        
        -- 执行更新操作
        Client:updateDocuments("TESTCOL", filter, update, options, function(result, error)
            if error then
                print("字段更新失败:", error)
            else
                print("字段更新完成:")
                print("匹配的文档数量:", result.matchedCount)
                print("修改的文档数量:", result.modifiedCount)
            end
        end)
        
        return
    end

    -- 删除单个文档测试
    if data.str1 == 'delete_one' then
        -- 定义过滤条件，删除特定的文档
        local filter = {
            score = 200
        }
        
        -- 定义选项（可选）
        local options = {
            -- 默认只删除第一个匹配的文档
        }
        
        -- 执行删除操作
        Client:deleteDocuments("TESTCOL", filter, options, function(result, error)
            if error then
                print("删除失败:", error)
            else
                print("删除操作完成:")
                print("删除的文档数量:", result.deletedCount)
                
                if result.deletedCount == 0 then
                    print("没有找到匹配的文档进行删除")
                else
                    print("成功删除了", result.deletedCount, "个文档")
                end
            end
        end)
        
        return
    end

    -- 批量删除测试
    if data.str1 == 'delete_many' then
        -- 定义过滤条件，删除多个文档
        local filter = {
            playerId = Client:getPlayerId(),
            itemType = {["$in"] = {"sword", "shield", "potion"}}
        }
        
        -- 定义选项，启用批量删除
        local options = {
            multi = true  -- 删除所有匹配的文档
        }
        
        -- 执行批量删除操作
        Client:deleteDocuments("TESTCOL", filter, options, function(result, error)
            if error then
                print("批量删除失败:", error)
            else
                print("批量删除操作完成:")
                print("删除的文档数量:", result.deletedCount)
                print("成功删除了", result.deletedCount, "个文档")
            end
        end)
        
        return
    end

    -- 删除特定类型文档测试
    if data.str1 == 'delete_type' then
        -- 删除特定类型的文档
        local filter = {
            type = "global_config"
        }
        
        local options = {
            multi = true  -- 删除所有匹配的文档
        }
        
        -- 执行删除操作
        Client:deleteDocuments("TESTCOL", filter, options, function(result, error)
            if error then
                print("删除特定类型文档失败:", error)
            else
                print("删除特定类型文档完成:")
                print("删除的文档数量:", result.deletedCount)
            end
        end)
        
        return
    end

    -- 删除所有玩家数据测试（谨慎使用）
    if data.str1 == 'delete_all_mine' then
        -- 删除当前玩家的所有数据
        local filter = {
            playerId = Client:getPlayerId()
        }
        
        local options = {
            multi = true  -- 删除所有匹配的文档
        }
        
        -- 执行删除操作
        Client:deleteDocuments("TESTCOL", filter, options, function(result, error)
            if error then
                print("删除所有玩家数据失败:", error)
            else
                print("删除所有玩家数据完成:")
                print("删除的文档数量:", result.deletedCount)
                print("成功删除了", result.deletedCount, "个文档")
            end
        end)
        
        return
    end

    -- 删除过期数据测试
    if data.str1 == 'delete_expired' then
        -- 删除过期的数据（假设有一个timestamp字段）
        local filter = {
            timestamp = {["$lt"] = y3.game.get_current_server_time().timestamp - 86400}  -- 删除一天前的数据
        }
        
        local options = {
            multi = true
        }
        
        -- 执行删除操作
        Client:deleteDocuments("TESTCOL", filter, options, function(result, error)
            if error then
                print("删除过期数据失败:", error)
            else
                print("删除过期数据完成:")
                print("删除的文档数量:", result.deletedCount)
            end
        end)
        
        return
    end

    -- 删除包含特定字段的文档
    if data.str1 == 'delete_has_field' then
        -- 删除包含global_string字段的文档
        local filter = {
            global_string = {["$exists"] = true}
        }
        
        local options = {
            multi = true
        }
        
        -- 执行删除操作
        Client:deleteDocuments("TESTCOL", filter, options, function(result, error)
            if error then
                print("删除包含特定字段的文档失败:", error)
            else
                print("删除包含特定字段的文档完成:")
                print("删除的文档数量:", result.deletedCount)
            end
        end)
        
        return
    end

    if data.player == y3.player.get_local() then
        Client:sendChatMessage(data.str1)
    end

end)

-- 提供全局访问点
_G.Client = Client

-- 返回客户端实例以供其他脚本使用
return Client
-- 全服聊天功能使用示例
local ChatClient = require 'chat_client'
-- 创建聊天客户端实例
local chatClient = ChatClient.create('10.222.238.224', 25897, {
    playerId = y3.player.get_local():get_platform_id(),
    playerName = GameAPI.get_player_full_nick_name(y3.player.get_local().handle)
})

-- 连接到聊天服务器
chatClient:connect()

-- 等待连接建立后发送测试消息
y3.ltimer.wait(2, function()
    if chatClient.connected then
        chatClient:sendChatMessage("大家好！我是新玩家。")
    end
end)

-- 监听游戏内事件来发送聊天消息
-- 例如：玩家按下回车键发送消息
y3.game:event("玩家-发送消息", function(trg, data)
    if data.str1 == 'lv' then
        chatClient:disconnect()
        return
    end
    if data.player == y3.player.get_local() then
        chatClient:sendChatMessage(data.str1)
    end

end)

-- 提供全局访问点
_G.chatClient = chatClient

-- 返回客户端实例以供其他脚本使用
return chatClient
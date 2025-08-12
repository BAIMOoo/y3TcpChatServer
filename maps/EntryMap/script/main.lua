-- 游戏启动后会自动运行此文件
--在开发模式下，将日志打印到游戏中

y3.config.log.level  = 'debug'


y3.game:event('游戏-初始化', function (trg, data)
    print('Hello, Y3!')
end)

y3.game:event("玩家-发送消息", function(trg, data)
    -- 断开链接
    if data.str1 == 'lv' then
        Client:disconnect()
        return
    end
    -- 全服聊天
    if data.player == y3.player.get_local() then
        Client:sendChatMessage(data.str1)
    end

end)

require 'TcpClient.clientEcaDefine'
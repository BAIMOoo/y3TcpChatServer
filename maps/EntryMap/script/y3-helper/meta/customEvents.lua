---@class ECAHelper
---@field call fun(name: '[回调]本地玩家查询指定集合下的所有文档', result: table, 请求id: string)
---@field call fun(name: '[回调]本地玩家查询指定集合下指定key的文档', result: table, 请求id: string)
---@field call fun(name: '[回调]本地玩家查询指定集合下指定id的文档', result: table, 请求id: string)
---@field call fun(name: '[回调]在指定集合中插入文档', 是否插入成功: boolean, 请求id: string)
---@field call fun(name: '[回调]更新指定集合下的指定key的文档', 是否更新成功: boolean, 请求id: string)
---@field call fun(name: '[回调]更新指定集合下的指定id的文档', 是否更新成功: boolean, 请求id: string)
---@field call fun(name: '[回调]删除指定集合下的指定key的文档', 是否删除成功: boolean, 请求id: string)
---@field call fun(name: '[回调]删除指定集合下的指定id的文档', 是否删除成功: boolean, 请求id: string)

---@diagnostic disable: invisible

y3.eca = y3.eca or {}
y3.eca.register_custom_event_impl = y3.eca.register_custom_event_impl or function (name, impl) end
y3.eca.register_custom_event_resolve = y3.eca.register_custom_event_resolve or function (name, resolve) end

y3.eca.register_custom_event_impl('[回调]本地玩家查询指定集合下的所有文档', function (_, result, 请求id)
    y3.game.send_custom_event(1769892995, {
        ["result"] = result,
        ["请求id"] = 请求id
    })
end)

y3.eca.register_custom_event_impl('[回调]本地玩家查询指定集合下指定key的文档', function (_, result, 请求id)
    y3.game.send_custom_event(1823476942, {
        ["result"] = result,
        ["请求id"] = 请求id
    })
end)

y3.eca.register_custom_event_impl('[回调]本地玩家查询指定集合下指定id的文档', function (_, result, 请求id)
    y3.game.send_custom_event(1314992201, {
        ["result"] = result,
        ["请求id"] = 请求id
    })
end)

y3.eca.register_custom_event_impl('[回调]在指定集合中插入文档', function (_, 是否插入成功, 请求id)
    y3.game.send_custom_event(2090989310, {
        ["是否插入成功"] = 是否插入成功,
        ["请求id"] = 请求id
    })
end)

y3.eca.register_custom_event_impl('[回调]更新指定集合下的指定key的文档', function (_, 是否更新成功, 请求id)
    y3.game.send_custom_event(1644828896, {
        ["是否更新成功"] = 是否更新成功,
        ["请求id"] = 请求id
    })
end)

y3.eca.register_custom_event_impl('[回调]更新指定集合下的指定id的文档', function (_, 是否更新成功, 请求id)
    y3.game.send_custom_event(1769069557, {
        ["是否更新成功"] = 是否更新成功,
        ["请求id"] = 请求id
    })
end)

y3.eca.register_custom_event_impl('[回调]删除指定集合下的指定key的文档', function (_, 是否删除成功, 请求id)
    y3.game.send_custom_event(1543859026, {
        ["是否删除成功"] = 是否删除成功,
        ["请求id"] = 请求id
    })
end)

y3.eca.register_custom_event_impl('[回调]删除指定集合下的指定id的文档', function (_, 是否删除成功, 请求id)
    y3.game.send_custom_event(1791002452, {
        ["是否删除成功"] = 是否删除成功,
        ["请求id"] = 请求id
    })
end)

y3.const.CustomEventName = y3.const.CustomEventName or {}

y3.const.CustomEventName['[回调]本地玩家查询指定集合下的所有文档'] = 1769892995
y3.const.CustomEventName['[回调]本地玩家查询指定集合下指定key的文档'] = 1823476942
y3.const.CustomEventName['[回调]本地玩家查询指定集合下指定id的文档'] = 1314992201
y3.const.CustomEventName['[回调]在指定集合中插入文档'] = 2090989310
y3.const.CustomEventName['[回调]更新指定集合下的指定key的文档'] = 1644828896
y3.const.CustomEventName['[回调]更新指定集合下的指定id的文档'] = 1769069557
y3.const.CustomEventName['[回调]删除指定集合下的指定key的文档'] = 1543859026
y3.const.CustomEventName['[回调]删除指定集合下的指定id的文档'] = 1791002452

---@enum(key, partial) y3.Const.CustomEventName
local CustomEventName = {
    ['[回调]本地玩家查询指定集合下的所有文档'] = 1769892995,
    ['[回调]本地玩家查询指定集合下指定key的文档'] = 1823476942,
    ['[回调]本地玩家查询指定集合下指定id的文档'] = 1314992201,
    ['[回调]在指定集合中插入文档'] = 2090989310,
    ['[回调]更新指定集合下的指定key的文档'] = 1644828896,
    ['[回调]更新指定集合下的指定id的文档'] = 1769069557,
    ['[回调]删除指定集合下的指定key的文档'] = 1543859026,
    ['[回调]删除指定集合下的指定id的文档'] = 1791002452,
}

y3.eca.register_custom_event_resolve("[回调]本地玩家查询指定集合下的所有文档", function (data)
    data.name = "[回调]本地玩家查询指定集合下的所有文档"
    data.data = {
        ["result"] = data.c_param_dict["result"],
        ["请求id"] = data.c_param_dict["请求id"],
    }
    return data
end)
y3.eca.register_custom_event_resolve("[回调]本地玩家查询指定集合下指定key的文档", function (data)
    data.name = "[回调]本地玩家查询指定集合下指定key的文档"
    data.data = {
        ["result"] = data.c_param_dict["result"],
        ["请求id"] = data.c_param_dict["请求id"],
    }
    return data
end)
y3.eca.register_custom_event_resolve("[回调]本地玩家查询指定集合下指定id的文档", function (data)
    data.name = "[回调]本地玩家查询指定集合下指定id的文档"
    data.data = {
        ["result"] = data.c_param_dict["result"],
        ["请求id"] = data.c_param_dict["请求id"],
    }
    return data
end)
y3.eca.register_custom_event_resolve("[回调]在指定集合中插入文档", function (data)
    data.name = "[回调]在指定集合中插入文档"
    data.data = {
        ["是否插入成功"] = data.c_param_dict["是否插入成功"],
        ["请求id"] = data.c_param_dict["请求id"],
    }
    return data
end)
y3.eca.register_custom_event_resolve("[回调]更新指定集合下的指定key的文档", function (data)
    data.name = "[回调]更新指定集合下的指定key的文档"
    data.data = {
        ["是否更新成功"] = data.c_param_dict["是否更新成功"],
        ["请求id"] = data.c_param_dict["请求id"],
    }
    return data
end)
y3.eca.register_custom_event_resolve("[回调]更新指定集合下的指定id的文档", function (data)
    data.name = "[回调]更新指定集合下的指定id的文档"
    data.data = {
        ["是否更新成功"] = data.c_param_dict["是否更新成功"],
        ["请求id"] = data.c_param_dict["请求id"],
    }
    return data
end)
y3.eca.register_custom_event_resolve("[回调]删除指定集合下的指定key的文档", function (data)
    data.name = "[回调]删除指定集合下的指定key的文档"
    data.data = {
        ["是否删除成功"] = data.c_param_dict["是否删除成功"],
        ["请求id"] = data.c_param_dict["请求id"],
    }
    return data
end)
y3.eca.register_custom_event_resolve("[回调]删除指定集合下的指定id的文档", function (data)
    data.name = "[回调]删除指定集合下的指定id的文档"
    data.data = {
        ["是否删除成功"] = data.c_param_dict["是否删除成功"],
        ["请求id"] = data.c_param_dict["请求id"],
    }
    return data
end)

---@alias EventParam.游戏-消息._回调_本地玩家查询指定集合下的所有文档 { c_param_1: 1769892995, c_param_dict: py.Dict, event: "[回调]本地玩家查询指定集合下的所有文档", data: { ["result"]: table, ["请求id"]: string } }
---@alias EventParam.游戏-消息._回调_本地玩家查询指定集合下指定key的文档 { c_param_1: 1823476942, c_param_dict: py.Dict, event: "[回调]本地玩家查询指定集合下指定key的文档", data: { ["result"]: table, ["请求id"]: string } }
---@alias EventParam.游戏-消息._回调_本地玩家查询指定集合下指定id的文档 { c_param_1: 1314992201, c_param_dict: py.Dict, event: "[回调]本地玩家查询指定集合下指定id的文档", data: { ["result"]: table, ["请求id"]: string } }
---@alias EventParam.游戏-消息._回调_在指定集合中插入文档 { c_param_1: 2090989310, c_param_dict: py.Dict, event: "[回调]在指定集合中插入文档", data: { ["是否插入成功"]: boolean, ["请求id"]: string } }
---@alias EventParam.游戏-消息._回调_更新指定集合下的指定key的文档 { c_param_1: 1644828896, c_param_dict: py.Dict, event: "[回调]更新指定集合下的指定key的文档", data: { ["是否更新成功"]: boolean, ["请求id"]: string } }
---@alias EventParam.游戏-消息._回调_更新指定集合下的指定id的文档 { c_param_1: 1769069557, c_param_dict: py.Dict, event: "[回调]更新指定集合下的指定id的文档", data: { ["是否更新成功"]: boolean, ["请求id"]: string } }
---@alias EventParam.游戏-消息._回调_删除指定集合下的指定key的文档 { c_param_1: 1543859026, c_param_dict: py.Dict, event: "[回调]删除指定集合下的指定key的文档", data: { ["是否删除成功"]: boolean, ["请求id"]: string } }
---@alias EventParam.游戏-消息._回调_删除指定集合下的指定id的文档 { c_param_1: 1791002452, c_param_dict: py.Dict, event: "[回调]删除指定集合下的指定id的文档", data: { ["是否删除成功"]: boolean, ["请求id"]: string } }

---@class Game
---@diagnostic disable-next-line: duplicate-doc-field
---@field event fun(self: Game, event: "游戏-消息", event_id: "[回调]本地玩家查询指定集合下的所有文档", callback: fun(trigger: Trigger, data: EventParam.游戏-消息._回调_本地玩家查询指定集合下的所有文档))
---@diagnostic disable-next-line: duplicate-doc-field
---@field event fun(self: Game, event: "游戏-消息", event_id: "[回调]本地玩家查询指定集合下指定key的文档", callback: fun(trigger: Trigger, data: EventParam.游戏-消息._回调_本地玩家查询指定集合下指定key的文档))
---@diagnostic disable-next-line: duplicate-doc-field
---@field event fun(self: Game, event: "游戏-消息", event_id: "[回调]本地玩家查询指定集合下指定id的文档", callback: fun(trigger: Trigger, data: EventParam.游戏-消息._回调_本地玩家查询指定集合下指定id的文档))
---@diagnostic disable-next-line: duplicate-doc-field
---@field event fun(self: Game, event: "游戏-消息", event_id: "[回调]在指定集合中插入文档", callback: fun(trigger: Trigger, data: EventParam.游戏-消息._回调_在指定集合中插入文档))
---@diagnostic disable-next-line: duplicate-doc-field
---@field event fun(self: Game, event: "游戏-消息", event_id: "[回调]更新指定集合下的指定key的文档", callback: fun(trigger: Trigger, data: EventParam.游戏-消息._回调_更新指定集合下的指定key的文档))
---@diagnostic disable-next-line: duplicate-doc-field
---@field event fun(self: Game, event: "游戏-消息", event_id: "[回调]更新指定集合下的指定id的文档", callback: fun(trigger: Trigger, data: EventParam.游戏-消息._回调_更新指定集合下的指定id的文档))
---@diagnostic disable-next-line: duplicate-doc-field
---@field event fun(self: Game, event: "游戏-消息", event_id: "[回调]删除指定集合下的指定key的文档", callback: fun(trigger: Trigger, data: EventParam.游戏-消息._回调_删除指定集合下的指定key的文档))
---@diagnostic disable-next-line: duplicate-doc-field
---@field event fun(self: Game, event: "游戏-消息", event_id: "[回调]删除指定集合下的指定id的文档", callback: fun(trigger: Trigger, data: EventParam.游戏-消息._回调_删除指定集合下的指定id的文档))

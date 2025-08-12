---配置
---
---可以设置日志、同步等相关的配置
---@class Config
local M = Class 'Config'

---同步相关的配置，当设置为 `true` 后将启用同步，
---会产生额外的流量。  
---同步需要一定的时间，获取到的是一小段时间前的状态，
---因此启用同步后不能立即获取状态。  
---@class Config.Sync
---@field mouse boolean # 同步玩家的鼠标位置
---@field key boolean # 同步玩家的键盘与鼠标按键
---@field camera boolean # 同步玩家的镜头
M.sync = y3.proxy.new({
    mouse  = false,
    key    = false,
    camera = false,
}, {
    updateRaw = true,
    setter = {
        mouse = function (self, raw, key, value, config)
            assert(type(value) == 'boolean', ('`Config.sync.%s` 的赋值类型必须是 `boolean`'):format(key))
            GameAPI.force_enable_mouse_sync(value)
            return value
        end,
        key = function (self, raw, key, value, config)
            assert(type(value) == 'boolean', ('`Config.sync.%s` 的赋值类型必须是 `boolean`'):format(key))
            GameAPI.force_enable_keyboard_sync(value)
            return value
        end,
        camera = function (self, raw, key, value, config)
            assert(type(value) == 'boolean', ('`Config.sync.%s` 的赋值类型必须是 `boolean`'):format(key))
            GameAPI.force_enable_camera_sync(value)
            return value
        end,
    },
})

-- 是否是debug模式
---@type boolean|'auto'
M.debug = 'auto'

---@class Config.Log
---@field level Log.Level # 日志等级，默认为 `debug`
---@field toFile boolean # 是否打印到文件中，默认为 `true`
---@field toDialog boolean # 是否打印到Dialog窗口，默认为 `true`
---@field toConsole boolean # 是否打印到控制台中，默认为 `true`
---@field toGame boolean # 是否打印到游戏窗口中，默认为 `false`
---@field toHelper boolean # 是否打印到《Y3开发助手》中，默认为 `true`
---@field logger fun(level: Log.Level, message: string, timeStamp: string): boolean # 自定义的日志处理函数，返回 `true` 将阻止默认的日志处理。在处理函数的执行过程中会屏蔽此函数。
-- 日志相关的配置
M.log = y3.proxy.new({
    level     = 'debug',
    toFile    = true,
    toDialog  = true,
    toConsole = true,
    toGmae    = false,
    toHelper  = true,
}, {
    updateRaw = true,
    setter = {
        level = function (self, raw, key, value, config)
            log.level = value
        end,
        toFile = function (self, raw, key, value, config)
            log.enable = value
        end,
    }
})

---每秒的逻辑帧率，请将其设置为与你地图中设置的一致。
---目前默认为30帧，未来默认会读取你地图中的设置。
---必须在游戏开始时就设置好，请勿中途修改。
M.logic_frame = GameAPI.api_get_logic_fps
            and GameAPI.api_get_logic_fps()
            or  30

---缓存相关的配置，一般要求你不在ECA中操作相关的对象才可以使用缓存。
M.cache = {
    ---是否对UI进行缓存。需要保证你没有在ECA中操作UI。
    ui = false,
}

---动态执行代码相关的设置
M.code = {
    ---在非debug模式下是否允许执行本地代码。
    enable_local = false,
    ---在非debug模式下是否允许执行其他玩家广播过来的远程代码。
    enable_remote = false,
}

---界面相关设置
M.ui = {
}

---运动器直接使用引擎接口注册
M.mover = {
    enable_internal_regist = false
}

M.ref = {
    -- 控制当单位回归对象池时是否清除lua中技能和魔法效果的引用
    -- 默认行为不清除，从对象池复用的单位在事件单位创建中获取技能和魔法效果的对象会有包含事件触发器、storage等数据
    -- 注意: 从对象池复用的单位不会再触发技能-获得以及效果-获得事件
    clear_ref_when_unit_return_to_pool = false
}

return M

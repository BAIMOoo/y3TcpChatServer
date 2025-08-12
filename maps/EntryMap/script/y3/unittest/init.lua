Class   = require 'y3.tools.class'.declare
New     = require 'y3.tools.class'.new
Extends = require 'y3.tools.class'.extends
IsValid = require 'y3.tools.class'.isValid
Type    = require 'y3.tools.class'.type
Delete  = require 'y3.tools.class'.delete

---@class Log
log = {
    error = print,
}

---@class Y3
y3 = {}
y3.util    = require 'y3.tools.utility'
y3.reload  = require 'y3.tools.reload'
y3.linked_table = require 'y3.tools.linked-table'

require 'y3.util.event'
require 'y3.util.event_manager'
require 'y3.util.custom_event'
y3.trigger = require 'y3.util.trigger'

require 'y3.unittest.eventtest'
require 'y3.unittest.eventperform'
require 'y3.unittest.ltimer'

print('测试完成！')

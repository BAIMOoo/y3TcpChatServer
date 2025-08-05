# 全服聊天系统

这个项目包含一个基于Node.js的聊天服务器和一个基于Lua的客户端，用于Y3游戏引擎中实现全服聊天功能。

## 服务端 (Node.js)

### 启动服务器

```bash
node chat_server.js
```

默认监听端口为 25897。

### 服务器特性

1. 使用TCP协议进行通信
2. 采用自定义协议：4字节包头（大端序）+ JSON包体
3. 支持玩家加入、聊天和离开消息
4. 自动广播消息给所有连接的客户端

## 客户端 (Lua)

### 集成到游戏中

```lua
local ChatClient = require 'chat_client'
local chatClient = ChatClient.create('127.0.0.1', 25897)
chatClient:connect()
```

### 发送聊天消息

```lua
chatClient:sendChatMessage("你好，世界！")
```

### 断开连接

```lua
chatClient:disconnect()
```

## 协议格式

所有消息都使用以下格式：

```
[4字节包头，表示JSON数据长度][JSON格式数据]
```

### 消息类型

1. **join** - 玩家加入游戏
   ```json
   {
     "type": "join",
     "playerId": "player_1234",
     "playerName": "张三"
   }
   ```

2. **chat** - 聊天消息
   ```json
   {
     "type": "chat",
     "playerId": "player_1234",
     "playerName": "张三",
     "content": "你好！",
     "timestamp": 1234567890
   }
   ```

3. **leave** - 玩家离开游戏
   ```json
   {
     "type": "leave",
     "playerId": "player_1234",
     "playerName": "张三"
   }
   ```

4. **system** - 系统消息（由服务器广播）
   ```json
   {
     "type": "system",
     "content": "张三加入了游戏"
   }
   ```

## 使用示例

参考 [chat_example.lua](chat_example.lua) 文件了解如何在Y3引擎中使用聊天客户端。
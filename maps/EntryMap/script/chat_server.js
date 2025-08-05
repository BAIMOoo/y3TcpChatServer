const net = require('net');
const EventEmitter = require('events');

// 简单的消息协议：4字节包头（大端序）+ JSON数据包体
class MessageProtocol {
    static encode(data) {
        const jsonStr = JSON.stringify(data);
        const len = Buffer.byteLength(jsonStr);
        const buffer = Buffer.alloc(4 + len);
        buffer.writeUInt32BE(len, 0);
        buffer.write(jsonStr, 4);
        return buffer;
    }

    static decode(buffer) {
        if (buffer.length < 4) {
            return null;
        }
        const len = buffer.readUInt32BE(0);
        if (buffer.length < 4 + len) {
            return null;
        }
        const jsonStr = buffer.toString('utf8', 4, 4 + len);
        const data = JSON.parse(jsonStr);
        const consumed = 4 + len;
        return { data, consumed };
    }
}

// 聊天服务器类
class ChatServer extends EventEmitter {
    constructor() {
        super();
        this.clients = new Map(); // 存储所有连接的客户端
        this.clientIdCounter = 0;
    }

    // 启动服务器
    start(port = 25897) {
        this.server = net.createServer((socket) => {
            this.handleConnection(socket);
        });

        this.server.listen(port, () => {
            console.log(`聊天服务器已在端口 ${port} 上启动`);
        });

        this.server.on('error', (err) => {
            console.error('服务器错误:', err);
        });
    }

    // 处理客户端连接
    handleConnection(socket) {
        this.clientIdCounter++;
        const clientId = this.clientIdCounter;
        
        console.log(`客户端 ${clientId} 已连接`);
        
        // 初始化客户端数据
        const client = {
            id: clientId,
            socket: socket,
            playerId: null,
            playerName: null
        };
        
        this.clients.set(clientId, client);
        
        // 设置数据接收处理
        let buffer = Buffer.alloc(0);
        socket.on('data', (data) => {
            buffer = Buffer.concat([buffer, data]);
            this.handleData(client, buffer, (newBuffer) => {
                buffer = newBuffer;
            });
        });
        
        // 处理连接断开
        socket.on('close', () => {
            this.handleDisconnection(client);
        });
        
        // 处理错误
        socket.on('error', (err) => {
            console.error(`客户端 ${clientId} 发生错误:`, err);
        });
    }

    // 处理数据接收
    handleData(client, buffer, callback) {
        const result = MessageProtocol.decode(buffer);
        if (result) {
            this.handleMessage(client, result.data);
            const remainingBuffer = buffer.slice(result.consumed);
            callback(remainingBuffer);
            // 继续处理剩余数据
            if (remainingBuffer.length > 0) {
                this.handleData(client, remainingBuffer, callback);
            }
        } else {
            callback(buffer);
        }
    }

    // 处理消息
    handleMessage(client, message) {
        console.log(`收到来自客户端 ${client.id} 的消息:`, message);
        
        switch (message.type) {
            case 'join':
                this.handleJoin(client, message);
                break;
            case 'chat':
                this.handleChat(client, message);
                break;
            case 'leave':
                this.handleLeave(client, message);
                break;
            default:
                console.log(`未知消息类型: ${message.type}`);
        }
    }

    // 处理玩家加入
    handleJoin(client, message) {
        client.playerId = message.playerId;
        client.playerName = message.playerName;
        
        console.log(`${client.playerName} 加入了游戏`);
        
        // 向所有客户端广播加入消息
        const joinMessage = {
            type: 'system',
            content: `${client.playerName} 加入了游戏`
        };
        
        this.broadcast(joinMessage, client.id);
    }

    // 处理聊天消息
    handleChat(client, message) {
        if (!client.playerName) {
            console.log(`未注册的客户端 ${client.id} 尝试发送消息`);
            return;
        }
        
        console.log(`[${client.playerName}]: ${message.content}`);
        
        // 广播聊天消息给所有客户端
        const chatMessage = {
            type: 'chat',
            playerId: client.playerId,
            playerName: client.playerName,
            content: message.content,
            timestamp: Date.now()
        };
        
        this.broadcast(chatMessage);
    }

    // 处理玩家离开
    handleLeave(client, message) {
        if (client.playerName) {
            console.log(`${client.playerName} 离开了游戏`);
            
            // 广播离开消息
            const leaveMessage = {
                type: 'system',
                content: `${client.playerName} 离开了游戏`
            };
            
            this.broadcast(leaveMessage);
        }
    }

    // 处理客户端断开连接
    handleDisconnection(client) {
        console.log(`客户端 ${client.id} 断开连接`);
        this.clients.delete(client.id);
        
        // 如果玩家已加入游戏，则广播离开消息
        if (client.playerName) {
            const leaveMessage = {
                type: 'system',
                content: `${client.playerName} 离开了游戏`
            };
            
            this.broadcast(leaveMessage);
        }
    }

    // 广播消息给所有客户端
    broadcast(message, excludeClientId = null) {
        const buffer = MessageProtocol.encode(message);
        for (const [clientId, client] of this.clients) {
            if (clientId !== excludeClientId && client.socket.writable) {
                client.socket.write(buffer);
            }
        }
    }
}

// 启动服务器
const server = new ChatServer();
server.start(25897);
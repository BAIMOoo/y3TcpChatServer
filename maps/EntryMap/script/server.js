const net = require('net');
const EventEmitter = require('events');
const mongoUri = "mongodb+srv://BAIM:710717@cluster0.uxhwf7q.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0";
const dbName = "TESTDB"; // 替换为你的数据库名称
const { MongoClient, ServerApiVersion, ObjectId } = require('mongodb');

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

// 新增服务基类
class Service {
    constructor(server) {
        this.server = server;
    }
    
    // 服务需要实现的方法
    handleConnection(socket) {}
    handleMessage(client, message) {}
    handleDisconnection(client) {}
}

// 聊天服务类
class ChatService extends Service {
    constructor(server) {
        super(server);
        this.clients = new Map();
    }

    handleJoin(client, message) {
        client.playerId = message.playerId;
        client.playerName = message.playerName;
        
        console.log(`${client.playerName} 加入了游戏`);
        
        this.clients.set(message.playerId, client);
        
        const joinMessage = {
            type: 'system',
            content: `${client.playerName} 加入了游戏`
        };
        
        this.server.broadcast('chat', joinMessage, client.id);
    }

    handleChat(client, message) {
        if (!client.playerName) {
            console.log(`未注册的客户端 ${client.id} 尝试发送消息`);
            return;
        }
        
        // console.log(`[${client.playerName}]: ${message.content}`);
        
        const chatMessage = {
            type: 'chat',
            playerId: client.playerId,
            playerName: client.playerName,
            content: message.content,
            timestamp: message.timestamp
        };
        
        this.server.broadcast('chat', chatMessage);
    }

    handleLeave(client, message) {
        if (client.playerName) {
            console.log(`${client.playerName} 离开了游戏`);
        }
        
        this.clients.delete(client.playerId);
        client.socket.end();
    }

    handleDisconnection(client) {
        if (client.disconnected) {
            return;
        }
        
        client.disconnected = true;
        
        const clientId = client.playerId || client.id;
        console.log(`客户端 ${clientId} 断开连接`);
        
        if (client.playerId) {
            this.clients.delete(client.playerId);
        }
        
        if (client.socket && !client.socket.destroyed) {
            client.socket.destroy();
        }
    }

    handleMessage(client, message) {
        // console.log(`收到来自客户端 ${client.id} 的消息:`, message);
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
}

// MongoDB服务类
class MongoDBService extends Service {
    constructor(server) {
        super(server);
        this.collections = new Map(); // 存储不同集合的引用
        this.db = null;
        this.client = null;
        this.initialized = false;
    }

    // 初始化MongoDB连接
    async initialize(mongoUri, dbName) {
        try {
            
            
            this.client = new MongoClient(mongoUri, {
                serverApi: {
                    version: ServerApiVersion.v1,
                    strict: true,
                    deprecationErrors: true,
                }
            });
            
            await this.client.connect();
            console.log("MongoDB服务已成功连接!");
            
            this.db = this.client.db(dbName);
            this.initialized = true;
        } catch (error) {
            console.error("MongoDB连接失败:", error);
        }
    }

    // 验证参数是否为有效的对象
    validateObject(obj, paramName) {
        // 如果参数不存在或为null，返回空对象
        if (obj === null || obj === undefined) {
            return {};
        }
        
        // 如果参数是对象且不是数组，直接返回
        if (typeof obj === 'object' && !Array.isArray(obj)) {
            return obj;
        }
        
        // 其他情况，记录警告并返回空对象
        // console.warn(`${paramName}不是有效的对象，使用空对象替代:`, obj);
        return {};
    }

    // 获取集合引用
    getCollection(collectionName) {
        if (!this.initialized) {
            throw new Error("MongoDB服务尚未初始化");
        }
        
        if (!this.collections.has(collectionName)) {
            const collection = this.db.collection(collectionName);
            this.collections.set(collectionName, collection);
        }
        return this.collections.get(collectionName);
    }

    // 处理MongoDB相关消息
    async handleMessage(client, message) {
        // 检查服务是否已初始化
        if (!this.initialized) {
            this.sendError(client, "MongoDB服务尚未初始化");
            return;
        }
        
        // console.log(`收到来自客户端 ${client.id} 的MongoDB消息:`, message);
        try {
            switch (message.type) {
                case 'find':
                    await this.handleFind(client, message);
                    break;
                case 'insert':
                    await this.handleInsert(client, message);
                    break;
                case 'update':
                    await this.handleUpdate(client, message);
                    break;
                case 'delete':
                    await this.handleDelete(client, message);
                    break;
                default:
                    this.sendError(client, `未知的MongoDB操作类型: ${message.type}`);
            }
        } catch (error) {
            console.error("MongoDB服务错误:", error);
            this.sendError(client, `操作失败: ${error.message}`);
        }
    }


    // 查询文档
    async handleFind(client, message) {
        // console.log('正在处理MongoDB查询:', message);
        let { collection, filter, options, requestId } = message;
        
        try {
            // 验证参数
            filter = this.validateObject(filter, 'filter');
            options = this.validateObject(options, 'options');
            
            // 如果 filter 中有 _id 且是字符串，尝试转换为 ObjectId
            if (filter._id && typeof filter._id === 'string') {
                try {
                    filter._id = new ObjectId(filter._id);
                } catch (e) {
                    // 如果转换失败，保持原样（作为字符串处理）
                    console.log('无法转换为 ObjectId，按字符串处理:', filter._id);
                }
            }
            
            // console.log('查询条件:', filter);
            
            const coll = this.getCollection(collection);
            const result = await coll.find(filter, options).toArray();
            
            // console.log('查询结果:', result);
            
            this.sendResponse(client, {
                type: 'findResult',
                requestId,
                reqPlayerId: client.playerId,
                data: result
            });
        } catch (error) {
            console.error("MongoDB查询错误:", error);
            this.sendError(client, `查询失败: ${error.message}`, requestId);
        }
    }


    // 插入文档
    async handleInsert(client, message) {
        const { collection, document, requestId } = message;
        console.log(`正在处理MongoDB插入:`, message);   
        try {
            const coll = this.getCollection(collection);
            
            let result;
            if (Array.isArray(document)) {
                // 批量插入
                result = await coll.insertMany(document);
            } else {
                // 单个插入
                result = await coll.insertOne(document);
            }
            
            this.sendResponse(client, {
                type: 'insertResult',
                requestId,
                reqPlayerId: client.playerId,
                insertedCount: result.insertedCount,
                insertedIds: result.insertedIds
            });
            console.log(`插入成功`,  requestId);
        } catch (error) {
            console.error("MongoDB插入错误:", error);
            this.sendError(client, `插入失败: ${error.message}`, requestId);
        }
    }

    // 更新文档
    async handleUpdate(client, message) {
        let { collection, filter, update, options, requestId } = message;
        
        try {
            // 验证参数
            filter = this.validateObject(filter, 'filter');
            options = this.validateObject(options, 'options');
            // 如果 filter 中有 _id 且是字符串，尝试转换为 ObjectId
            if (filter._id && typeof filter._id === 'string') {
                try {
                    filter._id = new ObjectId(filter._id);
                } catch (e) {
                    // 如果转换失败，保持原样（作为字符串处理）
                    console.log('无法转换为 ObjectId，按字符串处理:', filter._id);
                }
            }

            const coll = this.getCollection(collection);
            
            // 默认使用updateOne，如果options.multi为true则使用updateMany
            const isMulti = options.multi;
            delete options.multi; // 从选项中移除multi字段
            
            let result;
            if (isMulti) {
                result = await coll.updateMany(filter, update, options);
            } else {
                result = await coll.updateOne(filter, update, options);
            }
            
            this.sendResponse(client, {
                type: 'updateResult',
                requestId,
                reqPlayerId: client.playerId,
                matchedCount: result.matchedCount,
                modifiedCount: result.modifiedCount
            });
        } catch (error) {
            this.sendError(client, `更新失败: ${error.message}`, requestId);
        }
    }

    // 删除文档
    async handleDelete(client, message) {
        let { collection, filter, options, requestId } = message;
        
        try {
            // 验证参数
            filter = this.validateObject(filter, 'filter');
            options = this.validateObject(options, 'options');
            // 如果 filter 中有 _id 且是字符串，尝试转换为 ObjectId
            if (filter._id && typeof filter._id === 'string') {
                try {
                    filter._id = new ObjectId(filter._id);
                } catch (e) {
                    // 如果转换失败，保持原样（作为字符串处理）
                    console.log('无法转换为 ObjectId，按字符串处理:', filter._id);
                }
            }
            const coll = this.getCollection(collection);
            
            // 默认使用deleteOne，如果options.multi为true则使用deleteMany
            const isMulti = options.multi;
            delete options.multi; // 从选项中移除multi字段
            
            let result;
            if (isMulti) {
                result = await coll.deleteMany(filter, options);
            } else {
                result = await coll.deleteOne(filter, options);
            }
            
            this.sendResponse(client, {
                type: 'deleteResult',
                requestId,
                reqPlayerId: client.playerId,
                deletedCount: result.deletedCount
            });
        } catch (error) {
            this.sendError(client, `删除失败: ${error.message}`, requestId);
        }
    }

    // 发送响应消息
    sendResponse(client, response) {
        const message = {
            service: 'mongodb',
            ...response
        };
        
        const buffer = MessageProtocol.encode(message);
        if (client.socket.writable) {
            client.socket.write(buffer);
        }
    }

    // 发送错误消息
    sendError(client, error, requestId = null) {
        const message = {
            service: 'mongodb',
            type: 'error',
            requestId,
            error
        };
        
        const buffer = MessageProtocol.encode(message);
        if (client.socket.writable) {
            client.socket.write(buffer);
        }
    }

    // 关闭MongoDB连接
    async close() {
        if (this.client) {
            await this.client.close();
            console.log("MongoDB连接已关闭");
        }
    }
}
// 在 server.js 中添加以下代码

class Server extends EventEmitter {
    constructor() {
        super();
        this.services = new Map();
        this.clientIdCounter = 0;
        this.clients = new Map();
    }

    // 注册服务
    registerService(name, serviceClass) {
        const service = new serviceClass(this);
        this.services.set(name, service);
        console.log(`服务 "${name}" 已注册`);
        return service; // 返回服务实例，以便进行进一步初始化
    }

    // 启动服务器
    start(port = 25897) {
        this.server = net.createServer((socket) => {
            this.handleConnection(socket);
        });

        this.server.listen(port, () => {
            console.log(`服务器已在端口 ${port} 上启动`);
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
        
        const client = {
            id: clientId,
            socket: socket,
            playerId: null,
            playerName: null,
            disconnected: false,
            services: new Map() // 客户端关联的服务
        };
        
        this.clients.set(clientId, client);
        
        let buffer = Buffer.alloc(0);
        socket.on('data', (data) => {
            buffer = Buffer.concat([buffer, data]);
            this.handleData(client, buffer, (newBuffer) => {
                buffer = newBuffer;
            });
        });
        
        socket.on('close', () => {
            console.log(`客户端 ${clientId} socket close`);
            this.handleDisconnection(client);
        });
        
        socket.on('error', (err) => {
            if (err != 'Error: read ECONNRESET') 
                console.error(`客户端 ${clientId} 发生错误:`, err);
        });
        
        // 通知所有服务有新连接
        for (const [name, service] of this.services) {
            if (service.handleConnection) {
                service.handleConnection(client);
            }
        }
    }

    // 处理数据接收
    handleData(client, buffer, callback) {
        const result = MessageProtocol.decode(buffer);
        if (result) {
            // 消息格式需要包含服务标识
            // { service: 'chat', type: 'join', ... }
            this.handleMessage(client, result.data);
            const remainingBuffer = buffer.slice(result.consumed);
            callback(remainingBuffer);
            if (remainingBuffer.length > 0) {
                this.handleData(client, remainingBuffer, callback);
            }
        } else {
            callback(buffer);
        }
    }

    // 处理消息分发到对应服务
    handleMessage(client, message) {
        const serviceName = message.service || 'chat'; // 默认为聊天服务
        const service = this.services.get(serviceName);
        
        if (service && service.handleMessage) {
            service.handleMessage(client, message);
        } else {
            console.log(`未找到服务: ${serviceName}`);
        }
    }

    // 处理客户端断开连接
    handleDisconnection(client) {
        if (client.disconnected) {
            return;
        }
        
        client.disconnected = true;
        
        const clientId = client.playerId || client.id;
        console.log(`客户端 ${clientId} 断开连接`);
        
        // 通知所有服务客户端断开连接
        for (const [name, service] of this.services) {
            if (service.handleDisconnection) {
                service.handleDisconnection(client);
            }
        }
        
        this.clients.delete(client.id);
        
        if (client.socket && !client.socket.destroyed) {
            client.socket.destroy();
        }
    }

    // 广播消息给所有客户端
    broadcast(serviceName, message, excludeClientId = null) {
        // 在消息中添加服务标识
        message.service = serviceName;
        const buffer = MessageProtocol.encode(message);
        for (const [clientId, client] of this.clients) {
            if (clientId !== excludeClientId && client.socket.writable) {
                client.socket.write(buffer);
            }
        }
    }
}

// 启动服务器并注册服务
const server = new Server();

// 注册聊天服务
server.registerService('chat', ChatService);

// 注册MongoDB服务
const mongoDBService = server.registerService('mongodb', MongoDBService);
mongoDBService.initialize(mongoUri, dbName).then(() => {
    console.log("MongoDB服务初始化完成");
}).catch(error => {
    console.error("MongoDB服务初始化失败:", error);
});

// 启动服务器
server.start(25897);


process.on('SIGINT', async () => {
    console.log('正在关闭服务器...');
    if (mongoDBService) {
        await mongoDBService.close();
    }
    process.exit(0);
});
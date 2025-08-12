// test_sequence.js
const net = require('net');

// 消息协议（与服务端一致）
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

class SequenceTestClient {
    constructor(host, port, clientId) {
        this.host = host;
        this.port = port;
        this.clientId = clientId;
        this.socket = null;
        this.buffer = Buffer.alloc(0);
        this.sequenceId = 0;
        this.pendingAcks = new Map(); // 等待确认的消息
        this.receivedAcks = 0;
        this.testDuration = 30000; // 测试持续30秒
        this.sendInterval = null;
        this.testActive = false;
    }

    connect() {
        return new Promise((resolve, reject) => {
            this.socket = new net.Socket();
            
            this.socket.connect(this.port, this.host, () => {
                console.log(`测试客户端 ${this.clientId} 连接成功`);
                resolve();
            });

            this.socket.on('data', (data) => {
                this.buffer = Buffer.concat([this.buffer, data]);
                this.handleData();
            });

            this.socket.on('close', () => {
                console.log(`测试客户端 ${this.clientId} 连接关闭`);
                this.testActive = false;
                if (this.sendInterval) {
                    clearInterval(this.sendInterval);
                }
            });

            this.socket.on('error', (err) => {
                console.error(`测试客户端 ${this.clientId} 错误:`, err);
                reject(err);
            });
        });
    }

    handleData() {
        const result = MessageProtocol.decode(this.buffer);
        if (result) {
            this.handleMessage(result.data);
            this.buffer = this.buffer.slice(result.consumed);
            if (this.buffer.length > 0) {
                this.handleData();
            }
        }
    }

    handleMessage(message) {
        if (message.service === 'test' && message.type === 'sequenceAck') {
            const sequenceId = message.sequenceId;
            
            // 检查是否是我们发送的消息
            if (this.pendingAcks.has(sequenceId)) {
                const sentTime = this.pendingAcks.get(sequenceId);
                const roundTripTime = Date.now() - sentTime;
                
                this.receivedAcks++;
                this.pendingAcks.delete(sequenceId);
                
                console.log(`收到确认: 序号 ${sequenceId}, 往返时间: ${roundTripTime}ms`);
            }
        }
    }

    startSequenceTest(messageCount = 1000, intervalMs = 10) {
        console.log(`开始序号测试: 发送 ${messageCount} 条消息, 间隔 ${intervalMs}ms`);
        
        this.testActive = true;
        let sentCount = 0;
        
        this.sendInterval = setInterval(() => {
            if (!this.testActive || sentCount >= messageCount) {
                clearInterval(this.sendInterval);
                if (sentCount >= messageCount) {
                    console.log(`测试完成: 计划发送 ${messageCount} 条消息，实际发送 ${sentCount} 条`);
                    // 等待所有确认后再关闭连接
                    setTimeout(() => {
                        this.reportResults();
                        this.socket.end();
                    }, 5000);
                }
                return;
            }
            
            this.sendSequenceMessage();
            sentCount++;
        }, intervalMs);
    }

    sendSequenceMessage() {
        this.sequenceId++;
        const timestamp = Date.now();
        
        const message = {
            service: 'test',
            type: 'sequenceTest',
            sequenceId: this.sequenceId,
            timestamp: timestamp,
            clientId: this.clientId
        };
        
        // 记录发送时间
        this.pendingAcks.set(this.sequenceId, timestamp);
        
        const buffer = MessageProtocol.encode(message);
        this.socket.write(buffer);
    }

    reportResults() {
        console.log('\n=== 测试结果 ===');
        console.log(`客户端 ID: ${this.clientId}`);
        console.log(`发送消息数: ${this.sequenceId}`);
        console.log(`收到确认数: ${this.receivedAcks}`);
        console.log(`丢失确认数: ${this.sequenceId - this.receivedAcks}`);
        console.log(`丢失率: ${((this.sequenceId - this.receivedAcks) / this.sequenceId * 100).toFixed(2)}%`);
        console.log(`待确认数: ${this.pendingAcks.size}`);
        console.log('===============\n');
    }

    close() {
        if (this.socket) {
            this.socket.destroy();
        }
    }
}

// 运行测试
async function runTest() {
    const client = new SequenceTestClient('localhost', 25897, 'test-client-1');
    
    try {
        await client.connect();
        
        // 等待一会儿再开始测试
        setTimeout(() => {
            // 发送1000条消息，间隔10ms (每秒约100条消息)
            client.startSequenceTest(1000, 10);
        }, 1000);
        
        // 设置测试最大持续时间
        setTimeout(() => {
            if (client.testActive) {
                console.log('测试时间到，结束测试');
                client.testActive = false;
                if (client.sendInterval) {
                    clearInterval(client.sendInterval);
                }
                client.reportResults();
                client.socket.end();
            }
        }, 40000); // 40秒后强制结束
        
    } catch (error) {
        console.error('测试客户端错误:', error);
    }
}

// 同时运行多个客户端测试
async function runMultipleTests() {
    const clients = [];
    const clientCount = 3; // 同时运行3个客户端
    
    console.log(`启动 ${clientCount} 个并发测试客户端`);
    
    for (let i = 0; i < clientCount; i++) {
        const client = new SequenceTestClient('localhost', 25897, `test-client-${i+1}`);
        clients.push(client);
        
        try {
            await client.connect();
        } catch (error) {
            console.error(`客户端 ${i+1} 连接失败:`, error);
            continue;
        }
        
        // 稍微错开开始时间
        setTimeout(() => {
            client.startSequenceTest(500, 20); // 每个客户端发送500条消息，间隔20ms
        }, i * 1000);
    }
    
    // 60秒后关闭所有客户端
    setTimeout(() => {
        console.log('测试时间结束，关闭所有客户端');
        clients.forEach(client => {
            if (client.testActive) {
                client.testActive = false;
                if (client.sendInterval) {
                    clearInterval(client.sendInterval);
                }
                client.reportResults();
            }
            client.close();
        });
    }, 60000);
}

// 根据命令行参数决定运行哪种测试
if (process.argv.includes('--multiple')) {
    runMultipleTests();
} else {
    runTest();
}

module.exports = { SequenceTestClient };
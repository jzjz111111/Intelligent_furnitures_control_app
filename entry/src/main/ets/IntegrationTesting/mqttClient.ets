import socket from '@ohos.net.socket';
import buffer from '@ohos.buffer';
import { AgricultureMqttLogic, SensorData } from './AgricultureMqttLogic';

// ==================== 1. 显式定义必要接口 ====================
interface MqttConfig {
  host: string;
  port: number;
  clientId: string;
  userName: string;
  password: string;
  reportTopic: string;
  cmdTopic: string;
}

interface MqttParseResult {
  type: number;
  topic?: string;
  payload?: string;
}

interface PacketParseResult {
  packet: MqttParseResult;
  length: number;
}

type MqttConnectionState = 'disconnected' | 'connecting' | 'connected';

// ==================== 2. 全局状态 ====================
const mqttLogic: AgricultureMqttLogic = new AgricultureMqttLogic();
let tcpSocket: socket.TCPSocket | null = null ;
let connectionState: MqttConnectionState = 'disconnected';
let resolveConnect: ((value: boolean) => void) | null = null ;
let packetIdCounter: number = 1;
let recvBuffer: Uint8Array = new Uint8Array(0); // 用于处理 TCP 粘包/半包

// ==================== 3. MQTT配置（按控制台修正） ====================
// 如果你想临时通过本地 proxy 做调试（App -> 本地明文，proxy -> cloud TLS）
// 将 USE_PROXY 设为 true 并在本地运行 proxy.js（之前给你的脚本）。
const USE_PROXY = false;

const CLOUD_HOST = "f99cbb495b.st1.iotda-device.cn-north-4.myhuaweicloud.com";
const CLOUD_PORT = 8883;
const PROXY_HOST = "127.0.0.1";
const PROXY_PORT = 1884;

const MQTT_CONFIG: MqttConfig = {
  host: USE_PROXY ? PROXY_HOST : CLOUD_HOST,
  port: USE_PROXY ? PROXY_PORT : CLOUD_PORT,
  clientId: "69c286e57f2e6c302f603fd8_Sensor_001_0_0_2026040406",
  userName: "69c286e57f2e6c302f603fd8_Sensor_001",
  password: "<PASSWORD>", // 替换为实际设备密码/签名
  // 以控制台日志为准：device_id 带后缀 _Sensor_001
  reportTopic: "$oc/devices/69c286e57f2e6c302f603fd8_Sensor_001/sys/properties/report",
  cmdTopic: "$oc/devices/69c286e57f2e6c302f603fd8_Sensor_001/sys/messages/down"
};

// ==================== 4. 核心工具方法 ====================
function concatUint8Arrays(arrays: Uint8Array[]): Uint8Array {
  let totalLength: number = 0;
  for ( const arr of arrays) { totalLength += arr.length; }
  const result: Uint8Array = new Uint8Array(totalLength);
  let offset: number = 0;
  for ( const arr of arrays) {
    result.set(arr, offset);
    offset += arr.length;
  }
  return result;
}

function encodeVariableByteInteger(value: number): number[] {
  const bytes: number[] = [];
  do {
    let byte: number = value % 128;
    value = Math.floor(value / 128);
    if (value > 0) byte |= 0x80;
    bytes.push(byte);
  } while (value > 0);
  return bytes;
}

function stringToUint8Array(str: string): Uint8Array {
  const buf: buffer.Buffer = buffer.from(str);
  const arr: Uint8Array = new Uint8Array(buf.length);
  for ( let i: number = 0; i < buf.length; i++) {
    try {
      arr[i] = buf.readUInt8(i);
    } catch (e) {
      console.error("Buffer read error");
    }
  }
  return arr;
}

function encodeConnectPacket(config: MqttConfig): Uint8Array {
  const fixedHeader: Uint8Array = new Uint8Array([0x10]);
  const protocolName: Uint8Array = new Uint8Array([0x00, 0x04, 0x4D, 0x51, 0x54, 0x54]);
  const protocolLevel: Uint8Array = new Uint8Array([0x04]);
  const connectFlags: Uint8Array = new Uint8Array([0xC2]); // user/pass + clean session + will flags as in original
  const keepAlive: Uint8Array = new Uint8Array([0x00, 0x3C]);

  const clientIdBytes: Uint8Array = stringToUint8Array(config.clientId);
  const clientId: Uint8Array = concatUint8Arrays([ new Uint8Array([(clientIdBytes.length >> 8) & 0xFF, clientIdBytes.length & 0xFF]), clientIdBytes]);

  const userNameBytes: Uint8Array = stringToUint8Array(config.userName);
  const userName: Uint8Array = concatUint8Arrays([ new Uint8Array([(userNameBytes.length >> 8) & 0xFF, userNameBytes.length & 0xFF]), userNameBytes]);

  const passwordBytes: Uint8Array = stringToUint8Array(config.password);
  const password: Uint8Array = concatUint8Arrays([ new Uint8Array([(passwordBytes.length >> 8) & 0xFF, passwordBytes.length & 0xFF]), passwordBytes]);

  const remainingLength: number = protocolName.length + protocolLevel.length + connectFlags.length + keepAlive.length + clientId.length + userName.length + password.length;
  const remainingLengthBytes: Uint8Array = new Uint8Array(encodeVariableByteInteger(remainingLength));

  return concatUint8Arrays([fixedHeader, remainingLengthBytes, protocolName, protocolLevel, connectFlags, keepAlive, clientId, userName, password]);
}

function encodeSubscribePacket(topic: string, packetId: number): Uint8Array {
  const fixedHeader: Uint8Array = new Uint8Array([0x82]);
  const topicBytes: Uint8Array = stringToUint8Array(topic);
  const topicHeader: Uint8Array = new Uint8Array([(topicBytes.length >> 8) & 0xFF, topicBytes.length & 0xFF]);
  const qos: Uint8Array = new Uint8Array([0x01]);
  const packetIdBytes: Uint8Array = new Uint8Array([(packetId >> 8) & 0xFF, packetId & 0xFF]);
  const remainingLength: number = 2 + topicHeader.length + topicBytes.length + qos.length;
  const remainingLengthBytes: Uint8Array = new Uint8Array(encodeVariableByteInteger(remainingLength));
  return concatUint8Arrays([fixedHeader, remainingLengthBytes, packetIdBytes, topicHeader, topicBytes, qos]);
}

// 使用 QoS0 的 Publish（不包含 packetId）
function encodePublishPacket(topic: string, payload: string): Uint8Array {
  const fixedHeader: Uint8Array = new Uint8Array([0x30]); // PUBLISH, QoS0
  const topicBytes: Uint8Array = stringToUint8Array(topic);
  const topicHeader: Uint8Array = new Uint8Array([(topicBytes.length >> 8) & 0xFF, topicBytes.length & 0xFF]);
  const payloadBytes: Uint8Array = stringToUint8Array(payload);
  const remainingLength: number = topicHeader.length + topicBytes.length + payloadBytes.length;
  const remainingLengthBytes: Uint8Array = new Uint8Array(encodeVariableByteInteger(remainingLength));
  return concatUint8Arrays([fixedHeader, remainingLengthBytes, topicHeader, topicBytes, payloadBytes]);
}

// 解析单个完整 MQTT 包（若不完整则返回 null）
// 返回 { packet, length }，length 为该完整包的字节数
function tryParsePacket(buf: Uint8Array): PacketParseResult | null {
  if (buf.length < 2) return null;
  const fixedHeader: number = buf[0];
  const packetType: number = (fixedHeader >> 4) & 0x0F;

  // 解析 remaining length（变长整数）
  let offset: number = 1;
  let remainingLength: number = 0;
  let multiplier: number = 1;
  let lenBytesCount: number = 0;
  while (offset <= buf.length) {
    if (offset >= buf.length) return null; // 等待更多数据
    const byte: number = buf[offset];
    remainingLength += (byte & 0x7F) * multiplier;
    multiplier *= 128;
    offset++;
    lenBytesCount++;
    if ((byte & 0x80) === 0) break;
    if (lenBytesCount > 4) return null; // 协议异常
  }

  const totalLength = 1 + lenBytesCount + remainingLength;
  if (buf.length < totalLength) return null; // 等待更多数据

  // 现在 buf 中有完整一包（从 0 到 totalLength-1）
  if (packetType === 0x02) {
    // CONNACK (我们不解析具体字段，这里仅返回类型)
    const result: PacketParseResult = { packet: { type: packetType }, length: totalLength };
    return result;
  }

  if (packetType === 0x03) {
    try {
      let pos = 1 + lenBytesCount;
      const topicLength: number = (buf[pos] << 8) | buf[pos + 1];
      pos += 2;
      const topic: string = buffer.from(buf.subarray(pos, pos + topicLength)).toString();
      pos += topicLength;

      // 判断 QoS（固定头的 bits 1-2）
      const qos: number = (fixedHeader >> 1) & 0x03;
      if (qos > 0) {
        // 若为 QoS1/2，则应有 packet id（当前实现通常为 QoS0，但兼容性保留）
        pos += 2;
      }

      const payloadLength: number = remainingLength - (2 + topicLength + (qos > 0 ? 2 : 0));
      const payload: string = buffer.from(buf.subarray(pos, pos + payloadLength)).toString();
      const result: PacketParseResult = {
        packet: { type: packetType, topic: topic, payload: payload },
        length: totalLength
      };
      return result;
    } catch (e) {
      return null;
    }
  }

  // 其他包类型（PINGRESP, SUBACK, PUBACK 等）我们只返回类型，具体可按需扩展
  return { packet: { type: packetType }, length: totalLength };
}

// ==================== 5. 核心业务逻辑 ====================
export function mqttConnect(): Promise<boolean> {
  return new Promise<boolean>((resolve: (value: boolean) => void, reject: (reason: Error) => void): void => {
    if (connectionState !== 'disconnected') {
      reject( new Error("MQTT已连接或连接中"));
      return;
    }

    connectionState = 'connecting';
    resolveConnect = resolve;

    const socketInstance: socket.TCPSocket = socket.constructTCPSocketInstance();
    tcpSocket = socketInstance;
    recvBuffer = new Uint8Array(0);

    socketInstance.on('message', (value: socket.SocketMessageInfo): void => {
      console.info('MQTT: socket message len=', value && value.message ? value.message.byteLength : 0);
      // append to recvBuffer
      const incoming = new Uint8Array(value.message);
      recvBuffer = concatUint8Arrays([recvBuffer, incoming]);

      // 解析缓冲区中所有完整包
      while (true) {
        const parsed = tryParsePacket(recvBuffer);
        if (!parsed) break;
        const packet = parsed.packet;
        const length = parsed.length;

        if (packet.type === 0x02) { // CONNACK
          connectionState = 'connected';
          console.info("✅ MQTT连接成功");
          // 订阅 reportTopic（使用 packetId 并回绕）
          const pid = packetIdCounter = ((packetIdCounter % 0xFFFF) + 1);
          const subPacket: Uint8Array = encodeSubscribePacket(MQTT_CONFIG.reportTopic, pid);
          socketInstance.send({ data: subPacket.buffer }).then(() => {
            console.info('MQTT: SUBSCRIBE packet sent for topic=', MQTT_CONFIG.reportTopic, ' pid=', pid);
          }).catch((err: Error) => { console.error('MQTT: send SUBSCRIBE failed', err && err.message); });
          if (resolveConnect) {
            resolveConnect(true);
            resolveConnect = null;
          }
        } else if (packet.type === 0x03 && packet.topic === MQTT_CONFIG.reportTopic && packet.payload) {
          console.info('MQTT: PUBLISH received on reportTopic');
          const sensorData: SensorData | null = mqttLogic.parseDeviceReport(packet.payload);
          if (sensorData) console.info("📊 解析成功", sensorData);
        } else {
          console.info('MQTT: other packet type=', packet.type, ' topic=', packet.topic ? packet.topic : '');
        }

        // 从 recvBuffer 中移除已处理的数据
        if (length >= recvBuffer.length) {
          recvBuffer = new Uint8Array(0);
        } else {
          recvBuffer = recvBuffer.subarray(length);
        }
      }
    });

    socketInstance.on('error', (err: Error): void => {
      console.error("❌ MQTT: socket ERROR:", err && err.message, err);
      connectionState = 'disconnected';
      tcpSocket = null;
      if (resolveConnect) { resolveConnect = null; }
      reject(err);
    });

    socketInstance.on('close', (): void => {
      console.info("🔌 MQTT: socket CLOSED");
      connectionState = 'disconnected';
      tcpSocket = null;
      if (resolveConnect) { resolveConnect = null; }
    });

    const connectOptions: socket.TCPConnectOptions = {
      address: {
        address: MQTT_CONFIG.host,
        port: MQTT_CONFIG.port
      }
    };

    console.info('MQTT: attempting TCP connect to', MQTT_CONFIG.host, MQTT_CONFIG.port, 'USE_PROXY=', USE_PROXY);

    socketInstance.connect(connectOptions)
      .then((): void => {
        console.info('MQTT: TCP connect success, sending CONNECT packet...');
        const connectPacket: Uint8Array = encodeConnectPacket(MQTT_CONFIG);
        socketInstance.send({ data: connectPacket.buffer }).then(() => {
          console.info('MQTT: CONNECT packet sent');
        }).catch((_err: Error) => { console.error('MQTT: send CONNECT failed', _err && _err.message); });
      })
      .catch((err: Error): void => {
        console.error('MQTT: TCP connect failed:', err && err.message, err);
        connectionState = 'disconnected';
        if (resolveConnect) { resolveConnect = null; }
        reject(err);
      });
  });
}

export function mqttPublish(cmdJson: string): Promise<void> {
  return new Promise<void>((resolve: () => void, reject: (reason: Error) => void): void => {
    if (connectionState !== 'connected' || !tcpSocket) {
      console.error('MQTT: mqttPublish failed - not connected. state=', connectionState);
      reject(new Error("MQTT未连接"));
      return;
    }
    // QoS0 publish（不含 packetId）
    const publishPacket: Uint8Array = encodePublishPacket(MQTT_CONFIG.cmdTopic, cmdJson);
    tcpSocket.send({ data: publishPacket.buffer }).then(() => {
      console.info('MQTT: PUBLISH packet sent to', MQTT_CONFIG.cmdTopic, ' payload=', cmdJson);
      resolve();
    }).catch((err: Error) => {
      console.error('MQTT: send PUBLISH failed', err && err.message);
      reject(err);
    });
  });
}

export function getLatestSensorData(): SensorData | null { return mqttLogic.getLatestData(); }

export function mqttDisconnect(): Promise<void> {
  return new Promise<void>((resolve: () => void, reject: (reason: Error) => void): void => {
    if (!tcpSocket) { connectionState = 'disconnected'; resolve(); return; }
    tcpSocket.close().then(() => {
      console.info('MQTT: socket close successful');
      connectionState = 'disconnected';
      tcpSocket = null;
      recvBuffer = new Uint8Array(0);
      if (resolveConnect) { resolveConnect = null; }
      resolve();
    }).catch((err: Error) => {
      console.error('MQTT: socket close failed', err && err.message);
      reject(err);
    });
  });
}
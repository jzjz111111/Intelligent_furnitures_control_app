import { Context } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import relationalStore from '@ohos.data.relationalStore';

import {
  openAgriDb,
  updateUserAvatar,
  getUserAvatar,
  updateUserProfile,
  getUserById,
  getUserByUsername,
  verifyUserLogin,
  createUser,
  checkUsernameExists,
  addFarm,
  getFarmList,
  deleteFarm,
  deleteDevice,
  setFarmImage,
  addVideoRecord,
  getVideoListByUserId,
  getVideoById,
  deleteVideoRecord,
  getLatestVideoPerDevice,
  addCapturePhoto,
  getPhotoListByDevice,
  addDeviceToDatabase
} from '../common/db';
import { alarmService } from '../repository/roomDatabase';
import buffer from '@ohos.buffer';
import socket from '@ohos.net.socket';
import { BusinessError } from '@kit.BasicServicesKit';
import util from '@ohos.util';

// 最新视频响应接口
interface LatestVideoResponse {
  videoPath: string;
  videoId?: number;
  fileName?: string;
  createTime?: string;
  message?: string;
}

// 登录请求体
interface LoginBody {
  username: string;
  password: string;
}

// 登录响应数据
interface LoginResponseData {
  userId: number;
  username: string;
  token?: string;
}

// 注册请求体
interface RegisterBody {
  username: string;
  password: string;
}
// 统一响应接口
interface ApiResponse<T> {
  code: number;
  data: T;
  msg: string;
}

// 请求体接口
interface AlarmAddBody {
  deviceId: string;
  alarmType: string;
  level: 'WARNING' | 'ERROR' | 'CRITICAL';
  message: string;
}

interface AlarmReadBody {
  id: number;
}

interface AvatarUploadBody {
  userId: number;
  tempPath: string;
}

// 用户修改信息接口
interface UserUpdateProfileBody {
  userId: number;
  oldPassword: string;
  newUsername?: string;
  newPassword?: string;
}

// 本地定义 UserInfo
interface UserInfo {
  id: number;
  username: string;
  password: string;
}

// 用户修改响应接口
interface UserUpdateResponse {
  message: string;
  username: string;
}

// 头像数据
interface AvatarData {
  avatarPath: string;
}

// 传感器数据
interface SensorData {
  temperature: number;
  humidity: number;
  soilHumidity: number;
  light: number;
  ph: number;
  co2: number;
}

// 添加设备请求体
interface AddDeviceRequest {
  farmlandId: number;
  deviceId: string;
  deviceName: string;
  typeId: number;
}

// 设备状态
interface DeviceStatus {
  status: string;
  online: boolean;
}

// 设备信息
interface DeviceInfo {
  deviceId: string;
  name: string;
  status: string;
}

// 基础响应接口 (在添加设备响应之前添加)
interface BaseResponse {
  code: number;
  msg: string;
}

// 设备添加响应数据
interface AddDeviceData {
  deviceId: string;
  message: string;
}

// 添加设备响应
interface AddDeviceResponse extends BaseResponse {
  data: AddDeviceData;
}

// 告警响应
interface AlarmIdResponse {
  alarmId: number | undefined;
}

interface AlarmUpdateResponse {
  updated: number | undefined;
}

interface AlarmClearResponse {
  cleared: number | undefined;
}

// 农田接口结构
interface FarmAddBody {
  userId: number;
  name: string;
  location: string;
  note: string;
  imagePath?: string;
}

interface FarmImageBody {
  zoneId: number;
  imagePath: string;
}

// 农田图片上传请求体
interface FarmAvatarUploadBody {
  userId: number;
  farmName: string;
  location?: string;
  note?: string;
  base64: string;
  fileName: string;
}

// 农田图片上传响应
interface FarmAvatarUploadResponse {
  message: string;
  zoneId: number;
  imagePath: string;
}

// 删除农田请求体
interface FarmDeleteBody {
  zoneId: number;
}

// 删除设备请求体
interface DeviceDeleteBody {
  farmlandId: number;
  deviceName: string;
}


// 通用操作响应接口
interface CommonResponse {
  message: string;
}

// 视频接口
interface VideoUploadBody {
  userId: number;
  zoneId?: number;
  tempPath: string;
  fileName: string;
}

// 视频删除请求体
interface VideoDeleteBody {
  videoId: number;
}

// 视频上传响应
interface VideoUploadResponse {
  message: string;
  videoPath: string;
}

// 控制参数
interface HardwareControlParas {
  led1: number;
  led2: number;
  led3: number;
  spray: number;
}

// 华为云 IoT 标准命令格式
interface HardwareControlCommand {
  serviceId: string;
  commandName: string;
  paras: HardwareControlParas;
}

// 硬件控制响应接口
interface HardwareControlResponse {
  device: string;
  status: string;
  command: HardwareControlCommand;
}

// 光照模块接口
interface LightReportBody {
  deviceId: string;
  light: number;
}

interface LightReportResponse {
  deviceId: string;
  light: number;
  level: 'NORMAL' | 'WARNING' | 'CRITICAL';
  msg: string;
}

interface LightRealtimeResponse {
  deviceId: string;
  light: number;
  ts: number;
}

// ESP32 上传视频接口结构体
interface Esp32VideoUploadBody {
  userId: number;
  zoneId?: number;
  deviceSn: string;
  fileName: string;
  fileData: string;
}

// 历史照片列表响应接口
interface PhotoListResponse {
  photos: string[];
  count: number;
}

// 最新照片响应接口
interface LatestPhotoResponse {
  path: string;
}

export class MyHttpServer {
  private isRunning: boolean = false;
  private context: Context;
  private tcpServer: socket.TCPSocketServer | null = null;
  private readonly PORT: number = 8080;

  constructor(context: Context) {
    this.context = context;
  }

  async startServer(): Promise<void> {
    if (this.isRunning) {
      console.warn("[服务器] 服务器已在运行中");
      return;
    }

    try {
      console.log("[服务器] 开始创建 TCP 服务器...");

      this.tcpServer = socket.constructTCPSocketServerInstance();

      this.tcpServer = socket.constructTCPSocketServerInstance();

      this.tcpServer.on('connect', (connection: socket.TCPSocketConnection) => {
        console.log("🔗 新连接建立");

        connection.on('message', (msg: socket.SocketMessageInfo) => {
          this.handleMessage(connection , msg);
        });

        connection.on('close', () => {
          console.log("🔌 连接关闭");
        });
      });


      const serverAddress: socket.NetAddress = {
        address: '127.0.0.1',
        port: this.PORT
      };
      await this.tcpServer.listen(serverAddress);

      this.isRunning = true;
      console.log(`✅ 智慧农业后端服务启动成功，监听端口: ${this.PORT}`);
      console.log(`📡 访问地址: http://127.0.0.1:${this.PORT}/api/xxx`);

      this.startTimerTasks();
      console.log("✅ 定时任务已启动");

    } catch (err) {
      const error = err as BusinessError;
      console.error("❌ 服务器启动失败:", error.message);
      console.error("❌ 错误码:", error.code);
      throw new Error(`HTTP 服务器启动失败: ${error.message}`);
    }
  }

  private handleMessage(connection: socket.TCPSocketConnection, msgInfo: socket.SocketMessageInfo): void {
    try {
      const data: ArrayBuffer | string = msgInfo.message;
      let requestStr = '';

      if (data instanceof ArrayBuffer) {
        requestStr = buffer.from(data).toString('utf-8');
      } else if (typeof data === 'string') {
        requestStr = data;
      }

      console.log("📨 收到请求:", requestStr.substring(0, 100));

      if (!requestStr) {
        console.warn("⚠️ 空请求，忽略");
        return;
      }

      const self = this;
      this.handleHttpRequest(requestStr).then((responseStr: string): void => {
        const responseBuffer: ArrayBuffer = buffer.from(responseStr).buffer;
        connection.send({ data: responseBuffer });
        console.log("✅ 响应已发送");
      }).catch((err: Error): void => {
        console.error("❌ 处理请求失败", err);
        const errorResponse: string = self.buildHttpResponse(self.fail("服务器内部错误"), 500);
        connection.send({ data: buffer.from(errorResponse).buffer });
      });

    } catch (e) {
      console.error("❌ 消息处理异常", e);
    }
  }

  private async handleHttpRequest(requestStr: string): Promise<string> {
    const lines: string[] = requestStr.split('\r\n');
    if (lines.length === 0) {
      return this.buildHttpResponse(this.fail('无效请求'), 400);
    }

    const requestLine: string = lines[0];
    const parts: string[] = requestLine.split(' ');
    if (parts.length < 2) {
      return this.buildHttpResponse(this.fail('无效请求行'), 400);
    }

    const method: string = parts[0];
    const fullPath: string = parts[1];
    const path: string = fullPath.split('?')[0];

    let body: object | undefined = undefined;

    const emptyLineIndex: number = lines.findIndex((line: string): boolean => line.trim() === '');
    if (emptyLineIndex !== -1 && emptyLineIndex < lines.length - 1) {
      const bodyStr: string = lines.slice(emptyLineIndex + 1).join('\r\n');
      if (bodyStr.trim()) {
        try {
          body = JSON.parse(bodyStr);
        } catch (e) {
          console.warn('⚠️ 解析请求体失败');
        }
      }
    }

    console.log(`🎯 路由: ${method} ${path}`);

    let responseData: string;
    try {
      responseData = await this.getMockResponse(path, body);
    } catch (err) {
      console.error('❌ 路由处理失败:', err);
      responseData = this.fail('接口处理失败');
    }

    return this.buildHttpResponse(responseData, 200);
  }

  private buildHttpResponse(body: string, statusCode: number = 200): string {
    const statusText: string = statusCode === 200 ? 'OK' : 'Bad Request';
    const bodyLength: number = buffer.from(body, 'utf-8').length;
    const headers: string[] = [
      'HTTP/1.1 ' + statusCode + ' ' + statusText,
      'Content-Type: application/json; charset=utf-8',
      'Access-Control-Allow-Origin: *',
      'Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers: Content-Type',
      'Content-Length: ' + bodyLength,
      'Connection: close',
      '',
      ''
    ];

    return headers.join('\r\n') + body;
  }

  /**
   * 启动定时任务（光照自动采集等）
   */
  private startTimerTasks(): void {
    // 光照自动采集 - 每8秒一次
    setInterval(() => {
      const randomLight = Math.floor(Math.random() * 50000) + 1000;
      console.log(`[光照] 自动采集: ${randomLight} lux`);
    }, 8000);

    // 定时截帧 - 每60秒检查一次新视频并截帧
    setInterval(async () => {
      try {
        const store = await openAgriDb(this.context);
        const videos = await getLatestVideoPerDevice(store);

        for (const video of videos) {
          const photoPath = await this.captureFrame(video.file_path);
          if (photoPath) {
            await addCapturePhoto(store, video.device_sn || "", video.zone_id || null, photoPath);
            console.log("✅ 定时截帧成功:", photoPath);
          }
        }
      } catch (err) {
        console.error("定时截帧失败", err);
      }
    }, 60000);
  }


  stopServer(): void {
    if (this.tcpServer) {
      try {
        this.tcpServer.close();
        this.tcpServer = null;
      } catch (err) {
        const error = err as BusinessError;
        console.error('❌ 关闭服务器失败:', error.message);
      }
    }
    this.isRunning = false;
    console.log("[后端] 服务器已停止");
  }

  private success<T>(data: T): string {
    const res: ApiResponse<T> = {
      code: 200,
      data: data,
      msg: "success"
    };
    return JSON.stringify(res);
  }

  private fail(msg: string): string {
    const res: ApiResponse<null> = {
      code: 500,
      data: null,
      msg: msg
    };
    return JSON.stringify(res);
  }

  //视频截帧
  private async captureFrame(videoPath: string): Promise<string> {
    const photoDir: string = this.context.filesDir + "/photos/";
    try {
      if (!(await fs.access(photoDir))) {
        await fs.mkdir(photoDir);
      }
    } catch (err) {
      console.error("❌ 创建照片目录失败：", err);
      return "";
    }

    const photoPath: string = `${photoDir}capture_${Date.now()}.jpg`;

    try {
      const videoFile = fs.openSync(videoPath, fs.OpenMode.READ_ONLY);
      const thumbnailData = new Uint8Array([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x03, 0x02, 0x02, 0x03
      ]);
      const photoFile = fs.openSync(photoPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(photoFile.fd, thumbnailData);

      try {
        fs.closeSync(videoFile.fd);
        fs.closeSync(photoFile.fd);
      } catch (closeErr) {
        console.error("❌ 关闭文件失败：", closeErr);
      }
      console.log("✅ 截帧成功：", photoPath);
    } catch (err) {
      console.error("❌ 截帧失败：", err);
      return "";
    }
    return photoPath;
  }

  //获取 URL 查询参数
  private getQueryParam(url: string, key: string): string | null {
    const reg = new RegExp(`[?&]${key}=([^&]+)`, "i");
    const match = url.match(reg);
    return match ? decodeURIComponent(match[1]) : null;
  }

  //上传用户头像
  private async uploadAvatar(userId: number, tempPath: string): Promise<string> {
    try {
      const avatarDir: string = this.context.filesDir + "/avatars/";
      if (!(await fs.access(avatarDir))) {
        await fs.mkdir(avatarDir);
      }
      const ext: string = tempPath.split(".").pop() || "png";
      const targetPath: string = `${avatarDir}avatar_${userId}_${Date.now()}.${ext}`;
      await fs.copyFile(tempPath, targetPath);
      const store = await openAgriDb(this.context);
      await updateUserAvatar(store, userId, targetPath);
      const res: AvatarData = {
        avatarPath: targetPath
      };
      return this.success(res);
    } catch (err) {
      return this.fail("文件操作失败");
    }
  }

  //获取用户头像信息
  private async getUserAvatarInfo(userId: number): Promise<string> {
    try {
      const store = await openAgriDb(this.context);
      const avatarPath: string = await getUserAvatar(store, userId);
      const res: AvatarData = {
        avatarPath: avatarPath
      };
      return this.success(res);
    } catch (err) {
      return this.fail("获取头像失败");
    }
  }

  async getMockResponse(path: string, body?: object): Promise<string> {
    // 注册接口
    if (path === "/api/user/register" && body) {
      try {
        const b: RegisterBody = body as RegisterBody;

        if (!b.username || !b.password) {
          return JSON.stringify({ code: 400, msg: "用户名和密码不能为空" });
        }

        const store = await openAgriDb(this.context);
        const exists = await checkUsernameExists(store, b.username);

        if (exists) {
          return JSON.stringify({ code: 409, msg: "用户名已存在" });
        }

        await createUser(store, b.username, b.password);

        const result: CommonResponse = { message: "注册成功" };
        return this.success(result);
      } catch (err) {
        console.error("注册处理失败", err);
        return this.fail("注册失败");
      }
    }

    // 检查用户名是否已存在
    if (path === "/api/user/checkUsername") {
      try {
        const username: string | null = this.getQueryParam(path, "username");
        if (!username) {
          return JSON.stringify({ code: 400, msg: "用户名不能为空" });
        }

        const store = await openAgriDb(this.context);
        const exists = await checkUsernameExists(store, username);

        if (exists) {
          return JSON.stringify({ code: 409, msg: "用户名已存在" });
        }

        const result: CommonResponse = { message: "用户名可用" };
        return this.success(result);
      } catch (err) {
        console.error("检查用户名失败", err);
        return this.fail("检查失败");
      }
    }

    // 登录接口
    if (path === "/api/user/login" && body) {
      try {
        const b: LoginBody = body as LoginBody;

        if (!b.username || !b.password) {
          return JSON.stringify({ code: 400, msg: "用户名和密码不能为空" });
        }

        const store = await openAgriDb(this.context);
        const loginResult = await verifyUserLogin(store, b.username, b.password);

        if (!loginResult.success) {
          return JSON.stringify({ code: 401, msg: loginResult.message || "用户名或密码错误" });
        }

        const res: LoginResponseData = {
          userId: loginResult.userId!,
          username: loginResult.username!
        };

        return this.success(res);
      } catch (err) {
        console.error("登录处理失败", err);
        return this.fail("登录失败");
      }
    }

    if (path === "/api/esp32/uploadVideo" && body) {
      try {
        const b: Esp32VideoUploadBody = body as Esp32VideoUploadBody;
        const store = await openAgriDb(this.context);
        const videoDir: string = this.context.filesDir + "/videos/";
        if (!(await fs.access(videoDir))) {
          await fs.mkdir(videoDir);
        }
        const finalPath: string = videoDir + b.fileName;

        const file = fs.openSync(finalPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
        const fileData = buffer.from(b.fileData, 'base64');
        fs.writeSync(file.fd, fileData.buffer);
        fs.closeSync(file.fd);

        const stat = await fs.stat(finalPath);

        await addVideoRecord(
          store,
          b.userId,
          b.zoneId || null,
          b.deviceSn,
          b.fileName,
          finalPath,
          stat.size
        );
        const res: CommonResponse = {
          message: "ESP32 视频上传成功"
        };
        return this.success(res);
      } catch (err) {
        console.error("ESP32 上传失败", err);
        return this.fail("上传失败");
      }
    }

    if (path === "/api/app/photo/list") {
      try {
        const deviceSn: string | null = this.getQueryParam(path, "deviceSn");
        if (!deviceSn) {
          return this.fail("deviceSn 不能为空");
        }
        const store = await openAgriDb(this.context);
        const list = await getPhotoListByDevice(store, deviceSn);
        return this.success(list);
      } catch (err) {
        return this.fail("获取照片列表失败");
      }
    }

    if (path === "/api/sensor/light/report" && body) {
      try {
        const b: LightReportBody = body as LightReportBody;
        const deviceId: string = b.deviceId || "sensor_light_01";
        const lightValue: number = b.light;
        let level: 'NORMAL' | 'WARNING' | 'CRITICAL' = "NORMAL";
        if (lightValue < 500) {
          level = "WARNING";
        }
        if (lightValue > 50000) {
          level = "CRITICAL";
        }
        if (level !== "NORMAL") {
          await alarmService?.triggerAlarm(deviceId, "LIGHT", level, `光照异常：${lightValue} lux`);
        }
        const res: LightReportResponse = {
          deviceId: deviceId,
          light: lightValue,
          level: level,
          msg: "上报成功"
        };
        return this.success(res);
      } catch (err) {
        return this.fail("光照上报失败");
      }
    }

    if (path.includes("/api/sensor/light/realtime")) {
      const res: LightRealtimeResponse = {
        deviceId: "sensor_light_01",
        light: 15600,
        ts: Date.now()
      };
      return this.success(res);
    }

    if (path.includes("/api/sensor/latest")) {
      const data: SensorData = {
        temperature: 25.8,
        humidity: 46,
        soilHumidity: 52,
        light: 3600,
        ph: 6.7,
        co2: 430
      };
      return this.success(data);
    }

    if (path.includes("/api/device/status")) {
      const statusData: DeviceStatus = {
        status: "ONLINE",
        online: true
      };
      return this.success(statusData);
    }

    if (path.includes("/api/device/list")) {
      const list: DeviceInfo[] = [
        { deviceId: "agri_device_001", name: "1 号大棚传感器", status: "ONLINE" },
        { deviceId: "agri_device_002", name: "1 号大棚控制器", status: "ONLINE" }
      ];
      return this.success(list);
    }

    if (path === "/api/alarm/list") {
      try {
        const list = await alarmService?.getAlarms();
        return this.success(list || []);
      } catch (err) {
        return this.fail("获取告警失败");
      }
    }

    if (path === "/api/alarm/add" && body) {
      try {
        const b: AlarmAddBody = body as AlarmAddBody;
        const id = await alarmService?.triggerAlarm(b.deviceId, b.alarmType, b.level, b.message);
        const res: AlarmIdResponse = {
          alarmId: id
        };
        return this.success(res);
      } catch (err) {
        return this.fail("添加告警失败");
      }
    }

    if (path === "/api/alarm/read" && body) {
      try {
        const b: AlarmReadBody = body as AlarmReadBody;
        const rows = await alarmService?.markRead(b.id);
        const res: AlarmUpdateResponse = {
          updated: rows
        };
        return this.success(res);
      } catch (err) {
        return this.fail("标记已读失败");
      }
    }

    if (path === "/api/alarm/clear" && body) {
      try {
        const rows = await alarmService?.clearAll();
        const res: AlarmClearResponse = {
          cleared: rows
        };
        return this.success(res);
      } catch (err) {
        return this.fail("清空告警失败");
      }
    }

    if (path.includes("/api/user/avatar/upload") && body) {
      try {
        const b: AvatarUploadBody = body as AvatarUploadBody;
        if (!b.userId || !b.tempPath) {
          return this.fail("参数缺失");
        }
        return this.uploadAvatar(b.userId, b.tempPath);
      } catch (err) {
        return this.fail("头像上传失败");
      }
    }

    if (path.includes("/api/user/avatar/info")) {
      try {
        const userIdStr: string | null = this.getQueryParam(path, "userId");
        if (!userIdStr) {
          return this.fail("缺少 userId");
        }
        return this.getUserAvatarInfo(Number(userIdStr));
      } catch (err) {
        return this.fail("获取头像失败");
      }
    }

    if (path === "/api/user/updateProfile" && body) {
      try {
        const b: UserUpdateProfileBody = body as UserUpdateProfileBody;
        if (!b.userId || !b.oldPassword) {
          return this.fail("参数不完整");
        }
        const store = await openAgriDb(this.context);
        const user = await getUserById(store, b.userId) as UserInfo | null;
        if (!user) {
          return this.fail("用户不存在");
        }
        if (user.password !== b.oldPassword) {
          return this.fail("旧密码不正确");
        }
        const uname: string = b.newUsername || user.username;
        const pwd: string = b.newPassword || user.password;
        await updateUserProfile(store, b.userId, uname, pwd);
        const res: UserUpdateResponse = {
          message: "修改成功",
          username: uname
        };
        return this.success(res);
      } catch (err) {
        return this.fail("修改失败");
      }
    }

    if (path === "/api/farm/list") {
      try {
        const userIdStr: string | null = this.getQueryParam(path, "userId");
        const userId: number = Number(userIdStr);
        const store = await openAgriDb(this.context);
        const list = await getFarmList(store, userId);
        return this.success(list);
      } catch (err) {
        return this.fail("获取农田列表失败");
      }
    }

    if (path === "/api/farm/add" && body) {
      try {
        const b: FarmAddBody = body as FarmAddBody;
        const store = await openAgriDb(this.context);
        await addFarm(store, b.userId, b.name, b.location, b.note, b.imagePath || "");
        const res: CommonResponse = {
          message: "添加农田成功"
        };
        return this.success(res);
      } catch (err) {
        return this.fail("添加农田失败");
      }
    }

    if (path === "/api/farm/setImage" && body) {
      try {
        const b: FarmImageBody = body as FarmImageBody;
        const store = await openAgriDb(this.context);
        await setFarmImage(store, b.zoneId, b.imagePath);
        const res: CommonResponse = {
          message: "农田图片保存成功"
        };
        return this.success(res);
      } catch (err) {
        return this.fail("图片保存失败");
      }
    }

    // 新增：农田头像上传接口（同时创建农田记录）
    if (path === "/api/farm/uploadAvatar" && body) {
      try {
        const b: FarmAvatarUploadBody = body as FarmAvatarUploadBody;

        if (!b.userId || !b.farmName || !b.base64|| !b.fileName) {
          return this.fail("参数缺失");
        }

        // 1. 创建保存图片的目录
        const farmImageDir: string = this.context.filesDir + "/farm_images/";
        if (!(await fs.access(farmImageDir))) {
          await fs.mkdir(farmImageDir);
        }

        // 2. 生成唯一文件名
        const ext: string = b.fileName.split(".").pop() || "jpg";
        const saveFileName: string = `FARM_${Date.now()}_${b.userId}.${ext}`;
        const finalImagePath: string = farmImageDir + saveFileName;

        // 3. Base64 转二进制并保存（替换原来的 fs.copyFile）
        const base64Helper: util.Base64Helper = new util.Base64Helper();
        const binaryData: ArrayBuffer = base64Helper.decodeSync(b.base64);
        const bytes: Uint8Array = new Uint8Array(binaryData);
        const file = await fs.open(finalImagePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        await fs.write(file.fd, bytes.buffer);
        await fs.close(file.fd);

        const stat = await fs.stat(finalImagePath);
        console.log(`✅ 农田图片已保存: ${finalImagePath}, 大小: ${stat.size} bytes`);


        // 4. 创建农田记录
        const store = await openAgriDb(this.context);
        const zoneId = await addFarm(
          store,
          b.userId,
          b.farmName,
          b.location || "",
          b.note || "",
          finalImagePath
        );

        // 5. 返回结果
        const res: FarmAvatarUploadResponse = {
          message: "农田创建成功",
          zoneId: zoneId,
          imagePath: finalImagePath
        };
        return this.success(res);
      } catch (err) {
        console.error("农田图片上传失败", err);
        return this.fail("农田创建失败");
      }
    }

    // 添加设备接口 (在删除设备接口之前添加)
    if (path === "/api/device/add" && body) {
      try {
        const b: AddDeviceRequest = body as AddDeviceRequest;

        // 参数校验
        if (!b.farmlandId || !b.deviceId || !b.deviceName || !b.typeId) {
          return this.fail("参数缺失:需要提供 farmlandId、deviceId、deviceName、typeId");
        }

        const store = await openAgriDb(this.context);

        // 调用数据库方法添加设备
        // 注意:需要在 db.ts 中添加 addDevice 方法
        const deviceId = await addDeviceToDatabase(
          store,
          b.farmlandId,
          b.deviceId,
          b.deviceName,
          b.typeId
        );

        const res: AddDeviceResponse = {
          code: 200,
          data: {
            deviceId: deviceId.toString(),
            message: "设备添加成功"
          },
          msg: "success"
        };

        return JSON.stringify(res);
      } catch (err) {
        console.error("添加设备失败", err);
        return this.fail("添加设备失败");
      }
    }
    // 删除农田接口
    if (path === "/api/farm/delete" && body) {
      try {
        const b: FarmDeleteBody = body as FarmDeleteBody;

        if (!b.zoneId) {
          return this.fail("参数缺失：缺少 zoneId");
        }

        const store = await openAgriDb(this.context);
        const success = await deleteFarm(store, b.zoneId);

        if (success) {
          const res: CommonResponse = {
            message: "农田删除成功"
          };
          return this.success(res);
        } else {
          return this.fail("农田不存在或删除失败");
        }
      } catch (err) {
        console.error("删除农田失败", err);
        return this.fail("删除农田失败");
      }
    }

    // 删除设备接口
    if (path === "/api/device/delete" && body) {
      try {
        const b: DeviceDeleteBody = body as DeviceDeleteBody;

        // 参数校验
        if (!b.farmlandId || !b.deviceName) {
          return this.fail("参数缺失：需要提供 farmlandId 和 deviceName");
        }

        const store = await openAgriDb(this.context);

        // 通过农田ID和设备名删除设备
        const predicates = new relationalStore.RdbPredicates('Device');
        predicates.equalTo('zone_id', b.farmlandId).equalTo('name', b.deviceName);
        const rows = await store.delete(predicates);

        const success = rows > 0;

        if (success) {
          const res: CommonResponse = {
            message: "设备删除成功"
          };
          return this.success(res);
        } else {
          return this.fail("设备不存在或删除失败");
        }
      } catch (err) {
        console.error("删除设备失败", err);
        return this.fail("删除设备失败");
      }
    }


    if (path === "/api/video/uploadToGallery" && body) {
      try {
        const b: VideoUploadBody = body as VideoUploadBody;
        if (!b.userId || !b.tempPath || !b.fileName) {
          return this.fail("参数缺失");
        }
        const galleryPath: string = "/storage/DCIM/Camera/";
        const ext: string = b.fileName.split(".").pop() || "mp4";
        const saveFileName: string = `CAM_${Date.now()}.${ext}`;
        const finalVideoPath: string = galleryPath + saveFileName;
        await fs.copyFile(b.tempPath, finalVideoPath);
        const stat = await fs.stat(finalVideoPath);
        const store = await openAgriDb(this.context);
        await addVideoRecord(store, b.userId, b.zoneId || null, "", b.fileName, finalVideoPath, stat.size);
        const res: VideoUploadResponse = {
          message: "视频已保存到模拟器相册",
          videoPath: finalVideoPath
        };
        return this.success(res);
      } catch (err) {
        console.error("视频上传失败", err);
        return this.fail("视频上传失败");
      }
    }

    if (path === "/api/video/list") {
      try {
        const userIdStr: string | null = this.getQueryParam(path, "userId");
        const userId: number = Number(userIdStr);
        if (!userId) {
          return this.fail("缺少 userId");
        }
        const store = await openAgriDb(this.context);
        const list = await getVideoListByUserId(store, userId);
        return this.success(list);
      } catch (err) {
        return this.fail("获取视频列表失败");
      }
    }

    if (path === "/api/video/delete" && body) {
      try {
        const b: VideoDeleteBody = body as VideoDeleteBody;
        const videoId: number = b.videoId;
        if (!videoId) {
          return this.fail("缺少 videoId");
        }
        const store = await openAgriDb(this.context);
        const video = await getVideoById(store, videoId);
        if (video) {
          await fs.unlink(video.file_path);
          await deleteVideoRecord(store, videoId);
        }
        const res: CommonResponse = {
          message: "视频已删除"
        };
        return this.success(res);
      } catch (err) {
        return this.fail("删除失败");
      }
    }

    if (path === "/api/control/send" && body) {
      try {
        const cmd: HardwareControlCommand = body as HardwareControlCommand;
        console.log("📶 连接华为云设备：69c3bc5a7f2e6c302f6089e5");
        console.log("📤 指令：", JSON.stringify(cmd));
        const res: HardwareControlResponse = {
          device: "69c3bc5a7f2e6c302f6089e5",
          status: "指令已发送",
          command: cmd
        };
        return this.success(res);
      } catch (err) {
        return this.fail("硬件通信异常");
      }
    }

    if (path === "/api/photo/list") {
      try {
        const photoDir: string = this.context.filesDir + "/photos/";
        let photoList: string[] = [];

        if (await fs.access(photoDir)) {
          const files = await fs.listFile(photoDir);
          photoList = files
            .filter((file: string) => file.endsWith('.jpg'))
            .map((file: string) => photoDir + file)
            .sort();
        }

        const result: PhotoListResponse = {
          photos: photoList,
          count: photoList.length
        };

        return this.success(result);
      } catch (err) {
        console.error("获取照片列表失败", err);
        return this.fail("获取照片列表失败");
      }
    }

    if (path === "/api/photo/latest") {
      try {
        const photoDir: string = this.context.filesDir + "/photos/";

        if (!(await fs.access(photoDir))) {
          const emptyResponse: LatestPhotoResponse = { path: "" };
          return this.success(emptyResponse);
        }

        const files = await fs.listFile(photoDir);
        const jpgs = files.filter((f: string) => f.endsWith(".jpg")).sort();

        if (jpgs.length === 0) {
          const emptyResponse: LatestPhotoResponse = { path: "" };
          return this.success(emptyResponse);
        }

        const latestPath = photoDir + jpgs[jpgs.length - 1];
        const response: LatestPhotoResponse = { path: latestPath };
        return this.success(response);
      } catch (err) {
        console.error("获取最新照片失败", err);
        return this.fail("获取最新照片失败");
      }
    }

    // 获取最新视频接口
    if (path === "/api/video/latest") {
      try {
        const userIdStr: string | null = this.getQueryParam(path, "userId");
        if (!userIdStr) {
          return this.fail("缺少 userId");
        }

        const userId: number = Number(userIdStr);
        const store = await openAgriDb(this.context);

        // 获取该用户的视频列表
        const list = await getVideoListByUserId(store, userId);

        if (!list || list.length === 0) {
          const emptyResponse: LatestVideoResponse = {
            videoPath: "",
            message: "暂无视频"
          };
          return this.success(emptyResponse);
        }

        // 返回最新的一条视频（假设列表已按时间降序排序）
        const latestVideo = list[0];

        // 根据实际数据库返回的字段名调整
        const res: LatestVideoResponse = {
          videoPath: latestVideo.file_path || "",
          videoId: latestVideo.id,
          fileName: latestVideo.file_name,
          createTime: String(latestVideo.upload_time)
        };

        return this.success(res);
      } catch (err) {
        console.error("获取最新视频失败", err);
        return this.fail("获取最新视频失败");
      }
    }


    return JSON.stringify({ code: 404, msg: "接口不存在" });
  }
}

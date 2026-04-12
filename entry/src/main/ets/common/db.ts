import relationalStore from '@ohos.data.relationalStore';
import fileio from '@ohos.fileio';
import fs from '@ohos.file.fs';

const DB_NAME = 'agri.db';

// 本地定义UserInfo，与HttpServer.ets保持一致
interface UserInfo {
  id: number;
  username: string;
  password: string;
}

// Users表
const CREATE_USERS = `
CREATE TABLE IF NOT EXISTS Users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  created_at INTEGER,
  avatar TEXT DEFAULT ''
);`;

// 种植区域表
const CREATE_ZONE = `
CREATE TABLE IF NOT EXISTS Zone (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  name TEXT NOT NULL,
  location TEXT,
  note TEXT,
  image_path TEXT DEFAULT '',
  created_at INTEGER,
  updated_at INTEGER
);`;

// 设备类型表
const CREATE_DEVICE_TYPE = `
CREATE TABLE IF NOT EXISTS DeviceType (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  desc TEXT
);`;

// 设备表
const CREATE_DEVICE = `
CREATE TABLE IF NOT EXISTS Device (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  zone_id INTEGER NOT NULL,
  device_type_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  sn TEXT UNIQUE,
  status TEXT
);`;

// 传感器读数表
const CREATE_SENSOR_READING = `
CREATE TABLE IF NOT EXISTS SensorReading (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_id INTEGER NOT NULL,
  metric TEXT NOT NULL,
  value REAL NOT NULL,
  ts INTEGER NOT NULL
);`;

// 自动控制规则表
const CREATE_RULE = `
CREATE TABLE IF NOT EXISTS Rule (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  zone_id INTEGER NOT NULL,
  sensor_metric TEXT NOT NULL,
  operator TEXT NOT NULL,
  threshold_low REAL,
  threshold_high REAL,
  action TEXT NOT NULL,
  target_device_id INTEGER NOT NULL,
  duration_sec INTEGER DEFAULT 0,
  priority INTEGER DEFAULT 0,
  enabled INTEGER DEFAULT 1
);`;

// 视频表（适配ESP32-CAM，加device_sn）
const CREATE_VIDEO = `
CREATE TABLE IF NOT EXISTS Video (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  zone_id INTEGER,
  device_sn TEXT,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size INTEGER NOT NULL,
  upload_time INTEGER NOT NULL,
  duration INTEGER DEFAULT 0,
  FOREIGN KEY (user_id) REFERENCES Users(id)
);`;

// 每10分钟抓拍照片表
const CREATE_CAPTURE_PHOTO = `
CREATE TABLE IF NOT EXISTS CapturePhoto (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_sn TEXT NOT NULL,
  zone_id INTEGER,
  photo_path TEXT NOT NULL,
  capture_time INTEGER NOT NULL
);`;

// 打开/创建数据库
// 第109-118行 openAgriDb 函数
export async function openAgriDb(context: any): Promise<relationalStore.RdbStore> {
  try {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    const store = await relationalStore.getRdbStore(context, config);
    await ensureSchema(store);
    await seedDeviceTypes(store);
    await seedTestData(store);
    return store;
  } catch (err) {
    console.error('打开数据库失败:', err);
    throw err;
  }
}

async function ensureSchema(store: relationalStore.RdbStore) {
  try {
    await store.executeSql(CREATE_USERS);
    await store.executeSql(CREATE_ZONE);
    await store.executeSql(CREATE_DEVICE_TYPE);
    await store.executeSql(CREATE_DEVICE);
    await store.executeSql(CREATE_SENSOR_READING);
    await store.executeSql(CREATE_RULE);
    await store.executeSql(CREATE_VIDEO);
    await store.executeSql(CREATE_CAPTURE_PHOTO);
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_zone_user ON Zone(user_id)');
  } catch (err) {
    console.error('创建表结构失败:', err);
    throw err;
  }
}

// 自动插入默认设备类型（已加：光照传感器）
async function seedDeviceTypes(store: relationalStore.RdbStore) {
  try {
    const types = [
      ['SENSOR_SOIL', '土壤湿度传感器', 'sensor', '采集土壤含水率'],
      ['SENSOR_TEMP', '温度传感器', 'sensor', '采集环境温度'],
      ['SENSOR_LIGHT', '光照强度传感器', 'sensor', '采集环境光照强度(lux)'],
      ['VALVE_MAIN', '主灌溉阀门', 'valve', '控制灌溉水路'],
      ['CTRL_GATEWAY', '网关控制器', 'controller', '现场控制网关']
    ];
    for (const [code, name, category, desc] of types) {
      await store.executeSql(
        'INSERT OR IGNORE INTO DeviceType (code, name, category, desc) VALUES (?, ?, ?, ?)',
        [code, name, category, desc]
      );
    }
  } catch (err) {
    console.error('初始化设备类型失败:', err);
    throw err;
  }
}

// 初始化测试数据（已加：光照设备）
async function seedTestData(store: relationalStore.RdbStore) {
  try {
    await store.executeSql(`      INSERT OR IGNORE INTO Zone (name, location, note, created_at)
      VALUES ('一号大棚', '东区', '蔬菜种植区', ?)
    `, [Date.now()]);

    await store.executeSql(`      INSERT OR IGNORE INTO Device (zone_id, device_type_id, name, sn, status)
      VALUES (1, 1, '土壤传感器', 'SN001', 'online')
    `);
    await store.executeSql(`      INSERT OR IGNORE INTO Device (zone_id, device_type_id, name, sn, status)
      VALUES (1, 3, '主灌溉阀门', 'VALVE001', 'online')
    `);
    await store.executeSql(`      INSERT OR IGNORE INTO Device (zone_id, device_type_id, name, sn, status)
      VALUES (1, 5, '光照传感器', 'LIGHT001', 'online')
    `);

    await store.executeSql(`      INSERT OR IGNORE INTO Rule
      (zone_id, sensor_metric, operator, threshold_low, threshold_high, action, target_device_id, enabled)
      VALUES
      (1, 'soilHumidity', '<', 30, 100, 'open', 3, 1)
    `);
  } catch (err) {
    console.error('初始化测试数据失败:', err);
    throw err;
  }
}


// 根据用户名获取用户信息（用于登录验证）
export async function getUserByUsername(
  store: relationalStore.RdbStore,
  username: string
): Promise<UserInfo | null> {
  const predicates = new relationalStore.RdbPredicates('Users');
  predicates.equalTo('username', username);
  const resultSet = await store.query(predicates, ['id', 'username', 'password']);

  let user: UserInfo | null = null;
  try {
    if (resultSet && !resultSet.isClosed && resultSet.goToFirstRow()) {
      user = {
        id: resultSet.getLong(0),
        username: resultSet.getString(1),
        password: resultSet.getString(2)
      };
    }
  } catch (err) {
    console.error('查询用户失败:', err);
    throw err;
  } finally {
    if (resultSet && !resultSet.isClosed) {
      resultSet.close();
    }
  }
  return user;
}

// 用户登录验证
export interface LoginResult {
  success: boolean;
  userId?: number;
  username?: string;
  message?: string;
}

// 创建用户(注册)
export async function createUser(
  store: relationalStore.RdbStore,
  username: string,
  password: string
): Promise<number> {
  const values = {
    username: username,
    password: password,
    created_at: Date.now()
  };
  return await store.insert('Users', values);
}

// 检查用户名是否存在
export async function checkUsernameExists(
  store: relationalStore.RdbStore,
  username: string
): Promise<boolean> {
  const predicates = new relationalStore.RdbPredicates('Users');
  predicates.equalTo('username', username);
  const resultSet = await store.query(predicates, ['id']);

  let exists = false;
  try {
    if (resultSet && !resultSet.isClosed && resultSet.goToFirstRow()) {
      exists = true;
    }
  } finally {
    if (resultSet && !resultSet.isClosed) {
      resultSet.close();
    }
  }
  return exists;
}

export async function verifyUserLogin(
  store: relationalStore.RdbStore,
  username: string,
  password: string
): Promise<LoginResult> {
  try {
    const user = await getUserByUsername(store, username);

    if (!user) {
      return {
        success: false,
        message: '用户不存在'
      };
    }

    if (user.password !== password) {
      return {
        success: false,
        message: '密码错误'
      };
    }

    return {
      success: true,
      userId: user.id,
      username: user.username,
      message: '登录成功'
    };
  } catch (err) {
    console.error('登录验证失败:', err);
    return {
      success: false,
      message: '服务器内部错误'
    };
  }
}

// 执行初始化SQL文件
export async function runInitSql(store: relationalStore.RdbStore, context: any) {
  try {
    const resourceManager = context.resourceManager;

    // 直接获取文件内容（返回 ArrayBuffer）
    const content: ArrayBuffer = resourceManager.getRawFileContent('init.sql');

    // 将 ArrayBuffer 转为字符串
    const uint8Array: Uint8Array = new Uint8Array(content);
    const sql: string = String.fromCharCode.apply(null, Array.from(uint8Array) as any);

    // 分割并执行 SQL 语句
    const stmts: string[] = sql.split(';').map(s => s.trim()).filter(s => s.length > 0);
    for (const s of stmts) {
      if (s.length > 0) {
        await store.executeSql(s);
      }
    }
  } catch (e) {
    console.error('执行init.sql失败:', e);
  }
}

// 头像功能
export async function updateUserAvatar(
  store: relationalStore.RdbStore,
  userId: number,
  avatarPath: string
): Promise<number> {
  try {
    const predicates = new relationalStore.RdbPredicates('Users');
    predicates.equalTo('id', userId);
    const values = { avatar: avatarPath };
    return await store.update(values, predicates);
  } catch (err) {
    console.error('更新头像失败:', err);
    throw err;
  }
}

export async function getUserAvatar(
  store: relationalStore.RdbStore,
  userId: number
): Promise<string> {
  const predicates = new relationalStore.RdbPredicates('Users');
  predicates.equalTo('id', userId);
  const resultSet = await store.query(predicates, ['avatar']);

  let avatar = '';
  try {
    if (resultSet && !resultSet.isClosed && resultSet.goToFirstRow()) {
      avatar = resultSet.getString(resultSet.getColumnIndex('avatar'));
    }
  } catch (err) {
    console.error('查询头像失败:', err);
    throw err;
  } finally {
    if (resultSet && !resultSet.isClosed) {
      resultSet.close();
    }
  }
  return avatar;
}

export async function getUserById(
  store: relationalStore.RdbStore,
  userId: number
): Promise<UserInfo | null> {
  const predicates = new relationalStore.RdbPredicates('Users');
  predicates.equalTo('id', userId);
  const resultSet = await store.query(predicates, ['id', 'username', 'password']);

  let user: UserInfo | null = null;
  try {
    if (resultSet && !resultSet.isClosed && resultSet.goToFirstRow()) {
      user = {
        id: resultSet.getLong(0),
        username: resultSet.getString(1),
        password: resultSet.getString(2)
      };
    }
  } catch (err) {
    console.error('查询用户失败:', err);
    throw err;
  } finally {
    if (resultSet && !resultSet.isClosed) {
      resultSet.close();
    }
  }
  return user;
}
// 修改用户名+密码
export async function updateUserProfile(
  store: relationalStore.RdbStore,
  userId: number,
  newUsername: string,
  newPassword: string
): Promise<number> {
  try {
    const predicates = new relationalStore.RdbPredicates('Users');
    predicates.equalTo('id', userId);
    const values = {
      username: newUsername,
      password: newPassword
    };
    return await store.update(values, predicates);
  } catch (err) {
    console.error('更新用户资料失败:', err);
    throw err;
  }
}

// 设置农田图片
export async function setFarmImage(
  store: relationalStore.RdbStore,
  zoneId: number,
  imagePath: string
): Promise<number> {
  try {
    const predicates = new relationalStore.RdbPredicates('Zone');
    predicates.equalTo('id', zoneId);
    return await store.update({ image_path: imagePath }, predicates);
  } catch (err) {
    console.error('设置农田图片失败:', err);
    throw err;
  }
}

export async function getFarmImage(
  store: relationalStore.RdbStore,
  zoneId: number
): Promise<string> {
  const predicates = new relationalStore.RdbPredicates('Zone');
  predicates.equalTo('id', zoneId);
  const resultSet = await store.query(predicates, ['image_path']);

  let path = '';
  try {
    if (resultSet && !resultSet.isClosed && resultSet.goToFirstRow()) {
      path = resultSet.getString(0);
    }
  } catch (err) {
    console.error('查询农田图片失败:', err);
    throw err;
  } finally {
    if (resultSet && !resultSet.isClosed) {
      resultSet.close();
    }
  }
  return path;
}

// 添加农田（支持图片）
export async function addFarm(
  store: relationalStore.RdbStore,
  userId: number,
  name: string,
  location: string,
  note: string,
  imagePath: string = ''
): Promise<number> {
  try {
    const values = {
      user_id: userId,
      name: name,
      location: location,
      note: note,
      image_path: imagePath,
      created_at: Date.now(),
      updated_at: Date.now()
    };
    return await store.insert('Zone', values);
  } catch (err) {
    console.error('添加农田失败:', err);
    throw err;
  }
}

// 删除农田（包括图片和关联设备）
export async function deleteFarm(
  store: relationalStore.RdbStore,
  zoneId: number
): Promise<boolean> {
  try {
    // 1. 先查询农田信息，获取图片路径
    const predicates = new relationalStore.RdbPredicates('Zone');
    predicates.equalTo('id', zoneId);
    const resultSet = await store.query(predicates, ['id', 'image_path']);

    let imagePath = '';
    if (resultSet && !resultSet.isClosed && resultSet.goToFirstRow()) {
      imagePath = resultSet.getString(resultSet.getColumnIndex('image_path'));
    }
    resultSet?.close();

    // 2. 删除关联的设备
    const devicePredicates = new relationalStore.RdbPredicates('Device');
    devicePredicates.equalTo('zone_id', zoneId);
    await store.delete(devicePredicates);

    // 3. 删除农田记录
    const zonePredicates = new relationalStore.RdbPredicates('Zone');
    zonePredicates.equalTo('id', zoneId);
    const result = await store.delete(zonePredicates);

    // 4. 删除图片文件（如果存在）
    if (imagePath && imagePath.length > 0) {
      try {
        if (await fs.access(imagePath)) {
          await fs.unlink(imagePath);
          console.log('✅ 农田图片已删除:', imagePath);
        }
      } catch (err) {
        console.error('⚠️ 删除农田图片失败:', err);
      }
    }

    return result > 0;
  } catch (err) {
    console.error('删除农田失败:', err);
    throw err;
  }
}

// 删除设备
export async function deleteDevice(
  store: relationalStore.RdbStore,
  deviceId: number
): Promise<boolean> {
  try {
    const predicates = new relationalStore.RdbPredicates('Device');
    predicates.equalTo('id', deviceId);
    const result = await store.delete(predicates);
    return result > 0;
  } catch (err) {
    console.error('删除设备失败:', err);
    throw err;
  }
}


// 获取农田列表（带图片）
export interface FarmZone {
  id: number;
  name: string;
  location: string;
  note: string;
  imagePath: string;
}

export async function getFarmList(
  store: relationalStore.RdbStore,
  userId: number
): Promise<FarmZone[]> {
  const predicates = new relationalStore.RdbPredicates('Zone');
  predicates.equalTo('user_id', userId);
  const resultSet = await store.query(predicates, [
    'id', 'name', 'location', 'note', 'image_path'
  ]);

  const list: FarmZone[] = [];
  try {
    if (resultSet && !resultSet.isClosed) {
      while (resultSet.goToNextRow()) {
        list.push({
          id: resultSet.getLong(0),
          name: resultSet.getString(1),
          location: resultSet.getString(2),
          note: resultSet.getString(3),
          imagePath: resultSet.getString(4)
        });
      }
    }
  } catch (err) {
    console.error('查询农田列表失败:', err);
    throw err;
  } finally {
    if (resultSet && !resultSet.isClosed) {
      resultSet.close();
    }
  }
  return list;
}
// 视频功能
export interface Video {
  id?: number;
  user_id: number;
  zone_id?: number;
  device_sn?: string; // <<< 新增
  file_name: string;
  file_path: string;
  file_size: number;
  upload_time: number;
  duration?: number;
}

// 新增视频记录（已适配ESP32，支持device_sn）
export async function addVideoRecord(
  store: relationalStore.RdbStore,
  user_id: number,
  zone_id: number | null,
  device_sn: string | null,
  file_name: string,
  file_path: string,
  file_size: number,
  duration: number = 0
): Promise<number> {
  try {
    const data = {
      user_id,
      zone_id: zone_id ?? 0,
      device_sn: device_sn ?? '',
      file_name,
      file_path,
      file_size,
      upload_time: Date.now(),
      duration
    };
    return await store.insert('Video', data);
  } catch (err) {
    console.error('添加视频记录失败:', err);
    throw err;
  }
}

// 获取用户的所有视频
export async function getVideoListByUserId(
  store: relationalStore.RdbStore,
  user_id: number
): Promise<Video[]> {
  const predicates = new relationalStore.RdbPredicates('Video');
  predicates.equalTo('user_id', user_id);
  const resultSet = await store.query(predicates, [
    'id', 'user_id', 'zone_id', 'device_sn', 'file_name', 'file_path', 'file_size', 'upload_time', 'duration'
  ]);

  const list: Video[] = [];
  try {
    if (resultSet && !resultSet.isClosed) {
      while (resultSet.goToNextRow()) {
        list.push({
          id: resultSet.getLong(0),
          user_id: resultSet.getLong(1),
          zone_id: resultSet.getLong(2),
          device_sn: resultSet.getString(3),
          file_name: resultSet.getString(4),
          file_path: resultSet.getString(5),
          file_size: resultSet.getLong(6),
          upload_time: resultSet.getLong(7),
          duration: resultSet.getLong(8)
        });
      }
    }
  } catch (err) {
    console.error('查询视频列表失败:', err);
    throw err;
  } finally {
    if (resultSet && !resultSet.isClosed) {
      resultSet.close();
    }
  }
  return list;
}

// 根据ID获取单个视频
export async function getVideoById(
  store: relationalStore.RdbStore,
  id: number
): Promise<Video | null> {
  const predicates = new relationalStore.RdbPredicates('Video');
  predicates.equalTo('id', id);
  const resultSet = await store.query(predicates, [
    'id', 'user_id', 'zone_id', 'device_sn', 'file_name', 'file_path', 'file_size', 'upload_time', 'duration'
  ]);

  let video: Video | null = null;
  try {
    if (resultSet && !resultSet.isClosed && resultSet.goToFirstRow()) {
      video = {
        id: resultSet.getLong(0),
        user_id: resultSet.getLong(1),
        zone_id: resultSet.getLong(2),
        device_sn: resultSet.getString(3),
        file_name: resultSet.getString(4),
        file_path: resultSet.getString(5),
        file_size: resultSet.getLong(6),
        upload_time: resultSet.getLong(7),
        duration: resultSet.getLong(8)
      };
    }
  } catch (err) {
    console.error('查询视频失败:', err);
    throw err;
  } finally {
    if (resultSet && !resultSet.isClosed) {
      resultSet.close();
    }
  }
  return video;
}

// 删除视频记录
export async function deleteVideoRecord(
  store: relationalStore.RdbStore,
  id: number
): Promise<number> {
  try {
    const predicates = new relationalStore.RdbPredicates('Video');
    predicates.equalTo('id', id);
    return await store.delete(predicates);
  } catch (err) {
    console.error('删除视频记录失败:', err);
    throw err;
  }
}



export interface CapturePhoto {
  id?: number;
  device_sn: string;
  zone_id?: number;
  photo_path: string;
  capture_time: number;
}

// 插入抓拍照片（定时任务用）
export async function addCapturePhoto(
  store: relationalStore.RdbStore,
  device_sn: string,
  zone_id: number | null,
  photo_path: string
): Promise<number> {
  try {
    const data = {
      device_sn,
      zone_id: zone_id ?? 0,
      photo_path,
      capture_time: Date.now()
    };
    return await store.insert('capture_photo', data);
  } catch (err) {
    console.error('添加抓拍照片失败:', err);
    throw err;
  }
}

// 获取每个设备最新视频（抓拍用）
export async function getLatestVideoPerDevice(store: relationalStore.RdbStore): Promise<Video[]> {
  const sql = `    SELECT * FROM Video v1
    WHERE upload_time = (SELECT MAX(upload_time) FROM Video v2 WHERE v2.device_sn = v1.device_sn)
  `;
  const resultSet = await store.querySql(sql, []);
  const list: Video[] = [];
  try {
    while (resultSet.goToNextRow()) {
      list.push({
        id: resultSet.getLong(0),
        user_id: resultSet.getLong(1),
        zone_id: resultSet.getLong(2),
        device_sn: resultSet.getString(3),
        file_name: resultSet.getString(4),
        file_path: resultSet.getString(5),
        file_size: resultSet.getLong(6),
        upload_time: resultSet.getLong(7),
        duration: resultSet.getLong(8)
      });
    }
  } catch (err) {
    console.error('查询最新视频失败:', err);
    throw err;
  } finally {
    resultSet.close();
  }
  return list;
}

// APP照片列表接口（按设备SN查询）
export async function getPhotoListByDevice(
  store: relationalStore.RdbStore,
  device_sn: string
): Promise<CapturePhoto[]> {
  const predicates = new relationalStore.RdbPredicates('capture_photo');
  predicates.equalTo('device_sn', device_sn);
  predicates.orderByDesc('capture_time');

  const resultSet = await store.query(predicates, ['id', 'device_sn', 'zone_id', 'photo_path', 'capture_time']);
  const list: CapturePhoto[] = [];
  try {
    while (resultSet.goToNextRow()) {
      list.push({
        id: resultSet.getLong(0),
        device_sn: resultSet.getString(1),
        zone_id: resultSet.getLong(2),
        photo_path: resultSet.getString(3),
        capture_time: resultSet.getLong(4)
      });
    }
  } catch (err) {
    console.error('查询照片列表失败:', err);
    throw err;
  } finally {
    resultSet.close();
  }
  return list;
}
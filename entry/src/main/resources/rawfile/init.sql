BEGIN TRANSACTION;

CREATE TABLE IF NOT EXISTS Users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  created_at INTEGER,
  avatar TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS Zone (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER,
  name TEXT NOT NULL,
  location TEXT,
  note TEXT,
  created_at INTEGER,
  updated_at INTEGER
);

CREATE TABLE IF NOT EXISTS DeviceType (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  desc TEXT
);

CREATE TABLE IF NOT EXISTS Device (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  zone_id INTEGER NOT NULL,
  device_type_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  sn TEXT UNIQUE,
  status TEXT
);

CREATE TABLE IF NOT EXISTS SensorReading (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_id INTEGER NOT NULL,
  metric TEXT NOT NULL,
  value REAL NOT NULL,
  ts INTEGER NOT NULL
);

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
);

CREATE TABLE IF NOT EXISTS alarm (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  deviceId TEXT NOT NULL,
  alarmType TEXT NOT NULL,
  level TEXT NOT NULL,
  message TEXT NOT NULL,
  createTime TEXT NOT NULL,
  isRead INTEGER DEFAULT 0
);

-- ESP32视频存储表
CREATE TABLE IF NOT EXISTS video (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_sn TEXT NOT NULL,        -- ESP32-CAM 序列号
  zone_id INTEGER,                -- 所属种植区
  file_path TEXT NOT NULL,        -- 视频在鸿蒙后端的存储路径
  duration INTEGER DEFAULT 0,
  upload_time INTEGER NOT NULL,
  FOREIGN KEY (zone_id) REFERENCES Zone(id)
);

-- 10分钟抓拍照片表
CREATE TABLE IF NOT EXISTS capture_photo (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_sn TEXT NOT NULL,        -- 哪个摄像头抓拍
  zone_id INTEGER,                -- 所属区域
  photo_path TEXT NOT NULL,       -- 照片服务器路径
  capture_time INTEGER NOT NULL,  -- 抓拍时间戳
  FOREIGN KEY (zone_id) REFERENCES Zone(id)
);

-- 索引（查询加速）
CREATE INDEX IF NOT EXISTS idx_video_device ON video(device_sn);
CREATE INDEX IF NOT EXISTS idx_photo_device ON capture_photo(device_sn);
CREATE INDEX IF NOT EXISTS idx_photo_time ON capture_photo(capture_time);

CREATE INDEX IF NOT EXISTS idx_zone_user ON Zone(user_id);

INSERT OR IGNORE INTO DeviceType (code, name, category, desc) VALUES
('SENSOR_SOIL','土壤湿度传感器','sensor','采集土壤含水率'),
('SENSOR_TEMP','温度传感器','sensor','采集环境温度'),
('VALVE_MAIN','主灌溉阀门','valve','控制灌溉水路'),
('CTRL_GATEWAY','网关控制器','controller','现场控制网关'),
('SENSOR_LIGHT','光照强度传感器','sensor','采集环境光照强度(lux)');

COMMIT;
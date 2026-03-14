import relationalStore from '@ohos.data.relationalStore';
import fileio from '@ohos.fileio';

const DB_NAME = 'agri.db';

const CREATE_ZONE = `
CREATE TABLE IF NOT EXISTS Zone (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  location TEXT,
  note TEXT,
  created_at INTEGER,
  updated_at INTEGER
);`;

const CREATE_DEVICE_TYPE = `
CREATE TABLE IF NOT EXISTS DeviceType (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  code TEXT UNIQUE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  desc TEXT
);`;

const CREATE_DEVICE = `
CREATE TABLE IF NOT EXISTS Device (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  zone_id INTEGER NOT NULL,
  device_type_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  sn TEXT UNIQUE,
  status TEXT
);`;

const CREATE_SENSOR_READING = `
CREATE TABLE IF NOT EXISTS SensorReading (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  device_id INTEGER NOT NULL,
  metric TEXT NOT NULL,
  value REAL NOT NULL,
  ts INTEGER NOT NULL
);`;

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

export async function openAgriDb(context: any): Promise<relationalStore.RdbStore> {
  const config: relationalStore.StoreConfig = {
    name: DB_NAME,
    securityLevel: relationalStore.SecurityLevel.S1
  };
  const store = await relationalStore.getRdbStore(context, config);
  await ensureSchema(store);
  await seedDeviceTypes(store);
  return store;
}

async function ensureSchema(store: relationalStore.RdbStore) {
  await store.executeSql(CREATE_ZONE);
  await store.executeSql(CREATE_DEVICE_TYPE);
  await store.executeSql(CREATE_DEVICE);
  await store.executeSql(CREATE_SENSOR_READING);
  await store.executeSql(CREATE_RULE);
  try { await store.executeSql('ALTER TABLE Room RENAME TO Zone;'); } catch {}
  try { await store.executeSql('ALTER TABLE Zone ADD COLUMN note TEXT;'); } catch {}
}

async function seedDeviceTypes(store: relationalStore.RdbStore) {
  const types = [
    ['SENSOR_SOIL', '土壤湿度传感器', 'sensor', '采集土壤含水率'],
    ['SENSOR_TEMP', '温度传感器', 'sensor', '采集环境温度'],
    ['VALVE_MAIN', '主灌溉阀门', 'valve', '控制灌溉水路'],
    ['CTRL_GATEWAY', '网关控制器', 'controller', '现场控制网关']
  ];
  for (const [code, name, category, desc] of types) {
    await store.executeSql(
      'INSERT OR IGNORE INTO DeviceType (code, name, category, desc) VALUES (?, ?, ?, ?)',
      [code, name, category, desc]
    );
  }
}

export async function runInitSql(store: relationalStore.RdbStore, context: any) {
  try {
    const d = context.resourceManager.getRawFileDescriptor('init.sql');
    const stat = fileio.fstatSync(d.fd);
    const buf = new ArrayBuffer(stat.size);
    fileio.readSync(d.fd, buf);
    const sql = String.fromCharCode.apply(null, Array.from(new Uint8Array(buf)) as any);
    const stmts = sql.split(';').map(s => s.trim()).filter(s => s.length > 0);
    for (const s of stmts) { await store.executeSql(s); }
  } catch {}
}
import relationalStore from '@ohos.data.relationalStore';
import { Context } from '@kit.AbilityKit';

// 转义SQL特殊字符
function esc(v: string | null | undefined): string {
  if (v === null || v === undefined) return 'NULL';
  const s = String(v);
  if (/^-?\d+(\.\d+)?$/.test(s)) return s;
  return `'${s.replace(/'/g, "''")}'`;
}

// 导出单表数据
async function dumpTable(
  store: relationalStore.RdbStore,
  table: string,
  cols: string[]
): Promise<string> {
  let rs: relationalStore.ResultSet | null = null;
  try {
    rs = await store.query(new relationalStore.RdbPredicates(table), cols);
    if (!rs || rs.isClosed) return '';

    const lines: string[] = [];
    while (rs.goToNextRow()) {
      const vals: string[] = [];
      for (const c of cols) {
        const idx = rs.getColumnIndex(c);
        let v: string | null = null;
        try { v = rs.getString(idx); } catch { v = null; }
        vals.push(esc(v));
      }
      lines.push(`INSERT OR IGNORE INTO ${table} (${cols.join(',')}) VALUES (${vals.join(',')});`);
    }
    return lines.length > 0 ? lines.join('\n') + '\n' : '';
  } catch (err) {
    console.error('AgriServer', 'dumpTable error:', JSON.stringify(err));
    return '';
  } finally {
    if (rs && !rs.isClosed) rs.close();
  }
}

// 导出完整SQL
export async function exportInitSql(
  store: relationalStore.RdbStore,
  context: Context
): Promise<string> {
  const createPart = `BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS Users (id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE NOT NULL, password TEXT NOT NULL, created_at INTEGER, avatar TEXT DEFAULT '');
CREATE TABLE IF NOT EXISTS Zone (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, name TEXT NOT NULL, location TEXT, note TEXT, image_path TEXT DEFAULT '', created_at INTEGER, updated_at INTEGER);
CREATE TABLE IF NOT EXISTS DeviceType (id INTEGER PRIMARY KEY AUTOINCREMENT, code TEXT UNIQUE, name TEXT NOT NULL, category TEXT NOT NULL, desc TEXT);
CREATE TABLE IF NOT EXISTS Device (id INTEGER PRIMARY KEY AUTOINCREMENT, zone_id INTEGER NOT NULL, device_type_id INTEGER NOT NULL, name TEXT NOT NULL, sn TEXT UNIQUE, status TEXT);
CREATE TABLE IF NOT EXISTS SensorReading (id INTEGER PRIMARY KEY AUTOINCREMENT, device_id INTEGER NOT NULL, metric TEXT NOT NULL, value REAL NOT NULL, ts INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS Rule (id INTEGER PRIMARY KEY AUTOINCREMENT, zone_id INTEGER NOT NULL, sensor_metric TEXT NOT NULL, operator TEXT NOT NULL, threshold_low REAL, threshold_high REAL, action TEXT NOT NULL, target_device_id INTEGER NOT NULL, duration_sec INTEGER DEFAULT 0, priority INTEGER DEFAULT 0, enabled INTEGER DEFAULT 1);
CREATE INDEX IF NOT EXISTS idx_zone_user ON Zone(user_id);
CREATE INDEX IF NOT EXISTS idx_device_zone ON Device(zone_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_zone_user_name ON Zone(user_id, name);
CREATE UNIQUE INDEX IF NOT EXISTS uq_rule_signature ON Rule(zone_id, sensor_metric, operator, action, target_device_id);

INSERT OR IGNORE INTO DeviceType (code, name, category, desc) VALUES
('SENSOR_SOIL','土壤湿度传感器','sensor','采集土壤含水率'),
('SENSOR_TEMP','温度传感器','sensor','采集环境温度'),
('VALVE_MAIN','主灌溉阀门','valve','控制灌溉水路'),
('CTRL_GATEWAY','网关控制器','controller','现场控制网关');
`;

  const users = await dumpTable(store, 'Users', ['id','username','password','created_at','avatar']);
  const zones = await dumpTable(store, 'Zone', ['id','user_id','name','location','note','image_path','created_at','updated_at']);
  const types = await dumpTable(store, 'DeviceType', ['id','code','name','category','desc']);
  const devices = await dumpTable(store, 'Device', ['id','zone_id','device_type_id','name','sn','status']);
  const readings = await dumpTable(store, 'SensorReading', ['id','device_id','metric','value','ts']);
  const rules = await dumpTable(store, 'Rule', ['id','zone_id','sensor_metric','operator','threshold_low','threshold_high','action','target_device_id','duration_sec','priority','enabled']);

  const finalSql = createPart + users + zones + types + devices + readings + rules + 'COMMIT;\n';

  // ==============================================
  // ✅ 核心：直接把完整SQL打印到日志
  // ==============================================
  console.log("========================================");
  console.log("✅ 你的 SQL 文件内容如下：");
  console.log("========================================");
  console.log(finalSql);
  console.log("========================================");
  console.log("✅ 复制上面所有内容 → 粘贴到 D:\\MycppSQL\\init_export.sql");
  console.log("========================================");

  return finalSql;
}
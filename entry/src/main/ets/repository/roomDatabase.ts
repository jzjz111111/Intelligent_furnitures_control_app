import relationalStore from '@ohos.data.relationalStore';
import { openAgriDb } from '../common/db';

// 告警实体
export interface Alarm {
  id?: number;
  deviceId: string;
  alarmType: string;
  level: 'WARNING' | 'ERROR' | 'CRITICAL';
  message: string;
  createTime: string;
  isRead: number;
}

// 告警服务
export class AlarmService {
  private db: RoomDatabase;

  constructor(db: RoomDatabase) {
    this.db = db;
  }

  // 触发告警
  async triggerAlarm(
    deviceId: string,
    alarmType: string,
    level: 'WARNING' | 'ERROR' | 'CRITICAL',
    message: string
  ): Promise<number> {
    return this.db.addAlarm({
      deviceId,
      alarmType,
      level,
      message,
      createTime: new Date().toISOString(),
      isRead: 0
    });
  }

  // 获取告警列表
  async getAlarms(): Promise<Alarm[]> {
    return this.db.getAlarmList();
  }

  // 标记已读
  async markRead(id: number): Promise<number> {
    return this.db.readAlarm(id);
  }

  // 清空全部
  async clearAll(): Promise<number> {
    return this.db.clearAllAlarm();
  }
}

// 全局单例（方便任意地方调用）
export let alarmService: AlarmService | null = null;

export function initAlarmService(db: RoomDatabase) {
  alarmService = new AlarmService(db);
  console.log("✅ 告警服务已启动");
}

// RoomDatabase（纯农业后端，只保留告警功能）
export class RoomDatabase {
  private context: any;
  private rdbStore: relationalStore.RdbStore | null = null;

  constructor(context: any) {
    this.context = context;
    this.initDatabase();
  }

  private async initDatabase() {
    try {
      this.rdbStore = await openAgriDb(this.context);
    } catch (err: any) {
      console.error(`数据库初始化失败: ${err?.message}`);
    }
  }

  // 告警数据库操作
  async addAlarm(alarm: Omit<Alarm, 'id'>): Promise<number> {
    if (!this.rdbStore) return -1;
    try {
      return await this.rdbStore.insert('alarm', alarm);
    } catch (e) {
      console.error('添加告警失败', e);
      return -1;
    }
  }

  async getAlarmList(): Promise<Alarm[]> {
    if (!this.rdbStore) return [];
    try {
      const resultSet = await this.rdbStore.querySql(
        'SELECT * FROM alarm ORDER BY createTime DESC',
        []
      );
      const list: Alarm[] = [];
      while (resultSet.goToNextRow()) {
        list.push({
          id: resultSet.getLong(resultSet.getColumnIndex('id')),
          deviceId: resultSet.getString(resultSet.getColumnIndex('deviceId')),
          alarmType: resultSet.getString(resultSet.getColumnIndex('alarmType')),
          level: resultSet.getString(resultSet.getColumnIndex('level')) as any,
          message: resultSet.getString(resultSet.getColumnIndex('message')),
          createTime: resultSet.getString(resultSet.getColumnIndex('createTime')),
          isRead: resultSet.getLong(resultSet.getColumnIndex('isRead')),
        });
      }
      resultSet.close();
      return list;
    } catch (e) {
      console.error('获取告警失败', e);
      return [];
    }
  }

  async readAlarm(id: number): Promise<number> {
    if (!this.rdbStore) return 0;
    try {
      const predicates = new relationalStore.RdbPredicates('alarm');
      predicates.equalTo('id', id);
      return await this.rdbStore.update(
        { isRead: 1 },
        predicates
      );
    } catch (e) {
      console.error('标记已读失败', e);
      return 0;
    }
  }

  async clearAllAlarm(): Promise<number> {
    if (!this.rdbStore) return 0;
    try {
      const predicates = new relationalStore.RdbPredicates('alarm');
      return await this.rdbStore.delete(predicates);
    } catch (e) {
      console.error('清空告警失败', e);
      return 0;
    }
  }
}
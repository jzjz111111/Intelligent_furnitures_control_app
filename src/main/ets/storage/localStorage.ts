import { preferences } from '@kit.ArkData';

export class LocalStorage {
  private dataPreferences: preferences.Preferences | null = null;
  private storage: string;
//创建存储文件
  constructor(name: string) {
    this.storage = name;
  }

  private async getPreferences(): Promise<preferences.Preferences> {
    if (!this.dataPreferences) {
      this.dataPreferences = await preferences.getPreferences(globalThis.context, this.storage);
    }
    return this.dataPreferences!;
  }

  public async set(key: string, value: string | boolean | number): Promise<void> {//存数据
    const prefs = await this.getPreferences();
    await prefs.put(key, value);
    await new Promise<void>((resolve, reject) => {
      prefs.flush(err => (err ? reject(err) : resolve()));
    });
  }

  public async get<T extends string | boolean | number>(key: string, defaultValue: T): Promise<T> {//取数据
    const prefs = await this.getPreferences();
    const value = await prefs.get(key, defaultValue);
    return value as T;
  }

  public async getString(key: string): Promise<string> {
    const prefs = await this.getPreferences();
    const value = await prefs.get(key, '');
    return String(value);
  }

  public async clear(key: string): Promise<void> {//清除清空
    const prefs = await this.getPreferences();
    await prefs.put(key, '');
    await new Promise<void>((resolve, reject) => {
      prefs.flush(err => (err ? reject(err) : resolve()));
    });
  }

  public async setJSON(key: string, obj: any): Promise<void> {//存JSON对象
    await this.set(key, JSON.stringify(obj));
  }

  public async getJSON<T>(key: string): Promise<T | null> {//取JSON对象
    const s = await this.getString(key);
    if (!s) return null;
    try {
      return JSON.parse(s) as T;
    } catch {
      return null;
    }
  }
}
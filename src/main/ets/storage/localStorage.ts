import { preferences } from '@kit.ArkData';

export class LocalStorage {
  private dataPreferences: preferences.Preferences | null = null;
  private storage: string;

  constructor(name: string) {
    this.storage = name;
  }

  private async getPreferences(): Promise<preferences.Preferences> {
    if (!this.dataPreferences) {
      this.dataPreferences = await preferences.getPreferences(globalThis.context, this.storage);
    }
    return this.dataPreferences!;
  }

  public async set(key: string, value: string | boolean | number): Promise<void> {
    const prefs = await this.getPreferences();
    await prefs.put(key, value);
    await new Promise<void>((resolve, reject) => {
      prefs.flush(err => (err ? reject(err) : resolve()));
    });
  }

  public async get<T extends string | boolean | number>(key: string, defaultValue: T): Promise<T> {
    const prefs = await this.getPreferences();
    const value = await prefs.get(key, defaultValue);
    return value as T;
  }

  public async getString(key: string): Promise<string> {
    const prefs = await this.getPreferences();
    const value = await prefs.get(key, '');
    return String(value);
  }

  public async clear(key: string): Promise<void> {
    const prefs = await this.getPreferences();
    await prefs.put(key, '');
    await new Promise<void>((resolve, reject) => {
      prefs.flush(err => (err ? reject(err) : resolve()));
    });
  }

  public async setJSON(key: string, obj: any): Promise<void> {
    await this.set(key, JSON.stringify(obj));
  }

  public async getJSON<T>(key: string): Promise<T | null> {
    const s = await this.getString(key);
    if (!s) return null;
    try {
      return JSON.parse(s) as T;
    } catch {
      return null;
    }
  }
}
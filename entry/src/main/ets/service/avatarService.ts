import fs from '@ohos.file.fs';
import { openAgriDb, updateUserAvatar, getUserAvatar } from '../common/db';

// 头像存储目录
const AVATAR_DIR = 'avatars/';

export class AvatarService {
  private context: any;
  private store: any;

  constructor(context: any) {
    this.context = context;
    this.initStore();
  }

  // 初始化数据库
  async initStore() {
    this.store = await openAgriDb(this.context);
  }

  // 确保头像目录存在
  private async ensureDir() {
    const root = this.context.filesDir;
    const fullPath = root + '/' + AVATAR_DIR;
    if (!(await fs.access(fullPath))) {
      await fs.mkdir(fullPath);
    }
  }

  // 上传并保存头像
  async uploadAvatar(userId: number, tempFilePath: string): Promise<string> {
    try {
      await this.ensureDir();

      // 生成唯一文件名
      const ext = tempFilePath.split('.').pop() || 'png';
      const fileName = `avatar_${userId}_${Date.now()}.${ext}`;
      const targetPath = this.context.filesDir + '/' + AVATAR_DIR + fileName;

      // 复制文件
      await fs.copyFile(tempFilePath, targetPath);

      // 更新数据库
      await updateUserAvatar(this.store, userId, targetPath);
      return targetPath;
    } catch (e) {
      console.error('上传头像失败', e);
      return '';
    }
  }

  // 获取用户头像路径
  async getAvatar(userId: number): Promise<string> {
    return await getUserAvatar(this.store, userId);
  }
}
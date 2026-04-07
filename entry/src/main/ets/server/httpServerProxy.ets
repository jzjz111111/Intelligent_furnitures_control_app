// 文件路径：entry/src/main/ets/server/httpServerProxy.ts
import { Context } from '@kit.AbilityKit';
import { MyHttpServer as MyHttpServerInternal } from './HttpServer';

// 定义类型别名，让外部.ts文件可以识别
export type MyHttpServer = MyHttpServerInternal;

// 导出工厂函数，用于创建MyHttpServer实例
export function createHttpServer(context: Context): MyHttpServer {
  return new MyHttpServerInternal(context);
}
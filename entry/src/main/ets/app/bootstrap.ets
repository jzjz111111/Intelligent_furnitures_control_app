import { Context } from '@kit.AbilityKit';
import relationalStore from '@ohos.data.relationalStore';
import { openAgriDb, runInitSql } from '../common/db';
import { MyHttpServer } from '../server/HttpServer';
import { BusinessError } from '@kit.BasicServicesKit';
import { RoomDatabase, initAlarmService } from '../repository/roomDatabase';

// 全局单例：HTTP 后端服务器
let agriServer: MyHttpServer | null = null;

//应用初始化入口
export async function bootstrap(context: Context): Promise<void> {
  try {
    console.log("[启动] 应用初始化开始...");

    // 1. 初始化数据库
    //const store: relationalStore.RdbStore = await openAgriDb(context);
    //await runInitSql(store, context);
    //console.log("[数据库] 初始化完成");
    console.log("[数据库] 跳过初始化，直接行使HTTP请求");

    // 2. 初始化告警服务（你唯一需要的非HTTP功能）
    const roomDb = new RoomDatabase(context);
    initAlarmService(roomDb);
    console.log("[告警] 服务初始化完成");

    // 3. 启动后端 HTTP 服务器
    agriServer = new MyHttpServer(context);
    agriServer.startServer();
    console.log("[后端] HTTP 服务器启动成功");

    console.log("✅ 应用全部启动完成！");

  } catch (err) {
    const e = err as BusinessError;
    console.error("[启动失败] 错误信息：", e.message);
  }
}

// 应用退出时释放资源
export async function onAppExit(): Promise<void> {
  console.log("[退出] 应用正在销毁资源...");

  // 停止后端服务器
  if (agriServer) {
    agriServer.stopServer();
    agriServer = null;
  }

  console.log("✅ 已释放所有资源");
}
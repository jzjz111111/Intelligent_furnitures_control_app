import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { bootstrap } from '../app/bootstrap';
import { MyHttpServer } from '../server/HttpServer';
import { openAgriDb } from '../common/db';
import { exportInitSql } from '../tool/exportSql';


export default class EntryAbility extends UIAbility {
  private server: MyHttpServer | null = null;

  async onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(0, 'AgriServer', 'EntryAbility 启动成功');

    // 项目初始化
    await bootstrap(this.context);

    // 导出SQL
    try {
      const store = await openAgriDb(this.context);
      await exportInitSql(store, this.context);
      hilog.info(0, 'AgriServer', 'SQL导出成功');
    } catch (e) {
      hilog.error(0, 'AgriServer', 'SQL导出失败: ' + JSON.stringify(e));
    }

    // 启动HTTP服务
    this.server = new MyHttpServer(this.context);
    this.server.startServer();

    hilog.info(0, 'AgriServer', '智慧农业服务 + 云平台硬件连接 已启动');
  }

  onDestroy(): void {
    hilog.info(0, 'AgriServer', '服务销毁');
    if (this.server) {
      this.server.stopServer();
    }
  }
}
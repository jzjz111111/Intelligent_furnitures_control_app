import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { bootstrap } from '../app/bootstrap';
import { MyHttpServer } from '../server/HttpServer';
import { openAgriDb } from '../common/db';
import { exportInitSql } from '../tool/exportSql';


const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private server: MyHttpServer | null = null;

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    // ========== 第一段原有逻辑 ==========
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // ========== 第二段原有逻辑 ==========
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
    hilog.info(0, 'AgriServer', '准备启动后端服务...');
    this.server = new MyHttpServer(this.context);
    hilog.info(0, 'AgriServer', 'MyHttpServer 实例创建成功，即将调用 startServer()');
    await this.server.startServer();
    hilog.info(0, 'AgriServer', 'startServer() 调用完成');

    hilog.info(0, 'AgriServer', '智慧农业服务 + 云平台硬件连接 已启动');
  }

  onDestroy(): void {
    // ========== 第一段原有逻辑 ==========
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');

    // ========== 第二段原有逻辑 ==========
    hilog.info(0, 'AgriServer', '服务销毁');
   if (this.server) {
     this.server.stopServer();
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 第一段原有逻辑：窗口创建 + 加载页面
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Open', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // 第一段原有逻辑
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // 第一段原有逻辑
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // 第一段原有逻辑
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}

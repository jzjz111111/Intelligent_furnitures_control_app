import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { bootstrap, onAppExit } from '../app/bootstrap';
import { openAgriDb } from '../common/db';
import { exportInitSql } from '../tool/exportSql';


const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);

    hilog.info(0, 'AgriServer', 'EntryAbility 启动成功');

    // 项目初始化（包含数据库和HTTP服务器启动）
    await bootstrap(this.context);

    // 导出SQL
    try {
      const store = await openAgriDb(this.context);
      await exportInitSql(store, this.context);
      hilog.info(0, 'AgriServer', 'SQL导出成功');
    } catch (e) {
      hilog.error(0, 'AgriServer', 'SQL导出失败: ' + JSON.stringify(e));
    }

    hilog.info(0, 'AgriServer', '智慧农业服务已启动');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    hilog.info(0, 'AgriServer', '服务销毁');
    onAppExit();
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
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
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}

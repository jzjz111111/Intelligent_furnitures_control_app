import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { bootstrap } from '../app/bootstrap';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'entry', '%{public}s', 'onCreate');
    bootstrap(this.context);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'entry', '%{public}s', 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'entry', '%{public}s', 'onWindowStageCreate');
    windowStage.loadContent('pages/Open', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'entry', 'load fail %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'entry', 'load ok');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'entry', '%{public}s', 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'entry', '%{public}s', 'onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'entry', '%{public}s', 'onBackground');
  }
}
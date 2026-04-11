// pages/WarnPage.ets
// 智慧农业 - 警告页面 (修复版，使用 @Link 实现双向绑定)

import { ThemeColors } from '../utils/theme';
import { farmland, Device } from '../tool/classes';
import { Datamodel } from '../utils/common';
import { _IoTad } from './scan_devices';
import { curves, promptAction } from '@kit.ArkUI';

// 定义警告配置接口
interface WarnConfig {
  icon: string;
  title: string;
  desc: string;
  subDesc: string;
  unit: string;
}
@Entry
@Component
struct WarnPage {
  // 使用 @Link 实现双向绑定，修改会同步给父组件
  @Link warn_data: Datamodel;
  @Link is_warn: boolean;

  // 本地状态
  @State Warn_f_list: Device[] = [];
  @State have_temperature_control_device: boolean = false;
  @State have_fan: boolean = false;
  @State a_id: number = 0;
  @State Air_c: Device = new Device("", 0, 0);

  // 动画状态
  @State pageOpacity: number = 0;
  @State pageTranslate: number = 100;
  @State iconScale: number = 0.5;
  @State pulseOpacity: number = 0.6;
  @State dataNumber: number = 0;
  @State cardScale: number = 0.9;
  @State buttonOpacity: number = 0;
  @State buttonTranslate: number = 50;
  @State isProcessing: boolean = false;

  // 动画定时器
  private pulseTimer: number = -1;

  aboutToAppear(): void {
    if (!this.warn_data || !this.warn_data.type) {
      this.initMockData();
    }
    this.initDevices();
    this.startEntryAnimation();
    this.startPulseAnimation();
  }

  aboutToDisappear(): void {
    if (this.pulseTimer !== -1) {
      clearInterval(this.pulseTimer);
      this.pulseTimer = -1;
    }
  }

  private initMockData(): void {
    this.warn_data = new Datamodel();
    this.warn_data.type = 'temp';
    this.warn_data.data = 38.5;
    const mockDevice1: Device = new Device("温控设备-01", 0, 3001);
    const mockDevice2: Device = new Device("排风扇-01", 0, 4001);
    const mockFarmland: farmland = new farmland("模拟大棚01", [mockDevice1, mockDevice2], "");
    this.warn_data.arr = [mockFarmland];
  }

  private initDevices(): void {
    this.Warn_f_list = [];
    this.have_temperature_control_device = false;
    this.have_fan = false;
    if (!this.warn_data.arr) return;

    for (let r of this.warn_data.arr) {
      if (!r.device_s) continue;
      for (let f of r.device_s) {
        if (f.type_id < 4000 && f.type_id > 2999) {
          this.Warn_f_list.push(f);
          this.have_temperature_control_device = true;
          this.a_id = f.type_id;
          this.Air_c = f;
        }
        if (f.type_id > 3999 && f.type_id < 5000) {
          this.Warn_f_list.push(f);
          this.have_fan = true;
        }
      }
    }
  }

  private startEntryAnimation(): void {
    animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
      this.pageOpacity = 1;
      this.pageTranslate = 0;
    });

    setTimeout(() => {
      animateTo({
        duration: 600,
        curve: curves.springMotion(0.4, 0.8)
      }, () => {
        this.iconScale = 1;
      });
    }, 100);

    this.animateNumber();

    setTimeout(() => {
      animateTo({
        duration: 500,
        curve: curves.springMotion(0.5, 0.7)
      }, () => {
        this.cardScale = 1;
      });
    }, 200);

    setTimeout(() => {
      animateTo({
        duration: 400,
        curve: curves.springMotion(0.4, 0.6)
      }, () => {
        this.buttonOpacity = 1;
        this.buttonTranslate = 0;
      });
    }, 400);
  }

  private animateNumber(): void {
    const target = Number(this.warn_data.data) || 0;
    const steps = 30;
    const increment = target / steps;
    let current = 0;
    const timer = setInterval(() => {
      current += increment;
      if (current >= target) {
        current = target;
        clearInterval(timer);
      }
      this.dataNumber = current;
    }, 33);
  }

  private startPulseAnimation(): void {
    this.pulseTimer = setInterval(() => {
      animateTo({
        duration: 1000,
        curve: Curve.EaseInOut
      }, () => {
        this.pulseOpacity = this.pulseOpacity === 0.6 ? 0.2 : 0.6;
      });
    }, 1000);
  }

  private getWarnConfig(): WarnConfig {
    if (this.warn_data.type === 'temp') {
      return { icon: '🌡️', title: '温度异常警告', desc: '目前温度已超过作物生长安全标准', subDesc: '请及时处理，避免作物受损', unit: '°C' };
    } else if (this.warn_data.type === 'humi') {
      return { icon: '💧', title: '湿度异常警告', desc: '目前湿度已超过作物生长安全标准，易引发病害', subDesc: '请及时干预保持环境干燥', unit: '%' };
    } else if (this.warn_data.type === 'co2') {
      return { icon: '🧪', title: 'CO₂异常警告', desc: '目前CO₂浓度已超过作物安全标准，影响光合作用', subDesc: '请及时通风换气，保障空气流通', unit: ' ppm' };
    } else {
      return { icon: '⚠️', title: '环境异常警告', desc: '检测到环境参数异常', subDesc: '请检查设备状态', unit: '' };
    }
  }

  private async handleAction(): Promise<void> {
    if (this.isProcessing) return;
    this.isProcessing = true;
    promptAction.showToast({ message: '正在执行...', duration: 1000 });

    try {
      if (this.warn_data.type === 'temp' || this.warn_data.type === 'humi') {
        if (this.have_temperature_control_device) {
          const mode = this.warn_data.type === 'temp' ? 'zl' : 'cs';
          await _IoTad.set_temperature_control_device_by_id(25, "on", mode);
        }
      } else if (this.warn_data.type === 'co2') {
        if (this.have_fan) {
          await _IoTad.set_fan_by_id("on");
        }
      }
      promptAction.showToast({ message: '处理成功', duration: 1500 });
      this.closePage();
    } catch (err) {
      console.error('处理失败', err);
      promptAction.showToast({ message: '处理失败，请重试', duration: 2000 });
      this.isProcessing = false;
    }
  }

  // 关键修复：动画完成后修改 @Link 状态，同步给父组件
  private closePage(): void {
    animateTo({ duration: 300, curve: Curve.EaseIn }, () => {
      this.pageOpacity = 0;
      this.pageTranslate = 100;
    });

    setTimeout(() => {
      console.info('WarnPage: 关闭警告页面');
      this.is_warn = false; // 双向绑定，会自动修改父组件的 is_warn
    }, 300);
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ThemeColors.bgPrimary);

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(230, 57, 70, 0.05)');

      Column({ space: 0 }) {
        Row().height(44).width('100%');

        Scroll() {
          Column({ space: 20 }) {
            this.WarningIconSection();
            this.WarningInfoCard();
            this.ActionButtonsSection();
            Row().height(40).width('100%');
          }
          .width('100%')
          .padding(20);
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off);
      }
      .width('100%')
      .height('100%')
      .opacity(this.pageOpacity)
      .translate({ y: this.pageTranslate })
      .animation({ duration: 400, curve: Curve.EaseOut });
    }
    .width('100%')
    .height('100%');
  }

  @Builder
  WarningIconSection() {
    Column({ space: 12 }) {
      Stack() {
        Circle()
          .width(120)
          .height(120)
          .fill(`rgba(230, 57, 70, ${this.pulseOpacity})`)
          .scale({ x: 1.2, y: 1.2 })
          .animation({ duration: 1000, curve: Curve.EaseInOut });

        Circle()
          .width(100)
          .height(100)
          .fill('rgba(230, 57, 70, 0.2)')
          .scale({ x: 1.1, y: 1.1 })
          .animation({ duration: 1000, curve: Curve.EaseInOut });

        Stack() {
          Text(this.getWarnConfig().icon)
            .fontSize(56)
            .scale({ x: this.iconScale, y: this.iconScale })
            .animation({ duration: 600, curve: curves.springMotion(0.4, 0.8) });
        }
        .width(80)
        .height(80)
        .backgroundColor(Color.White)
        .borderRadius(40)
        .shadow({ color: 'rgba(230, 57, 70, 0.4)', radius: 20, offsetY: 8 });
      }
      .width(120)
      .height(120);

      Text("WARNING")
        .fontSize(12)
        .fontColor(ThemeColors.danger)
        .fontWeight(FontWeight.Bold)
        .letterSpacing(2)
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('rgba(230, 57, 70, 0.1)')
        .borderRadius(12);
    }
    .width('100%')
    .margin({ top: 20 });
  }

  @Builder
  WarningInfoCard() {
    Column({ space: 16 }) {
      Row({ space: 4 }) {
        Text(this.dataNumber.toFixed(this.warn_data.type === 'co2' ? 0 : 1))
          .fontSize(72)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.danger)
          .fontFamily('HarmonyOS Sans Number');

        Text(this.getWarnConfig().unit)
          .fontSize(24)
          .fontColor(ThemeColors.danger)
          .margin({ top: 20 });
      }
      .width('100%')
      .height(100)
      .justifyContent(FlexAlign.Center);

      Divider()
        .width('60%')
        .height(1)
        .color('rgba(230, 57, 70, 0.3)');

      Text(this.getWarnConfig().title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.textPrimary);

      Column({ space: 6 }) {
        Text(this.getWarnConfig().desc)
          .fontSize(14)
          .fontColor(ThemeColors.textSecondary)
          .textAlign(TextAlign.Center);

        Text(this.getWarnConfig().subDesc)
          .fontSize(13)
          .fontColor(ThemeColors.textTertiary)
          .textAlign(TextAlign.Center);
      }
      .width('100%')
      .padding({ left: 20, right: 20 });
    }
    .width('100%')
    .padding(24)
    .backgroundColor('rgba(255, 255, 255, 0.95)')
    .borderRadius(24)
    .border({ width: 1, color: 'rgba(230, 57, 70, 0.2)' })
    .shadow({ color: 'rgba(230, 57, 70, 0.15)', radius: 20, offsetY: 8 })
    .scale({ x: this.cardScale, y: this.cardScale })
    .animation({ duration: 500, curve: curves.springMotion(0.5, 0.7) });
  }

  @Builder
  ActionButtonsSection() {
    Column({ space: 12 }) {
      Button() {
        Row({ space: 8 }) {
          if (this.isProcessing) {
            LoadingProgress()
              .width(20)
              .height(20)
              .color(Color.White);
          }
          Text(this.isProcessing ? '处理中...' :
            (this.warn_data.type === 'temp' ? (this.have_temperature_control_device ? '🌀 启动温控设备' : '🪟 开窗通风') :
              this.warn_data.type === 'humi' ? (this.have_temperature_control_device ? '🌀 启动温控设备除湿' : '🪟 开窗通风') :
                this.have_fan ? '🌀 启动排风扇' : '🪟 开窗通风'))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White);
        }
      }
      .width('85%')
      .height(54)
      .backgroundColor(this.isProcessing ? ThemeColors.textTertiary : ThemeColors.danger)
      .borderRadius(27)
      .shadow({
        color: this.isProcessing ? 'transparent' : 'rgba(230, 57, 70, 0.4)',
        radius: 12,
        offsetY: 6
      })
      .scale({ x: this.isProcessing ? 0.98 : 1, y: this.isProcessing ? 0.98 : 1 })
      .animation({ duration: 200 })
      .onClick(() => this.handleAction());

      Button('稍后处理')
        .width('85%')
        .height(48)
        .backgroundColor(Color.White)
        .borderRadius(24)
        .border({ width: 1.5, color: ThemeColors.textTertiary })
        .fontColor(ThemeColors.textSecondary)
        .fontSize(15)
        .onClick(() => this.closePage());

      Row({ space: 6 }) {
        Text('🛡️').fontSize(12);
        Text('系统将自动记录此次事件')
          .fontSize(11)
          .fontColor(ThemeColors.textTertiary);
      }
      .margin({ top: 8 });
    }
    .width('100%')
    .opacity(this.buttonOpacity)
    .translate({ y: this.buttonTranslate })
    .animation({ duration: 400, curve: curves.springMotion(0.4, 0.6) });
  }
}

export { WarnPage };
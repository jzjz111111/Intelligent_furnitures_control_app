// src/main/ets/pages/index.ets
import router from '@ohos.router';
import { homepage } from './homepage';
import { FarmScenePage } from './scene_page';
import { userpage } from './userpage';
import { WarnPage } from './WarnPage';
import { ThemeColors } from '../utils/theme';
import { Datamodel } from '../utils/common';
import { _Tcp } from '../tool/TCP';
import { FarmlandDatabase } from '../data/RdbStorage';
import { farmland, Device } from '../tool/classes';

// 全局导出实例（保持原有全局调用能力）
export let tcp: _Tcp = new _Tcp(8888, '192.168.191.19');
export let Farmland_db: FarmlandDatabase = new FarmlandDatabase(globalThis.getContext());

@Component
@Entry
struct Index {
  @State arr_farmland: farmland[] = [];
  @State selectnumber: number = 0;
  @State is_show_humidity: boolean = false;
  @State is_warn: boolean = false;
  @State warn_data: Datamodel = new Datamodel();
  @State _height_AI: string = "0%";
  @State is_show_AI: boolean = false;
  // 其他状态（与原代码完全一致）
  @State is_show_lights: boolean = false;
  @State is_show_temperature_control_device: boolean = false;
  @State is_show_robot: boolean = false;
  @State is_show_waterValve: boolean = false;
  @State is_show_dan: boolean = false;
  @State edit_f: Device = new Device("", 0, 0);

  // 启动时自动弹出警告（模拟数据）
  aboutToAppear(): void {
    // 延迟一点显示，确保页面渲染完成
    setTimeout(() => {
      this.showMockWarning();
    }, 500);
  }

  // 显示模拟警告数据
  private showMockWarning(): void {
    // 创建模拟警告数据（可切换 'temp' | 'humi' | 'co2' 测试不同场景）
    const mockWarnData: Datamodel = new Datamodel();
    mockWarnData.type = 'temp'; // 可切换: 'temp' 温度 | 'humi' 湿度 | 'co2' 二氧化碳
    mockWarnData.data = 38.5;   // 异常数值

    // 创建设备实例（name, switch, type_id）
    // type_id: 3001-3999 是温控设备，4001-4999 是风扇
    const mockDevice1: Device = new Device("温控设备-01", 0, 3001);
    const mockDevice2: Device = new Device("排风扇-01", 0, 4001);

    // 创建农田实例
    const mockFarmland: farmland = new farmland("模拟大棚01", [mockDevice1, mockDevice2], "");

    mockWarnData.arr = [mockFarmland];

    // 设置警告状态，触发 WarnPage 显示
    this.warn_data = mockWarnData;
    this.is_warn = true;

    console.info('启动模拟警告:', mockWarnData.type, mockWarnData.data);
  }

  @Builder
  MyBuilder_user(title: string, num: number) {
    Column() {
      Row().width("100%").height(12);
      Image($r("app.media.user"))
        .height(num == this.selectnumber ? 24 : 20)
        .width(num == this.selectnumber ? 24 : 20)
        .fillColor(num == this.selectnumber ? ThemeColors.primary : ThemeColors.textTertiary);
      Text(title)
        .fontSize(12)
        .fontColor(num == this.selectnumber ? ThemeColors.primary : ThemeColors.textTertiary)
        .margin({ top: 4 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(num == this.selectnumber ? ThemeColors.bgCard : Color.White)
    .padding({ bottom: 8 });
  }

  @Builder
  MyBuilder_add(title: string, num: number) {
    Column() {
      Row().width("100%").height(12);
      Image($r("app.media.add"))
        .height(num == this.selectnumber ? 24 : 20)
        .width(num == this.selectnumber ? 24 : 20)
        .fillColor(num == this.selectnumber ? ThemeColors.primary : ThemeColors.textTertiary);
      Text("智能场景")
        .fontSize(12)
        .fontColor(num == this.selectnumber ? ThemeColors.primary : ThemeColors.textTertiary)
        .margin({ top: 4 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(num == this.selectnumber ? ThemeColors.bgCard : Color.White)
    .padding({ bottom: 8 });
  }

  @Builder
  MyBuilder_home(title: string, num: number) {
    Column() {
      Row().width("100%").height(12);
      Image($r("app.media.ic_water"))
        .height(num == this.selectnumber ? 24 : 20)
        .width(num == this.selectnumber ? 24 : 20)
        .fillColor(num == this.selectnumber ? ThemeColors.primary : ThemeColors.textTertiary);
      Text("农场总览")
        .fontSize(12)
        .fontColor(num == this.selectnumber ? ThemeColors.primary : ThemeColors.textTertiary)
        .margin({ top: 4 });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(num == this.selectnumber ? ThemeColors.bgCard : Color.White)
    .padding({ bottom: 8 });
  }

  build() {
    Stack() {
      Column() {
        Tabs({ barPosition: BarPosition.End }) {
          TabContent() {
            homepage({
              is_warn: this.is_warn,
              warn_data: this.warn_data,
              arr_farmland: this.arr_farmland
            });
          }
          .tabBar(this.MyBuilder_home("农场总览", 0))
          TabContent() {
            FarmScenePage({ arr_farmland: this.arr_farmland });
          }
          .tabBar(this.MyBuilder_add("智能场景", 1))
          TabContent() {
            userpage();
          }
          .tabBar(this.MyBuilder_user("个人中心", 2))
        }
        .width('100%')
        .height('100%')
        .onChange((index: number) => {
          this.selectnumber = index;
        })
        .animationDuration(10)
        .barHeight(60)
        .barBackgroundColor(Color.White)
        .barMode(BarMode.Fixed)
      }
      .height('100%')
      .width('100%')
      .backgroundColor(ThemeColors.bgPrimary);

      // AI 悬浮按钮
      Button("AI")
        .backgroundColor(ThemeColors.primary)
        .fontColor(Color.White)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .shadow({ radius: 12, offsetX: 0, offsetY: 6, color: ThemeColors.techGlow })
        .onClick(() => {
          router.pushUrl({ url: 'pages/deepseek_page' }).catch((err: Error) => {
            console.error('跳转 AI 页面失败:', err.message);
            AlertDialog.show({ message: '页面跳转失败：' + err.message });
          });
        })
        .position({ x: "82%", y: "78%" })
        .width(64)
        .height(64)
        .borderRadius(32);

      // 警告弹窗（最上层）- 原有功能保持不变
      if (this.is_warn) {
        WarnPage({ warn_data: $warn_data, is_warn: $is_warn });
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor(ThemeColors.bgPrimary);
  }
}
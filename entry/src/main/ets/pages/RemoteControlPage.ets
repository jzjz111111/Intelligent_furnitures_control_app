// pages/RemoteControlPage.ets
import { ThemeColors } from '../utils/theme';
import { displayFarmland } from '../tool/component';
import { farmland, Device } from '../tool/classes';
import { curves } from '@kit.ArkUI';
import { FarmlandDatabase } from "../data/RdbStorage";
import common from '@ohos.app.ability.common';
import http from '@ohos.net.http';
//import relationalStore from '@ohos.data.relationalStore';

interface DeviceDeleteResponse {
  code: number;
  msg: string;
  data?: Object;
}

interface PhotoData{
  path?:string;
}
interface LatestPhotoResponse {
  code: number;
  data:PhotoData ;

}

@Entry
@Component
export struct RemoteControlPage {
  // ========== 原有功能：链接和属性 ==========
  @Link showPage: boolean;
  @Link farm: farmland | null;
  @Prop temp: string = '';
  @Prop humi: string = '';
  @Prop co2: string = '';
  @Link currentFarm: farmland | null;
  @State showMyList: boolean = false;
  @State is_sleep: boolean = false;
  @State latestPhotoPath: string = "";
  // ========== UI动画状态 ==========
  @State headerScale: number = 0.95;
  @State headerOpacity: number = 0;
  @State cardsOffsetY: number = 30;
  @State cardsOpacity: number = 0;
  @State deviceListOffsetY: number = 40;
  @State deviceListOpacity: number = 0;
  @State buttonScale: number = 0.9;
  @State buttonOpacity: number = 0;

  // ========== 删除功能状态 ==========
  @State showDeleteDialog: boolean = false;
  @State deleteIndex: number = -1;
  @State deleteDeviceName: string = '';
  @State pressedDeleteIndex: number = -1;




  private db: FarmlandDatabase | null = null;

  aboutToAppear() {
    this.loadLatestPhoto();
    const context = getContext(this) as common.UIAbilityContext;
    this.db = new FarmlandDatabase(context);

    // ========== 入场动画序列 ==========
    animateTo({ duration: 400, curve: curves.springMotion() }, () => {
      this.headerScale = 1;
      this.headerOpacity = 1;
    });

    animateTo({ duration: 500, delay: 100, curve: Curve.EaseOut }, () => {
      this.cardsOffsetY = 0;
      this.cardsOpacity = 1;
    });

    animateTo({ duration: 500, delay: 200, curve: Curve.EaseOut }, () => {
      this.buttonScale = 1;
      this.buttonOpacity = 1;
    });

    animateTo({ duration: 600, delay: 300, curve: Curve.EaseOut }, () => {
      this.deviceListOffsetY = 0;
      this.deviceListOpacity = 1;
    });
  }

  private async loadLatestPhoto() {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        'http://127.0.0.1:8080/api/photo/latest',
        { method: http.RequestMethod.GET }
      );

      const result: LatestPhotoResponse = JSON.parse(response.result.toString()) as LatestPhotoResponse;

      if (result.code === 200 && result.data.path) {
        this.latestPhotoPath = result.data.path;
      }
      httpRequest.destroy();
    } catch (err) {
      console.error("加载最新照片失败", err);
    }
  }

  // 根据农田ID和设备名获取设备数据库ID
  /*private async getDeviceId(farmlandId: number, deviceName: string): Promise<number> {
    try {
      const predicates = new relationalStore.RdbPredicates('Device');
      predicates.equalTo('zone_id', farmlandId).equalTo('name', deviceName);
      const resultSet = await this.db!.getRdbStore().query(predicates, ['id']);

      let deviceId = -1;
      if (resultSet.goToFirstRow()) {
        deviceId = resultSet.getLong(0);
      }
      resultSet.close();
      return deviceId;
    } catch (err) {
      console.error("获取设备ID失败:", err);
      return -1;
    }
  }*/

  //删除逻辑
  private async deleteDevice(index: number) {
    if (!this.farm || !this.farm.device_s || !this.db) return;

    try {
      const delDevice = this.farm.device_s[index];
      let r_id = await this.db.getFarmlandsIdByName(this.farm.name);

      // 1. 先调用后端接口删除设备
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        'http://127.0.0.1:8080/api/device/delete',
        {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: JSON.stringify({
            farmlandId: r_id,
            deviceName: delDevice.name
          })
        }
      );

      // 2. 检查后端响应
      if (response.responseCode === 200) {
        const result: DeviceDeleteResponse = JSON.parse(response.result as string) as DeviceDeleteResponse;

        if (result.code === 200) {
          // 后端删除成功,再删除本地数据库
          await this.db.deleteDeviceByFarmlandIdAndName(r_id, delDevice.name);

          // 更新本地列表
          this.farm.device_s = this.farm.device_s.filter(
            (element) => element.name !== delDevice.name
          );

          if (this.currentFarm) {
            this.currentFarm.device_s = [...this.farm.device_s];
          }

          console.log("✅ 设备删除成功");
        } else {
          console.error("后端删除失败:", result.msg);
          AlertDialog.show({ message: result.msg || "删除失败" });
        }
      } else {
        console.error("网络请求失败");
        AlertDialog.show({ message: "网络错误,请重试" });
      }

      httpRequest.destroy();
    } catch (err) {
      console.error("删除设备异常:", err);
      AlertDialog.show({ message: "删除失败,请重试" });
    }
  }

  private showDeleteConfirm(index: number, deviceName: string) {
    this.deleteIndex = index;
    this.deleteDeviceName = deviceName;
    this.showDeleteDialog = true;
  }

  // ========== 样式定义 ==========
  @Styles pressedStyle() {
    .backgroundColor(ThemeColors.primaryDark)
  }

  @Styles normalStyle() {
    .backgroundColor(ThemeColors.primary)
  }

  build() {
    Stack() {
      // ✅ 整个页面套 Scroll，实现全屏滚动（关键修改）
      Scroll() {
        Column() {
          // ========== 顶部导航栏 - 玻璃拟态 ==========
          this.GlassNavigationBar()

          // ========== 农田信息卡片 - 3D悬浮效果 ==========
          this.FarmInfoCard()

          // ========== 环境数据卡片 - 动态展示 ==========
          this.EnvironmentDataCards()

          // ========== 添加设备按钮 - 脉冲光效 ==========
          this.AddDeviceButton()

          // ========== 设备列表 - 智能控制 ==========
          this.DeviceControlList()

          // 底部留白，防止最后一条被遮挡
          Column().height(30)
        }
        .width("100%")
        .height("100%")
      }
      .backgroundColor(ThemeColors.bgPrimary)

      // ========== 删除确认对话框 ==========
      if (this.showDeleteDialog) {
        this.DeleteDialog()
      }

      // ========== 原有功能：模态框 ==========
      if (this.showMyList && this.currentFarm) {
        displayFarmland({
          currentFarm: this.currentFarm,
          is_sleep: $is_sleep,
          showList: $showMyList
        })
      }
    }
  }

  // ========== 删除确认对话框 ==========
  @Builder
  DeleteDialog() {
    Column() {
      Column({ space: 16 }) {
        Text("确认删除")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.textPrimary)

        Text(`确定要删除设备 "${this.deleteDeviceName}" 吗？`)
          .fontSize(14)
          .fontColor(ThemeColors.textSecondary)
          .textAlign(TextAlign.Center)

        Row({ space: 16 }) {
          Button("取消")
            .width(100)
            .height(40)
            .backgroundColor(ThemeColors.bgCard)
            .fontColor(ThemeColors.textPrimary)
            .border({ width: 1, color: ThemeColors.borderLight })
            .onClick(() => {
              this.showDeleteDialog = false;
            })

          Button("删除")
            .width(100)
            .height(40)
            .backgroundColor(ThemeColors.danger)
            .fontColor(Color.White)
            .onClick(() => {
              this.deleteDevice(this.deleteIndex);
              this.showDeleteDialog = false;
            })
        }
      }
      .width(280)
      .padding(24)
      .backgroundColor(ThemeColors.bgCard)
      .borderRadius(16)
      .shadow({
        color: 'rgba(0,0,0,0.2)',
        radius: 20,
        offsetX: 0,
        offsetY: 4
      })
    }
    .width("100%")
    .height("100%")
    .backgroundColor('rgba(0,0,0,0.5)')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.showDeleteDialog = false;
    })
  }

  // ========== 玻璃拟态导航栏 ==========
  @Builder
  GlassNavigationBar() {
    Row() {
      Row({ space: 4 }) {
        Text("‹")
          .fontSize(28)
          .fontColor(ThemeColors.primary)
          .fontWeight(FontWeight.Bold)

        Text("返回")
          .fontSize(16)
          .fontColor(ThemeColors.primary)
          .fontWeight(FontWeight.Medium)
      }
      .onClick(() => {
        animateTo({ duration: 200, curve: Curve.EaseIn }, () => {
          this.showPage = false;
        });
      })

      Blank()

      Text("智慧农业远程控制")
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.textPrimary)

      Blank()
      Row().width(60)
    }
    .width("100%")
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(ThemeColors.bgGlass)
    .backdropBlur(20)
    .border({
      width: { bottom: 1 },
      color: ThemeColors.borderLight
    })
  }

  // ========== 农田信息卡片 ==========
  @Builder
  FarmInfoCard() {
    Column() {
      if (this.latestPhotoPath) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(255, 255, 255, 0.85)')  // 半透明白色遮罩
          .borderRadius(16)
          .zIndex(-1);  // 放在内容下面
      }
      Row({ space: 16 }) {
        Stack() {
          if (this.farm?.avatar) {
            Image('file://' +this.farm.avatar)
              .width(98)
              .height(90)
              .borderRadius(16)
              .objectFit(ImageFit.Cover)
              .shadow({
                color: ThemeColors.techGlow,
                radius: 20,
                offsetX: 0,
                offsetY: 8
              })
          } else {
            Column() {
              Text("🌱")
                .fontSize(48)
            }
            .width(98)
            .height(90)
            .backgroundColor(ThemeColors.primaryLight)
            .borderRadius(16)
            .border({
              width: 2,
              color: ThemeColors.accent,
              style: BorderStyle.Solid
            })
            .shadow({
              color: ThemeColors.techGlow,
              radius: 16,
              offsetX: 0,
              offsetY: 6
            })
          }

          Column()
            .width(12)
            .height(12)
            .backgroundColor(ThemeColors.success)
            .borderRadius(6)
            .border({ width: 2, color: Color.White })
            .shadow({ color: ThemeColors.success, radius: 8 })
            .position({ x: 88, y: -4 })
        }

        Column({ space: 6 }) {
          Text(this.farm?.name || "智慧农田 A-01")
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: 8 }) {
            Text("在线")
              .fontSize(10)
              .fontColor(Color.White)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .backgroundColor(ThemeColors.success)
              .borderRadius(10)

            Text("一号园区 · 8亩")
              .fontSize(13)
              .fontColor(ThemeColors.textSecondary)
          }

          Text("品种：智慧温室大棚")
            .fontSize(13)
            .fontColor(ThemeColors.textTertiary)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width("92%")
      .padding(20)
      .backgroundColor(ThemeColors.bgCard)
      .borderRadius(20)
      .border({
        width: 1,
        color: ThemeColors.borderLight
      })
      .shadow({
        color: ThemeColors.shadowDark,
        radius: 12,
        offsetX: 0,
        offsetY: 4
      })
      .scale({ x: this.headerScale, y: this.headerScale })
      .opacity(this.headerOpacity)
      .animation({ duration: 400, curve: curves.springMotion() })
      .margin({ top: 100, bottom: 5 })
      .shadow(10)
      .borderWidth(1)
      .borderColor('#f0f0f0')
    }
    .height(240)
    .width("100%")
    .padding(15)
    .backgroundImage(this.latestPhotoPath ? this.latestPhotoPath : '')
    .backgroundImageSize(ImageSize.Cover)
    .borderRadius(16)
    .margin({ top: 5, bottom: 5 })
  }

  // ========== 环境数据卡片 ==========
  @Builder
  EnvironmentDataCards() {
    Row({ space: 10 }) {
      this.DataCard("温度", this.temp + "℃", ThemeColors.primary, 0)
      this.DataCard("湿度", this.humi + "%", ThemeColors.techBlue, 1)
      this.DataCard("CO₂", this.co2 + "ppm", ThemeColors.secondary, 2)
    }
    .width("92%")
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ top: 16 })
    .translate({ y: this.cardsOffsetY })
    .opacity(this.cardsOpacity)
    .animation({ duration: 500, curve: Curve.EaseOut })
  }

  @Builder
  DataCard(title: string, value: string, color: string, index: number) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(14)
        .fontColor(ThemeColors.textSecondary);
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(color);
    }
    .width('31%')
    .height(85)
    .backgroundColor(ThemeColors.bgCard)
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .shadow({
      color: 'rgba(0,0,0,0.05)',
      radius: 6,
      offsetX: 0,
      offsetY: 2
    });
  }

  // ========== 添加设备按钮 ==========
  @Builder
  AddDeviceButton() {
    Button("+ 添加设备")
      .width("92%")
      .height(48)
      .fontSize(15)
      .backgroundColor(ThemeColors.primary)
      .fontColor(Color.White)
      .borderRadius(24)
      .margin({ top: 16, bottom: 16 })
      .shadow({
        color: ThemeColors.techGlow,
        radius: 8,
        offsetX: 0,
        offsetY: 4
      })
      .scale({ x: this.buttonScale, y: this.buttonScale })
      .opacity(this.buttonOpacity)
      .animation({ duration: 500, curve: Curve.EaseOut })
      .onClick(() => {
        this.currentFarm = this.farm;
        this.showMyList = true;
      })
  }

  // ========== 设备控制列表 ==========
  @Builder
  DeviceControlList() {
    Column({ space: 12 }) {
      if (this.farm?.device_s.length === 0) {
        Text("暂无设备，点击上方添加设备")
          .fontSize(16)
          .fontColor(ThemeColors.textSecondary)
          .margin({ top: 20 });
      }

      ForEach(this.farm?.device_s || [], (item: Device, index: number) => {
        this.ControlItem(item, index)
      }, (item: Device) => item.name )
    }
    .width("92%")
    .translate({ y: this.deviceListOffsetY })
    .opacity(this.deviceListOpacity)
    .animation({ duration: 600, curve: Curve.EaseOut })
  }

  // ========== 设备控制项 ==========
  @Builder
  ControlItem(item: Device, index: number) {
    Row() {
      Row({ space: 12 }) {
        Text(this.getDeviceIcon(item.name))
          .fontSize(24);

        Text(item.name)
          .fontSize(16)
          .fontColor(ThemeColors.textPrimary)
          .fontWeight(FontWeight.Medium);
      }

      Blank()

      Stack() {
        Text("🗑️")
          .fontSize(18)
          .opacity(this.pressedDeleteIndex === index ? 0.6 : 1)
          .scale({ x: this.pressedDeleteIndex === index ? 0.9 : 1, y: this.pressedDeleteIndex === index ? 0.9 : 1 })
          .animation({ duration: 100 })
      }
      .width(36)
      .height(36)
      .backgroundColor(this.pressedDeleteIndex === index ? ThemeColors.danger : 'rgba(230, 57, 70, 0.1)')
      .borderRadius(18)
      .margin({ right: 12 })
      .onClick(() => {
        this.showDeleteConfirm(index, item.name);
      })
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          this.pressedDeleteIndex = index;
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.pressedDeleteIndex = -1;
        }
      })

      Toggle({ type: ToggleType.Switch, isOn: item.switch === 1 })
        .selectedColor(ThemeColors.primary)
        .switchPointColor(Color.White)
        .onChange((isOn: boolean) => {
          item.switch = isOn ? 1 : 0;
          console.log(`设备 ${item.name} 状态切换为: ${isOn ? '开启' : '关闭'}`);
        })
    }
    .width("100%")
    .padding(16)
    .backgroundColor(ThemeColors.bgCard)
    .borderRadius(12)
    .shadow({
      color: 'rgba(0,0,0,0.05)',
      radius: 4,
      offsetX: 0,
      offsetY: 2
    })
  }

  private getDeviceIcon(name: string): string {
    if (name.includes('灯') || name.includes('light')) return '💡';
    if (name.includes('风扇') || name.includes('fan')) return '🔘';
    if (name.includes('水') || name.includes('water')) return '💧';
    if (name.includes('温') || name.includes('temp')) return '🌡️';
    if (name.includes('门') || name.includes('door')) return '🚪';
    return '🔧';
  }
}

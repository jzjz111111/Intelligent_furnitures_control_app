import { Device, farmland } from "../tool/classes";
import { ControlTemp } from "./TotalControl";
import { _IoTad } from "./scan_devices";
import router from '@ohos.router';

interface EnvironmentItemParams {
  icon: Resource;
  value: string;
  title: string;
  color?: string;
  onAction?: () => void;
}
type DescMap = Record<string, string>;
interface ControlItemParams {
  icon: Resource;
  title: string;
  status: string;
  buttonText: string;
  onAction: () => void;
}

@Entry
@Component
export struct FarmScenePage {
  @Link arr_farmland: farmland[];
  @State sceneList: string[] = ["育苗保温模式", "灌溉节水模式", "通风遮阳模式"];
  @State isSeedlingSceneShow: boolean = false;
  @State isIrrigationSceneShow: boolean = false;
  @State currentScene: string = '';
  @State panelHeight: string = "0%";

  build(): void {
    Stack() {
      // 背景
      Image($r('app.media.farm_bg'))
        .objectFit(ImageFit.Cover)
        .width('100%')
        .height('100%');

      // 产品化卡片列表
      Scroll() {
        Column({ space: 14 })
        {
          ForEach(this.sceneList, (sceneName: string, index: number) => {
            Column({ space: 6 }) {
              Image(this.getSystemIcon(index))
                .width(48)
                .height(48)
                .margin({ bottom: 8 });

              Text(sceneName)
                .fontSize(18)
                .fontColor('#2C3E50')
                .fontWeight(FontWeight.Medium);

              Text(this.getSceneDescription(sceneName))
                .fontSize(12)
                .fontColor('#7F8C8D')
                .margin({ top: 4 });
            }
            .padding(20)
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 8, color: '#00000010', offsetX: 2, offsetY: 4 })
            .width('100%')
            .onClick(() => this.handleSceneClick(index));
          }, (sceneName: string, index: number) => index.toString());
        }
        .width('90%')
        .margin({ top: 30, bottom: 20 })
      }
      .edgeEffect(EdgeEffect.Spring);

      // 弹窗逻辑
      if (this.isSeedlingSceneShow || this.isIrrigationSceneShow) {
        Column() {
          Blank()
            .onClick(() => this.closeScenePanels())
            .backgroundColor('#00000030')
            .layoutWeight(1);

          if (this.isSeedlingSceneShow) {
            SeedlingScene({
              scene: this.currentScene,
              arr_farmland: this.arr_farmland,
              is_show: this.isSeedlingSceneShow,
              _height: this.panelHeight
            })
              .transition(TransitionEffect.translate({ y: 1000 }).animation({ duration: 300 }));
          }

          if (this.isIrrigationSceneShow) {
            IrrigationScene({
              arr_farmland: this.arr_farmland,
              is_show: this.isIrrigationSceneShow,
              _height: this.panelHeight
            })
              .transition(TransitionEffect.translate({ y: 1000 }).animation({ duration: 300 }));
          }
        }
        .width('100%')
        .height('100%');
      }
    }
    .height('100%');
  }
  private getSystemIcon(index: number): Resource {
    switch (index) {
      case 0:  return $r('app.media._robot');
      case 1:  return $r('app.media._robot');
      case 2:  return $r('app.media._robot');
      default: return $r('app.media._robot');
    }
  }
  private handleSceneClick(index: number): void {
    this.currentScene = this.sceneList[index];
    animateTo({ duration: 300 }, () => {
      this.panelHeight = "100%";
      if (index === 0) this.isSeedlingSceneShow = true;
      if (index === 1) this.isIrrigationSceneShow = true;
    });
  }

  private closeScenePanels(): void {
    animateTo({ duration: 300 }, () => {
      this.panelHeight = "0%";
      this.isSeedlingSceneShow = false;
      this.isIrrigationSceneShow = false;
    });
  }

  private getSceneDescription(scene: string): string {
    const descriptionMap: DescMap = {
      "育苗保温模式": "开启补光与恒温，保持幼苗适宜生长环境",
      "灌溉节水模式": "智能水肥控制，根据土壤湿度自动节水灌溉",
      "通风遮阳模式": "自动调节遮阳与通风，降低棚内温湿度"
    };
    return descriptionMap[scene] || '';
  }
}
@Component
struct SeedlingScene {
  @Link scene: string;
  @Link arr_farmland: farmland[];
  @Link is_show: boolean;
  @Link _height: string;
  @State deviceList: Device[] = [];
  @State isEnabled: boolean = false;

  aboutToAppear(): void {
    this.deviceList = this.arr_farmland
      .flatMap(r => r.device_s)
      .filter(f => f.type_id > 999 && f.type_id < 3000);
  }

  build(): void {
    Column() {
      Row() {
        Image($r("app.media.ic_back"))
          .fillColor('#ff111141')
          .width(24)
          .height(24)
          .onClick(() => this.closePanel());

        Text(this.scene)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);

        Text(this.isEnabled ? "已启用" : "已关闭")
          .fontColor(this.isEnabled ? '#27AE60' : '#E74C3C')

        Toggle({ type: ToggleType.Switch, isOn:this.isEnabled})
          .onClick(()=>{
            this.isEnabled = !this.isEnabled
            if(this.isEnabled){
              _IoTad.set_LED_brightness_by_id(1,1001)
              _IoTad.set_waterValve_by_id("off")
              let new_list:Device[] = []
              for (let i of this.deviceList){
                i.switch = 0
                new_list.push(i)
              }
              this.deviceList = new_list
            }else{
              _IoTad.set_LED_brightness_by_id(5000,1001)
              _IoTad.set_waterValve_by_id("on")
            }
          })
      }
      .padding(16)
      .backgroundColor('#ffaaabff')
      .backdropBlur(10);

      Grid() {
        ForEach(this.deviceList, (item: Device,value) => {
          GridItem() {
            Column() {
              Stack() {
                Circle()
                  .width(60)
                  .height(60)
                  .fill(item.switch ? '#3498DB30' : '#BDC3C730');

                Image(this.getDeviceIcon(item.type_id))
                  .width(30)
                  .height(30);
              }

              Text(item.name)
                .fontSize(14)
                .margin({ top: 8 })
                .textAlign(TextAlign.Center);

              Text(item.switch ? "已开启" : "已关闭")
                .fontSize(12)
                .fontColor(item.switch ? '#27AE60' : '#95A5A5');
            }
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .shadow({ radius: 4, color: '#00000010' })
            .onClick(() => {
              let f = this.toggleDevice(item)
              this.deviceList[value] = f;
            });
          }
        });
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(12)
      .columnsGap(12)
      .padding(16)
      .layoutWeight(1);
    }
    .backgroundColor('#F8F9FA')
    .height('100%');
  }

  private toggleDevice(item: Device): Device {
    item.switch = item.switch ? 0 : 1;
    _IoTad.set_waterValve_by_id(item.switch ? "on" : "off");
    _IoTad.set_LED_brightness_by_id(item.switch?5000:1)
    return new Device(item.name,item.switch,item.type_id)
  }

  private closePanel(): void {
    this.is_show = false;
    this._height = "0%";
  }

  private getDeviceIcon(typeId: number): Resource {
    return typeId < 2000 ? $r("app.media.fill_light") : $r("app.media.water_valve");
  }
}

@Component
struct IrrigationScene {
  @Link arr_farmland: farmland[];
  @Link is_show: boolean;
  @Link _height: string;
  @State isTemperatureControlDeviceShow: boolean = false;
  @State soilHumidityRemaining: number = 65;

  build(): void {
    Stack(){
      Column() {
        Row() {
          Image($r("app.media.ic_back"))
            .fillColor('#ff111141')
            .width(24)
            .height(24)
            .onClick(() => this.closePanel());
          Text("灌溉节水模式")
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .layoutWeight(1)
            .textAlign(TextAlign.Center);
        }
        .padding(16)
        .backgroundColor('#ffaaabff')
        .backdropBlur(10);

        Row() {
          FarmEnvItem({
            icon: $r("app.media.ic_temp"),
            value: '26℃',
            title: '棚内温度',
            color: '#E74C3C'
          });

          FarmEnvItem({
            icon: $r("app.media.ic_humidity"),
            value: `${this.soilHumidityRemaining}%`,
            //value: '55%',
            title: '土壤湿度',
            color: '#3498DB'
          });

          FarmEnvItem({
            icon: $r("app.media.ic_gas"),
            value: this.getCO2Status(),
            //value: '正常',
            title: 'CO₂浓度',
            color: '#ff544539'
          });
        }
        .padding(16)
        .justifyContent(FlexAlign.SpaceEvenly);

        List() {
          FarmDeviceItem({
            params: {
              icon: $r("app.media.ic_camera"),
              title: "农田监控",
              status: "在线",
              buttonText: "实时查看",
              onAction: () => this.viewCamera()
            }
          });

          FarmDeviceItem({
            params: {
              icon: $r("app.media.ac_icon"),
              title: "棚内温控",
              status: "26℃ 恒温模式",
              buttonText: "远程调节",
              onAction: () => this.isTemperatureControlDeviceShow = true
            }
          });

          FarmDeviceItem({
            params: {
              icon: $r("app.media.ic_feeder"),
              title: "水肥灌溉",
              //status: `土壤湿度：${this.soilHumidityRemaining}%`,
              status: `土壤湿度：${this.soilHumidityRemaining}%\n ${this.getHumidityTip(this.soilHumidityRemaining)}`,
              buttonText: "立即灌溉",
              onAction: () => this.autoIrrigation()
            }
          });
        }
        .borderRadius(16)
        .margin(16)
        .backgroundColor(Color.White)
        .shadow({ radius: 8, color: '#00000010' });
      }
      .backgroundColor('#F8F9FA')
      .height('100%');

      if (this.isTemperatureControlDeviceShow) {
        ControlTemp({
          is_show: this.isTemperatureControlDeviceShow,
          arr_farmland: this.arr_farmland
        });
      }
    }
  }

  private viewCamera(): void {
    router.pushUrl({
      url: "pages/FarmMonitor"
    });
  }

  private autoIrrigation(): void {
    this.soilHumidityRemaining = Math.max(this.soilHumidityRemaining +10, 80);
  }

  private closePanel(): void {
    this.is_show = false;
    this._height = "0%";
  }
  private getHumidityTip(humidity: number): string {
    if (humidity < 60) {
      return "⚠️ 偏干，建议灌溉";
    } else if (humidity > 80) {
      return "⚠️ 过湿，注意排水";
    } else {
      return "✅ 湿度适宜";
    }
  }
  private getCO2Status(): string {
    const co2 = 580; // 这里接传感器
    if (co2 > 1000) return "⚠️ 超高";
    if (co2 > 600) return "⚠️ 偏高";
    return "✅ 正常";
  }
}

@Component
struct FarmEnvItem {
  @Prop icon: Resource;
  @Prop value: string;
  @Prop title: string;
  @Prop color: string = '#ffaaabff';

  build(): void {
    Column() {
      Image(this.icon)
        .width(40)
        .height(40)
        .fillColor(this.color);

      Text(this.value)
        .fontSize(20)
        .fontColor(this.color)
        .margin({ top: 8 })
        .fontWeight(FontWeight.Medium);

      Text(this.title)
        .fontSize(12)
        .fontColor('#7F8C8D');
    }
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 4, color: '#00000010' });
  }
}

@Component
struct FarmDeviceItem {
  @Prop params: ControlItemParams;

  build(): void {
    Row() {
      Image(this.params.icon)
        .width(32)
        .height(32)
        .margin({ right: 16 });

      Column() {
        Text(this.params.title)
          .fontSize(16)
          .fontColor('#2C3E50');
        Text(this.params.status)
          .fontSize(12)
          .fontColor('#7F8C8D');
      }
      .layoutWeight(1);

      Button(this.params.buttonText)
        .type(ButtonType.Normal)
        .backgroundColor('#ffaaabff')
        .fontColor(Color.White)
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .onClick(this.params.onAction);
    }
    .padding(16)
    .width('100%');
  }
}

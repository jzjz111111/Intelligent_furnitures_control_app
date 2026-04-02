// pages/homepage.ets

import { McLineChart, Options } from '@mcui/mccharts';
import util from '@ohos.util';
import router from '@ohos.router';
import { temperature_control_device, Device, farmland } from '../tool/classes';
import { displayFarmland, my_DeepSeek, add_farmland_page, AccountSetting, AboutProject, ControlLights, ControlWaterValve, ControlTemp } from '../tool/component';
import { LocalStorage } from '../data/LocalStorage';
import { _Udp } from '../tool/UDP';
import { Data_Tcp, _Tcp } from '../tool/TCP';
import { Farmland_db, tcp } from './Index';
import socket from '@ohos.net.socket';
import wifi from '@ohos.wifi';
import { notificationManager } from '@kit.NotificationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { _IoTad } from './scan_devices';
import { FarmScenePage } from './scene_page';
import { Data_id_yun, DATA_new } from '../tool/IoTad';
import picker from '@ohos.file.picker';
import prompt from '@ohos.prompt';
import promptAction from '@ohos.promptAction';
import geoLocationManager from '@ohos.geoLocationManager';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { common } from '@kit.AbilityKit';
import type { PermissionRequestResult } from '@ohos.abilityAccessCtrl';
import { ThemeColors } from '../utils/theme';
import { Datamodel, WarnHistoryItem, EnvStatusResult, getEnvStatus, resolveIP, max_temp, max_humi, max_co2 } from '../utils/common';
import { delete_farmland } from './delete_farmland';
import { detail_data } from './detail_data';
import { RemoteControlPage } from './RemoteControlPage';

type Context = common.UIAbilityContext;
let DATA_IoTda: string = ''
let Data_Id_me: string = ''
const TAG: string = '[PublishOperation]';
const DOMAIN_NUMBER: number = 0xFF00;

@Entry
@Component
export struct homepage {
  // 图表配置 - 移除数据点标记（symbol: 'none'）
  @State serOption_temp: Options = new Options({
    legend: { show: false },
    xAxis: {
      data: ["0:00", "3:00", "6:00", "9:00", "12:00", "15:00", "18:00", "21:00"],
      axisLine: { lineStyle: { color: '#e2e8f0', width: 1 } },
      axisLabel: { color: ThemeColors.textSecondary, fontSize: 10 }
    },
    yAxis: {
      name: '温度(℃)',
      nameTextStyle: { color: ThemeColors.textSecondary, fontSize: 10 },
      axisLine: { show: false },
      splitLine: { lineStyle: { color: '#f1f5f9', type: 'dashed' } }
    },
    series: [{
      name: '实时温度',
      data: [14, 16, 17, 18, 22, 22, 21, 18],
      color: '#06b6d4',
      lineStyle: { width: 3 },
      smooth: true,
      symbol: 'none', // 移除数据点
      areaStyle: {
        color: 'rgba(6, 182, 212, 0.2)'
      }
    }]
  })

  @State serOption_humi: Options = new Options({
    legend: { show: false },
    xAxis: {
      data: ["0:00", "3:00", "6:00", "9:00", "12:00", "15:00", "18:00", "21:00"],
      axisLine: { lineStyle: { color: '#e2e8f0', width: 1 } },
      axisLabel: { color: ThemeColors.textSecondary, fontSize: 10 }
    },
    yAxis: {
      name: '湿度(%)',
      nameTextStyle: { color: ThemeColors.textSecondary, fontSize: 10 },
      axisLine: { show: false },
      splitLine: { lineStyle: { color: '#f1f5f9', type: 'dashed' } }
    },
    series: [{
      name: '实时湿度',
      data: [88, 89, 86, 78, 79, 85, 88, 77],
      color: '#059669',
      lineStyle: { width: 3 },
      smooth: true,
      symbol: 'none', // 移除数据点
      areaStyle: {
        color: 'rgba(5, 150, 105, 0.2)'
      }
    }]
  })

  @State serOption_co2: Options = new Options({
    legend: { show: false },
    xAxis: {
      data: ["0:00", "3:00", "6:00", "9:00", "12:00", "15:00", "18:00", "21:00"],
      axisLine: { lineStyle: { color: '#e2e8f0', width: 1 } },
      axisLabel: { color: ThemeColors.textSecondary, fontSize: 10 }
    },
    yAxis: {
      name: 'CO₂(ppm)',
      nameTextStyle: { color: ThemeColors.textSecondary, fontSize: 10 },
      axisLine: { show: false },
      splitLine: { lineStyle: { color: '#f1f5f9', type: 'dashed' } }
    },
    series: [{
      name: 'CO₂浓度',
      data: [11, 10, 2, 11, 22, 66, 10, 60],
      color: ThemeColors.textPrimary,
      lineStyle: { width: 3 },
      smooth: true,
      symbol: 'none', // 移除数据点
      areaStyle: {
        color: 'rgba(2, 6, 23, 0.15)'
      }
    }]
  })

  private localAddr: socket.NetAddress | null = null
  private mixerAddr: socket.NetAddress | null = null

  @State _h_detail: string = '0%'
  @State num1: string = '';
  @State num2: string = '';
  @State is_Lock: boolean = false
  @State is_show_r: boolean = false
  @State is_sleep: boolean = false
  @State is_chang: boolean = false
  @State is_delete_h: string = "0%"
  @Link arr_farmland: farmland[]
  @State is_show_humidity: boolean = false
  @State _height: string = "20%"
  @State backG: string = "app.media.back_house"
  @State _width: string = '90%'
  @State temp: string = ''
  @State humi: string = ''
  @State co2: string = ''
  @State currentFarm: farmland | null = null;
  @State showMyList: boolean = false;
  @Link is_warn: boolean
  @Link warn_data: Datamodel
  @StorageLink('globalAvatar') avatarUri: string = '';
  @StorageLink('globalNickName') nickName: string = '智慧农业';
  @State locationText: string = "定位中...";
  @State greetText: string = "Good Morning";
  @State topFarm: farmland | null = null

  @State currentFarmWarnHistory: WarnHistoryItem[] = [];
  @State showWarnHistoryPanel: boolean = false
  @State globalWarnHistory: WarnHistoryItem[] = [];
  @State showGlobalHistory: boolean = false;
  @State showRemoteControl: boolean = false;

  @State pressedFarmKey: string = '';
  @State highlightedFarmKey: string = '';
  @State pulseEnvType: string = '';

  async aboutToAppear() {
    this.localAddr = {
      family: 1,
      port: 8889,
      address: resolveIP(wifi.getIpInfo().ipAddress)
    }
    this.mixerAddr = {
      address: '192.168.191.19',
      port: 8889
    }
    setTimeout(async () => {
      let farmlandList: farmland[] = await Farmland_db.getAllFarmlands()
      if (farmlandList.length == 0) {
        AlertDialog.show({
          message: "还没有农田哦，快去录入吧~",
          alignment: DialogAlignment.Center,
          offset: { dx: 0, dy: -20 }
        })
      }
      for (let item of await Farmland_db.getAllFarmlands()) {
        this.arr_farmland.push(item)
      }
      setTimeout(async () => {
        await tcp.getData()
        this.analyze_data(Data_Tcp)
        await _IoTad.get_data()
        await this.new_analyze_data(DATA_new)
        Data_Id_me = Data_id_yun
      }, 1000)
      setInterval(async () => {
        if (Data_Id_me != Data_id_yun) {
          DATA_IoTda = DATA_new
          await this.new_analyze_data(DATA_IoTda)
        }
      }, 1000)
    }, 100)
    this.setGreetingByTime();
  }

  async judge(temp?: number, humi?: number, co2?: number) {
    let title: string = ''
    if (temp != null) {
      if (temp > max_temp) {
        let paramInfo: Datamodel = {
          type: "temp",
          data: temp,
          arr: await Farmland_db.getAllFarmlands()
        }
        this.warn_data = paramInfo
        this.is_warn = true
        title = "温度过高"
        this.globalWarnHistory.unshift({
          typeText: "温度过高警告",
          data: temp,
          time: new Date().toLocaleString()
        });
        this.currentFarmWarnHistory.unshift({
          typeText: "温度过高警告",
          data: temp,
          time: new Date().toLocaleString()
        });
      }
    }
    if (humi != null) {
      if (humi > max_humi) {
        let paramInfo: Datamodel = {
          type: "humi",
          data: humi,
          arr: await Farmland_db.getAllFarmlands()
        }
        this.warn_data = paramInfo
        this.is_warn = true
        title = "湿度过高"
        this.globalWarnHistory.unshift({
          typeText: "湿度过高警告",
          data: humi,
          time: new Date().toLocaleString()
        });
        this.currentFarmWarnHistory.unshift({
          typeText: "湿度过高警告",
          data: humi,
          time: new Date().toLocaleString()
        });
        this.pulseEnvType = 'humi'
        setTimeout(() => { this.pulseEnvType = '' }, 900)
      }
    }
    if (co2 != null) {
      if (co2 > max_co2) {
        let paramInfo: Datamodel = {
          type: "co2",
          data: co2,
          arr: await Farmland_db.getAllFarmlands()
        }
        this.warn_data = paramInfo
        this.is_warn = true
        title = "co2浓度过高"
        this.globalWarnHistory.unshift({
          typeText: "CO₂浓度过高警告",
          data: co2,
          time: new Date().toLocaleString()
        });
        this.currentFarmWarnHistory.unshift({
          typeText: "CO₂浓度过高警告",
          data: co2,
          time: new Date().toLocaleString()
        });
        this.pulseEnvType = 'co2'
        setTimeout(() => { this.pulseEnvType = '' }, 900)
      }
    }
    let notificationRequest: notificationManager.NotificationRequest = {
      id: 1,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '农业环境警告',
          text: title,
          additionalText: '请及时处理',
        }
      }
    };
    notificationManager.publish(notificationRequest, (err: BusinessError) => {
      if (err) {
        hilog.error(DOMAIN_NUMBER, TAG,
          `Failed to publish notification. Code is ${err.code}, message is ${err.message}`);
        return;
      }
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in publishing notification.');
    });
  }

  analyze_data(data: string) {
    let arr: string[] = data.split("/")
    for (let item of arr) {
      let values: string = JSON.parse(item)
      if (typeof values?.["temp"] != "undefined") {
        this.temp = values?.["temp"]
        this.humi = values?.["humi"]
        this.judge(Number(this.temp), Number(this.humi), Number())
      } else {
        let new_arr_farmland: farmland[] = []
        for (let r of this.arr_farmland) {
          let new_arr_f: Device[] = []
          for (let f of r.device_s) {
            if (f.type_id == values?.["id"]) {
              if (typeof values?.["lighting"] != "undefined") {
                f = new Device(f.name, values?.["switch"], values?.["id"])
                f.lighting = values?.["lighting"]
              } else if (typeof values?.["a_temp"] != "undefined") {
                f = new Device(f.name, values?.["switch"], values?.["id"])
                f.temp = values?.["a_temp"]
                f.mode = values?.["mode"]
              } else {
                f = new Device(f.name, values?.["switch"], values?.["id"])
              }
            }
            new_arr_f.push(f)
          }
          new_arr_farmland.push(new farmland(r.name, new_arr_f))
        }
        this.arr_farmland = new_arr_farmland
      }
    }
  }

  async new_analyze_data(data: string) {
    let values: string = JSON.parse(data)
    if (typeof values?.["temperature"] != "undefined") {
      this.temp = values?.["temperature"]
      this.humi = values?.["humidity"]
      this.co2 = "1900"
      this.judge(Number(this.temp), Number(this.humi), Number(this.co2))
      let new_arr_farmland: farmland[] = []
      for (let r of this.arr_farmland) {
        let new_arr_f: Device[] = []
        for (let f of r.device_s) {
          if (typeof values?.[f.type_id.toString()] != "undefined") {
            let new_v: string = values?.[f.type_id.toString()]
            new_v = JSON.parse(new_v)
            if (f.type_id < 999) {
              f = new Device(f.name, values?.[f.type_id.toString()], f.type_id)
            } else if (f.type_id < 1999) {
              f = new Device(f.name, values?.[f.type_id.toString()], f.type_id)
              f.lighting = (values?.["brightness"]) / 1000
            } else if (f.type_id < 2999) {
              f = new Device(f.name, values?.[f.type_id.toString()], f.type_id)
            } else if (f.type_id < 3999 && f.type_id > 3000) {
              f = new Device(f.name, values?.[f.type_id.toString()], f.type_id)
              f.temp = Number(values?.[f.type_id.toString() + "_2"])
              f.mode = values?.[f.type_id.toString() + "_3"]
            } else {
              f = new Device(f.name, values?.[f.type_id.toString()], f.type_id)
            }
          }
          new_arr_f.push(f)
        }
        new_arr_farmland.push(new farmland(r.name, new_arr_f))
      }
      this.arr_farmland = new_arr_farmland
    }
  }

  @Builder
  MenuBar() {
    Menu() {
      MenuItem() {
        Text('添加农田').fontColor(ThemeColors.textPrimary).fontSize(14).fontWeight(FontWeight.Bold)
      }.onClick(() => {
        this.is_show_r = true
      })
      MenuItem() {
        Text("删除农田").fontColor(ThemeColors.danger).fontSize(14).fontWeight(FontWeight.Bold)
      }.onClick(() => {
        animateTo({ duration: 500 }, () => { this.is_delete_h = "90%" })
      })
    }
    .fontColor(ThemeColors.textPrimary)
    .backgroundColor(ThemeColors.bgCard)
    .border({ width: 1, color: ThemeColors.borderLight })
    .shadow({ color: ThemeColors.shadowDark, radius: 12, offsetX: 0, offsetY: 6 })
  }

  // ... 保留其他所有代码不变，仅修改以下两个 Builder ...

  @Builder
  ActionButton(text: string, onClick: () => void, btnWidth: string = '90%') {
    Button(text)
      .width(btnWidth)
      .height(32) // 稍微降低高度
      .fontSize(11) // 减小字体确保四字完整显示
      .fontWeight(FontWeight.Bold)
      .backgroundColor(ThemeColors.primary)
      .fontColor('#FFFFFF')
      .borderRadius(16) // 稍微减小圆角
      .padding({ left: 2, right: 2 }) // 减少内边距增加文字空间
      .shadow({ color: 'rgba(0, 0, 0, 0.2)', radius: 4, offsetX: 0, offsetY: 2 })
      .onClick(() => {
        animateTo({ duration: 100 }, () => { })
        onClick()
      })
  }

  @Builder
  FarmlandCard(farmlandItem: farmland) {
    Column() {
      // 顶部霓虹绿条 - 确保与卡片圆角契合
      Row()
        .width('100%')
        .height(4)
        .backgroundColor(ThemeColors.accent)
        .borderRadius({ topLeft: 16, topRight: 16 })

      // 卡片内容区
      Row() {
        // 左侧图片区域 28%
        Column() {
          if (farmlandItem.avatar) {
            Image(farmlandItem.avatar)
              .width('100%')
              .height(100) // 降低高度
              .borderRadius(10)
              .objectFit(ImageFit.Cover)
          } else {
            Column() {
              Text("🌱")
                .fontSize(36)
                .margin({ bottom: 4 })
              Text("SMART")
                .fontSize(9)
                .fontColor(ThemeColors.textTertiary)
                .letterSpacing(1)
            }
            .width('100%')
            .height(100)
            .backgroundColor(ThemeColors.primaryLight)
            .borderRadius(10)
            .justifyContent(FlexAlign.Center)
          }
        }
        .width('28%')
        .height(100)

        // 右侧内容区域 72%
        Column({ space: 4 }) {
          Text(farmlandItem.name)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .width('100%')

          Text("设备在线 • 运行正常")
            .fontSize(10)
            .fontColor(ThemeColors.textTertiary)
            .margin({ bottom: 2 })

          // 三按钮横向排列 - 调整间距和宽度确保文字完整显示
          Row({ space: 6 }) {
            this.ActionButton("历史记录", () => {
              animateTo({ duration: 500 }, () => { this._h_detail = "90%"; this.is_show_humidity = true })
            }, '31%')
            this.ActionButton("远程控制", () => {
              this.currentFarm = farmlandItem
              this.showRemoteControl = true
            }, '31%')
            this.ActionButton("预警通知", () => {
              this.showWarnHistoryPanel = true
              this.showGlobalHistory = false
            }, '31%')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('72%')
        .height(100)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 10 })
      }
      .width('100%')
      .padding(12)
    }
    .width('100%')
    .backgroundColor(ThemeColors.bgCard)
    .borderRadius(16) // 整个卡片统一圆角
    .shadow({
      color: (this.highlightedFarmKey === farmlandItem.name) ? ThemeColors.techGlow : ThemeColors.shadowDark,
      radius: (this.highlightedFarmKey === farmlandItem.name) ? 20 : 12,
      offsetX: 0,
      offsetY: (this.highlightedFarmKey === farmlandItem.name) ? 8 : 4
    })
    .onClick(() => {
      this.pressedFarmKey = farmlandItem.name ? farmlandItem.name : ''
      animateTo({ duration: 100 }, () => { })
      setTimeout(() => {
        this.pressedFarmKey = ''
        this.highlightedFarmKey = farmlandItem.name ? farmlandItem.name : ''
      }, 150)
    })
    .transform({ scale: (this.pressedFarmKey === farmlandItem.name) ? 0.98 : 1.0 })
  }

  build() {
    Stack() {
      // 背景图片层
      Image($r('app.media.SmartFarmBackground'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)

      // 内容层
      Scroll() {
        Column() {
          Column() {
            // 顶部区域：用户头像+欢迎语（左），搜索+报警（右）
            Row() {
              Row({ space: 12 }) {
                // 用户头像
                Image(this.avatarUri || $r("app.media.user"))
                  .width(44)
                  .height(44)
                  .borderRadius(22)
                  .border({ width: 2, color: ThemeColors.accent })
                  .shadow({ color: ThemeColors.techGlow, radius: 6, offsetX: 0, offsetY: 0 })

                // 欢迎语
                Column({ space: 2 }) {
                  Text(this.greetText)
                    .fontSize(12)
                    .fontColor(ThemeColors.textSecondary)
                    .letterSpacing(0.5)
                  Text(this.nickName)
                    .fontSize(20)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(ThemeColors.textPrimary)
                }
                .alignItems(HorizontalAlign.Start)
              }
              .padding({ left: 12, right: 16, top: 8, bottom: 8 })
              .backgroundColor(ThemeColors.bgGlass)
              .borderRadius(24)
              .border({ width: 1, color: ThemeColors.borderLight })
              .shadow({ color: ThemeColors.shadowDark, radius: 6, offsetX: 0, offsetY: 2 })

              Blank()

              Row({ space: 20 }) {
                Image($r("app.media.search"))
                  .width(24)
                  .height(24)
                  .fillColor(ThemeColors.textPrimary)
                Image($r("app.media.ic_alarm"))
                  .width(24)
                  .height(22)
                  .fillColor(ThemeColors.textPrimary)
                  .onClick(() => { this.showGlobalHistory = true; this.showWarnHistoryPanel = true })
              }
            }
            .width("100%")
            .padding({ left: 20, right: 20, top: 16, bottom: 12 })

            // 天气卡片（原Stack）：包含定位+天气+图表
            Stack() {
              Column() {
                // 定位信息移至天气卡片顶部
                Row({ space: 6 }) {
                  Image($r("app.media.location"))
                    .width(16)
                    .height(16)
                    .fillColor(ThemeColors.accent)
                    .shadow({ color: ThemeColors.techGlow, radius: 2 })
                  Text(this.locationText)
                    .fontSize(13)
                    .fontColor(ThemeColors.textSecondary)
                    .fontWeight(FontWeight.Medium)
                }
                .width('100%')
                .margin({ bottom: 16 })

                // 天气信息（温度+图表）
                Row() {
                  McLineChart({ options: this.serOption_temp })
                    .layoutWeight(1)
                    .height(140)

                  // 大温度显示
                  Column() {
                    Text(`${this.temp || '--'}°`)
                      .fontSize(42)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(ThemeColors.textPrimary)
                      .lineHeight(42)
                    Text("多云 | 东风")
                      .fontSize(12)
                      .fontColor(ThemeColors.textSecondary)
                      .margin({ top: 6 })
                  }
                  .alignItems(HorizontalAlign.End)
                  .padding({ left: 12 })
                  .width(100)
                }
                .width("100%")
                .alignItems(VerticalAlign.Center)
              }
              .width("100%")
              .padding(20)
              .backgroundColor(ThemeColors.cardGlass)
              .borderRadius(24)
              .border({ width: 1, color: 'rgba(255,255,255,0.8)' })
              .shadow({ color: ThemeColors.shadowDark, radius: 24, offsetX: 0, offsetY: 12 })
            }
            .width("92%")
            .margin({ bottom: 20, top: 4 })

            Row({ space: 12 }) {
              this.EnvCard("湿度", this.humi, "%", 'humi')
              this.EnvCard("CO₂", this.co2, "ppm", 'co2')
            }
            .width("92%")
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ bottom: 24 })

            Row() {
              Column({ space: 4 }) {
                Text("我的农田")
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(ThemeColors.textPrimary)
                Text(`${this.arr_farmland.length} 个监测点`)
                  .fontSize(12)
                  .fontColor(ThemeColors.textSecondary)
              }

              Blank()

              Text("管理")
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(ThemeColors.bgCard)
                .padding({ left: 20, right: 20, top: 10, bottom: 10 })
                .backgroundColor(ThemeColors.primary)
                .borderRadius(20)
                .shadow({ color: ThemeColors.shadowDark, radius: 8, offsetX: 0, offsetY: 4 })
                .bindMenu(this.MenuBar)
            }
            .width('92%')
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .margin({ bottom: 20 })

            Scroll() {
              Flex({ alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
                ForEach(this.arr_farmland, (item: farmland, index: number) => {
                  Column({ space: 8 }) {
                    Stack() {
                      if (item.avatar) {
                        Image(item.avatar)
                          .width(72)
                          .height(72)
                          .borderRadius(36)
                          .objectFit(ImageFit.Cover)
                          .border({
                            width: (this.highlightedFarmKey === item.name) ? 4 : 2,
                            color: (this.highlightedFarmKey === item.name) ? ThemeColors.accent : ThemeColors.primary
                          })
                      } else {
                        Column() {
                          Text("🌾")
                            .fontSize(36)
                        }
                        .width(72)
                        .height(72)
                        .backgroundColor(ThemeColors.primaryLight)
                        .borderRadius(36)
                        .border({ width: 2, color: ThemeColors.primary })
                      }

                      if (index === 0) {
                        Row()
                          .width(14)
                          .height(14)
                          .backgroundColor(ThemeColors.accent)
                          .borderRadius(7)
                          .border({ width: 3, color: ThemeColors.bgCard })
                          .position({ x: 50, y: 50 })
                          .shadow({ color: ThemeColors.techGlow, radius: 4 })
                      }
                    }

                    Text(item.name)
                      .fontSize(13)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(ThemeColors.textPrimary)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width(80)
                      .textAlign(TextAlign.Center)
                  }
                  .width(90)
                  .alignItems(HorizontalAlign.Center)
                  .onClick(() => { this.topFarm = item; this.highlightedFarmKey = item.name ? item.name : '' })
                })
              }
              .padding({ left: 16, right: 16 })
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
            .margin({ bottom: 20 })

            List({ space: 16 }) {
              if (this.arr_farmland.length === 0) {
                ListItem() {
                  Column() {
                    Image($r("app.media.empty_farm"))
                      .width(100)
                      .height(100)
                      .margin({ bottom: 16 })
                      .fillColor(ThemeColors.borderDark)
                    Text("暂无监测数据")
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(ThemeColors.textSecondary)
                    Text("点击右上角管理添加农田")
                      .fontSize(13)
                      .fontColor(ThemeColors.textSecondary)
                      .margin({ top: 8 })
                  }
                  .width('100%')
                  .height(240)
                  .justifyContent(FlexAlign.Center)
                }
              } else {
                ForEach(this.arr_farmland, (farmlandItem: farmland) => {
                  ListItem() {
                    this.FarmlandCard(farmlandItem)
                  }
                  .padding({ left: 16, right: 16 })
                })
              }
            }
            .width('100%')
            .flexGrow(1)
            .padding({ bottom: 24, top: 8 })
          }
          .width("100%")
        }
        .width('100%')
      }
      .height('100%')
      .width('100%')

      if (this.is_show_r) {
        add_farmland_page({ arr: $arr_farmland, is_show: $is_show_r })
      }
      delete_farmland({ _h: this.is_delete_h, arr_farmland: this.arr_farmland })

      if (this.is_show_humidity) {
        detail_data({
          _h: this._h_detail,
          is_show: this.is_show_humidity,
          serOption_humi: this.serOption_humi,
          serOption_temp: this.serOption_temp,
          serOption_co2: this.serOption_co2
        })
      }

      if (this.showWarnHistoryPanel) {
        Column() {
          Row() {
            Button("← 返回")
              .onClick(() => { this.showWarnHistoryPanel = false })
              .backgroundColor(ThemeColors.bgCard)
              .fontColor(ThemeColors.primary)
              .borderRadius(16)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .padding({ left: 16, right: 16 })

            Blank()

            Text(this.showGlobalHistory ? "全部预警" : "当前预警")
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeColors.textPrimary)
          }
          .width("100%")
          .margin({ bottom: 20 })

          Scroll() {
            Column({ space: 12 }) {
              if (this.currentFarmWarnHistory.length === 0) {
                Column() {
                  Text("⚡")
                    .fontSize(48)
                    .margin({ bottom: 12 })
                  Text("系统运行正常")
                    .fontSize(16)
                    .fontColor(ThemeColors.textSecondary)
                    .fontWeight(FontWeight.Bold)
                }
                .margin({ top: 60 })
              } else {
                ForEach(this.showGlobalHistory ? this.globalWarnHistory : this.currentFarmWarnHistory, (item: WarnHistoryItem) => {
                  Column() {
                    Row() {
                      Column({ space: 4 }) {
                        Text(item.typeText)
                          .fontSize(15)
                          .fontColor(ThemeColors.danger)
                          .fontWeight(FontWeight.Bold);
                        Text(item.time)
                          .fontSize(11)
                          .fontColor(ThemeColors.textTertiary);
                      }
                      .layoutWeight(1)

                      Text(item.data.toString())
                        .fontSize(20)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(ThemeColors.danger)
                    }
                    .width("100%")
                  }
                  .width("100%")
                  .backgroundColor(ThemeColors.bgCard)
                  .padding(16)
                  .borderRadius(12)
                  .border({ width: 1, color: 'rgba(239, 68, 68, 0.2)' })
                  .shadow({ radius: 4, color: 'rgba(239, 68, 68, 0.1)' })
                });
              }
            }
            .width("100%")
            .padding(4);
          }
          .layoutWeight(1);
        }
        .width("100%")
        .height("90%")
        .backgroundColor(ThemeColors.bgPrimary)
        .padding(20);
      }

      if (this.showRemoteControl) {
        RemoteControlPage({
          showPage: this.showRemoteControl,
          farm: this.currentFarm,
          temp: this.temp,
          humi: this.humi,
          co2: this.co2,
          currentFarm: $currentFarm,
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  EnvCard(title: string, value: string, unit: string, type: 'humi' | 'co2') {
    Column({ space: 6 }) {
      Row({ space: 6 }) {
        Text(type === 'humi' ? '💧' : '🌫️')
          .fontSize(16)
        Text(title)
          .fontSize(13)
          .fontColor(ThemeColors.textTertiary)
          .fontWeight(FontWeight.Bold)
      }

      Row({ space: 4 }) {
        Text(`${value || '--'}`)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.textPrimary);
        Text(unit)
          .fontSize(14)
          .fontColor(ThemeColors.textSecondary)
          .margin({ bottom: 6 })
      }

      if (value) {
        Text(getEnvStatus(Number(value), type).text)
          .fontSize(11)
          .fontColor(getEnvStatus(Number(value), type).color)
          .backgroundColor(`${getEnvStatus(Number(value), type).color}15`)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .borderRadius(12)
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('48%')
    .height(110)
    .padding(16)
    .backgroundColor(ThemeColors.cardGlass)
    .borderRadius(20)
    .border({
      width: 1,
      color: (this.pulseEnvType === type) ? ThemeColors.accent : ThemeColors.borderLight
    })
    .shadow({
      color: (this.pulseEnvType === type) ? ThemeColors.techGlow : ThemeColors.shadowDark,
      radius: (this.pulseEnvType === type) ? 20 : 10,
      offsetX: 0,
      offsetY: (this.pulseEnvType === type) ? 8 : 3
    })
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(HorizontalAlign.Start)
  }

  setGreetingByTime() {
    const hour = new Date().getHours();
    if (hour >= 5 && hour < 12) {
      this.greetText = "早上好，开启绿色一天";
    } else if (hour >= 12 && hour < 18) {
      this.greetText = "下午好，继续耕耘";
    } else {
      this.greetText = "晚上好，休息一下吧";
    }
  }
}
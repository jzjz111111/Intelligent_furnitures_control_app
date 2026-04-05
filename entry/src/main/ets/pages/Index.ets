import { McLineChart, Options } from '@mcui/mccharts'
import util from '@ohos.util';
import router from '@ohos.router';
import { temperature_control_device, Device, farmland } from '../tool/classes';
import { displayFarmland, my_DeepSeek,add_farmland_page,AccountSetting,AboutProject,ControlLights,ControlWaterValve,ControlTemp} from '../tool/component';
import { LocalStoraga } from '../data/LocalStorage';
import { _Udp } from '../tool/UDP';
import { Data_Tcp, _Tcp } from '../tool/TCP';
import { FarmlandDatabase } from '../data/RdbStorage';
import socket from '@ohos.net.socket';
import wifi from '@ohos.wifi';
import {  notificationManager } from '@kit.NotificationKit';
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
import { getSensorData, controlHardware } from '../../common/api/HttpApi';
import  {DataAnalysisPage} from './DataAnalysis';
import type { PermissionRequestResult } from '@ohos.abilityAccessCtrl';
type Context = common.UIAbilityContext;



interface WarnHistoryItem {
  typeText: string;
  data: number;
  time: string;
}



let DATA_IoTda:string =''
let Data_Id_me:string = ''
const max_temp = 30
const max_humi = 90
const max_co2 = 1500
const TAG: string = '[PublishOperation]';
const DOMAIN_NUMBER: number = 0xFF00;
//export let udp:_Udp = new _Udp(3861,'172.16.0.119')
//export let tcp:_Tcp = new _Tcp(3861,'172.16.0.119')
export let tcp:_Tcp = new _Tcp(8888,'192.168.191.19')
let Farmland_db:FarmlandDatabase = new FarmlandDatabase(globalThis.getContext())
export interface EnvStatus {
  color: string;
  text: string;
}
// 农业环境状态判断工具函数
function getEnvStatus(value: number, type: 'temp' | 'humi' | 'co2'):EnvStatus {
  switch(type) {
    case 'temp':
      if (value > max_temp) return { color: '#ff4444', text: '偏高' };
      if (value < 15) return { color: '#ff9900', text: '偏低' };
      return { color: '#4cd964', text: '适宜' };
    case 'humi':
      if (value > max_humi) return { color: '#ff4444', text: '偏高' };
      if (value < 40) return { color: '#ff9900', text: '偏低' };
      return { color: '#4cd964', text: '适宜' };
    case 'co2':
      if (value > max_co2) return { color: '#ff4444', text: '偏高' };
      if (value < 400) return { color: '#ff9900', text: '偏低' };
      return { color: '#4cd964', text: '适宜' };
    default:
      return { color: '#666666', text: '未知' };
  }
}

function resolveIP(ip:number):string{
  if(ip<0||ip>0xFFFFFFFF){
    return '0'
  }
  return (ip >>>24)+'.'+(ip >> 16 & 0xFF)+'.'+(ip >>8 &0xFF) +'.'+(ip &0xFF);
}

@Component
struct homepage {

  @State serOption_temp: Options = new Options({
    xAxis: { data: ["0:00", "3:00", "6:00", "9:00", "12:00", "15:00", "18:00", "21:00"] },
    yAxis: { name: '温度(℃)' },
    series: [{
      name: '实时温度',
      data: [14, 16, 17, 18, 22, 22, 21, 18],
      color: "#dd00dd",
      arcLineWidth: 100
    }]
  })
  @State serOption_humi: Options = new Options({
    xAxis: { data: ["0:00", "3:00", "6:00", "9:00", "12:00", "15:00", "18:00", "21:00"] },
    yAxis: { name: '湿度(%)' },
    series: [{
      name: '实时湿度',
      data: [88, 89, 86, 78, 79, 85, 88, 77],
      color: "#ff039f96",
      arcLineWidth: 100
    }]
  })
  @State serOption_co2: Options = new Options({
    xAxis: { data: ["0:00", "3:00", "6:00", "9:00", "12:00", "15:00", "18:00", "21:00"] },
    yAxis: { name: 'CO₂浓度(ppm)' },
    series: [{
      name: '实时CO₂浓度',
      data: [11, 10, 2, 11, 22, 66, 10, 60],
      color: "#ffddb801",
      arcLineWidth: 100
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
  // 存储当前农田的预警历史（纯内存，无数据库）
  @State currentFarmWarnHistory: WarnHistoryItem[] = [];
  // 控制历史面板显示
  @State showWarnHistoryPanel: boolean = false
  @State globalWarnHistory: WarnHistoryItem[] = []; // 全部农田的预警
  @State showGlobalHistory: boolean = false; // true=全局，false=当前农田
  @State showRemoteControl: boolean = false;

  // ========== 后端硬件控制函数 ==========
  // 打开 LED1
  async openLED1() {
    await controlHardware({ led1: 5, led2: 0, led3: 0, spray: 0 });
    promptAction.showToast({ message: "LED1 已开启" });
  }

  // 关闭 LED1
  async closeLED1() {
    await controlHardware({ led1: 0, led2: 0, led3: 0, spray: 0 });
    promptAction.showToast({ message: "LED1 已关闭" });
  }

  // 打开喷雾
  async openSpray() {
    await controlHardware({ led1: 0, led2: 0, led3: 0, spray: 5 });
    promptAction.showToast({ message: "喷雾已开启" });
  }

  // 关闭喷雾
  async closeSpray() {
    await controlHardware({ led1: 0, led2: 0, led3: 0, spray: 0 });
    promptAction.showToast({ message: "喷雾已关闭" });
  }
  async aboutToAppear() {
    this.requestLocation()
    this.localAddr = {
      family: 1,
      port: 8889,
      address: resolveIP(wifi.getIpInfo().ipAddress)
    }
    //接收者的ip地址
    this.mixerAddr = {
      address: '192.168.191.19',
      port: 8889
    }

    setTimeout(async () => {
      let farmland: farmland[] = await Farmland_db.getAllFarmlands()
      if (farmland.length == 0) {
        AlertDialog.show({ message: "还没有农田哦，快去录入吧~" })
      }
      for (let item of await Farmland_db.getAllFarmlands()) {
        this.arr_farmland.push(item)
        console.log("q_farmland" + JSON.stringify(item))
      }

      console.log("open_arr_farmland:" + JSON.stringify(this.arr_farmland))
      setTimeout(async () => {
        await tcp.getData()
        console.log("Tcp_get_data : " + Data_Tcp)
        this.analyze_data(Data_Tcp)
        await _IoTad.get_data()
        await this.new_analyze_data(DATA_new)
        Data_Id_me = Data_id_yun
        try {
          let sensorData = await getSensorData();
          this.temp = sensorData.temperature.toString();
          this.humi = sensorData.humidity.toString();
          this.co2 = sensorData.co2.toString();

          promptAction.showToast({ message: "✅ 后端数据加载成功" });
        } catch (err) {
          promptAction.showToast({ message: "❌ 连接后端失败" });
        }
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
        // 全局记录
        this.globalWarnHistory.unshift({
          typeText: "温度过高警告",
          data: temp,
          time: new Date().toLocaleString()
        });
        // 当前农田记录
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
      }
    }
    if (co2 != null) {
      console.log("co2:::")
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
      }
    }

    let notificationRequest: notificationManager.NotificationRequest = {
      id: 1,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT, // 普通文本类型通知
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
  // ========== 定位功能 ==========
  async requestLocation() {
    const permissions: Array<Permissions> = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION'];
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      const result = await atManager.requestPermissionsFromUser(getContext(this) as common.UIAbilityContext, permissions);
      const granted = result.authResults.every(r => r === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
      if (granted) {
        this.getCurrentLocation();
      } else {
        this.locationText = '授权失败，无法获取位置';
      }
    } catch (err) {
      console.error('权限请求异常', err);
      this.locationText = '权限请求异常';
    }
  }

  async getCurrentLocation() {
    if (!geoLocationManager.isLocationEnabled()) {
      this.locationText = '请前往系统设置开启位置服务';
      return;
    }

    try {
      const location = await geoLocationManager.getCurrentLocation({
        timeoutMs: 10000
      });
      this.locationText = `正在获取地址`;
      // 可选：调用逆地理编码获取地址
      this.getAddress(location.latitude, location.longitude);
    } catch (err) {
      console.error('获取位置失败', err);
      this.locationText = '获取位置失败';
    }
  }

  async getAddress(lat: number, lng: number) {
      console.info('开始逆地理编码，坐标：', lat, lng);
    const reverseRequest: geoLocationManager.ReverseGeoCodeRequest = {
      latitude: lat,
      longitude: lng,
      maxItems: 1
    };
    try {
      const result = await geoLocationManager.getAddressesFromLocation(reverseRequest);
      if (result && result.length > 0) {
        this.locationText = ` ${result[0].placeName}`;
      }
    } catch (err) {
      console.error('逆地理编码失败', err);
    }
  }
  analyze_data(data: string) {
    let arr: string[] = data.split("/")
    for (let item of arr) {
      console.log("TCP data:" + item)
      let values: string = JSON.parse(item)
      if (typeof values?.["temp"] != "undefined") {
        this.temp = values?.["temp"]
        this.humi = values?.["humi"]
        this.judge(Number(this.temp), Number(this.humi), Number())
        console.log("udp send temp" + this.temp + "::" + this.humi)
      } else {
        let new_arr_farmland: farmland[] = []
        for (let r of this.arr_farmland) {
          let new_arr_f: Device[] = []
          for (let f of r.device_s) {
            if (f.type_id == values?.["id"]) {
              if (typeof values?.["lighting"] != "undefined") {
                f = new Device(f.name, values?.["switch"], values?.["id"])
                f.lighting = values?.["lighting"]
                console.log("udp send t" + f.switch + "::" + f.lighting + '::' + f.type_id)
              } else if (typeof values?.["a_temp"] != "undefined") {
                f = new Device(f.name, values?.["switch"], values?.["id"])
                f.temp = values?.["a_temp"]
                f.mode = values?.["mode"]
              } else {
                f = new Device(f.name, values?.["switch"], values?.["id"])
                console.log("udp send t" + f.switch + "::" + f.type_id)
              }
            }
            new_arr_f.push(f)
          }
          new_arr_farmland.push(new farmland(r.name, new_arr_f))
          console.log("UDP Farmland NEW" + JSON.stringify(r))
        }
        this.arr_farmland = new_arr_farmland
      }
    }
  }

  //{"temperature":16,"humidity":0,"co2":0,"motion_state":1,"door_state":0,"brightness":500,"1001":1,"1102":1,"2001":0,"3001_2":0,"4001":0,"3001_1":0,"3001_3":0}
  async new_analyze_data(data: string) {
    //data = "{\"temperature\":49,\"humidity\":85,\"co2\":0,\"motion_state\":1,\"door_state\":0,\"brightness\":3000,\"1001\":1,\"1102\":1,\"2001\":1,\"3001_2\":22,\"4001\":1,\"3001\":1,\"3001_3\":\"zl\"}"

    console.log("IoTad data:" + data)
    let values: string = JSON.parse(data)
    if (typeof values?.["temperature"] != "undefined") {
      this.temp = values?.["temperature"]
      this.humi = values?.["humidity"]
      this.co2 = "1900"
      //this.co2 = values?.['co2']
      this.judge(Number(this.temp), Number(this.humi), Number(this.co2))
      console.log("IoTad send temp" + this.temp + "::" + this.humi)
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
              console.log("temperature_control_device:::" + JSON.stringify(f))
              f = new Device(f.name, values?.[f.type_id.toString()], f.type_id)
              f.temp = Number(values?.[f.type_id.toString() + "_2"])
              f.mode = values?.[f.type_id.toString() + "_3"]
              console.log("temperature_control_device:::" + JSON.stringify(f))
            } else {
              f = new Device(f.name, values?.[f.type_id.toString()], f.type_id)
            }
          }
          new_arr_f.push(f)
        }
        new_arr_farmland.push(new farmland(r.name, new_arr_f))
        console.log("UDP Farmland NEW" + JSON.stringify(r))
      }
      this.arr_farmland = new_arr_farmland
    }
  }

  @Builder
  MenuBar() {
    Menu() {
      MenuItem({ content: '添加农田' }).onClick(() => {
        this.is_show_r = true
      })
      MenuItem({ content: "删除农田" }).onClick(() => {
        animateTo({ duration: 500 }, () => this.is_delete_h = "90%")
      })
    }
  }

  @Builder
  FarmlandCard(farmlandItem: farmland) {
    Column() {

      Row() {
        Column() {
          if (farmlandItem.avatar) {
            Image(farmlandItem.avatar)
              .width('100%')
              .height('100%')
              .borderRadius(8)
              .objectFit(ImageFit.Cover)
          } else {
            Text("农田头像")
              .fontSize(20)
              .fontColor('#666')
          }
        }
        .width('50%')
        .height(140)
        .backgroundColor('#f5f5f5')
        .borderRadius(8)
        .justifyContent(FlexAlign.Center)


        Column({ space: 10 }) {
          Text(farmlandItem.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333')

          Column({ space: 6 }) {
            Button("历史数据")
              .width('70%')
              .height(28)
              .fontSize(12)
              .backgroundColor('#f0f0f0')
              .fontColor('#333')
              .borderRadius(4)
              .onClick(() => {
                animateTo({ duration: 500 }, () => {
                  this._h_detail = "90%"
                  this.is_show_humidity = true
                })
              })

            Button("远程控制")
              .width('70%')
              .height(28)
              .fontSize(12)
              .backgroundColor('#f0f0f0')
              .fontColor('#333')
              .borderRadius(4)
              .onClick(() => {
                // 把当前点击的农田 赋值给全局变量
                this.currentFarm = farmlandItem;
                // 打开控制页面
                this.showRemoteControl = true;
              })

            Button("预警通知")
              .width('70%')
              .height(28)
              .fontSize(12)
              .backgroundColor('#f0f0f0')
              .fontColor('#333')
              .borderRadius(4)
              .onClick(() => {
                this.showWarnHistoryPanel = true;
                this.showGlobalHistory = false;
              })
          }
        }
        .width('50%')
        .justifyContent(FlexAlign.Start)
        .alignItems(HorizontalAlign.Center)
        .padding({left:30})
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.Start)
      .borderRadius(12)
      .shadow({
        color: '#0000001A',
        radius: 8,
        offsetX: 2,
        offsetY: 2
      })

    }
    .width('100%')
  }

  build() {
    Stack() {
      Scroll() {
        Column() {

          Column() {
            Row() {
              Text(this.locationText)
                .fontSize(16)
                .padding({
                  left: 10,
                  right: 5,
                  top: 10,
                  bottom: 5
                })
                .borderRadius(5)
              Image($r("app.media.search"))
                .width(22)
                .height(22)
                .margin({ right: 12 })
              Image($r("app.media.ic_alarm"))
                .width(20)
                .height(18)
                .padding({ right: 5 })
                .onClick(() => {
                  this.showGlobalHistory = true;
                  this.showWarnHistoryPanel = true;
                })

            }
            .width("100%")
            .margin({ bottom: 10 })

            Stack() {
              Column() {
                Column() {
                  Row() {
                    Image(this.avatarUri || $r("app.media.user"))
                      .width(50)
                      .height(50)
                      .borderRadius(25)
                      .margin({ right: 5 })

                    Column() {
                      Text(this.greetText)
                        .fontSize(19)
                        .fontWeight(FontWeight.Normal)
                      Text(this.nickName)
                        .fontSize(21)
                        .fontWeight(FontWeight.Medium)
                    }
                    .alignItems(HorizontalAlign.Start)

                  }
                  .width("100%")
                  .padding({ bottom: 10 })

                  Row() {
                    McLineChart({ options: this.serOption_temp })
                      .width('65%')
                      .height(200)
                    Column() {
                      Text(`${this.temp || '--'}°C`)
                        .fontSize(40)
                        .maxLines(1)
                        .textAlign(TextAlign.End)
                      Text("多云 | 东风")
                        .maxLines(1)
                        .textAlign(TextAlign.End)
                    }

                    .alignItems(HorizontalAlign.End)
                    .padding({ right: 10 })

                  }
                  .width("100%")
                  .alignItems(VerticalAlign.Center)
                  .justifyContent(FlexAlign.SpaceBetween)
                  .padding({ right: 10 })

                }

              }
              .width("100%")
              .padding(20)
              .backgroundColor(Color.White)
              .border({ width: 1, color: "#333" })
              .borderRadius(10)
            }
            .width("92%")
            .margin({ bottom: 20 })

            Row() {
              Column() {
                Text("湿度")
                  .fontSize(30)
                  .fontColor('#6d9cee')
                  .margin({ bottom: 10 })
                  .maxLines(1);

                Row({ space: 4 }) {
                  Text(`${this.humi || '--'}%`)
                    .fontSize(15)
                    .fontColor('#6d9cee');
                  if (this.humi) {
                    Text(getEnvStatus(Number(this.humi), 'humi').text)
                      .fontSize(12)
                      .fontColor(getEnvStatus(Number(this.humi), 'humi').color)
                      .backgroundColor(`${getEnvStatus(Number(this.humi), 'humi').color}10`)
                      .padding({
                        left: 3,
                        right: 3,
                        top: 1,
                        bottom: 1
                      })
                      .margin({ left: 3 })
                      .borderRadius(4)
                  }
                }
                .margin({ bottom: 3 });
              }
              .width("48%")
              .padding(12)
              .backgroundColor(Color.White)
              .border({ width: 1 })
              .borderRadius(10)

              Column() {
                Text("CO₂")
                  .fontSize(30)
                  .fontColor('#6d9cee')
                  .margin({ bottom: 10 })
                  .maxLines(1);

                Row({ space: 4 }) {
                  Text(`${this.co2 || '--'}ppm`)
                    .fontSize(15)
                    .fontColor('#6d9cee');
                  if (this.co2) {
                    Text(getEnvStatus(Number(this.co2), 'co2').text)
                      .fontSize(12)
                      .fontColor(getEnvStatus(Number(this.co2), 'co2').color)
                      .backgroundColor(`${getEnvStatus(Number(this.co2), 'co2').color}10`)
                      .padding({ left: 4, right: 8 })
                      .borderRadius(4)
                  }

                }
                .margin({ bottom: 3 });
              }
              .width("48%")
              .padding(12)
              .backgroundColor(Color.White)
              .border({ width: 1 })
              .borderRadius(10)
            }
            .width("90%")
            .justifyContent(FlexAlign.SpaceBetween)
            Row() {
              Text("我的农田")
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333')


              Blank()

              Text("管理农田")
                .fontSize(14)
                .fontColor('#4A90E2')
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .border({ width: 1, color: '#4A90E2' })
                .borderRadius(6)
                .bindMenu(this.MenuBar)
            }
            .width('90%')
            .justifyContent(FlexAlign.SpaceBetween)
            .margin({ top:16,bottom: 16 })

            Scroll() {
              Flex({ alignItems: ItemAlign.Center }) {
                ForEach(this.arr_farmland, (item: farmland) => {
                  Column({ space: 4 }) {
                    if (item.avatar) {
                      Image(item.avatar)
                        .width(60)
                        .height(60)
                        .borderRadius(30)
                        .objectFit(ImageFit.Cover)
                    } else {
                      Circle({ width: 60, height: 60 })
                        .fill(Color.White)
                        .stroke('#4A90E2')
                        .strokeWidth(2)
                    }
                    Text(item.name)
                      .fontSize(14)
                      .fontColor('#333')
                  }
                  .width('25%')
                  .alignItems(HorizontalAlign.Center)
                  .onClick(() => {
                    this.topFarm = item
                  })
                })
              }
              .padding(10)
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .width('100%')
            .margin({ bottom: 16 })

            List({ space: 16 }) {
              if (this.arr_farmland.length === 0) {
                ListItem() {
                  Column() {
                    Image($r("app.media.empty_farm"))
                      .width(80)
                      .height(80)
                      .margin({ bottom: 12 })
                    Text("暂无农田数据")
                      .fontSize(16)
                      .fontColor('#999999')
                    Text("点击右上角 + 号添加农田")
                      .fontSize(12)
                      .fontColor('#cccccc')
                      .margin({ top: 4 })
                  }
                  .width('100%')
                  .height(200)
                  .justifyContent(FlexAlign.Center)
                }
              } else {
                // 农田卡片列表
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
            .padding({ bottom: 20 })

          }
          .width("100%")
          .backgroundColor("#F5F5F5")

        }
        .width('100%')
      }
      .height('100%')
      .width('100%')

      if (this.is_show_r) {
        add_farmland_page({
          arr: $arr_farmland, // 双向绑定农田列表（新增后同步更新）
          is_show: $is_show_r // 双向绑定弹窗开关（关闭时同步隐藏）
        })
      }
      delete_farmland({ _h: this.is_delete_h, arr_farmland: this.arr_farmland })

      //显示温度详情数据
      if (this.is_show_humidity){
        detail_data({
        _h: this._h_detail,
        is_show: this.is_show_humidity,
        serOption_humi: this.serOption_humi,
        serOption_temp: this.serOption_temp,
        serOption_co2: this.serOption_co2
      })
      }
      // 全局预警历史面板（所有农田）
      if (this.showWarnHistoryPanel) {
        Column() {

          Button("返回")
            .onClick(() => {
              this.showWarnHistoryPanel = false;
            })
            .margin({ bottom: 10 });

          Text(this.showGlobalHistory ? "全部农田预警历史" : "当前农田预警记录")
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom:10 });

          Scroll() {
            Column({ space: 12 }) {
              if (this.currentFarmWarnHistory.length === 0) {
                Text("暂无预警记录")
                  .fontSize(16)
                  .fontColor("#999")
                 .margin({ top: 0 });
              } else {
                ForEach(this.currentFarmWarnHistory? this.globalWarnHistory : this.currentFarmWarnHistory,(item: WarnHistoryItem) => {
                  Column() {
                    Text(item.typeText)
                      .fontSize(16)
                      .fontColor(Color.Red)
                      .fontWeight(FontWeight.Bold);
                    Text("数值：" + item.data)
                      .fontSize(14);
                    Text("时间：" + item.time)
                      .fontSize(12)
                      .fontColor("#666");
                  }
                  .width("100%")
                  .backgroundColor(Color.White)
                  .padding(15)
                  .borderRadius(10)
                  .shadow({ radius: 5, color: "#1a000000" });
                });
              }
            }
            .width("100%")
            //.padding({ left:10, right:10, bottom:10, top:0 });
            .padding(10);

          }
          //.flexGrow(1)
          //.height("100%")
          //.layoutWeight(1);
        }
        .width("100%")
        .height("100%")
        .backgroundColor("#f5f5f5")
        .padding(10);
      }
      if (this.showRemoteControl) {
        RemoteControlPage({
          showPage: this.showRemoteControl,
          farm: this.currentFarm,
          temp: this.temp,   // 温度
          humi: this.humi,  // 湿度
          co2: this.co2,     // CO2
          currentFarm: $currentFarm, // 传双向绑定

        })
      }
    }
    .width('100%')
    .height('100%')
  }

  setGreetingByTime() {
    const hour = new Date().getHours();

    if (hour >= 5 && hour < 12) {
      this.greetText = "Good Morning";
    } else if (hour >= 12 && hour < 18) {
      this.greetText = "Good Afternoon";
    } else {
      this.greetText = "Good Evening";
    }
  }



}
@Component
export struct RemoteControlPage {
  @Link showPage: boolean;
  @Link farm: farmland | null ;
  @Prop temp: string = '';
  @Prop humi: string = '';
  @Prop co2: string = '';
  @Link currentFarm: farmland | null;
  @State showMyList: boolean = false;
  @State is_sleep: boolean = false;


  build() {
    Stack(){
      Column() {
        Row() {
          Text("< 返回")
            .fontSize(16)
            .fontColor("#007AFF")
            .onClick(() => {
              this.showPage = false;
            })
          Blank()
          Text("远程控制")
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          Blank()
        }
        .width("100%")
        .padding(12)
        .backgroundColor(Color.White)
        Column() {
          Row({ space: 15 }) {
            if (this.farm?.avatar) {
              Image(this.farm.avatar)
                .width(100)
                .height(100)
                .borderRadius(10)
                .objectFit(ImageFit.Cover)
            } else {
              Text("农田图片")
                .width(100)
                .height(90)
                .backgroundColor("#eee")
                .textAlign(TextAlign.Center)
            }

            Column({ space: 6 }) {
              Text(this.farm?.name || "未知农田")
                .fontSize(18)
                .fontWeight(FontWeight.Bold)

              Text("面积：8 亩")
                .fontSize(12)
                .fontColor("#666")
              Text("种类：普通品种")
                .fontSize(12)
                .fontColor("#666")
              Text("位置：一号园区")
                .fontSize(12)
                .fontColor("#666")
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width("85%")
          .padding(12)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ top: 100,bottom:5 })
          .shadow(10)        // 阴影：让卡片从背景里“浮”出来
          .borderWidth(1)    // 轻微边框：强化边缘，绝对不混色
          .borderColor('#f0f0f0')
        }
        .width("95%")
        .padding(15)
        .backgroundColor("#fff8f6f6") // 背景颜色（浅灰，可自定义）
        .borderRadius(16)
        .margin({ top: 10,bottom:10})
        .height(240)
        Row({ space: 10 }) {
          this.DataCard("温度", this.temp + "℃", "#ff6b6b")
          this.DataCard("湿度", this.humi + "%", "#4dabf7")
          this.DataCard("CO₂", this.co2 + "ppm", "#9775fa")
        }
        .width("90%")
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 15, bottom: 10 })

        Button("+ 添加设备")
          .width("90%")
          .height(48)
          .fontSize(12)
          .backgroundColor("#4A90E2")
          .fontColor(Color.White)
          .borderRadius(6)
          .margin({ top: 5, bottom: 5 })
          .onClick(() => {
            this.currentFarm = this.farm;
            this.showMyList = true;
          })
        Scroll() {
          Column({ space: 12 }) {
            if (this.farm?.device_s.length === 0) {
              Text("暂无设备，点击上方添加设备")
                .fontSize(16)
                .fontColor("#999")
                .margin({ top: 10 });
            }

            ForEach(this.farm?.device_s || [], (item: Device) => {
              this.ControlItem(item.name, item.switch === 1);
            })
          }
          .width("90%")
          .padding(0)
          .margin({ top: 0 })
        }
        .layoutWeight(1)
      }
      .width("100%")
      .height("100%")
      .backgroundColor("#F5F5F5")
      if (this.showMyList && this.currentFarm) {
        displayFarmland({
          currentFarm: this.currentFarm,
          is_sleep: $is_sleep,
          showList: $showMyList
        })
      }


    }
  }
  @Builder
  DataCard(title: string, value: string, color: string) {
    Column({ space: 6 }) {
      Text(title)
        .fontSize(14)
        .fontColor("#666")
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
    }
    .width('31%')
    .height(80)
    .backgroundColor(Color.White)
    .borderRadius(10)
    .justifyContent(FlexAlign.Center)
  }


  @Builder
  ControlItem(name: string, isOn: boolean) {
    Row() {
      Text(name)
        .fontSize(16)
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .onChange((value) => {
          if (value) {
            controlHardware({ led1: 5, led2: 0, led3: 0, spray: 0 });
            promptAction.showToast({ message: "✅ 已开启：" + name });
          } else {
            controlHardware({ led1: 0, led2: 0, led3: 0, spray: 0 });
            promptAction.showToast({ message: "✅ 已关闭：" + name });
          }
        })
    }
    .width("100%")
    .padding(14)
    .backgroundColor(Color.White)
    .borderRadius(10)
  }
}
@Component
struct detail_data {
  @Link is_show: boolean
  @Link serOption_humi: Options
  @Link serOption_temp: Options
  @Link serOption_co2: Options
  @State _w: string = "100%"
  @Link _h: string

  build() {
    Column() {
      if (this.is_show) {
      Button("返回")
        .onClick(() => {
          animateTo({ duration: 500 }, () => {
            this._h = "0%"
            this.is_show = false
          })
        })
        .margin({ bottom: 10 })

        Scroll() {
          Column() {
            Row() {
              Column() {
                Text("实时湿度")
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
              }.width("20%")
              McLineChart({ options: this.serOption_humi })
                .width("80%")
                .padding(10)
            }
            .width('100%')
            .padding(10)
            .height(400)
            .backgroundColor(Color.White)
            .margin({ bottom: 10 })
            .shadow({
              color: '#0000001A',
              radius: 10,
              offsetX: 2,
              offsetY: 2
            });
            Row() {
              Column() {
                Text("实时温度")
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
              }.width("20%")
              McLineChart({ options: this.serOption_temp })
                .width("80%")
                .padding(10)
            }
            .width('100%')
            .padding(10)
            .height(400)
            .backgroundColor(Color.White)
            .margin({ bottom: 10 })
            .shadow({
              color: '#0000001A',
              radius: 10,
              offsetX: 2,
              offsetY: 2
            });
            Row() {
              Column() {
                Text("实时CO₂浓度")
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
              }.width("20%")
              McLineChart({ options: this.serOption_co2 })
                .width("80%")
                .padding(10)
            }
            .width('100%')
            .padding(10)
            .height(400)
            .backgroundColor(Color.White)
            .margin({ bottom: 10 })
            .shadow({
              color: '#0000001A',
              radius: 10,
              offsetX: 2,
              offsetY: 2
            });
          }
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .padding(10)
      }
    }
    .width(this._w)
    .height(this.is_show ? "100%" : "0%")
    .backgroundColor(this.is_show ? '#f5f5f5' : Color.Transparent)
    .padding(this.is_show ? 10 : 0)
  }
}
@Component
struct delete_farmland {
  @Link arr_farmland: farmland[]
  @Link _h: string
  @State is_confirm:boolean = false
  @State confirm_index:string = ''

  build() {
    Stack(){
      Column() {
        Button("返回").onClick(()=>{
          animateTo({duration:500},()=>this._h = "0%")
        } )
          .backgroundColor(Color.White)
          .borderWidth(2)
          .borderColor('#6d9cee')
          .fontColor('#6d9cee')

        List({ space: 12 }) {
          ForEach(this.arr_farmland, (item: farmland,index) => {
            ListItem() {
              Row() {
                Text(item.name)
                  .fontSize(18)
                  .fontColor('#333')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({ left: 16 })

                Button("删除")
                  .onClick(() => this.showDeleteDialog(item.name))
                  .width(80)
                  .height(36)
                  .margin({ right: 16 })
                  .backgroundColor('#ffeeee')
                  .fontColor('#ff4444')
                  .borderRadius(6)
                  .borderWidth(1)
                  .borderColor('#ff8888')
                  .stateEffect(true)
              }
              .width('100%')
              .height(60)
              .backgroundColor(Color.White)
              .borderRadius(12)
            }
            .padding({ top: 8, bottom: 8 })
          })
        }
        .margin({ top: 20 })
        .width('90%')
        .flexGrow(1)
      }
      .height("100%")
      .width("100%")
      .backgroundColor('#f5f5f5')
      if(this.is_confirm){
        ConfirmDialog({arr_farmland:this.arr_farmland,is_show:this.is_confirm,name:this.confirm_index})
      }
    }.height(this._h)
    .width("100%")
  }

  private showDeleteDialog(item: string) {
    this.confirm_index = item
    animateTo({duration:300},()=>{
      this.is_confirm = true
    })
  }
}

@Component
struct ConfirmDialog{
  @Link is_show:boolean
  @Link arr_farmland:farmland[]
  @Link name:string
  build() {
    Stack(){
      Column()
        .width("100%")
        .height("100%")
        .backgroundColor("#11757575")
        .onClick(()=>{
          animateTo({duration:300},()=>{
            this.is_show = false
          })
        })
      Column() {
        Image($r('app.media.ic_warning'))
          .fillColor('#ff4444')
          .width(48)
          .height(48)
          .margin({ top: 24, bottom: 16 })

        Text(`删除「${this.name}」农田？`)
          .fontSize(20)
          .fontColor('#ff4444')
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })

        Text("删除后农田数据不可恢复，请谨慎操作！")
          .fontSize(14)
          .fontColor('#666')
          .margin({ bottom: 24 })

        Row() {
          Button('取消')
            .onClick(() => {
              animateTo({duration:300},()=>{
                this.is_show = false
              })
            })
            .width(120)
            .height(40)
            .backgroundColor('#ecf0f1')
            .fontColor('#34495e')
            .borderRadius(20)
            .stateEffect(true)

          Button('确认删除')
            .onClick(async () => {
              await Farmland_db.deleteFarmlandByName(this.name)
              this.arr_farmland = this.arr_farmland.filter(element => element.name !== this.name)
              animateTo({duration:300},()=>{
                this.is_show = false
              })
            })
            .width(120)
            .height(40)
            .margin({ left: 20 })
            .backgroundColor('#ff4444')
            .fontColor(Color.White)
            .borderRadius(20)
            .stateEffect(true)
        }
        .margin({ bottom: 24 })
      }.height("40%")
      .width('80%')
      .backgroundColor(Color.White)
      .borderRadius(16)
    }
    .width("100%")
    .height("100%")
  }
}
@Component
struct userpage {
  localstorage: LocalStoraga = new LocalStoraga("userData");
  @State username: string = '';
  @State f_arr: Device[] = [];
  @State _height: string = "0%";
  @State currentPage: string = 'main';
  @State avatarUri: string = '';
  @State nickName: string = '智慧农业';
  @State signText: string = '农场主';
  @State isNickDialogVisible: boolean = false;
  @State isSignDialogVisible: boolean = false;
  @State tempNick: string = '';
  @State tempSign: string = '';

  aboutToAppear() {
    this.localstorage.getDate("last_login").then(_User_ => {
      this.username = _User_ as string;
    });
    AppStorage.setOrCreate('globalAvatar', this.avatarUri);
    AppStorage.setOrCreate('globalNickName', this.nickName);
  }

  build() {
    Stack() {
      if (this.currentPage === 'main') {
        Column() {
          Column() {
            Row() {
              Text("个人中心")
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.Black)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
            .padding({ top: 15, bottom: 10 })

            Row() {
              Image(this.avatarUri || $r("app.media.user"))
                .width(60)
                .height(60)
                .borderRadius(30)
                .backgroundColor(Color.White)
                .onClick(() => {
                  this.selectAvatar();
                })
              Column() {
                Text(this.nickName)
                  .fontSize(22)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.Black)
                  .onClick(() => {
                    this.tempNick = this.nickName;
                    this.isNickDialogVisible = true;
                  })

                Text(this.signText)
                  .fontSize(14)
                  .fontColor('#666666')
                  .onClick(() => {
                    this.tempSign = this.signText;
                    this.isSignDialogVisible = true;
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .margin({ left: 12 })
              .flexGrow(1)
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 15 })
          }
          .width('100%')
          .backgroundColor('#E8F5E9')

          Row() {
            Row() {
              Text("⚙️")
                .fontSize(20)
                .margin({ right: 8 })
              Column() {
                Text("农业设置")
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(Color.White)
                Text("农场参数与环境阈值配置")
                  .fontSize(12)
                  .fontColor(Color.White)
              }
              .alignSelf(ItemAlign.Start)
            }
            .flexGrow(1)

            Button("关于中心")
              .fontSize(14)
              .fontColor(Color.Black)
              .backgroundColor('#FFE8B0')
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .onClick(() => this.currentPage = 'about')
          }
          .width('92%')
          .backgroundColor('#374151')
          .borderRadius(12)
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .margin({ top: 10, bottom: 16 })

          Column() {
            Text("个人信息")
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .width('100%')
              .padding({ left: 16, top: 12, bottom: 12 })

            Row() {
              this.QuickItem("个人信息", "🏠")
              this.QuickItem("农场管理", "📋")
              this.QuickItem("系统设置", "⚙️")
              this.QuickItem("帮助中心", "❓")
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
            .padding({ bottom: 12 })
          }
          .width('100%')
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ left: 16, right: 16 })

          Scroll() {
            Column({ space: 0 }) {
              this.MenuItem("设备管理", () => {})
              this.MenuItem("地块管理", () => {})
              this.MenuItem("数据报表", () => {})
              this.MenuItem("通知设置", () => {})
              this.MenuItem("帮助与反馈", () => {})
              this.MenuItem("账号设置", () => this.currentPage = 'account')
              this.MenuItem("关于智慧农田系统", () => this.currentPage = 'about')
              this.MenuItem("退出登录", () => {
                this.localstorage.setDate('is_land', false);
                router.replaceUrl({ url: 'pages/Open' });
              })
              Text('')
                .height(20)
            }
            .width('100%')
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ left: 16, right: 16, top: 16 })
            .padding({ top: 8, bottom: 8 })
          }
          .flexGrow(1)
          .height(0)
        }

        .width('100%')
        .height('100%')
        .backgroundColor('#F3F4F6')
      }
      else if (this.currentPage === 'account') {
        Column() {
          AccountSetting({
            onBack: () => { this.currentPage = 'main' }
          })
        }
        .width('100%')
        .height('100%')
      }
      else if (this.currentPage === 'about') {
        Column() {
          AboutProject({
            onBack: () => { this.currentPage = 'main' }
          })
        }
        .width('100%')
        .height('100%')
      }
      this.NickNameDialog()
      this.SignTextDialog()
    }
    .width('100%')
    .height('100%')
  }
  @Builder NickNameDialog() {
    if (this.isNickDialogVisible) {
      Column() {
        Text("修改用户名")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 15, bottom: 10 })
        TextInput({ text: this.tempNick })
          .width('80%')
          .height(40)
          .margin({ bottom: 20 })
          .onChange((value) => {
            this.tempNick = value; // 实时同步输入
          })
        Row() {
          Button("取消")
            .width(80)
            .onClick(() => {
              this.isNickDialogVisible = false;
            })
          Button("确定")
            .width(80)
            .margin({ left: 20 })
            .onClick(() => {
              this.nickName = this.tempNick ;
              AppStorage.setOrCreate('globalNickName', this.nickName);
              this.isNickDialogVisible = false;
            })
        }
      }
      .width('90%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .align(Alignment.Center)
      .position({ x: '5%', y: '30%' })
    }
  }
  @Builder SignTextDialog() {
    if (this.isSignDialogVisible) {
      Column() {
        Text("修改签名")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 15, bottom: 10 })
        TextInput({ text: this.tempSign })
          .width('80%')
          .height(40)
          .margin({ bottom: 20 })
          .onChange((value) => {
            this.tempSign = value; // 实时同步输入
          })
        Row() {
          Button("取消")
            .width(80)
            .onClick(() => {
              this.isSignDialogVisible = false;
            })
          Button("确定")
            .width(80)
            .margin({ left: 20 })
            .onClick(() => {
              this.signText = this.tempSign ;
              this.isSignDialogVisible = false;
            })
        }
      }
      .width('90%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .align(Alignment.Center)
      .position({ x: '5%', y: '30%' })
    }
  }

  @Builder
  QuickItem(title: string, icon: string) {
    Column() {
      Text(icon)
        .fontSize(28)
        .margin({ bottom: 4 })
      Text(title)
        .fontSize(12)
        .fontColor('#4B5563')
    }
    .alignSelf(ItemAlign.Center)
  }

  @Builder
  MenuItem(title: string, onClick: () => void) {
    Row() {
      Text(this.getIconForTitle(title))
        .fontSize(24)
        .fontColor('#4B5563')
        .margin({ right: 12 })

      Text(title)
        .fontSize(16)
        .fontColor('#1F2937')
        .fontWeight(FontWeight.Medium)
        .flexGrow(1)

      Text(">")
        .fontSize(20)
        .fontColor('#9CA3AF')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 14, bottom: 14 })
    .backgroundColor(Color.White)
    .onClick(onClick)

    if (title !== "退出登录") {
      Divider()
        .width('90%')
        .color('#E5E7EB')
    }
  }

  getIconForTitle(title: string): string {
    switch (title) {
      case "设备管理": return "📡";
      case "地块管理": return "🌾";
      case "数据报表": return "📊";
      case "通知设置": return "🔔";
      case "帮助与反馈": return "❓";
      case "账号设置": return "👤";
      case "关于智慧农田系统": return "ℹ️";
      case "退出登录": return "🚪";
      default: return "📋";
    }
  }
  // 选择头像
  async selectAvatar() {
    let photoPicker = new picker.PhotoViewPicker();
    let option = new picker.PhotoSelectOptions();
    option.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
    option.maxSelectNumber = 1;
    try {
      let result = await photoPicker.select(option);
      if (result.photoUris.length > 0) {
        this.avatarUri = result.photoUris[0];
        AppStorage.setOrCreate('globalAvatar', this.avatarUri);
      }
    } catch (err) {
      console.error("选择头像失败", err);
    }
  }

  }


@Entry
@Component
struct Index {
  @State arr_farmland:farmland[] = []
  @State selectnumber:number = 0;
  @State is_show_humidity:boolean = false
  @State is_warn:boolean = false
  @State warn_data:Datamodel={type:'',arr:[],data:0}
  @State _height_AI:string = "0%"
  @State is_show_AI:boolean = false
  @State _height_AI_com:string = '10%'
  @State is_show_lights: boolean = false
  @State is_show_temperature_control_device: boolean = false
  @State is_show_robot: boolean = false
  @State is_show_waterValve: boolean = false
  @State is_show_dan: boolean = false
  @State edit_f: Device = new Device("", 0, 0)


  @Builder
  MyBuilder_user (title:string,num:number){
    Column(){
      Row().width("100%").height(15)
      Image($r("app.media.user"))
        .height(num==this.selectnumber?20:10)
        .width(num==this.selectnumber?20:10)
        .fillColor(num==this.selectnumber?'#4A90E2':Color.White)

      Text(title)
        .fontColor(num==this.selectnumber?'#4A90E2':Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundImage(num == this.selectnumber ? $r('app.media.farm_bg') : $r('app.media.bottom_bg2'))
    .backgroundImageSize(ImageSize.Cover)
  }

  @Builder
  MyBuilder_add(title: string, num: number) {
    Column() {
      Row().width("100%").height(15);
      Image($r("app.media.add"))
        .height(num == this.selectnumber ? 20 : 10)
        .width(num == this.selectnumber ? 20 : 10)
        .fillColor(num == this.selectnumber ? '#4A90E2' : Color.White);

      Text("智能场景")
        .fontColor(num == this.selectnumber ? '#4A90E2' : Color.White);
    }
    .width('100%')
    .height('100%')
    .backgroundImage(num == this.selectnumber ? $r('app.media.farm_bg') : $r('app.media.bottom_bg2'))
    .backgroundImageSize(ImageSize.Cover)
  }

  @Builder
  MyBuilder_home(title: string, num: number) {
    Column() {
      Row().width("100%").height(15);
      Image($r("app.media.ic_water"))
        .height(num == this.selectnumber ? 20 : 10)
        .width(num == this.selectnumber ? 20 : 10)
        .fillColor(num == this.selectnumber ? '#4A90E2' : Color.White);

      Text("农场总览")
        .fontColor(num == this.selectnumber ? '#4A90E2' : Color.White);
    }
    .width('100%')
    .height('100%')
    .backgroundImage(num == this.selectnumber ? $r('app.media.farm_bg') : $r('app.media.bottom_bg2'))
    .backgroundImageSize(ImageSize.Cover)
  }
  @Builder
  MyBuilder_analysis(title:string,num:number){
    Column(){
      Row().width("100%").height(15)
      Image($r("app.media.user"))
        .height(num==this.selectnumber?20:10)
        .width(num==this.selectnumber?20:10)
        .fillColor(num==this.selectnumber?'#4A90E2':Color.White)

      Text(title)
        .fontColor(num==this.selectnumber?'#4A90E2':Color.White)
    }
    .width('100%')
    .height('100%')
    .backgroundImage(num == this.selectnumber ? $r('app.media.farm_bg') : $r('app.media.bottom_bg2'))
    .backgroundImageSize(ImageSize.Cover)
  }
  build() {
    Stack() {
      Column(){
        Tabs({ barPosition:BarPosition.End }){
          //主页面
          TabContent(){
            homepage({is_warn:this.is_warn,warn_data:this.warn_data,arr_farmland:this.arr_farmland})
          }
          .tabBar(this.MyBuilder_home("农场总览",0))
          TabContent(){
            DataAnalysisPage()
          }
          .tabBar(this.MyBuilder_analysis("数据分析",1))
          TabContent(){
            FarmScenePage({arr_farmland:this.arr_farmland})
          }
          .tabBar(this.MyBuilder_add("智能场景",2))

          TabContent(){
            userpage()
          }.tabBar(this.MyBuilder_user("个人中心",3))

        }
        .width('100%')
        .height('100%')
        .onChange((index:number)=> {
          this.selectnumber = index
        })
        .animationDuration(10)
      }
      .height('100%')
      .width('100%')
      .backgroundColor("#E6F2FF");

      Button("AI")
        .backgroundImage($r('app.media.ai_bg2'))
        .backgroundImageSize(ImageSize.Cover)
        .fontColor("#a8474545")
        .shadow({
          radius: 5,
          offsetX: 12,
          offsetY: 12,
          color: "#a8474545"
        })
        .onClick(()=>{
          this.is_show_AI = true
          animateTo({duration:500},()=>{
            this._height_AI = "100%"
          })
        })
        .position({x:"83%",y:"80%"})
        .width(60)
        .height(60)
        .borderRadius(30)

      if(this.is_show_AI){
        my_DeepSeek({is_show:this.is_show_AI,_height_AI:this._height_AI,_height:this._height_AI_com})
      }

      //最上层警告弹窗
      if(this.is_warn){
        WarnPage({warn_data:this.warn_data,is_warn:this.is_warn})
      }
    }
    .height('100%')
    .width('100%')
  }
}

export class Datamodel{
  type:string = ''
  arr:farmland[] = []
  data:number = 0
}

@Component
export struct WarnPage {
  title:string = "warning!!"
  @Link warn_data:Datamodel
  @State Warn_f_list:Device[] = []
  @State have_temperature_control_device:boolean = false
  @State have_fan:boolean = false
  @Link is_warn:boolean
  @State a_id:number = 0
  @State Air_c:Device = new Device("",0,0)

  aboutToAppear(): void {
    for(let r of this.warn_data.arr){
      for(let f of r.device_s){
        if(f.type_id<4000&&f.type_id>2999){
          this.Warn_f_list.push(f)
          this.have_temperature_control_device = true
          this.a_id = f.type_id
          this.Air_c = f
        }
        if(f.type_id>3999&&f.type_id<5000){
          this.Warn_f_list.push(f)
          this.have_fan = true
        }
      }
    }
  }

  build() {
    Stack() {
      Image($r('app.media.warning_bg2'))
        .objectFit(ImageFit.Cover)

      if (this.warn_data.type == 'temp') {
        Column() {
          Image($r('app.media.ic_warning'))
            .fillColor(Color.Red)
            .width(100)
            .height(100)

          Text(this.warn_data.data.toString())
            .fontColor(Color.Red)
            .fontSize(100);
          Text("***温度警告***")
            .fontSize(18);
          Text("目前温度已超过作物生长安全标准，请及时处理！")
            .margin(10)
            .fontSize(16);

          Button(this.have_temperature_control_device ? "启动温控设备" : "开窗通风")
            .backgroundColor('#ffdceffa')
            .width("50%")
            .height(50)
            .borderRadius(5)
            .borderWidth(2)
            .borderColor('#4A90E2')
            .fontColor('#4A90E2')
            .margin(10)
            .padding({ left: 15, right: 15 })
            .onClick(async () => {
              if (this.have_temperature_control_device) {
                await tcp.send_on(this.a_id)
                await _IoTad.set_temperature_control_device_by_id(25,"on","zl");
              }
              this.is_warn = false;
            });

          Row().height(5)

          Button("稍后处理")
            .onClick(()=>{this.is_warn = false;})
            .backgroundColor('#ffeeee')
            .width("50%")
            .height(50)
            .borderRadius(5)
            .borderWidth(2)
            .borderColor(Color.Red)
            .fontColor(Color.Red)
        }
      }

      if (this.warn_data.type == 'humi') {
        Column() {
          Row(){
            Image($r('app.media.ic_warning'))
              .fillColor(Color.Red)
              .width(100)
              .height(100)

            Text(this.warn_data.data.toString())
              .fontColor(Color.Red)
              .fontSize(100);
          }

          Text("***湿度警告***")
            .fontSize(18);
          Text("目前湿度已超过作物生长安全标准，易引发病害！")
            .fontSize(16);

          Button(this.have_temperature_control_device ? "启动温控设备除湿" : "开窗通风")
            .backgroundColor('#ffdceffa')
            .width("50%")
            .height(50)
            .borderRadius(5)
            .borderWidth(2)
            .borderColor('#4A90E2')
            .fontColor('#4A90E2')
            .padding({ left: 15, right: 15 })
            .onClick(async () => {
              if (this.have_temperature_control_device) {
                await tcp.send_on(this.a_id)
                await _IoTad.set_temperature_control_device_by_id(25,"on","cs");
              }
              this.is_warn = false;
            });

          Row().height(5)

          Button("稍后处理")
            .onClick(()=>{this.is_warn = false;})
            .backgroundColor('#ffeeee')
            .width("50%")
            .height(50)
            .borderRadius(5)
            .borderWidth(2)
            .borderColor(Color.Red)
            .fontColor(Color.Red)
        }
      }

      if (this.warn_data.type == 'co2') {
        Column() {
          Image($r('app.media.ic_warning'))
            .fillColor(Color.Red)
            .width(100)
            .height(100)

          Text(this.warn_data.data.toString())
            .fontColor(Color.Red)
            .fontSize(100);
          Text("***CO₂浓度警告***")
            .fontSize(18);
          Text("目前CO₂浓度已超过安全标准，影响作物光合作用！")
            .fontSize(16);
          Button(this.have_fan ? "启动排风扇" : "开窗通风")
            .backgroundColor('#ffdceffa')
            .width("50%")
            .height(50)
            .borderRadius(5)
            .borderWidth(2)
            .borderColor('#4A90E2')
            .fontColor('#4A90E2')
            .padding({ left: 15, right: 15 })
            .onClick(async () => {
              if (this.have_temperature_control_device) {
                await tcp.send_on(this.a_id)
                await _IoTad.set_fan_by_id("on");
              }
              this.is_warn = false;
            });

          Row().height(5)

          Button("稍后处理")
            .onClick(()=>{this.is_warn = false;})
            .backgroundColor('#ffeeee')
            .width("50%")
            .height(50)
            .borderRadius(5)
            .borderWidth(2)
            .borderColor(Color.Red)
            .fontColor(Color.Red)
        }
      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor("#E6F2FF");
  }
}

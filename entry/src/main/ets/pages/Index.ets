import { McLineChart, Options } from '@mcui/mccharts'
import util from '@ohos.util';
import router from '@ohos.router';
import { temperature_control_device, Device, farmland } from '../tool/classes';
import { displayFarmland, my_DeepSeek,add_farmland_page,FarmlandOverview,AccountSetting,AboutProject} from '../tool/component';
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
struct homepage{

  @State serOption_temp:Options = new Options({
    xAxis:{data:["0:00","3:00","6:00","9:00","12:00","15:00","18:00","21:00"]},
    yAxis:{name:'温度(℃)'},
    series:[{
      name:'实时温度',
      data:[14,16,17,18,22,22,21,18],
      color:"#dd00dd",
      arcLineWidth:100
    }]
  })
  @State serOption_humi:Options = new Options({
    xAxis:{data:["0:00","3:00","6:00","9:00","12:00","15:00","18:00","21:00"]},
    yAxis:{name:'湿度(%)'},
    series:[{
      name:'实时湿度',
      data:[88,89,86,78,79,85,88,77],
      color: "#ff039f96",
      arcLineWidth:100
    }]
  })
  @State serOption_co2:Options = new Options({
    xAxis:{data:["0:00","3:00","6:00","9:00","12:00","15:00","18:00","21:00"]},
    yAxis:{name:'CO₂浓度(ppm)'},
    series:[{
      name:'实时CO₂浓度',
      data:[11,10,2,11,22,66,10,60],
      color: "#ffddb801",
      arcLineWidth:100
    }]
  })

  private localAddr:socket.NetAddress |null = null
  private mixerAddr:socket.NetAddress |null = null
  @State _h_detail:string = '0%'
  @State num1:string = '';
  @State num2:string = '';
  @State is_Lock:boolean = false
  @State is_show_r:boolean = false
  @State is_sleep:boolean = false
  @State is_chang:boolean = false
  @State is_delete_h:string= "0%"
  @Link arr_farmland:farmland[]
  @State is_show_humidity:boolean = false
  @State _height:string = "20%"
  @State backG:string = "app.media.back_house"
  @State _width:string = '90%'
  @State temp:string = ''
  @State humi:string = ''
  @State co2:string = ''
  @State currentFarm: farmland | null = null;
  @State showMyList: boolean = false;
  @Link is_warn:boolean
  @Link warn_data:Datamodel

  async aboutToAppear() {
    this.localAddr = {
      family: 1,
      port: 8889,
      address: resolveIP(wifi.getIpInfo().ipAddress)
    }
    //接收者的ip地址
    this.mixerAddr = {
      address:'192.168.191.19',
      port:8889
    }

    setTimeout(async ()=>{
      let farmland:farmland[] = await Farmland_db.getAllFarmlands()
      if(farmland.length == 0){
        AlertDialog.show({message:"还没有农田哦，快去录入吧~"})
      }
      for (let item of await Farmland_db.getAllFarmlands()) {
        this.arr_farmland.push(item)
        console.log("q_farmland"+JSON.stringify(item))
      }

      console.log("open_arr_farmland:"+JSON.stringify(this.arr_farmland))
      setTimeout(async ()=>{
        await tcp.getData()
        console.log("Tcp_get_data : "+Data_Tcp)
        this.analyze_data(Data_Tcp)
        await _IoTad.get_data()
        await this.new_analyze_data(DATA_new)
        Data_Id_me = Data_id_yun

      },1000)

      setInterval(async ()=>{
        if(Data_Id_me != Data_id_yun){
          DATA_IoTda = DATA_new
          await this.new_analyze_data(DATA_IoTda)
        }
      },1000)
    },100)
  }

  async judge(temp?:number,humi?:number,co2?:number){
    let title:string = ''
    if(temp != null){
      if(temp>max_temp) {
        let paramInfo: Datamodel = {
          type: "temp",
          data: temp,
          arr: await Farmland_db.getAllFarmlands()
        }
        this.warn_data = paramInfo
        this.is_warn = true
        title = "温度过高"
      }
    }
    if(humi != null) {
      if (humi > max_humi) {
        let paramInfo: Datamodel = {
          type: "humi",
          data: humi,
          arr: await Farmland_db.getAllFarmlands()
        }
        this.warn_data = paramInfo
        this.is_warn = true
        title = "湿度过高"
      }
    }
    if(co2 != null){
      console.log("co2:::")
      if(co2>max_co2) {
        let paramInfo: Datamodel = {
          type: "co2",
          data: co2,
          arr: await Farmland_db.getAllFarmlands()
        }
        this.warn_data = paramInfo
        this.is_warn = true
        title = "co2浓度过高"
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
        hilog.error(DOMAIN_NUMBER, TAG, `Failed to publish notification. Code is ${err.code}, message is ${err.message}`);
        return;
      }
      hilog.info(DOMAIN_NUMBER, TAG, 'Succeeded in publishing notification.');
    });
  }

  analyze_data(data:string){
    let arr:string[] = data.split("/")
    for(let item of arr){
      console.log("TCP data:"+item)
      let values:string = JSON.parse(item)
      if(typeof values?.["temp"] != "undefined") {
        this.temp = values?.["temp"]
        this.humi = values?.["humi"]
        this.judge(Number(this.temp),Number(this.humi),Number())
        console.log("udp send temp"+this.temp+"::"+this.humi)
      }else {
        let new_arr_farmland:farmland[] = []
        for (let r of this.arr_farmland){
          let new_arr_f:Device[] = []
          for (let f of r.device_s){
            if(f.type_id ==values?.["id"]){
              if(typeof values?.["lighting"] != "undefined") {
                f = new Device(f.name,values?.["switch"],values?.["id"])
                f.lighting = values?.["lighting"]
                console.log("udp send t"+f.switch+"::"+f.lighting+'::'+f.type_id)
              }else if(typeof values?.["a_temp"] != "undefined"){
                f = new Device(f.name,values?.["switch"],values?.["id"])
                f.temp = values?.["a_temp"]
                f.mode = values?.["mode"]
              }
              else {
                f = new Device(f.name,values?.["switch"],values?.["id"])
                console.log("udp send t"+f.switch+"::"+f.type_id)
              }
            }
            new_arr_f.push(f)
          }
          new_arr_farmland.push(new farmland(r.name,new_arr_f))
          console.log("UDP Farmland NEW"+JSON.stringify(r))
        }
        this.arr_farmland = new_arr_farmland
      }
    }
  }

  //{"temperature":16,"humidity":0,"co2":0,"motion_state":1,"door_state":0,"brightness":500,"1001":1,"1102":1,"2001":0,"3001_2":0,"4001":0,"3001_1":0,"3001_3":0}
  async new_analyze_data(data:string){
    //data = "{\"temperature\":49,\"humidity\":85,\"co2\":0,\"motion_state\":1,\"door_state\":0,\"brightness\":3000,\"1001\":1,\"1102\":1,\"2001\":1,\"3001_2\":22,\"4001\":1,\"3001\":1,\"3001_3\":\"zl\"}"

    console.log("IoTad data:"+data)
    let values:string = JSON.parse(data)
    if(typeof values?.["temperature"] != "undefined") {
      this.temp = values?.["temperature"]
      this.humi = values?.["humidity"]
      this.co2 = values?.['co2']
      this.judge(Number(this.temp),Number(this.humi),Number(this.co2 ))
      console.log("IoTad send temp"+this.temp+"::"+this.humi)
      let new_arr_farmland:farmland[] = []
      for (let r of this.arr_farmland){
        let new_arr_f:Device[] = []
        for (let f of r.device_s){
          if(typeof values?.[f.type_id.toString()] != "undefined"){
            let new_v:string = values?.[f.type_id.toString()]
            new_v = JSON.parse(new_v)
            if(f.type_id<999){
              f = new Device(f.name,values?.[f.type_id.toString()],f.type_id)

            }else if(f.type_id<1999){
              f = new Device(f.name,values?.[f.type_id.toString()],f.type_id)
              f.lighting = (values?.["brightness"])/1000

            }else if(f.type_id<2999){
              f = new Device(f.name,values?.[f.type_id.toString()],f.type_id)

            }else if(f.type_id<3999&&f.type_id>3000){
              console.log("temperature_control_device:::"+JSON.stringify(f))
              f = new Device(f.name,values?.[f.type_id.toString()],f.type_id)
              f.temp = Number(values?.[f.type_id.toString()+"_2"])
              f.mode = values?.[f.type_id.toString()+"_3"]
              console.log("temperature_control_device:::"+JSON.stringify(f))
            }else{
              f = new Device(f.name,values?.[f.type_id.toString()],f.type_id)
            }
          }
          new_arr_f.push(f)
        }
        new_arr_farmland.push(new farmland(r.name,new_arr_f))
        console.log("UDP Farmland NEW"+JSON.stringify(r))
      }
      this.arr_farmland = new_arr_farmland
    }
  }

  @Builder
  MenuBar(){
    Menu(){
      MenuItem({content:'添加农田'}).onClick(()=>{
        this.is_show_r = true
      })
      MenuItem({content:"删除农田"}).onClick(()=>{
        animateTo({duration:500},()=>this.is_delete_h = "90%")
      })
    }
  }

  @Builder
  FarmlandCard(farmlandItem: farmland) {
    Column() {
      Row() {
        Row(){Image($r("app.media.farm_icon"))
          .width(24)
          .height(24)
          .fillColor('#4A90E2')
          .margin({ right: 8 })
          Text(farmlandItem.name)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ left: 6 })
        }
        Text("+")
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#4A90E2')
          .onClick(() => {
            this.currentFarm = farmlandItem;
            this.showMyList = true;
          })
      }
      .width('100%')
      .margin({ bottom: 12 })
      .justifyContent(FlexAlign.SpaceBetween)
      Grid() {
        ForEach(farmlandItem.device_s.slice(0, 4), (device: Device) => {
          GridItem() {
            Column() {
              Text(device.name)
                .fontSize(12)
                .fontColor('#666666')
                .margin({ bottom: 4 })
              Text(device.switch ? '运行中' : '已关闭')
                .fontSize(10)
                .fontColor(device.switch ? '#4cd964' : '#999999')
            }
            .width('100%')
            .height(40)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#f8f8f8')
            .borderRadius(6)
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width('100%')
      Button('进入管理')
        .width('100%')
        .height(36)
        .margin({ top: 12 })
        .backgroundColor('#4A90E2')
        .fontColor(Color.White)
        .borderRadius(6)
        .onClick(() => {
          // 这里可以跳转到农田详情页
          // router.pushUrl({ url: 'pages/FarmDetail', params: { farmlandName: farmlandItem.name } })
          AlertDialog.show({ message: `进入${farmlandItem.name}管理页面` })
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({
      color: '#0000001A',
      radius: 8,
      offsetX: 2,
      offsetY: 2
    })
  }

  build() {
    Column(){
      Row(){
        Stack(){
          Row(){
            //Column().width("25%")
            Column(){
              Text("农场环境概览")
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#4A90E2')
                .margin({ bottom: 10 })
                .width('100%')
                .textAlign(TextAlign.Start)
              Row(){
                Image($r("app.media._temp"))
                  .fillColor('#6d9cee')
                  .width(25)
                  .height(25)
                  .margin({ bottom: 3 })
                Text("温度：")
                  .fontSize(15)
                  .width(60)
                  .fontColor( '#6d9cee')
                  .margin({ bottom: 3 })
                  .maxLines(1);
                Text(`${this.temp || '--'}℃`)
                  .fontSize(15)
                  .width(100)
                  .fontColor( '#6d9cee')
                  .margin({ bottom: 3});
                if (this.temp) {
                  Text(getEnvStatus(Number(this.temp), 'temp').text)
                    .fontSize(12)
                    .fontColor(getEnvStatus(Number(this.temp), 'temp').color)
                    .backgroundColor(`${getEnvStatus(Number(this.temp), 'temp').color}10`) // 浅色背景
                    .padding({ left: 4, right: 8 })
                    .borderRadius(4)
                }
              }
              Row(){
                Image($r("app.media._humi"))
                  .fillColor('#6d9cee')
                  .width(25)
                  .height(25)
                  .margin({ bottom: 3 })
                //.size({width:20,height:20})
                Text("湿度：")
                  .fontSize(15)
                  .width(60)
                  .fontColor( '#6d9cee')
                  .margin({ bottom: 3 })
                  .maxLines(1);
                Text(`${this.humi || '--'}%`)
                  .fontSize(15)
                  .width(100)
                  .fontColor( '#6d9cee')
                  .margin({ bottom: 3 });
                if (this.humi) {
                  Text(getEnvStatus(Number(this.humi), 'humi').text)
                    .fontSize(12)
                    .fontColor(getEnvStatus(Number(this.humi), 'humi').color)
                    .backgroundColor(`${getEnvStatus(Number(this.humi), 'humi').color}10`)
                    .padding({ left: 4, right: 8 })
                    .borderRadius(4)
                }
              }
              Row(){
                Image($r("app.media._co2"))
                  .fillColor('#6d9cee')
                  .width(25)
                  .height(25)
                //.size({width:20,height:20})
                Text("CO₂：")
                  .fontSize(15)
                  .width(60)
                  .fontColor( '#6d9cee')
                  .margin({ bottom: 2 })
                  .maxLines(1);
                Text(`${this.co2 || '--'}ppm`)
                  .fontSize(15)
                  .width(100)
                  .fontColor( '#6d9cee')
                  .margin({ bottom: 2 });
                if (this.co2) {
                  Text(getEnvStatus(Number(this.co2), 'co2').text)
                    .fontSize(12)
                    .fontColor(getEnvStatus(Number(this.co2), 'co2').color)
                    .backgroundColor(`${getEnvStatus(Number(this.co2), 'co2').color}10`)
                    .padding({ left: 4, right: 8 })
                    .borderRadius(4)
                }
              }
            }
            .width("80%")
            .height('100')
            .justifyContent(FlexAlign.Start)
            .padding({left:0})
            .onClick(()=>{
              animateTo({duration:500},()=>{
                this._h_detail = "90%"
                this.is_show_humidity = true
              })
            })
            Column(){
              Row(){
                Button('+')
                  .backgroundColor(this.is_sleep?'transparent'   : '#e0efff')
                  .fontColor(this.is_sleep ? 'transparent'  : '#6d9cee')
                  .padding({ left: 5, right: 5 })
                  .bindMenu(this.MenuBar)
                  .width(50)
                  .height(50);
              }
            }
            .width(80)
            //.alignSelf(ItemAlign.End)
            //.justifyContent(FlexAlign.End)
            //.padding({right:10})
          }
          .height(this._height)
          .width(this._width)
          .backgroundImage($r(this.backG))
          .backgroundImageSize(ImageSize.Cover)
          .padding(20)
          .borderRadius(15)
          .shadow({
            color: '#0000005d',
            radius: 10,
            offsetX: 10,
            offsetY: 10
          });
          if(this.is_show_r){
            Column().width("100%").height('20%').backgroundColor("#9c000000")
          }
        }
      }
      //显示温度详情数据
      detail_data({
        _h:this._h_detail,
        is_show:this.is_show_humidity,
        serOption_humi:this.serOption_humi,
        serOption_temp:this.serOption_temp,
        serOption_co2:this.serOption_co2
      })
      //删除农田
      delete_farmland({_h:this.is_delete_h,arr_farmland:this.arr_farmland})
      /* Column(){
         displayFarmland({is_show_r:this.is_show_r,arr_farmland:this.arr_farmland,is_sleep:this.is_sleep})
       }
       .height("90%")
       .width('100%')*/

      if(this.is_show_r){
        add_farmland_page({
          arr: $arr_farmland,    // 双向绑定农田列表（新增后同步更新）
          is_show: $is_show_r // 双向绑定弹窗开关（关闭时同步隐藏）
        })
      }
      if (this.showMyList && this.currentFarm) {
        displayFarmland({
          currentFarm: this.currentFarm,
          is_sleep: this.is_sleep,
          showList: $showMyList
        })
      }
      Column(){
        Text("我的农田")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 16, bottom: 12, left: 16 })
          .width('100%')
          .textAlign(TextAlign.Start)
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
      .height("90%")
      .width('100%')

    }
    .height("100%")
    .width("100%")
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
      Button("返回")
        .onClick(() => {
          animateTo({ duration: 500 }, () => {
            this._h = "0%"
            this.is_show = false
          })
        })
        .margin({ bottom: 10 })
      if (this.is_show) {
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
        .height('75%')
        .scrollBar(BarState.Auto)
        .padding(10)
      }
    }
    .height(this._h === "0%" ? "0%" : "100%")
    .width(this._w)
    .padding(10)
    .backgroundColor('#f5f5f5')
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

  aboutToAppear() {
    this.localstorage.getDate("last_login").then(_User_ => {
      this.username = _User_ as string;
    });
  }

  build() {
    Stack() {
      if (this.currentPage === 'main') {
        Column() {
          Column() {
            Column() {
              Image($r("app.media.user"))
                .width(80)
                .height(80)
                .borderRadius(40)
                .backgroundColor(Color.White)
              Text(this.username || '智慧农田用户')
                .fontSize(22)
                .fontColor(Color.White)
                .fontWeight(FontWeight.Medium)
                .padding({top:10,bottom:10})
              Text("农场主")
                .fontSize(14)
                .fontColor(Color.White)
                .backgroundColor('#ffb800')
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .borderRadius(12)
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
            .margin({ bottom: 20 })
          }
          .width('100%')
          .backgroundColor('#10B981')
          .padding({ top: 40, bottom: 30 })

          Row() {
            Text("开启我的智慧农场")
              .fontSize(35)
              .fontColor('#10B981')
              .fontWeight(FontWeight.Bold)
              .padding({ left: 20, right: 20, top: 20, bottom: 20 })
          }
          .height(140)
          .width('90%')
          .backgroundColor('#E8F5E9')
          .borderRadius(12)
          .margin({ top: 16, bottom: 20 })
          .justifyContent(FlexAlign.Center)

          Scroll() {
            Column({ space: 0 }) {
              this.MenuItem("账号设置", () => this.currentPage = 'account')
              this.MenuItem("关于智慧农田系统", () => this.currentPage = 'about')
              this.MenuItem("退出登录", () => {
                this.localstorage.setDate('is_land', false);
                router.replaceUrl({ url: 'pages/Open' });
              })
            }
            .width('100%')
            .backgroundColor(Color.White)
            .borderRadius(12)
            .margin({ left: 16, right: 16 })
            .padding({ top: 8, bottom: 8 })
          }
          .flexGrow(1)

          Text("版本号1.0.0")
            .fontSize(14)
            .fontColor('#6B7280')
            .margin({ top: 20, bottom: 20 })
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
    }
    .width('100%')
    .height('100%')
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
      case "账号设置": return "👤";
      case "关于智慧农田系统": return "ℹ️";
      case "退出登录": return "🚪";
      default: return "📋";
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
  MyBuilder_overview(title: string, num: number) {
    Column() {
      Row().width("100%").height(15);
      Image($r("app.media.add"))
        .height(num == this.selectnumber ? 20 : 10)
        .width(num == this.selectnumber ? 20 : 10)
        .fillColor(num == this.selectnumber ? '#4A90E2' : Color.White);

      Text("设备总控")
        .fontColor(num == this.selectnumber ? '#4A90E2' : Color.White);
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
            FarmlandOverview({
              arr_farmland: this.arr_farmland,
              is_show_lights: this.is_show_lights,
              is_show_temperature_control_device: this.is_show_temperature_control_device,
              is_show_robot: this.is_show_robot,
              is_show_waterValve: this.is_show_waterValve,
              is_show_dan: this.is_show_dan,
              edit_f: this.edit_f
            })
          }
          .tabBar(this.MyBuilder_overview("设备总控", 1))
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

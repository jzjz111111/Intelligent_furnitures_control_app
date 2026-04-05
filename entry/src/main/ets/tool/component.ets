import { LocalStorage } from "../data/LocalStorage";
import { FarmlandDatabase } from "../data/RdbStorage";
import { tcp } from "../pages/Index";
import { API_DeepSeek } from "../pages/OpenAI_Page";
import { _IoTad } from "../pages/scan_devices";
import {  Device, farmland } from "./classes";
import { router } from "@kit.ArkUI";
import { face_cam } from "../pages/face_cma";
import { preferences } from '@kit.ArkData';
import cryptoFramework from '@ohos.security.cryptoFramework';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import picker from '@ohos.file.picker';
import { ThemeColors } from '../utils/theme';

let new_arr_farmlands:farmland[]
let new_arr_f:Device[]

let Farmland_db:FarmlandDatabase = new FarmlandDatabase(globalThis.getContext())
let new_f_R_Id:number

@Component
export struct device_long {

  @Link _height:string
  @Prop farmland1:farmland
  @Link is_show_d:boolean
  @Link arr_f:Device[]
  @Link index_d:number
  o_name:string = ''
  @State Light_number:number = 0
  @Link is_chang:boolean
  @State is_c:boolean = true
  @State o_f:Device = new Device('',0,0)
  @Link t_f:Device

  aboutToAppear(): void {
    this.Light_number = this.arr_f[this.index_d].lighting
    this.o_f = this.arr_f[this.index_d]
  }
  build() {
    Stack() {
      Column() {
        Row(){
          Text(this.o_f.name)
            .position({
              y:50,
              x:20
            })
            .fontColor(ThemeColors.textPrimary)
          Text(this.o_f.type_id.toString())
            .position({
              y:50,
              x:200
            })
            .fontColor(ThemeColors.textSecondary)
        }
        Row(){
          Button('删除')
            .onClick(async ()=>{
              let r_id = await Farmland_db.getFarmlandsIdByName(this.farmland1.name)

              await Farmland_db.deleteDeviceByFarmlandIdAndName(r_id,this.arr_f[this.index_d].name)
              this.arr_f = this.arr_f.filter((element) => element.name!== this.arr_f[this.index_d].name);
              this.is_chang = !this.is_chang
              this.is_show_d = false
              animateTo({duration:500},()=>{this._height = '0%'})

            })
            .padding(5)
            .width(100)
            .backgroundColor(ThemeColors.danger)
            .fontColor(ThemeColors.bgCard)
          Button('返回')
            .onClick(() => {
              this.is_show_d = false
              this.is_chang = !this.is_chang
              animateTo({duration:500},()=>{this._height = '0%'})
            })
            .padding(5)
            .width(100)
            .backgroundColor(ThemeColors.secondary)
            .fontColor(ThemeColors.bgCard)
        }.height(100)
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)


      }
      .height("55%")
      .width('100%')
      .borderRadius(20)
      .backgroundColor(ThemeColors.bgCard)
      .justifyContent(FlexAlign.End)
      if(this.o_f.type_id <2000 ){
        Text("亮度："+this.Light_number.toString())
          .position({
            y:250,
            x:20
          })
          .fontColor(ThemeColors.textPrimary)
        if(this.o_f.lighting != 0){
          Slider({value:this.arr_f[this.index_d].lighting,max:10,min:1})
            .width('90%')
            .showSteps(true)
            .position({
              x:20,
              y:300
            })
            .onChange((value)=>{
              this.arr_f[this.index_d].lighting = value
              this.Light_number = value
              console.log("LL:"+this.Light_number.toString())
              this.is_chang = !this.is_chang
              _IoTad.set_LED_brightness_by_id(value*1000)
              this.o_f = this.arr_f[this.index_d]

              //udp.sendLED_chang(value)
            })
            .blockColor(ThemeColors.accent)
            .trackColor(ThemeColors.borderLight)
            .selectedColor(ThemeColors.primary)
        }
      }
      if(this.o_f.type_id >2999 && this.o_f.type_id<4000){

        Column(){
          my_temCon_edit({ is_show: this.is_show_d,item:this.o_f })
        }
        .height("55%")
        .width('100%')
      }
    }

    .height(this._height)
    .width('100%')
    .backgroundColor('rgba(13, 51, 40, 0.65)')

  }
}

@Component
struct device_edit{

  @Link device:Device
  @Link _height:string
  @Prop farmland1:farmland
  @Link is_show_d:boolean
  @State Light_number:number = 0
  @State o_f:Device = new Device('',0,0)
  @State is_c:boolean = false

  aboutToAppear(): void {
    this.Light_number = this.device.lighting
    this.o_f = this.device
    console.log("ccc:::"+this.is_c)
  }
  build() {
    Stack() {
      Column() {
        Row(){
          Text(this.o_f.name)
            .position({
              y:50,
              x:20
            })
            .fontColor(ThemeColors.textPrimary)
          Text(this.o_f.type_id.toString())
            .position({
              y:50,
              x:200
            })
            .fontColor(ThemeColors.textSecondary)

        }
        Row(){
          Button('返回')
            .onClick(() => {
              this.is_show_d = false
              animateTo({duration:500},()=>{this._height = '0%'})
            })
            .padding(5)
            .width(100)
            .backgroundColor(ThemeColors.secondary)
            .fontColor(ThemeColors.bgCard)
        }.height(100)
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)


      }
      .height("55%")
      .width('100%')
      .borderRadius(20)
      .backgroundColor(ThemeColors.bgCard)
      .justifyContent(FlexAlign.End)
      if(this.o_f.type_id <2000 ){
        Text("亮度："+this.Light_number.toString())
          .position({
            y:250,
            x:20
          })
          .fontColor(ThemeColors.textPrimary)
        if(this.o_f.lighting != 0){
          Slider({value:this.device.lighting,max:10,min:1})
            .width('90%')
            .showSteps(true)
            .position({
              x:20,
              y:300
            })
            .onChange((value)=>{
              this.device.lighting = value
              this.Light_number = value
              console.log("LL:"+this.Light_number.toString())
              tcp.sendLED_chang(value,this.device.type_id)
              this.o_f = this.device
              //udp.sendLED_chang(value)
            })
            .blockColor(ThemeColors.accent)
            .trackColor(ThemeColors.borderLight)
            .selectedColor(ThemeColors.primary)
        }
      }
      if(this.o_f.type_id >2999 && this.o_f.type_id<4000){
        Column(){
          Row(){
            Text(this.o_f.name)
              .position({
                y:50,
                x:20
              })
              .fontColor(ThemeColors.textPrimary)
            Text("id:"+this.o_f.type_id.toString())
              .position({
                y:50,
                x:200
              })
              .fontColor(ThemeColors.textSecondary)

          }
          my_temCon_edit({is_show:this.is_show_d,item:this.device})
        }.width("100%").height('100%')
        .backgroundColor(ThemeColors.primaryLight)

      }
    }
    .height(this._height)
    .width('100%')
    .backgroundColor('rgba(13, 51, 40, 0.65)')

  }
}

@Component

export struct add_device_page {
  @Link _height: string
  @Link arr: Device[]
  @Link farmland1: farmland
  @Link is_show: boolean
  @State dev_name: string = ''
  type: number = 0

  build() {
    Stack() {
      Column() {
        TextInput({ placeholder: '输入设备名称', text: this.dev_name })
          .onChange((value) => {
            this.dev_name = value
          })
          .bindMenu(this.DeviceMenu)
          .width(300)
          .position({ y: 50 })
          .backgroundColor(ThemeColors.bgGlass)
          .fontColor(ThemeColors.textPrimary)
          .placeholderColor(ThemeColors.textTertiary)

        TextInput({ placeholder: '输入设备ID' })
          .onChange((value) => {
            this.type = Number(value)
          })
          .width(300)
          .position({ y: 100 })
          .backgroundColor(ThemeColors.bgGlass)
          .fontColor(ThemeColors.textPrimary)
          .placeholderColor(ThemeColors.textTertiary)

        Button('完成')
          .backgroundColor(ThemeColors.primary)
          .fontColor(ThemeColors.bgCard)
          .onClick(async () => {
            if (this.dev_name != '' && this.type != 0) {
              let success = await Farmland_db.insertFuByFarmlandId(new_f_R_Id, this.dev_name, this.type)
              if (success == 1) {
                const newDevice = new Device(this.dev_name, 0, this.type)
                this.arr = [...this.arr, newDevice]
                this.farmland1.device_s = this.arr
              } else {
                AlertDialog.show({
                  message: '名字或ID重复了喂 >o< '
                })
              }
            }

            animateTo({ duration: 500 }, () => { this._height = '0%' })
            this.is_show = false
          })
      }
      .height('50%')
      .width('100%')
      .borderRadius(20)
      .backgroundImage($r('app.media.farm_bg'))
      .backgroundImageSize(ImageSize.Cover)
      .justifyContent(FlexAlign.End)
    }
    .height(this._height)
    .width('100%')
    .backgroundColor('rgba(13, 51, 40, 0.65)')
  }

  @Builder
  DeviceMenu() {
    Menu() {
      MenuItem({ content: 'LED' }).onClick(() => {
        this.dev_name = 'LED'
      })
      // 删除 .fontColor(ThemeColors.textPrimary)

      MenuItem({ content: '水阀' }).onClick(() => {
        this.dev_name = '水阀'
      })
      // 删除 .fontColor(ThemeColors.textPrimary)

      MenuItem({ content: '温控设备' }).onClick(() => {
        this.dev_name = '温控设备'
      })
      // 删除 .fontColor(ThemeColors.textPrimary)
    }
    .backgroundColor(ThemeColors.bgCard)
  }
}

@Component
export struct add_farmland_page {
  @Link arr: farmland[]
  @State dev_name: string = ''
  @Link is_show: boolean
  @State avatarUri: string = ''

  build() {

    Stack() {
      Column() {
        // ========== 头像选择框 ==========
        Stack({ alignContent: Alignment.Center }) {
          // 如果已经选了头像，就显示图片
          if (this.avatarUri) {
            Image(this.avatarUri)
              .width(90)
              .height(90)
              .borderRadius(45)
              .objectFit(ImageFit.Cover)
          } else {
            // 没选头像，显示灰色圆形 + 文字
            Circle({ width: 90, height: 90 })
              .fill(ThemeColors.borderLight)
            Text("点击选头像")
              .fontSize(13)
              .fontColor(ThemeColors.textSecondary)
          }
        }
        .onClick(() => {
          this.selectAvatar() // 点击就打开相册
        })
        .margin({ bottom: 15 })
        // ========== 头像区域结束 ==========
        TextInput({ placeholder: '输入农田名称' })
          .onChange((value) => {
            this.dev_name = value
          })
          .backgroundColor(ThemeColors.bgGlass)
          .fontColor(ThemeColors.textPrimary)
          .placeholderColor(ThemeColors.textTertiary)
        Row(){
          Button('完成')
            .backgroundColor(ThemeColors.primary)
            .fontColor(ThemeColors.bgCard)
            .onClick(async () => {
              if (this.dev_name != '') {
                let success = await Farmland_db.insertFarmland(new farmland(this.dev_name, [],this.avatarUri))
                if(success != -1){
                  setTimeout(()=>{
                    this.arr.push(new farmland(this.dev_name, [],this.avatarUri))
                  },500)
                }else{
                  AlertDialog.show({
                    message:"名字重复了哦"
                  })
                }

              }
              this.is_show = false
            })
            .padding(5)
            .width(100)
          Button('返回')
            .backgroundColor(ThemeColors.secondary)
            .fontColor(ThemeColors.bgCard)
            .onClick(() => {
              this.is_show = false
            })
            .padding(5)
            .width(100)
        }
        .height(100)
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
      }
      .height('50%')
      .width('100%')
      .borderRadius(20)
      .backgroundImage($r('app.media.bottom_bg4'))
      .backgroundImageSize(ImageSize.Cover)
      .justifyContent(FlexAlign.End)
    }

    .height('100%')
    .width('100%')
    .backgroundColor('rgba(13, 51, 40, 0.65)')

  }
  // 打开相册选择头像
  async selectAvatar() {
    try {
      // 1. 创建选择配置
      let photoOption = new picker.PhotoSelectOptions();

      // 2. 只允许选图片
      photoOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;

      // 3. 最多选1张
      photoOption.maxSelectNumber = 1;

      // 4. 打开相册
      const photoPicker = new picker.PhotoViewPicker();
      const selectResult = await photoPicker.select(photoOption);

      // 5. 获取选中的图片地址
      if (selectResult.photoUris && selectResult.photoUris.length > 0) {
        this.avatarUri = selectResult.photoUris[0];
        console.log("选中头像地址：", this.avatarUri);
      }
    } catch (err) {
      console.error("选择图片失败：", err);
    }
  }
}

@Component
export struct myList {


  @ObjectLink farmland1: farmland
  @State num1: number = 1
  @State num2: number = 1
  @Prop arr_dev: Device[]
  @State show_add: boolean = false
  @Prop index:number
  @State is_show_d:boolean = false
  @Link is_sleep:boolean
  @State index_d:number = 0
  @State _height:string = "0%"
  @Link showList: boolean;
  @State this_d:Device = new Device('',0,1)
  @State is_change:boolean = true

  aboutToAppear(): void {

  }
  aboutToDisappear(): void {
    this.farmland1.device_s = this.arr_dev
    this.arr_dev = [...this.arr_dev]
  }
  build() {
    Stack() {
      List() {
        ForEach(this.arr_dev, (item: Device, index) => {
          ListItem() {
            Row(){
              myRow({ item1: item ,is_sleep:this.is_sleep ,is_chang:this.is_change})
            }.gesture(
              LongPressGesture({ repeat: true ,duration :300 })
                .onAction((event: GestureEvent|undefined) => {
                  if(event){
                    if (event.repeat) {
                      this.this_d = item
                      this.is_show_d = true
                      this.index_d = index
                      animateTo({duration:200},()=>{
                        this._height = "100%"
                      })
                      console.log('Long_touch')
                    }
                  }
                })
                .onActionEnd(() => {
                })
            )
            .onClick(()=>{
              if(item.type_id<2000){
                if(item.type_id>1100){
                }else{
                  if(item.switch){
                    this.arr_dev[index] = new Device(item.name,0,item.type_id)
                    this.arr_dev[index].lighting = 0
                    _IoTad.set_LED_brightness_by_id(1)
                  }else{
                    this.arr_dev[index] = new Device(item.name,1,item.type_id)
                    this.arr_dev[index].lighting = 5
                    _IoTad.set_LED_brightness_by_id(5000)
                    console.log("Farmland F IS :"+JSON.stringify(this.arr_dev))
                  }
                }
              }else if(item.type_id>=3000&&item.type_id<4000){
                if(item.switch){
                  this.arr_dev[index] = new Device(item.name,0,item.type_id)
                  _IoTad.set_temperature_control_device_by_id(item.temp,"off",item.mode)
                }else{
                  this.arr_dev[index] = new Device(item.name,1,item.type_id)
                  _IoTad.set_temperature_control_device_by_id(item.temp,"on",item.mode)
                }
              }
              else{

                if(item.switch){
                  this.arr_dev[index] = new Device(item.name,0,item.type_id)
                  set_device(item,"off")
                }else{
                  this.arr_dev[index] = new Device(item.name,1,item.type_id)
                  set_device(item,"on")
                }
              }

            })
          }
          .padding(10)
          .onClick(()=>{
            console.log("myRow:" + JSON.stringify(item))
          })
        })
        ListItem() {
          Row(){
            Button("+")
              .onClick(async () => {
                new_f_R_Id = await Farmland_db.getFarmlandsIdByName(this.farmland1.name)
                this.show_add = true
                animateTo({duration:200},()=>{
                  this._height = "100%"
                })

              })
              .backgroundColor(ThemeColors.primary)
              .fontColor(ThemeColors.bgCard)
              .height('100%')
              .width('100%')
          }
          .height(100)
          .width("90%")
          .padding(10)
          .margin(12)
          .backgroundColor(ThemeColors.primaryLight)
          .borderRadius(20);
        }
        ListItem() {
          Button("完成")
            .width("90%")
            .height(50)
            .backgroundColor(ThemeColors.primary)
            .fontColor(ThemeColors.bgCard)
            .fontSize(18)
            .borderRadius(12)
            .onClick(() => {
              this.showList=false;
            })
            .margin(10)
        }
      }
      .height("90%")
      .lanes(2)


      if (this.show_add) {
        add_device_page({
          _height: this._height,
          arr: this.arr_dev,
          farmland1: this.farmland1,
          is_show: this.show_add
        })
      }
      if(this.is_show_d){
        device_long({
          _height:this._height,
          t_f:this.this_d,
          farmland1:this.farmland1,
          is_show_d:this.is_show_d,
          arr_f:this.arr_dev,
          is_chang:this.is_change,
          index_d:this.index_d
        })
      }

    }.onClick(()=>{
      new_arr_f = this.arr_dev
    })
  }
}

@Component
export struct myRow {
  @State item1: Device = new Device("w", 0,0)
  @State is_clicknum: number = 0;
  @Prop is_sleep:boolean
  @Link is_chang:boolean

  build() {
    if(this.item1.type_id > 1999){
      Stack(){
        Row() {
          Text(this.item1.name)
            .fontColor(ThemeColors.textPrimary)
          if(this.item1.type_id<999){

          }else if(this.item1.type_id<1999){
            Image($r('app.media.water_valve6'))
              .height(20)
              .width(20)
              .fillColor(ThemeColors.techBlue);
          }else if(this.item1.type_id<2999){
            Image($r('app.media._water_valve'))
              .height(20)
              .width(20)
              .fillColor(ThemeColors.techBlue);
          }else if(this.item1.type_id<3999){
            Image($r('app.media._temperature_control_device'))
              .height(20)
              .width(20)
              .fillColor(ThemeColors.accent);
          }else if(this.item1.type_id<4999){
            Image($r('app.media._fan'))
              .height(20)
              .width(20)
              .fillColor(ThemeColors.techBlue);
          }else if(this.item1.type_id<5999){
            Image($r('app.media._icebox'))
              .height(20)
              .width(20)
              .fillColor(ThemeColors.techBlue);
          }
          else if(this.item1.type_id<6999){
            Image($r('app.media._robot'))
              .height(20)
              .width(20)
              .fillColor(ThemeColors.techBlue);
          }

        }
        .justifyContent(FlexAlign.SpaceAround)
        .height(100)
        .width("100%")
        .margin(2)
        .padding(10)
        .backgroundImage(this.item1.switch?$r('app.media.device_bg2') :$r('app.media.lights_bg'))
        .backgroundImageSize(ImageSize.Cover)
        .borderRadius(20)
        .borderWidth(2)
        .borderColor(this.item1.switch? ThemeColors.accent : ThemeColors.borderLight);
      }


    }else if(this.item1.type_id > 1000){
      Stack(){
        Row() {
          Text(this.item1.name)
            .fontColor(ThemeColors.textPrimary)
          Image($r('app.media.water_valve6'))
            .height(20)
            .width(20)
            .fillColor(ThemeColors.techBlue);
        }
        .justifyContent(FlexAlign.SpaceAround)
        .height(100)
        .width("100%")
        .margin(2)
        .padding(10)
        .backgroundImage(this.item1.switch?$r('app.media.device_bg2') :$r('app.media.lights_bg'))
        .backgroundImageSize(ImageSize.Cover)
        .borderRadius(20)
        .borderWidth(2)
        .borderColor(this.item1.switch? ThemeColors.accent :ThemeColors.borderLight );
      }
    }
  }

}

@Component
export struct displayFarmland {
  @ObjectLink currentFarm: farmland;
  @Link is_sleep: boolean;
  @State is_show_lights:boolean = false
  @State is_show_temperature_control_device:boolean = false
  @State is_show_robot:boolean = false
  @State is_show_waterValve:boolean = false
  @State is_show_dan:boolean = false
  @State edit_f:Device = new Device("",0,0)
  @Link showList: boolean;

  build() {
    Stack() {
      Column()
        .width("100%")
        .height("100%")
        .backgroundColor('rgba(13, 51, 40, 0.45)')
        .onClick(() => {
          this.showList = false;
        })
      myList({
        farmland1: this.currentFarm,
        arr_dev: this.currentFarm.device_s,
        index: 0,
        is_sleep: this.is_sleep,
        showList: this.showList
      })
        .width("90%")
        .height("80%")
        .backgroundColor(ThemeColors.bgCard)
        .borderRadius(20)
    }
    .width("100%")
    .height("100%")
  }
}

@Component
export struct FarmlandOverview {
  @Link arr_farmland: farmland[]
  @Link is_show_lights: boolean
  @Link is_show_temperature_control_device: boolean
  @Link is_show_robot: boolean
  @Link is_show_waterValve: boolean
  @Link is_show_dan: boolean
  @State edit_f: Device = new Device("", 0, 0)

  build() {
    Stack() {
      Column() {
        Row() {
          Text("设备总控")
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.bgCard)
        }
        .width('100%')
        .height(60)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(ThemeColors.primary)
        .padding({ top: 10 })

        Scroll() {
          Grid() {
            ForEach(this.getDeviceList(), (item: DeviceControlItem) => {
              GridItem() {
                this.DeviceCard(item)
              }
            })
            GridItem() {
              Column() {
                Text("+")
                  .fontSize(48)
                  .fontColor(ThemeColors.textTertiary)
                Text("添加设备")
                  .fontSize(14)
                  .fontColor(ThemeColors.textSecondary)
              }
              .width('100%')
              .height(160)
              .justifyContent(FlexAlign.Center)
              .backgroundColor(ThemeColors.bgPrimary)
              .borderRadius(16)
              .borderWidth(1)
              .borderColor(ThemeColors.borderLight)
            }
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(16)
          .rowsGap(16)
          .width('100%')
          .padding(16)
        }
        .width('100%')
        .flexGrow(1)
        .backgroundColor(ThemeColors.bgPrimary)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeColors.bgPrimary)

      if (this.is_show_lights) {
        ControlLights({ arr_farmland: this.arr_farmland, is_show: this.is_show_lights })
      }
      if (this.is_show_temperature_control_device) {
        ControlTemp({ arr_farmland: this.arr_farmland, is_show: this.is_show_temperature_control_device })
      }
      if (this.is_show_waterValve) {
        ControlWaterValve({ arr_farmland: this.arr_farmland, is_show: this.is_show_waterValve });
      }
      if (this.is_show_robot) {
        face_cam({ is_show: this.is_show_robot })
      }
      if (this.is_show_dan) {
        ControlFan({ arr_farmland: this.arr_farmland, is_show: this.is_show_dan })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  DeviceCard(item: DeviceControlItem) {
    Column({ space: 12 }) {
      Image(item.icon)
        .width(48)
        .height(48)
        .fillColor(item.color)
        .margin({ top: 16 })
      Text(item.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeColors.textPrimary)
      Text(item.desc)
        .fontSize(12)
        .fontColor(ThemeColors.textSecondary)
        .maxLines(1)
    }
    .width('100%')
    .height(160)
    .justifyContent(FlexAlign.Start)
    .padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(ThemeColors.bgCard)
    .borderRadius(16)
    .shadow({
      color: ThemeColors.shadowDark,
      radius: 8,
      offsetX: 0,
      offsetY: 2
    })
    .onClick(item.onClick)
  }

  getDeviceList(): DeviceControlItem[] {
    return [
      {
        title: "补光灯光控制",
        desc: "调节棚内光照强度",
        icon: $r("app.media.c_light2"),
        color: ThemeColors.warning,
        onClick: () => this.is_show_lights = true
      },
      {
        title: "水阀控制",
        desc: "控制灌溉水阀开关",
        icon: $r("app.media.waterValve5"),
        color: ThemeColors.techBlue,
        onClick: () => this.is_show_waterValve = true
      },
      {
        title: "门锁",
        desc: "远程开关棚门",
        icon: $r("app.media._door"),
        color: ThemeColors.success,
        onClick: () => this.is_show_robot = true
      },
      {
        title: "温控设备控制",
        desc: "调节棚内温度",
        icon: $r("app.media.ufo2"),
        color: ThemeColors.danger,
        onClick: () => this.is_show_temperature_control_device = true
      },
      {
        title: "风扇控制",
        desc: "调节通风风速",
        icon: $r("app.media._fan"),
        color: ThemeColors.secondary,
        onClick: () => this.is_show_dan = true
      }
    ]
  }
}

interface DeviceControlItem {
  title: string
  desc: string
  icon: Resource
  color: string
  onClick: () => void
}

@Component
export  struct ControlLights{
  @Link is_show:boolean
  @Link arr_farmland:farmland[]

  build() {
    Stack() {
      Column() {
        Row() {
          Button("<")
            .width(44)
            .height(44)
            .backgroundColor(Color.Transparent)
            .fontColor(ThemeColors.bgCard)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .onClick(() => this.is_show = false)

          Text("补光灯光控制")
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.bgCard)
            .flexGrow(1)
            .textAlign(TextAlign.Center)

          Text("")
            .width(44)
        }
        .width('100%')
        .height(60)
        .backgroundColor(ThemeColors.primary)
        .padding({ top: 10 })
        if(this.arr_farmland.length != 0){
          List({ space: 16 }) {
            ForEach(this.arr_farmland,(item:farmland,index)=>{
              ListItem() {
                Column() {
                  Text(item.name)
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(ThemeColors.textPrimary)
                    .width('100%')
                    .textAlign(TextAlign.Start)
                    .margin({ bottom: 12 })

                  MySlider({
                    _farmland:item,
                  })
                }
                .width('100%')
                .padding(20)
                .backgroundColor(ThemeColors.bgCard)
                .borderRadius(16)
                .shadow({
                  color: ThemeColors.shadowDark,
                  radius: 8,
                  offsetX: 0,
                  offsetY: 4
                })
              }
              .padding({ left: 16, right: 16 })
            })
          }
          .width('100%')
          .padding({ top: 16, bottom: 30 })
          .flexGrow(1)
        }else{
          Column() {
            Text("还没有农田哦")
              .fontSize(16)
              .fontColor(ThemeColors.textSecondary)
              .margin({ top: 60 })
          }
          .flexGrow(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeColors.bgPrimary)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct MySlider{
  @State lighting:number = 0
  @Prop _farmland:farmland
  @State bulbColor: string = ThemeColors.textPrimary
  aboutToAppear(): void {
    let max = 0
    for (let f of this._farmland.device_s){
      if(f.lighting>max){
        max = f.lighting
      }
    }
    this.lighting = max
    console.log("farmland max:"+this.lighting)
  }
  build() {
    Row(){
      Image($r('app.media.fill_light'))
        .height(25)
        .width(25)
        .fillColor(this.bulbColor);
      Slider({
        direction: Axis.Horizontal,
        max: 10,
        min: 0,
        step: 1,
        style: SliderStyle.OutSet,
        value: this.lighting
      })
        .onChange(async (value) => {
          this.lighting = value;
          for (let f of this._farmland.device_s) {
            if (f.type_id > 999 && f.type_id < 2000) {
              await tcp.sendLED_chang(value, f.type_id);
              tcp.getData();
            }
          }
          this.bulbColor = this.calculateBulbColor(this.lighting)
          _IoTad.set_LED_brightness_by_id(value*1000)

        })
        .width(200)
        .height(20)
        .blockColor(ThemeColors.accent)
        .trackColor(ThemeColors.borderLight)
        .selectedColor(ThemeColors.primary);

      Text((this.lighting * 10).toFixed(0) + "%")
        .fontSize(14)
        .margin({ left: 10 })
        .fontColor(ThemeColors.textSecondary)
        .width("15%")

    }

  }

  calculateBulbColor(lighting: number): string {
    const lightness = lighting / 10;
    // 修复：移除 (0, 245 - 13) 中的逗号操作符
    const r = Math.floor(13 + (245 - 13) * lightness);  // 原为 (0, 245 - 13)
    const g = Math.floor(51 + (245 - 51) * lightness);  // 原为 (0, 245 - 51)
    const b = Math.floor(40 + (245 - 40) * lightness);  // 原为 (0, 245 - 40)
    return `rgb(${r},${g},${b})`;
  }

}

@Component
export struct ControlWaterValve {
  @Link is_show: boolean
  @Link arr_farmland: farmland[]
  @State waterValve_List: Device[] = []

  aboutToAppear(): void {
    for (let r of this.arr_farmland) {
      let _exist = false
      let fan_ = new Device('', 0, 0)
      for (let f of r.device_s) {
        if (f.type_id > 3999 && f.type_id < 5000) {
          _exist = true
          fan_ = f
        }
      }
      this.waterValve_List.push(fan_)
    }
  }

  build() {
    Stack() {
      Column() {
        Row() {

          Button("<")
            .width(44)
            .height(44)
            .backgroundColor(Color.Transparent)
            .fontColor(ThemeColors.bgCard)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .onClick(() => this.is_show = false)

          Text("水阀控制")
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.bgCard)
            .flexGrow(1)
            .textAlign(TextAlign.Center)

          Text("")
            .width(44)
        }
        .width('100%')
        .height(60)
        .backgroundColor(ThemeColors.primary)
        .padding({ top: 10 })

        if (this.arr_farmland.length != 0) {
          List({ space: 16 }) {
            ForEach(this.arr_farmland, (item: farmland, index) => {
              ListItem() {
                Stack() {
                  Image(this.waterValve_List[index]?.switch === 1 ? $r('app.media.cur_open') : $r('app.media.cur_close'))
                    .width('70%')
                    .height('70%')
                    .objectFit(ImageFit.Cover)
                    .fillColor(ThemeColors.textTertiary)

                  Column() {
                    Text(item?.name)
                      .fontSize(16)
                      .fontColor(ThemeColors.textPrimary)
                    Toggle({
                      type: ToggleType.Switch,
                      isOn: this.waterValve_List[index]?.switch === 1
                    })
                      .onClick(async () => {
                        let newList = [...this.waterValve_List];
                        if (newList[index].switch === 1) {
                          newList[index] = new Device(
                            newList[index].name,
                            0,
                            newList[index].type_id
                          );
                          _IoTad.set_waterValve_by_id("off");
                        } else {
                          newList[index] = new Device(
                            newList[index].name,
                            1,
                            newList[index].type_id
                          );
                          _IoTad.set_waterValve_by_id("on");
                        }
                        this.waterValve_List = newList;
                      })
                  }
                  .width('100%')
                  .height('100%')
                  .padding(20)
                  .justifyContent(FlexAlign.SpaceBetween)
                }
                .width('100%')
                .height(200)
                .backgroundColor(ThemeColors.bgCard)
                .borderRadius(16)
                .shadow({
                  radius: 8,
                  offsetX: 0,
                  offsetY: 4,
                  color: ThemeColors.shadowDark
                })
              }
              .padding({ left: 16, right: 16 })
            })
          }
          .lanes(2)
          .width('100%')
          .padding({ top: 16, bottom: 30 })
          .flexGrow(1)
        } else {
          Column() {
            Text("还没有农田哦")
              .fontSize(16)
              .fontColor(ThemeColors.textSecondary)
              .margin({ top: 60 })
          }
          .flexGrow(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeColors.bgPrimary)
    }
    .width('100%')
    .height('100%')
  }
}


@Component
export struct ControlFan{
  @Link is_show:boolean
  @Link arr_farmland:farmland[]
  @State fan_List:Device[] = []
  @State fan_ex_list:boolean[] = []

  aboutToAppear(): void {
    for (let r of this.arr_farmland){
      let _exist = false
      let fan_ = new Device('',0,0)
      for (let f of r.device_s){
        if(f.type_id>3999&&f.type_id<5000){
          _exist = true
          fan_ = f
        }
      }
      this.fan_List.push(fan_)
      if(_exist){
        this.fan_ex_list.push(true)
      }else{
        this.fan_ex_list.push(false)
      }
    }
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Button("<")
            .width(44)
            .height(44)
            .backgroundColor(Color.Transparent)
            .fontColor(ThemeColors.bgCard)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .onClick(() => this.is_show = false)

          Text("风扇控制")
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.bgCard)
            .flexGrow(1)
            .textAlign(TextAlign.Center)

          Text("")
            .width(44)
        }
        .width('100%')
        .height(60)
        .backgroundColor(ThemeColors.primary)
        .padding({ top: 10 })
        if(this.arr_farmland.length != 0){
          List({ space: 16 }) {
            ForEach(this.arr_farmland,(item:farmland,index)=>{
              if(this.fan_ex_list[index]){
                ListItem(){
                  Row(){
                    Text(item.name)
                      .fontSize(18)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(ThemeColors.textPrimary)
                    Toggle({ type: ToggleType.Switch, isOn:this.fan_List[index].switch?true:false})
                      .onClick(async ()=>{
                        if(this.fan_List[index].switch){
                          this.fan_List[index] = new Device(this.fan_List[index].name,0,this.fan_List[index].type_id)
                          _IoTad.set_fan_by_id("off")
                        }else{
                          this.fan_List[index] = new Device(this.fan_List[index].name,1,this.fan_List[index].type_id)
                          _IoTad.set_fan_by_id("on")
                        }
                      })
                  }
                  .width('100%')
                  .padding(20)
                  .justifyContent(FlexAlign.SpaceBetween)
                  .backgroundColor(ThemeColors.bgCard)
                  .borderRadius(16)
                  .shadow({
                    radius: 8,
                    offsetX: 0,
                    offsetY: 4,
                    color: ThemeColors.shadowDark
                  })
                }
                .padding({ left: 16, right: 16 })
              }
            })
          }
          .width('100%')
          .padding({ top: 16, bottom: 30 })
          .flexGrow(1)
        }else{
          Column() {
            Text("还没有农田哦")
              .fontSize(16)
              .fontColor(ThemeColors.textSecondary)
              .margin({ top: 60 })
          }
          .flexGrow(1)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeColors.bgPrimary)
    }
    .width('100%')
    .height('100%')
  }
}

@Component
struct show_f{
  @Link arr:farmland[]
  @State ex_condition:boolean = false
  @State open_List:Device[] = []
  @State is_show_edit_List:boolean[] = []
  @State is_edit_h:string[] = []
  @Link f:Device


  async aboutToAppear(){
    console.log("f:::11")
    setInterval(()=>{
      this.open_List = []
      console.log("f:::11"+JSON.stringify(this.arr))
      for(let r of this.arr){
        for (let f of r.device_s){
          console.log("f:::11"+JSON.stringify(f))
          if(f.switch == 1&&f.type_id>2999){
            this.ex_condition = true
            this.open_List.push(f)
            this.is_show_edit_List.push(false)
            this.is_edit_h.push("13%")
          }
        }
      }
    },1000)
  }

  build() {

    if(this.ex_condition){
      List(){
        ForEach(this.open_List,(item:Device,value)=>{
          ListItem(){
            Row(){
              Column(){
                if(item.type_id<999){

                }else if(item.type_id<2000){

                }else if(item.type_id<3000){
                  Image($r("app.media._water_valve"))
                    .fillColor(this.select_color(value))
                }else if(item.type_id<4000){
                  Image($r("app.media._temperature_control_device"))
                    .fillColor(this.select_color(value))
                }else if(item.type_id<5000){
                  Image($r("app.media._fan"))
                    .fillColor(this.select_color(value))
                }else if(item.type_id<6000){
                  Image($r("app.media._icebox"))
                    .fillColor(this.select_color(value))
                }else if(item.type_id<7000){
                  Image($r("app.media._robot"))
                    .fillColor(this.select_color(value))
                }
              }.height(48)
              .width(48)
              .borderRadius(24)
              .padding(5)
              .backgroundColor(ThemeColors.bgCard)

              if(this.is_show_edit_List[value]){
                Text(item.name)
                  .fontColor(ThemeColors.textPrimary)
                Text("id:"+item.type_id)
                  .fontColor(ThemeColors.textSecondary)

              }
              Row().width(50)

            }
            .justifyContent(FlexAlign.SpaceBetween)
            .height(50)
            .width(this.is_edit_h[value])
            .borderRadius(25)
            .backgroundColor(ThemeColors.borderLight)
            .onClick(()=>{
              this.is_show_edit_List[value] = !this.is_show_edit_List[value]
              this.f = item
              animateTo({duration:200},()=>{
                if(this.is_show_edit_List[value]){
                  this.is_edit_h[value] = "60%"
                }else{
                  this.is_edit_h[value] = "13%"
                }
              })
            })
          }
          ListItem().width(10)
        })

      }
      .listDirection(Axis.Horizontal)
      .width("100%").height(60)
    }
  }
  select_color(value:number):string{
    if(value%3==0){
      return ThemeColors.secondary
    }
    else if(value%3==1){
      return ThemeColors.techBlue
    }
    else{
      return ThemeColors.accent
    }
  }
}

@Component
export struct my_DeepSeek{

  @State question:string = ''
  @Link _height:string
  @Link is_show:boolean
  @State history:string  = ''
  @Link _height_AI:string
  @State is_ark:boolean = false
  AI:API_DeepSeek = new API_DeepSeek()
  localstorage:LocalStorage = new LocalStorage("AI")
  @State TextList:string[] = []
  async aboutToAppear() {
    if(await this.localstorage.getDate("history") != false){

      this._height = "40%"
      this.history = await this.localstorage._getDate_("history")
      console.log("history::"+this.history)
      for(let message of this.history.split("::::")){
        if(message.split("///")[0] != ''){
          this.TextList.push(message.split("///")[0])
        }
        if(message.split("///")[1] != ''){
          this.TextList.push(message.split("///")[1])
        }

      }
    }

  }
  build() {
    Stack({alignContent:Alignment.BottomEnd}){
      Column()
        .height("100%").width("100%").backgroundColor('rgba(13, 51, 40, 0.45)')
        .onClick(()=>{
          animateTo({duration:500},()=>{
            this._height = "10%"
            this._height_AI = "0%"
            this.is_show = false
          })
        })
      Column(){
        List() {
          ForEach(this.TextList,(item:string,value)=>{
            ListItem(){
              if(value%2 == 0){
                if(item != "[object Promise]"){
                  Row(){
                    Text(item)
                      .fontColor(ThemeColors.bgCard)
                      .backgroundColor(ThemeColors.primary)
                      .borderRadius(10)
                      .padding(10)
                    Column()
                      .width(10)
                    Column(){
                      Image($r('app.media.user'))
                        .width("100%").height("100%")
                        .fillColor(ThemeColors.techBlue).size({width:"90%",height:"90%"})

                    }
                    .width(50).borderRadius(25).height(50)
                  }.justifyContent(FlexAlign.End)
                  .width("100%").padding(10)
                }

              }else{
                Row(){
                  Column()
                    .width(50).borderRadius(25).height(50) .backgroundImage($r('app.media.deepseek_icon')).backgroundImageSize(ImageSize.Cover)
                  Column()
                    .width(10)
                  Text(item)
                    .fontColor(ThemeColors.textPrimary)
                    .backgroundColor(ThemeColors.primaryLight)
                    .width("75%")
                    .borderRadius(10)
                    .padding(10)
                }.justifyContent(FlexAlign.Start)
                .width("100%").padding(10)
              }
            }

          })

        }.width("100%").height(this._height)
        Row(){
          if(this.is_show){
            TextInput({placeholder:"请输入问题",text:this.question}).width("80%").height("10%").backgroundColor(ThemeColors.bgGlass)
              .onChange((value)=>{this.question = value})
              .placeholderColor(ThemeColors.textTertiary)
              .fontColor(ThemeColors.textPrimary)

          }
          if(this.is_ark){
            Progress({ value: 0, total: 100, type: ProgressType.Ring })
              .width(50).color(ThemeColors.bgCard)  .backgroundColor(ThemeColors.primaryLight)
              .style({ strokeWidth: 10, status: ProgressStatus.LOADING })
          }
          else{
            Button("提问")
              .backgroundColor(ThemeColors.primary)
              .fontColor(ThemeColors.bgCard)
              .onClick(async ()=>{
                if(this.question != ''){
                  animateTo({duration:200},()=>{
                    this._height = "40%"
                  })
                  this.is_ark = true
                  this.TextList.push(this.question)
                  this.history = await this.AI.chat(this.question)
                  await this.localstorage.setDate("history",this.history)
                  this.TextList = []
                  for(let message of (this.history).split("::::")){
                    if(message.split("///")[0] != ''||message.split("///")[0] == this.question){
                      this.TextList.push(message.split("///")[0])
                    }
                    if(message.split("///")[1] != ''){
                      this.TextList.push(message.split("///")[1])
                    }
                  }
                  this.question = ''
                  this.is_ark = false
                }else {
                  this.history = "请输入问题"
                }

              })
          }

        }.justifyContent(FlexAlign.End).width("100%")
      }.justifyContent(FlexAlign.End).borderRadius({topLeft:20,topRight:20}).backgroundImage($r('app.media.ai_bg1')).backgroundImageSize(ImageSize.Cover)
    }.width("100%").height(this._height_AI)

  }
}

@Component
export struct my_temCon_edit{

  @Link item:Device
  @Link is_show:boolean
  @State selectedMode: 'auto' | 'heat' | 'cool' | 'dry' = 'auto';
  @State tempSetting: number = 26;
  @State acColor: string = ThemeColors.success;
  @State is_chang: boolean = true;
  @State Color_B:string[] = [ThemeColors.success,ThemeColors.danger,ThemeColors.techBlue,ThemeColors.warning]
  private calculateAcColor(): string {
    switch (this.selectedMode) {
      case 'heat': return ThemeColors.danger;
      case 'cool': return ThemeColors.techBlue;
      case 'dry': return ThemeColors.warning;
      default: return ThemeColors.success;
    }
  }
  aboutToAppear(): void {
    this.tempSetting = this.item.temp
    if(this.item.mode == "zd"){
      this.selectedMode = "auto"
    }else if(this.item.mode == 'zr'){
      this.selectedMode = "heat"
    }else if(this.item.mode == 'zl'){
      this.selectedMode = "cool"
    }else if(this.item.mode == 'cs'){
      this.selectedMode = "dry"
    }else{
      this.selectedMode = "auto"
    }
  }

  build() {
    Column() {
      Button('返回')
        .onClick(() => this.is_show = false)
        .padding(10)
        .backgroundColor(ThemeColors.bgCard)
        .borderWidth(2)
        .borderColor(ThemeColors.primary)
        .fontColor(ThemeColors.primary)
        .margin(5);


      Row() {
        ForEach(['auto', 'heat', 'cool', 'dry'] as ['auto', 'heat', 'cool', 'dry'], (mode: 'auto' | 'heat' | 'cool' | 'dry',value) => {
          Button(mode.toUpperCase())
            .onClick(() => {
              this.selectedMode = mode;
              this.acColor = this.calculateAcColor();
              _IoTad.set_temperature_control_device_by_id(this.tempSetting,"on",this.selectedMode == "auto"?"zd":this.selectedMode == "heat"?"zr":this.selectedMode == "cool"?"zl":this.selectedMode == "dry"?"cs":"zd")
            })
            .padding(10)
            .backgroundColor(this.selectedMode === mode ? this.Color_B[value] : ThemeColors.bgPrimary)
            .fontColor(this.selectedMode === mode ? ThemeColors.bgCard:ThemeColors.primary)
            .borderWidth(2)
            .borderColor(this.selectedMode === mode ?ThemeColors.bgCard:ThemeColors.primary)
            .margin(5);
        });
      }
      .margin(10);

      Column() {
        Text(`当前温度: ${this.tempSetting.toFixed(1)}°C`)
          .fontSize(24)
          .margin(10)
          .fontColor(ThemeColors.textPrimary);

        Row() {
          Button('-')
            .onClick(() => {
              if (this.tempSetting > 16) {
                this.tempSetting -= 1;
                this.is_chang = !this.is_chang;
                _IoTad.set_temperature_control_device_by_id(this.tempSetting,"on",this.item.mode)
              }
            })
            .padding(10)
            .backgroundColor(ThemeColors.bgPrimary)
            .margin(5)
            .fontColor(ThemeColors.textPrimary);

          this.CustomCircularProgress();

          Button('+')
            .onClick(() => {
              if (this.tempSetting < 30) {
                this.tempSetting += 1;
                this.is_chang = !this.is_chang;
                _IoTad.set_temperature_control_device_by_id(this.tempSetting,"on",this.item.mode)
              }
            })
            .padding(10)
            .backgroundColor(ThemeColors.bgPrimary)
            .margin(5)
            .fontColor(ThemeColors.textPrimary);
        }
        .margin(10);
      }
      .height("50%")
      .width("80%")
      .backgroundColor(ThemeColors.bgPrimary)
      .borderRadius(15)
      .padding(20);

    }
    .backgroundColor(ThemeColors.primaryLight)
    .borderRadius(20)
    .width('100%')
    .height('100%');

  }
  @Builder
  CustomCircularProgress() {
    Progress({
      value:this.tempSetting - 16,
      total: 14,
      style: ProgressStyle.Ring
    })
      .style({
        strokeWidth: 10,
        ringStyle: {
          startAngle: -90,
          sweepAngle: 360,
          gapRadius: 0
        }
      } as RingStyleOptions)
      .color(`rgb(13, ${51 +  Math.min(204, Math.max(0, (this.tempSetting - 16) * 14))}, ${40 +  Math.min(215, Math.max(0, (this.tempSetting - 16) * 15))})`)
      .size({ width: 80, height: 80 })
  }



}

@Component
export struct ControlTemp{
  @Link is_show: boolean;
  @Link arr_farmland: farmland[];
  @State selectedMode: 'auto' | 'heat' | 'cool' | 'dry' = 'auto';
  @State Color_B: string[] = [ThemeColors.success, ThemeColors.danger, ThemeColors.techBlue, ThemeColors.warning]
  @State tempSetting: number = 26;
  @State acColor: string = ThemeColors.success;
  @State is_chang: boolean = true;
  @State is_exist_list: boolean[] = []
  @State is_open_list: boolean[] = []
  @State is_exist: boolean = false
  @State is_open: boolean = false

  private calculateAcColor(): string {
    switch (this.selectedMode) {
      case 'heat': return ThemeColors.danger;
      case 'cool': return ThemeColors.techBlue;
      case 'dry': return ThemeColors.warning;
      default: return ThemeColors.success;
    }
  }

  aboutToAppear(): void {
    for (let r of this.arr_farmland) {
      let _is_e = false
      let _is_open = false
      for (let f of r.device_s) {
        if (f.type_id >= 3000 && f.type_id < 4000) {
          this.tempSetting = f.temp
          if (f.mode == "zd") {
            this.selectedMode = "auto"
          } else if (f.mode == 'zr') {
            this.selectedMode = "heat"
          } else if (f.mode == 'zl') {
            this.selectedMode = "cool"
          } else if (f.mode == 'cs') {
            this.selectedMode = "dry"
          } else {
            this.selectedMode = "auto"
          }
          this.is_exist = true
          _is_e = true
          if (f.switch == 1) {
            this.is_open = true
            _is_open = true
          }
        }
      }
      if (_is_e) {
        this.is_exist_list.push(true)
      } else {
        this.is_exist_list.push(false)
      }
      if (_is_open) {
        this.is_open_list.push(true)
      } else {
        this.is_open_list.push(false)
      }
    }
  }

  build() {
    Stack() {
      if (this.is_exist) {
        Column() {
          Row() {
            Text("<")
              .fontSize(22)
              .fontColor(ThemeColors.bgCard)
              .padding(10)
              .onClick(() => this.is_show = false)

            Text("温控设备控制")
              .fontSize(20)
              .fontColor(ThemeColors.bgCard)
              .fontWeight(FontWeight.Bold)
              .flexGrow(1)
              .textAlign(TextAlign.Center)

            Text("")
              .width(44)
          }
          .width('100%')
          .height(80)
          .backgroundColor(ThemeColors.primary)
          .padding({ top: 20 })
          if (this.is_open) {
            Scroll() {
              Column({ space: 16 }) {
                Row() {
                  ForEach(['auto', 'heat', 'cool', 'dry'] as ['auto', 'heat', 'cool', 'dry'], (mode: 'auto' | 'heat' | 'cool' | 'dry', value) => {
                    Button(mode.toUpperCase())
                      .onClick(() => {
                        this.selectedMode = mode;
                        this.acColor = this.calculateAcColor();
                        _IoTad.set_temperature_control_device_by_id(this.tempSetting, "on", this.selectedMode == "auto" ? "zd" : this.selectedMode == "heat" ? "zr" : this.selectedMode == "cool" ? "zl" : this.selectedMode == "dry" ? "cs" : "zd")
                      })
                      .padding(10)
                      .backgroundColor(this.selectedMode === mode ? this.Color_B[value] : ThemeColors.bgCard)
                      .fontColor(this.selectedMode === mode ? ThemeColors.bgCard : ThemeColors.textPrimary)
                      .borderRadius(8)
                      .margin(5);
                  });
                }
                .margin({ top: 16 })
                .justifyContent(FlexAlign.Center)

                Column() {
                  Text(`当前温度: ${this.tempSetting.toFixed(1)}°C`)
                    .fontSize(24)
                    .fontWeight(FontWeight.Medium)
                    .margin(10)
                    .fontColor(ThemeColors.textPrimary);

                  Row() {
                    Button('-')
                      .onClick(async () => {
                        if (this.tempSetting > 16) {
                          this.tempSetting -= 1;
                          this.is_chang = !this.is_chang;
                          await _IoTad.set_temperature_control_device_by_id(this.tempSetting, "on", this.selectedMode == "auto" ? "zd" : this.selectedMode == "heat" ? "zr" : this.selectedMode == "cool" ? "zl" : this.selectedMode == "dry" ? "cs" : "zd")
                        }
                      })
                      .padding(10)
                      .backgroundColor(ThemeColors.bgCard)
                      .borderRadius(8)
                      .margin(5)
                      .fontColor(ThemeColors.textPrimary);

                    this.CustomCircularProgress();

                    Button('+')
                      .onClick(async () => {
                        if (this.tempSetting < 30) {
                          this.tempSetting += 1;
                          this.is_chang = !this.is_chang;
                          await _IoTad.set_temperature_control_device_by_id(this.tempSetting, "on", this.selectedMode == "auto" ? "zd" : this.selectedMode == "heat" ? "zr" : this.selectedMode == "cool" ? "zl" : this.selectedMode == "dry" ? "cs" : "zd")
                        }
                      })
                      .padding(10)
                      .backgroundColor(ThemeColors.bgCard)
                      .borderRadius(8)
                      .margin(5)
                      .fontColor(ThemeColors.textPrimary);
                  }
                  .margin(10);
                }
                .width("90%")
                .backgroundColor(ThemeColors.bgCard)
                .borderRadius(16)
                .padding(20)
                .shadow({
                  color: ThemeColors.shadowDark,
                  radius: 8,
                  offsetX: 0,
                  offsetY: 4
                })

                List({ space: 12 }) {
                  ForEach(this.arr_farmland, (item: farmland, value) => {
                    if (this.is_exist_list[value]) {
                      ListItem() {
                        Row() {
                          Text(item.name)
                            .fontSize(18)
                            .fontWeight(FontWeight.Medium)
                            .fontColor(ThemeColors.textPrimary)

                          Row() {
                            Image($r(`app.media.ac_${this.selectedMode}`))
                              .height(40)
                              .width(40)
                              .fillColor(this.calculateAcColor());

                            Text(`${this.tempSetting.toFixed(1)}°C`)
                              .fontSize(20)
                              .margin({ left: 8, right: 8 })
                              .fontColor(ThemeColors.textPrimary);

                            Toggle({
                              type: ToggleType.Switch,
                              isOn: this.is_open_list[value]
                            })
                              .onClick(async () => {
                                let _is_exist_open: boolean = false
                                if (this.is_open_list[value]) {
                                  this.is_open_list[value] = false
                                  await _IoTad.set_temperature_control_device_by_id(25, "off", this.selectedMode == "auto" ? "zd" : this.selectedMode == "heat" ? "zr" : this.selectedMode == "cool" ? "zl" : this.selectedMode == "dry" ? "cs" : "zd")
                                } else {
                                  this.is_open_list[value] = true
                                  await _IoTad.set_temperature_control_device_by_id(25, "on", this.selectedMode == "auto" ? "zd" : this.selectedMode == "heat" ? "zr" : this.selectedMode == "cool" ? "zl" : this.selectedMode == "dry" ? "cs" : "zd")
                                }
                                this.is_open = this.is_open_list.some(i => i)
                              })
                          }
                          .flexGrow(1)
                          .justifyContent(FlexAlign.End)
                        }
                        .width('100%')
                        .padding(20)
                        .backgroundColor(ThemeColors.bgCard)
                        .borderRadius(16)
                        .shadow({
                          color: ThemeColors.shadowDark,
                          radius: 8,
                          offsetX: 0,
                          offsetY: 4
                        })
                      }
                    }
                  });
                }
                .width('100%')
                .padding(16)
              }
            }
            .flexGrow(1)
          } else {
            List({ space: 12 }) {
              ForEach(this.arr_farmland, (item: farmland, value) => {
                if (this.is_exist_list[value]) {
                  ListItem() {
                    Row() {
                      Text(item.name)
                        .fontSize(18)
                        .fontWeight(FontWeight.Medium)
                        .fontColor(ThemeColors.textPrimary)

                      Row() {
                        Image($r(`app.media.ac_${this.selectedMode}`))
                          .height(40)
                          .width(40)
                          .fillColor(this.calculateAcColor());

                        Text(`${this.tempSetting.toFixed(1)}°C`)
                          .fontSize(20)
                          .margin({ left: 8, right: 8 })
                          .fontColor(ThemeColors.textPrimary);

                        Toggle({
                          type: ToggleType.Switch,
                          isOn: this.is_open_list[value]
                        })
                          .onClick(async () => {
                            let _is_exist_open: boolean = false
                            if (this.is_open_list[value]) {
                              this.is_open_list[value] = false
                              await _IoTad.set_temperature_control_device_by_id(25, "off", this.selectedMode == "auto" ? "zd" : this.selectedMode == "heat" ? "zr" : this.selectedMode == "cool" ? "zl" : this.selectedMode == "dry" ? "cs" : "zd")
                            } else {
                              this.is_open_list[value] = true
                              await _IoTad.set_temperature_control_device_by_id(25, "on", this.selectedMode == "auto" ? "zd" : this.selectedMode == "heat" ? "zr" : this.selectedMode == "cool" ? "zl" : this.selectedMode == "dry" ? "cs" : "zd")
                            }
                            this.is_open = this.is_open_list.some(i => i)
                          })
                      }
                      .flexGrow(1)
                      .justifyContent(FlexAlign.End)
                    }
                    .width('100%')
                    .padding(20)
                    .backgroundColor(ThemeColors.bgCard)
                    .borderRadius(16)
                    .shadow({
                      color: ThemeColors.shadowDark,
                      radius: 8,
                      offsetX: 0,
                      offsetY: 4
                    })
                  }
                }
              });
            }
            .width('100%')
            .padding(16)
            .flexGrow(1)
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor(ThemeColors.bgPrimary)
      } else {
        Column({ space: 20 }) {
          Text("还没有温控设备呢")
            .fontSize(16)
            .fontColor(ThemeColors.textSecondary)

          Button("前往录入")
            .width(160)
            .height(44)
            .backgroundColor(ThemeColors.primary)
            .fontColor(ThemeColors.bgCard)
            .borderRadius(12)
            .onClick(() => this.is_show = false)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(ThemeColors.bgPrimary)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  CustomCircularProgress() {
    Progress({
      value: this.tempSetting - 16,
      total: 14,
      style: ProgressStyle.Ring
    })
      .style({
        strokeWidth: 10,
        ringStyle: {
          startAngle: -90,
          sweepAngle: 360,
          gapRadius: 0
        }
      } as RingStyleOptions)
      .color(`rgb(13, ${51 + Math.min(204, Math.max(0, (this.tempSetting - 16) * 14))}, ${40 + Math.min(215, Math.max(0, (this.tempSetting - 16) * 15))})`)
      .size({ width: 80, height: 80 })
  }
}

@Component
export struct AboutProject {
  onBack?: () => void;

  build() {
    Stack() {
      Column() {
        Row() {
          Text("<")
            .fontSize(22)
            .fontColor(ThemeColors.bgCard)
            .padding(10)
            .onClick(() => {
              if (this.onBack) {
                this.onBack()
              }
            })

          Text("关于智慧农田")
            .fontSize(20)
            .fontColor(ThemeColors.bgCard)
            .fontWeight(FontWeight.Bold)
            .flexGrow(1)
            .textAlign(TextAlign.Center)

          Text("")
            .width(44)
        }
        .width('100%')
        .height(60)
        .backgroundColor(ThemeColors.primary)
        .padding({ top: 10 })
        Column({ space: 15 }) {
          Text("系统介绍")
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.primary)
            .margin({ top: 40 })

          Text("本系统基于鸿蒙ArkTS开发\n实现环境监测、智能灌溉\n以及设备控制、场景联动\n适用于大棚/大田现代化农业管理")
            .fontSize(16)
            .fontColor(ThemeColors.textSecondary)
            .textAlign(TextAlign.Center)
            .width("90%")
            .margin({ top: 20 })
        }
        .width("100%")
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeColors.bgPrimary)
    }
    .width("100%")
    .height("100%")
  }
}

@Component
export struct AccountSetting {
  @State username: string = '';
  @State oldPwd: string = '';
  @State newPwd: string = '';
  onBack?: () => void;
  private userPreferences: preferences.Preferences | null = null;

  async aboutToAppear() {
    try {
      const context = getContext(this) as common.UIAbilityContext;
      this.userPreferences = await preferences.getPreferences(context, 'userData');
      const lastLogin = await this.userPreferences.get('last_login', '');
      this.username = lastLogin as string;
    } catch (e) {
      console.error("初始化存储失败:", e);
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        Row() {
          Text("<")
            .fontSize(22)
            .fontColor(ThemeColors.bgCard)
            .padding({ left: 12, right: 12 })
            .onClick(() => {
              if (this.onBack) {
                this.onBack()
              }
            })

          Text("账号设置")
            .fontSize(20)
            .fontColor(ThemeColors.bgCard)
            .fontWeight(FontWeight.Bold)
            .flexGrow(1)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(50)
        .backgroundColor(ThemeColors.primary)
        .alignItems(VerticalAlign.Center)
        Column({ space: 15 }) {
          TextInput({ placeholder: "当前用户", text: this.username })
            .width("90%")
            .height(50)
            .backgroundColor(ThemeColors.bgCard)
            .borderRadius(10)
            .fontColor(ThemeColors.textPrimary)
            .placeholderColor(ThemeColors.textTertiary)
            .enabled(false)

          TextInput({ placeholder: "请输入旧密码" })
            .type(InputType.Password)
            .width("90%")
            .height(50)
            .backgroundColor(ThemeColors.bgCard)
            .borderRadius(10)
            .fontColor(ThemeColors.textPrimary)
            .placeholderColor(ThemeColors.textTertiary)
            .onChange(v => this.oldPwd = v);

          TextInput({ placeholder: "请输入新密码" })
            .type(InputType.Password)
            .width("90%")
            .height(50)
            .backgroundColor(ThemeColors.bgCard)
            .borderRadius(10)
            .fontColor(ThemeColors.textPrimary)
            .placeholderColor(ThemeColors.textTertiary)
            .onChange(v => this.newPwd = v);

          Button("保存修改")
            .width("90%")
            .height(50)
            .backgroundColor(ThemeColors.primary)
            .backgroundImageSize(ImageSize.Cover)
            .fontColor(ThemeColors.bgCard)
            .borderRadius(10)
            .onClick(async () => {
              if (!this.oldPwd || !this.newPwd) {
                console.log("请填写完整信息");
                return;
              }
              await this.saveNewPassword();
            });


        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .margin({ top: 20 })


      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeColors.bgPrimary)
      .justifyContent(FlexAlign.Start)
    }
    .width("100%")
    .height("100%")
  }
  private async saveNewPassword() {
    if (!this.userPreferences) {
      console.error("存储对象未初始化");
      return;
    }

    try {
      const oldPwdEncrypted = await this.encryptPassword(this.oldPwd);
      const realPwd = await this.userPreferences.get(`user_${this.username}`, '') as string;

      if (oldPwdEncrypted !== realPwd) {
        console.log("旧密码错误");
        return;
      }
      const newPwdEncrypted = await this.encryptPassword(this.newPwd);
      await this.userPreferences.put(`user_${this.username}`, newPwdEncrypted);
      await this.userPreferences.flush();

      console.log("密码修改成功");
      router.back();
    } catch (e) {
      console.error("修改密码失败:", e);
    }
  }

  private async encryptPassword(plainText: string): Promise<string> {
    try {
      const md = cryptoFramework.createMd('SHA256');
      const input: cryptoFramework.DataBlob = {
        data: new util.TextEncoder().encode(plainText)
      };
      await md.update(input);
      const digest = await md.digest();
      return Array.from(new Uint8Array(digest.data))
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');
    } catch (e) {
      console.error("密码加密失败:", e);
      return "";
    }
  }
}

declare interface SliderStyle {
  readonly OutSet: SliderStyle;
}

function set_device(item:Device,command_on_off_number:string){

  if(item.type_id<999){

  }else if(item.type_id<2000){

  }else if(item.type_id<3000){
    _IoTad.set_waterValve_by_id(command_on_off_number)
  }else if(item.type_id<4000){

  }else if(item.type_id<5000){
    _IoTad.set_fan_by_id(command_on_off_number)
  }else if(item.type_id<6000){

  }else if(item.type_id<7000){

  }

}
async function renew_data(){
  await _IoTad.get_data()
}
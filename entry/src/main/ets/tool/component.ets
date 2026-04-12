import { FarmlandDatabase } from "../data/RdbStorage";
import { _IoTad } from "../pages/scan_devices";
import {  Device, farmland } from "./classes";
import { ThemeColors } from '../utils/theme';
import common from '@ohos.app.ability.common';
import http from '@ohos.net.http';


//let new_arr_farmlands:farmland[]
//let new_arr_f:Device[]

//let Farmland_db:FarmlandDatabase = new FarmlandDatabase(globalThis.getContext())
let new_f_R_Id:number

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
  private db: FarmlandDatabase | null = null;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.db = new FarmlandDatabase(context);
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
                if (this.db) {
                  new_f_R_Id = await this.db.getFarmlandsIdByName(this.farmland1.name)
                }
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
      .width('100%')
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
      //new_arr_f = this.arr_dev
    })
  }
}

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
  private db: FarmlandDatabase | null = null;

  aboutToAppear(): void {
    this.Light_number = this.arr_f[this.index_d].lighting
    this.o_f = this.arr_f[this.index_d]
    const context = getContext(this) as common.UIAbilityContext;
    this.db = new FarmlandDatabase(context);
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
              // ❌ 删除这些本地数据库操作
              // if (!this.db) return;
              // let r_id = await this.db.getFarmlandsIdByName(this.farmland1.name)
              // await this.db.deleteDeviceByFarmlandIdAndName(r_id,this.arr_f[this.index_d].name)

              // ✅ 改为只调用后端接口
              try {
                if (!this.db) return;
                let r_id = await this.db.getFarmlandsIdByName(this.farmland1.name);

                const deviceName = this.arr_f[this.index_d].name;

                const httpRequest = http.createHttp();
                const response = await httpRequest.request(
                  'http://127.0.0.1:8080/api/device/delete',
                  {
                    method: http.RequestMethod.POST,
                    header: { 'Content-Type': 'application/json' },
                    extraData: JSON.stringify({
                      farmlandId: r_id,
                      deviceName: deviceName
                    })
                  }
                );

                if (response.responseCode === 200) {
                  const result = JSON.parse(response.result as string) as Record<string, Object>;

                  if (result.code === 200) {
                    // ✅ 后端成功后，只更新 UI
                    this.arr_f = this.arr_f.filter((element) => element.name !== deviceName);
                    this.is_chang = !this.is_chang;
                    console.log("✅ 设备删除成功");
                  } else {
                    AlertDialog.show({
                      message: (result.msg as string) || '删除失败'
                    });
                    httpRequest.destroy();
                    return;
                  }
                } else {
                  AlertDialog.show({
                    message: '网络错误，请重试'
                  });
                  httpRequest.destroy();
                  return;
                }

                httpRequest.destroy();
              } catch (err) {
                console.error("删除设备异常:", err);
                AlertDialog.show({
                  message: '删除失败，请重试'
                });
              }

              this.is_show_d = false;
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

export struct add_device_page {
  @Link _height: string
  @Link arr: Device[]
  @Link farmland1: farmland
  @Link is_show: boolean
  @State dev_name: string = ''
  type: number = 0
  private db: FarmlandDatabase | null = null;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.db = new FarmlandDatabase(context);
  }

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
            if (this.dev_name != '' && this.type != 0 && this.db) {
              // ❌ 删除这行 - 不再操作本地数据库
              // let success = await this.db.insertFuByFarmlandId(new_f_R_Id, this.dev_name, this.type)

              // ✅ 改为只调用后端接口
              const httpRequest = http.createHttp();
              try {
                const response = await httpRequest.request(
                  'http://127.0.0.1:8080/api/device/add',
                  {
                    method: http.RequestMethod.POST,
                    header: { 'Content-Type': 'application/json' },
                    extraData: JSON.stringify({
                      farmlandId: new_f_R_Id,
                      deviceId: this.dev_name + ':' + new_f_R_Id,
                      deviceName: this.dev_name,
                      typeId: this.type
                    })
                  }
                );

                if (response.responseCode === 200) {
                  const result = JSON.parse(response.result as string) as Record<string, Object>;

                  if (result.code === 200) {
                    // ✅ 后端成功后，只更新 UI，不操作本地数据库
                    let success = await this.db.insertFuByFarmlandId(new_f_R_Id, this.dev_name, this.type);

                    if (success === 1) {
                      // 本地保存成功后，更新 UI
                      const newDevice = new Device(this.dev_name, 0, this.type);
                      this.arr = [...this.arr, newDevice];
                      this.farmland1.device_s = this.arr;
                      console.log("✅ 设备添加成功");
                    } else {
                      AlertDialog.show({
                        message: '本地保存失败，请重试'
                      });
                    }
                  } else {
                    AlertDialog.show({
                      message: (result.msg as string) || '添加失败'
                    });
                  }
                } else {
                  AlertDialog.show({
                    message: '网络错误，请重试'
                  });
                }
              } catch (err) {
                console.error("添加设备异常:", err);
                AlertDialog.show({
                  message: '添加失败，请重试'
                });
              } finally {
                httpRequest.destroy();
              }
            }

            animateTo({ duration: 500 }, () => { this._height = '0%' });
            this.is_show = false;
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
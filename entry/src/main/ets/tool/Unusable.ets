import { LocalStorage } from "../data/LocalStorage";
import { FarmlandDatabase } from "../data/RdbStorage";
//import { tcp } from "../pages/Index";
import { API_DeepSeek } from "../pages/OpenAI_Page";
import { _IoTad } from "../pages/scan_devices";
import {  Device, farmland } from "./classes";
import { ThemeColors } from '../utils/theme';

let new_arr_farmlands:farmland[]
let new_arr_f:Device[]

let Farmland_db:FarmlandDatabase = new FarmlandDatabase(globalThis.getContext())
let new_f_R_Id:number

////////可用来补充远程设备里的设备控制的功能
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
              //tcp.sendLED_chang(value,this.device.type_id)
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


/////////////////////////////////////////
//原来的ai组件
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
/////////////////////
//可用于设备总控，可展示正在运行的设备，横向滚动布局，类似于农田小卡片。。。。。纯ai布局

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


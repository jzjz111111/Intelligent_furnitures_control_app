import { tcp } from "./Index";
import { _IoTad } from "./scan_devices";
import {  Device, farmland } from "../tool/classes";
import { ThemeColors } from '../utils/theme';

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

declare interface SliderStyle {
  readonly OutSet: SliderStyle;
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

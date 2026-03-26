import { IoTda } from '../tool/IoTad';
import { On } from '@ohos.UiTest';


let _IoTad:IoTda = new IoTda()
@Entry
@Component
struct Test_Page {
  @State message: string|number = 'Hello World';

  aboutToAppear(): void {
    _IoTad.init()
  }
  build() {
    Column() {

      Text(this.message.toString()).width("100%").height("40%")
      Button("获取数据")
        .onClick(async ()=>{
          this.message = await _IoTad.get_data()
        })

      Row(){
        Button("水阀开").onClick(()=>{
          _IoTad.set_waterValve_by_id("on")
        })
        Button("水阀关").onClick(()=>{
          _IoTad.set_waterValve_by_id("off")
        })
      }
      Row(){
        Button("风扇开").onClick(()=>{
          _IoTad.set_fan_by_id("on")
        })
        Button("风扇关").onClick(()=>{
          _IoTad.set_fan_by_id("off")
        })
      }
      Row(){
        Button("温控设备25").onClick(()=>{
          _IoTad.set_temperature_control_device_by_id(25,"on","zl")
        })
        Button("温控设备28").onClick(()=>{
          _IoTad.set_temperature_control_device_by_id(28,"on","cs")
        })
      }
      Row(){
        Button("补光灯开").onClick(()=>{
          _IoTad.set_LED_brightness_by_id(8888)
        })
        Button("补光灯关").onClick(()=>{
          _IoTad.set_LED_brightness_by_id(1)
        })
      }
    }
    .height('100%')
    .width('100%')
  }
}
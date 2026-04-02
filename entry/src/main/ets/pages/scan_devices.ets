import { IoTda } from '../tool/IoTad';
import Notification from '@ohos.notification'
import Base from '@ohos.base'

import wifi from '@ohos.wifi';
import { router } from '@kit.ArkUI';
import { LocalStorage } from '../data/LocalStorage';


//***********本页面专门用来获取权限，初始化信息*********



export let _IoTad:IoTda = new IoTda()

@Entry
@Component
struct Scan_devices {
  @State message: string = '开始体验';
  locals:LocalStorage = new LocalStorage("scan")
  async aboutToAppear() {
    await _IoTad.init()
    if(await this.locals.getDate("is_scan")){
      router.replaceUrl({
        url:"pages/Search_devices"
      })
      return
    }

    try {
      let isWifiActive = wifi.isWifiActive();
      console.info("isWifiActive:" + isWifiActive);
      AlertDialog.show({message:"WiFi已打开"})
    }catch(error){
      console.error("failed:" + JSON.stringify(error));
      AlertDialog.show({message:"请打开WiFi"})
    }

    await Notification.requestEnableNotification().then(() => {
      console.info("requestEnableNotification success");
    }).catch((err: Base.BusinessError) => {
      console.error(`requestEnableNotification failed, code is ${err}`);
    });

  }


  build() {
    RelativeContainer() {
      Column(){
        Row(){
          Text(this.message)
            .id('Scan_devicesHelloWorld')
            .fontSize($r('app.float.page_text_font_size'))
            .fontWeight(FontWeight.Bold)
            .alignRules({
              center: { anchor: '__container__', align: VerticalAlign.Center },
              middle: { anchor: '__container__', align: HorizontalAlign.Center }
            })
            .fontColor(Color.White)
        }
      }.width("100%").height("20%").backgroundColor("##6d9cee").justifyContent(FlexAlign.Center)



    }
    .backgroundImage($r("app.media.back_house1"))
    .backgroundImageSize(ImageSize.Cover)
    .height('100%')
    .width('100%')
    .onClick(async () => {
      await this.locals.setDate("is_scan",true)
      router.replaceUrl({
        url:"pages/Index"
      })
    })
  }
}
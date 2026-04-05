import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import webview from '@ohos.web.webview';

@Entry
@Component
export struct FarmMonitor {
  build() {
    Column() {
      Button("返回")
        .margin(10)
        .onClick(() => {
          router.back();
        });
      Text("🌾 农田实时监控")
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin(10);
      // 实时监控画面（后续联调修改这里的地址）
      Web({
        src: "http://192.168.204.68",
        controller: new webview.WebviewController()
      })
        .width('100%')
        .height(460)
        .backgroundColor(Color.Black);
      // 查看历史照片按钮
      Button("查看历史监控照片")
        .width('80%')
        .margin(15)
        .backgroundColor('#2D7DFF')
        .fontColor(Color.White)
        .onClick(() => {
          router.pushUrl({
            url: "pages/FarmHistoryPhotos"
          });
        });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.Center);
  }
}
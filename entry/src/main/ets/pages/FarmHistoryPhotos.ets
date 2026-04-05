import router from '@ohos.router';

@Entry
@Component
export struct FarmHistoryPhotos {
  build() {
    Column() {
      Row() {
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back();
          });
        Text("历史监控照片")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center);
      }
      .padding(15);
      // 照片网格布局（后期替换后端真实图片）
      Scroll() {
        Grid() {
          ForEach([1, 2, 3, 4, 5, 6, 7, 8], (item:number) => {
            GridItem() {
              Image("https://picsum.photos/400/300?random=" + item)
                .width('100%')
                .height(150)
                .borderRadius(12)
            }
          })
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .padding(10)
      }
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5');
  }
}
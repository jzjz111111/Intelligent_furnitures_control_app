import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import http from '@ohos.net.http';

interface PhotoData {
  photos: string[];
  count: number;
}

interface PhotoListResponse {
  code: number;
  data: PhotoData;
}

@Entry
@Component
export struct FarmHistoryPhotos {
  @State photoList: string[] = [];  // 存储照片路径列表
  @State isLoading: boolean = true; // 加载状态

  aboutToAppear() {
    this.loadPhotoList();
  }
  private async loadPhotoList() {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        'http://127.0.0.1:8080/api/photo/list',
        { method: http.RequestMethod.GET }
      );

      const result: PhotoListResponse = JSON.parse(response.result.toString()) as PhotoListResponse;

      if (result.code === 200 && result.data.photos) {
        this.photoList = result.data.photos;
        if (this.photoList.length === 0) {
          promptAction.showToast({ message: '暂无监控照片' });
        }
      } else {
        promptAction.showToast({ message: '加载照片失败' });
      }
      httpRequest.destroy();
    } catch (err) {
      console.error("加载照片列表失败", err);
      promptAction.showToast({ message: '加载照片失败' });
    } finally {
      this.isLoading = false;
    }
  }

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
      if (this.isLoading) {
        Column() {
          Text("加载照片中...")
            .fontSize(16)
            .fontColor('#999');
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      } else if (this.photoList.length > 0) {
        Scroll() {
          Grid() {
            ForEach(this.photoList, (photoPath: string) => {
              GridItem() {
                Image(photoPath)
                  .width('100%')
                  .height(150)
                  .borderRadius(12)
                  .objectFit(ImageFit.Cover);
              }
            })
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(10)
          .rowsGap(10)
          .padding(10)
        }
        .layoutWeight(1);
      } else {
        Column() {
          Text("暂无监控照片")
            .fontSize(16)
            .fontColor('#999');
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center);
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5');
  }
}
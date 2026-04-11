/*import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import webview from '@ohos.web.webview';
import http from '@ohos.net.http';
import video from '@ohos.multimedia.media';

interface VideoResponse {
  code: number;
  data: {
    videoPath?: string;
    message?: string;
  };
}

private videoController: VideoController = new VideoController();

@Entry
@Component
export struct FarmMonitor {
  @State videoPath: string = "";
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadLatestVideo();
  }
  private async loadLatestVideo() {
    try {
      const userId = 1; // 改成实际登录用户ID
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `http://127.0.0.1:8080/api/video/latest?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );

      const result: VideoResponse = JSON.parse(response.result.toString()) as VideoResponse;

      if (result.code === 200 && result.data.videoPath) {
        this.videoPath = result.data.videoPath;
      } else {
        promptAction.showToast({ message: '暂无监控视频' });
      }
      httpRequest.destroy();
    } catch (err) {
      console.error("加载视频失败", err);
    } finally {
      this.isLoading = false;
    }
  }

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
      if (this.isLoading) {
        Text("加载视频中...")
          .fontSize(16)
          .fontColor('#999');
      } else if (this.videoPath) {
        Video({
          src: this.videoPath,
          controller: this.videoController
        })
          .width('100%')
          .height(460)
          .autoPlay(true)
          .controls(true);
      } else {
        Text("暂无监控视频")
          .fontSize(16)
          .fontColor('#999');
      }

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
}*/
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import http from '@ohos.net.http';

interface VideoData {
  videoPath?: string;
  message?: string;
}

interface VideoResponse {
  code: number;
  data: VideoData;
}

@Entry
@Component
export struct FarmMonitor {
  @State videoPath: string = "";
  @State isLoading: boolean = true;
  private videoController: VideoController = new VideoController();

  aboutToAppear() {
    this.loadLatestVideo();
  }
  private async loadLatestVideo() {
    try {
      const userId = 1;
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(
        `http://127.0.0.1:8080/api/video/latest?userId=${userId}`,
        { method: http.RequestMethod.GET }
      );

      const result: VideoResponse = JSON.parse(response.result.toString()) as VideoResponse;

      if (result.code === 200 && result.data.videoPath) {
        this.videoPath = result.data.videoPath;
      } else {
        promptAction.showToast({ message: '暂无监控视频' });
      }
      httpRequest.destroy();
    } catch (err) {
      console.error("加载视频失败", err);
    } finally {
      this.isLoading = false;
    }
  }

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
      if (this.isLoading) {
        Text("加载视频中...")
          .fontSize(16)
          .fontColor('#999');
      } else if (this.videoPath) {
        Video({
          src: this.videoPath,
          controller: this.videoController
        })
          .width('100%')
          .height(460)
          .autoPlay(true)
          .controls(true);
      } else {
        Text("暂无监控视频")
          .fontSize(16)
          .fontColor('#999');
      }

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

import { faceDetector } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import buffer from '@ohos.buffer';
import { webview } from '@kit.ArkWeb';
import { http } from '@kit.NetworkKit';

@Entry
@Component
export struct face_cam {
  @State chooseImage: PixelMap | undefined = undefined
  @State dataValues: string = ''
  @State is_choose:boolean = false
  @Link is_show:boolean
  private baseUrl: string = 'http://192.168.204.68';
  buffer:string|undefined = undefined
  build() {
    Column() {
      Button("返回")
        .onClick(()=>{
          this.is_show = false
        })

      if(this.is_choose){
        Image(this.chooseImage)
          .objectFit(ImageFit.Fill)
          .height('60%')
      }else{
        CameraPage()
      }
      Text(this.dataValues)
        .copyOption(CopyOptions.LocalDevice)
        .height('15%')
        .margin(10)
        .width('60%')
      Button('选择图片录入')
        .type(ButtonType.Capsule)
        .fontColor(Color.White)
        .alignSelf(ItemAlign.Center)
        .width('80%')
        .margin(10)
        .onClick(() => {
          // 拉起图库
          this.is_choose = true
          this.selectImage()
        })
      Button('录入')
        .type(ButtonType.Capsule)
        .fontColor(Color.White)
        .alignSelf(ItemAlign.Center)
        .width('80%')
        .margin(10)
        .onClick(async () => {
          if(this.is_choose){
            this.is_choose = false
            console.log("buffer:::"+JSON.stringify(this.buffer))

            this.registerFace(this.buffer?this.buffer:'null')

          }else{
            AlertDialog.show({message:"请选择图片"})
          }
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(Color.White)
  }

  private async selectImage() {
    let uri = await this.openPhoto()
    if (uri === undefined) {
      hilog.error(0x0000, 'faceDetectorSample', "Failed to get uri.");
    }
    this.loadImage(uri);
  }

  private openPhoto(): Promise<string> {
    return new Promise<string>((resolve) => {
      let photoPicker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
      photoPicker.select({
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      }).then(res => {
        resolve(res.photoUris[0])
      }).catch((err: BusinessError) => {
        hilog.error(0x0000, 'faceDetectorSample', `Failed to get photo image uri.code：${err.code}，message：${err.message}`);
        resolve('');
      })
    })
  }
  private loadImage(name: string) {
    setTimeout(async () => {
      let imageSource: image.ImageSource | undefined = undefined;
      let fileSource = await fileIo.open(name, fileIo.OpenMode.READ_ONLY);
      imageSource = image.createImageSource(fileSource.fd);
      this.chooseImage = await imageSource.createPixelMap();
      this.pixelMapToBuffer(this.chooseImage)
      this.dataValues = "";
      hilog.info(0x0000, 'faceDetectorSample', 'this.chooseImage:', this.chooseImage);
    }, 100
    )
  }
  async pixelMapToBuffer(pixelMap: image.PixelMap): Promise<ArrayBuffer> {
    try {
      // 1. 创建PixelMap打包器
      const packer = image.createImagePacker();

      // 2. 设置输出格式（JPEG/PNG）
      const options: image.PackingOption = {
        format: "image/jpeg", // 或 "image/png"
        quality: 90          // JPEG质量 (0-100)
      };

      // 3. 执行转换

      const arrayBuffer:ArrayBuffer = await packer.packing(pixelMap, options);
      console.log("buffer:::"+arrayBuffer.byteLength)
      this.buffer = await arrayBufferToBase64(arrayBuffer)
      return arrayBuffer;

    } catch (error) {
      console.error('转换失败:', (error as BusinessError).message);
      //throw error;
      return new ArrayBuffer(1)
    }
  }
  async sendCommand(cmd: string, val?: string): Promise<boolean> {
    try {
      const url = `${this.baseUrl}/control?cmd=${cmd}${val ? `&val=${val}` : ''}`;
      let response = http.createHttp()
      let resp = await response.request(url, { method:http.RequestMethod.GET });
      return resp.responseCode === 200;
    } catch (err) {
      console.error(`Command failed: ${err}`);
      return false;
    }
  }
  async registerFace(imageBase64: string): Promise<boolean> {
    const url = 'http://192.168.204.68/api/face_register';
    /*const formData = new FormData();
    formData.append('file', `data:image/jpeg;base64,${imageBase64}`);
    formData.append('command', 'register');*/
    const body:body = {
      file:`data:image/jpeg;base64,${imageBase64}`,
      command:'register'
    }

    try {
      let response = await http.createHttp().request(
        url,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'multipart/form-data'
          },
          extraData:JSON.stringify(body)
        }
      );
      return response.result === 'SUCCESS';
    } catch (err) {
      console.error('Upload failed:', err);
      return false;
    }
  }
}
interface body{
  file:string
  command:string
}
@Component
struct CameraPage {
  private ip: string = '192.168.204.68';
  private port: number = 81;
  //  //${this.ip}:${this.port}/stream
  build() {
    Column() {
      Web({ src: `http://192.168.204.68`,controller:new webview.WebviewController })
        .width('100%')
        .height(500)
      /*.onControllerReady((controller) => {
        controller.loadUrl(`http://${this.ip}:${this.port}/stream`);
      })*/
    }
  }
}

async function arrayBufferToBase64(buffer: ArrayBuffer): Promise<string> {
  // ArrayBuffer转Base64实现
  let binary = '';
  let bytes = new Uint8Array(buffer);
  console.log("buffer:::1"+buffer.byteLength)
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  console.log("buffer:::1"+binary.toString())
  return binary;
}
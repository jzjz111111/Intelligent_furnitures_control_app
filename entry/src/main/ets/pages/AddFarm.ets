import { FarmlandDatabase } from "../data/RdbStorage";
import { _IoTad } from "../pages/scan_devices";
import {  farmland } from "../tool/classes";
import picker from '@ohos.file.picker';
import { ThemeColors } from '../utils/theme';
//import common from '@ohos.app.ability.common';
import http from '@ohos.net.http';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import fileUri from '@ohos.file.fileuri';
import resourceManager from '@ohos.resourceManager';
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';


interface FarmUploadResponseData {
  imagePath: string;
  zoneId: number;
}

interface FarmUploadResponse {
  code: number;
  data: FarmUploadResponseData;
  msg: string;
}

interface FarmUploadRequest {
  userId: number;
  farmName: string;
  location: string;
  note: string;
  base64: string;
  fileName: string;
}

@Component
export struct add_farmland_page {
  @Link arr: farmland[]
  @State dev_name: string = ''
  @Link is_show: boolean
  @State avatarUri: string = ''

  private db: FarmlandDatabase | null = null;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.db = new FarmlandDatabase(context);
  }
  // 1. 方法接收一个 string 类型的 uri，并返回一个 Promise<string>
  async readPhotoToBase64(uri: string): Promise<string> {
    // 2. 明确 context 的类型为 common.UIAbilityContext
    let context = getContext(this) as common.UIAbilityContext;

    // 3. 明确 file 变量的类型为 fs.File
    let file: fs.File;
    try {
      // 直接用 fs.open 打开 URI
      file = await fs.open(uri, fs.OpenMode.READ_ONLY);
    } catch (err) {
      // 4. 错误处理时，明确 err 的类型为 BusinessError
      let error = err as BusinessError;
      console.error(`打开文件失败，错误码: ${error.code}, 信息: ${error.message}`);
      throw new Error('打开文件失败'); // 抛出错误，让调用方处理
    }

    // 5. 使用 statSync 获取文件信息，并明确 stat 变量的类型为 fs.Stat
    let stat: fs.Stat = fs.statSync(file.fd);

    // 6. 根据文件大小创建一个 ArrayBuffer
    let buffer = new ArrayBuffer(stat.size);
    // 7. 将文件内容读取到 buffer 中
    await fs.read(file.fd, buffer);

    // 8. 读取完成后，关闭文件
    await fs.close(file);

    // 9. 将 buffer 转为 Base64 字符串
    let base64Helper = new util.Base64Helper();
    let base64String = base64Helper.encodeToStringSync(new Uint8Array(buffer));

    return base64String;
  }

  build() {

    Stack() {
      Column() {
        // ========== 头像选择框 ==========
        Stack({ alignContent: Alignment.Center }) {
          // 如果已经选了头像，就显示图片
          if (this.avatarUri) {
            Image(this.avatarUri)
              .width(90)
              .height(90)
              .borderRadius(45)
              .objectFit(ImageFit.Cover)
          } else {
            // 没选头像，显示灰色圆形 + 文字
            Circle({ width: 90, height: 90 })
              .fill(ThemeColors.borderLight)
            Text("点击选头像")
              .fontSize(13)
              .fontColor(ThemeColors.textSecondary)
          }
        }
        .onClick(() => {
          this.selectAvatar() // 点击就打开相册
        })
        .margin({ bottom: 15 })
        // ========== 头像区域结束 ==========
        TextInput({ placeholder: '输入农田名称' })
          .onChange((value) => {
            this.dev_name = value
          })
          .backgroundColor(ThemeColors.bgGlass)
          .fontColor(ThemeColors.textPrimary)
          .placeholderColor(ThemeColors.textTertiary)
        Row(){
          Button('完成')
            .backgroundColor(ThemeColors.primary)
            .fontColor(ThemeColors.bgCard)
            .onClick(async () => {
              if (this.dev_name != '' && this.db) {
                // 检查是否选择了头像
                if (!this.avatarUri) {
                  AlertDialog.show({
                    message: "请先选择农田头像"
                  })
                  return
                }

                try {
                  const userId = 1

                  const fileName = this.avatarUri.split('/').pop() || 'farm_avatar.jpg'

                  const requestBody: FarmUploadRequest = {
                    userId: userId,
                    farmName: this.dev_name,
                    location: "",
                    note: "",
                    base64: "",
                    fileName: fileName
                  }

                  try {
                    // 直接调用我们新写的方法
                    requestBody.base64 = await this.readPhotoToBase64(this.avatarUri);
                    console.info("图片读取成功，base64长度:", requestBody.base64.length);

                    // 验证 base64 是否有效
                    if (requestBody.base64.length === 0) {
                      AlertDialog.show({ message: "图片数据为空，请重新选择" });
                      return;
                    }
                  } catch (err) {
                    // 这里的错误类型也最好明确一下
                    let error = err as Error;
                    console.error("读取图片失败:", error.message);
                    AlertDialog.show({ message: `图片读取失败：${error.message}` });
                    return;
                  }


                  let httpRequest = http.createHttp();
                  console.error('=== 准备发送上传请求，URL: http://127.0.0.1:8080/api/farm/uploadAvatar ===');
                  console.error('=== requestBody 预览: userId=' + requestBody.userId + ', farmName=' + requestBody.farmName + ', base64长度=' + requestBody.base64.length);
                  httpRequest.request(
                    'http://127.0.0.1:8080/api/farm/uploadAvatar',
                    {
                      method: http.RequestMethod.POST,
                      header: {
                        'Content-Type': 'application/json'
                      },
                      extraData: JSON.stringify(requestBody)
                    },
                    (err: Error, data: http.HttpResponse) => {
                      if (!err && data.result) {
                        const result: FarmUploadResponse = JSON.parse(data.result as string) as FarmUploadResponse
                        console.log("后端返回结果:", JSON.stringify(result))

                        if (result.code === 200) {
                          this.db?.insertFarmland(
                            new farmland(this.dev_name, [], result.data.imagePath, result.data.zoneId)
                          ).then((success) => {
                            if (success != -1) {
                              setTimeout(() => {
                                this.arr.push(new farmland(this.dev_name, [], result.data.imagePath, result.data.zoneId))
                              }, 500)
                              AlertDialog.show({ message: "农田创建成功！" })
                            } else {
                              AlertDialog.show({ message: "名字重复了哦" })
                            }
                          })
                        } else {
                          AlertDialog.show({ message: (result.msg as string) || "上传失败，请重试" })
                        }
                      } else {
                        AlertDialog.show({ message: "网络错误，请检查服务器是否启动" })
                      }
                    }
                  )

                } catch (err) {
                  console.error("上传农田图片失败:", err)
                  AlertDialog.show({ message: "上传失败" })
                }

              } else {
                AlertDialog.show({
                  message: "请输入农田名称"
                })
              }
              this.is_show = false
            })
            .padding(5)
            .width(100)

          Button('返回')
            .backgroundColor(ThemeColors.secondary)
            .fontColor(ThemeColors.bgCard)
            .onClick(() => {
              this.is_show = false
            })
            .padding(5)
            .width(100)
        }
        .height(100)
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)
      }
      .height('50%')
      .width('100%')
      .borderRadius(20)
      .backgroundImage($r('app.media.bottom_bg4'))
      .backgroundImageSize(ImageSize.Cover)
      .justifyContent(FlexAlign.End)
    }

    .height('100%')
    .width('100%')
    .backgroundColor('rgba(13, 51, 40, 0.65)')

  }
  // 打开相册选择头像
  async selectAvatar() {
    try {
      // 1. 创建选择配置
      let photoOption = new picker.PhotoSelectOptions();

      // 2. 只允许选图片
      photoOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;

      // 3. 最多选1张
      photoOption.maxSelectNumber = 1;

      // 4. 打开相册
      const photoPicker = new picker.PhotoViewPicker();
      const selectResult = await photoPicker.select(photoOption);
      if (selectResult.photoUris && selectResult.photoUris.length > 0) {
        this.avatarUri = selectResult.photoUris[0];
        console.info("选中头像地址：", this.avatarUri);
      } else {
        console.info("用户取消了选择");
        // 不赋值，保持原样
      }
    } catch (err) {
      console.error("选择图片失败：", err);
    }
  }
}



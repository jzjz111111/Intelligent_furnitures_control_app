import { FarmlandDatabase } from "../data/RdbStorage";
import { _IoTad } from "../pages/scan_devices";
import {  farmland } from "../tool/classes";
import picker from '@ohos.file.picker';
import { ThemeColors } from '../utils/theme';
import common from '@ohos.app.ability.common';
import http from '@ohos.net.http';
import fs from '@ohos.file.fs';
import util from '@ohos.util';
import fileUri from '@ohos.file.fileuri';
import resourceManager from '@ohos.resourceManager';
import fileio from '@ohos.fileio';

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

                  // 读取文件并转为 Base64（在第107行之后添加）
                  /*try {
                    const realPath: string = fileUri.getRealPath(this.avatarUri, getContext(this));
                    const file = await fs.open(this.avatarUri, fs.OpenMode.READ_ONLY);
                    const stat = await fs.stat(this.avatarUri);
                    const buffer = new ArrayBuffer(stat.size);
                    await fs.read(file.fd, buffer, { offset: 0, length: stat.size });
                    fs.closeSync(file);

                    const uint8Array = new Uint8Array(buffer);
                    const base64Helper: util.Base64Helper = new util.Base64Helper();
                    requestBody.base64 = base64Helper.encodeToStringSync(uint8Array);
                    console.log("开始上传农田图片...", "userId:", userId, "farmName:", this.dev_name, "fileName:", fileName, "base64长度:", requestBody.base64.length)
                  } catch (err) {
                    console.error("读取图片失败:", err);
                    AlertDialog.show({ message: "图片读取失败" });
                    return;
                  }*/
                  // 读取文件并转为 Base64
                  try {
                    const context = getContext(this) as common.UIAbilityContext;
                    // 去掉 file:// 前缀
                    const uriPath = this.avatarUri.replace('file://', '');

                    // 通过 resourceManager 获取文件描述符
                    const fileDescriptor: resourceManager.RawFileDescriptor = await context.resourceManager.getRawFileDescriptor(uriPath);
                    const fd: number = fileDescriptor.fd;
                    const stat = fileio.fstatSync(fd);
                    const buffer = new ArrayBuffer(stat.size);
                    fileio.readSync(fd, buffer, { offset: 0, length: stat.size });

                    const uint8Array = new Uint8Array(buffer);
                    const base64Helper = new util.Base64Helper();
                    requestBody.base64 = base64Helper.encodeToStringSync(uint8Array);

                    console.log("图片读取成功，base64长度:", requestBody.base64.length);
                  } catch (err) {
                    console.error("读取图片失败:", JSON.stringify(err));
                    AlertDialog.show({ message: "图片读取失败" });
                    return;
                  }


                  let httpRequest = http.createHttp();
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

      // 5. 获取选中的图片地址
      if (selectResult.photoUris && selectResult.photoUris.length > 0) {
        this.avatarUri = selectResult.photoUris[0];
        console.log("选中头像地址：", this.avatarUri);
      }
    } catch (err) {
      console.error("选择图片失败：", err);
    }
  }
}



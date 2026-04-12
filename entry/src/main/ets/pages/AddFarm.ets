import { FarmlandDatabase } from "../data/RdbStorage";
import {  farmland } from "../tool/classes";
import picker from '@ohos.file.picker';
import { ThemeColors } from '../utils/theme';
import common from '@ohos.app.ability.common';
import http from '@ohos.net.http';
import util from '@ohos.util';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import fs from '@ohos.file.fs';


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
        Row() {
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

                  // 读取文件并转为 Base64（复制到沙箱后读取）
                  try {
                    console.log("源URI:", this.avatarUri);

                    // 1. 获取应用沙箱目录
                    const context = getContext(this) as common.UIAbilityContext;
                    const tempDir = context.cacheDir + '/temp_avatar.jpg';
                    console.log("沙箱路径:", tempDir);

                    // 2. 复制文件到沙箱（通过 URI 直接复制）
                    const srcFile = fs.openSync(this.avatarUri, fs.OpenMode.READ_ONLY);
                    const destFile = fs.openSync(tempDir, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);

                    const stat = fs.statSync(this.avatarUri);
                    const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
                    fs.readSync(srcFile.fd, buffer, { offset: 0, length: stat.size });
                    fs.writeSync(destFile.fd, buffer);

                    fs.closeSync(srcFile);
                    fs.closeSync(destFile);

                    // 3. 从沙箱读取并转为 Base64
                    const destStat = fs.statSync(tempDir);
                    const destBuffer: ArrayBuffer = new ArrayBuffer(destStat.size);
                    const destFd = fs.openSync(tempDir, fs.OpenMode.READ_ONLY);
                    fs.readSync(destFd.fd, destBuffer, { offset: 0, length: destStat.size });
                    fs.closeSync(destFd);

                    const uint8Array: Uint8Array = new Uint8Array(destBuffer);
                    const base64Helper: util.Base64Helper = new util.Base64Helper();
                    requestBody.base64 = base64Helper.encodeToStringSync(uint8Array);

                    console.log("✅ 图片读取成功，base64长度:", requestBody.base64.length);

                    // 4. 清理临时文件
                    try {
                      fs.unlinkSync(tempDir);
                    } catch (e) {
                      console.warn("清理临时文件失败:", e);
                    }

                  } catch (err) {
                    console.error("读取图片失败:", err);
                    AlertDialog.show({ message: "图片读取失败: " + (err as Error).message });
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
                                this.arr.push(new farmland(this.dev_name, [], result.data.imagePath,
                                  result.data.zoneId))
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

  async selectAvatar() {
    try {
      const context = getContext(this) as common.UIAbilityContext;

      // 1. 申请权限
      const atManager = abilityAccessCtrl.createAtManager();
      const permissionResult = await atManager.requestPermissionsFromUser(context, ['ohos.permission.READ_IMAGEVIDEO']);

      // 2. 检查是否授权成功 (0 表示允许)
      if (permissionResult.authResults[0] !== 0) {
        // 权限申请失败，弹窗询问是否重新申请
        AlertDialog.show({
          title: "需要相册权限",
          message: "未获得相册权限，将无法选择照片",
          primaryButton: {
            value: "开启",
            action: () => {
              // 用户点击"开启"，重新调用申请权限
              this.selectAvatar();
            }
          },
          secondaryButton: {
            value: "取消",
            action: () => {}
          }
        });
        return;
      }

      // 3. 打开相册
      let photoOption = new picker.PhotoSelectOptions();
      photoOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoOption.maxSelectNumber = 1;

      const photoPicker = new picker.PhotoViewPicker();
      const selectResult = await photoPicker.select(photoOption);

      if (selectResult.photoUris && selectResult.photoUris.length > 0) {
        this.avatarUri = selectResult.photoUris[0];
        console.log("选中头像地址：", this.avatarUri);
      }
    } catch (err) {
      console.error("选择图片失败：", err);
    }
  }

}
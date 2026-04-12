import http from '@ohos.net.http';
import picker from '@ohos.file.picker';
import router from '@ohos.router';
import { BusinessError } from '@ohos.base';
import fs from '@ohos.file.fs';
import fileUri from '@ohos.file.fileuri';
import { photoAccessHelper } from '@kit.MediaLibraryKit';  // 新增
import { dataSharePredicates } from '@kit.ArkData';
import { abilityAccessCtrl, PermissionRequestResult } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';  // 替代 @ohos.file.fs
import { util } from '@kit.ArkTS';          // 用于 Base64


interface ImageUrl {
  url: string;
}

interface ContentItem {
  type: string;
  text?: string;
  image_url?: ImageUrl;
}

interface Message {
  role: string;
  content: ContentItem[];
}

interface RequestBody {
  model: string;
  messages: Message[];
}

@Entry
@Component
struct AiPestPage {
  @State selectedImageUri: string = '';
  @State isLoading: boolean = false;
  @State result: string = '';
  @State suggestion: string = '';
  @State debugInfo: string = '';

  private readonly API_KEY: string = 'bce-v3/ALTAK-XJJUJTqJTN8lt3bkftnMX/7957cbcaf23092dcc5f04b84a003a4e947d58bdd';
  private readonly API_URL: string = 'https://qianfan.baidubce.com/v2/chat/completions';

  build() {
    Column({ space: 20 }) {
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .onClick(() => router.back())

        Text('🐛 AI害虫识别')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding(20)

      Scroll() {
        Column({ space: 16 }) {
          this.ImageSelector()

          Button(this.isLoading ? '🔍 识别中...' : '🔍 开始识别')
            .width('90%')
            .height(50)
            .backgroundColor(this.isLoading ? '#999' : '#E74C3C')
            .enabled(!this.isLoading && this.selectedImageUri !== '')
            .onClick(() => this.recognizePest())

          if (this.result !== '') {
            this.ResultCard()
          }

          if (this.debugInfo !== '') {
            Column() {
              Text('调试信息:').fontSize(12).fontColor('#666')
              Text(this.debugInfo)
                .fontSize(10)
                .fontColor('#999')
                .maxLines(10)
            }
            .width('90%')
            .padding(10)
            .backgroundColor('#f0f0f0')
            .borderRadius(8)
          }
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  ImageSelector() {
    if (this.selectedImageUri === '') {
      Column({ space: 12 }) {
        Text('📷').fontSize(48)
        Text('点击选择害虫图片').fontSize(16).fontColor('#666')
        Text('支持拍照或从相册选择').fontSize(12).fontColor('#999')
      }
      .width('90%')
      .height(200)
      .backgroundColor('#F5F5F5')
      .borderRadius(16)
      .border({ width: 2, color: '#DDD', style: BorderStyle.Dashed })
      .onClick(() => this.selectImage())
    } else {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Image(this.selectedImageUri)
          .width('90%')
          .height(250)
          .objectFit(ImageFit.Cover)
          .borderRadius(16)

        Button('重新选择')
          .fontSize(12).height(32).margin(8)
          .backgroundColor('rgba(0,0,0,0.6)')
          .onClick(() => {
            this.selectedImageUri = '';
            this.result = '';
            this.debugInfo = '';
          })
      }
      .width('90%')
    }
  }

  @Builder
  ResultCard() {
    Column({ space: 12 }) {
      Row({ space: 8 }) {
        Text('🐛').fontSize(24)
        Text('识别结果').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#E74C3C')
      }
      .alignSelf(ItemAlign.Start)

      Text(this.result)
        .fontSize(16).width('100%')
        .padding(12)
        .backgroundColor('#FFEBEE')
        .borderRadius(8)

      Row({ space: 8 }) {
        Text('💡').fontSize(24)
        Text('防治建议').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#27AE60')
      }
      .alignSelf(ItemAlign.Start)
      .margin({ top: 8 })

      Text(this.suggestion)
        .fontSize(14).width('100%')
        .padding(12)
        .backgroundColor('#E8F5E9')
        .borderRadius(8)
    }
    .width('90%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(16)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.1)' })
  }

  private async selectImage(): Promise<void> {
    try {
      let photoPicker = new picker.PhotoViewPicker();
      let result = await photoPicker.select({
        MIMEType: picker.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1
      });

      if (result.photoUris.length > 0) {
        this.selectedImageUri = result.photoUris[0];
        console.info('选中URI:', this.selectedImageUri);
      }
    } catch (err) {
      console.error('选择图片失败:', JSON.stringify(err));
      this.debugInfo = '选图失败';
    }
  }

  private async recognizePest(): Promise<void> {
    this.isLoading = true;
    this.result = '';
    this.suggestion = '';
    this.debugInfo = '开始...\n';

    let httpRequest: http.HttpRequest | null = null;

    try {
      this.debugInfo += 'URI: ' + this.selectedImageUri.substring(0, 50) + '...\n';

      let base64Image = await this.readFileToBase64(this.selectedImageUri);

      if (base64Image === '') {
        throw new Error('图片处理失败');
      }

      this.debugInfo += '图片转换成功,长度:' + base64Image.length + '\n';

      let requestBody: RequestBody = {
        model: "qwen2.5-vl-7b-instruct",
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: "你是一位农业病虫害防治专家。请仔细分析这张农作物图片，识别是否有病虫害，并按以下格式返回：\n\n【害虫/病害名称】：xxx\n【危害程度】：轻度/中度/重度\n【症状描述】：xxx\n【防治建议】：\n1. 农业防治：xxx\n2. 物理防治：xxx\n3. 化学防治：xxx\n4. 生物防治：xxx\n\n如果没有发现病虫害，请说明作物健康状况。"
              },
              {
                type: "image_url",
                image_url: {
                  url: "data:image/jpeg;base64," + base64Image
                }
              }
            ]
          }
        ]
      };

      let bodyStr: string = JSON.stringify(requestBody);

      httpRequest = http.createHttp();

      this.debugInfo += '请求API...\n';

      let response = await this.doHttpRequest(httpRequest, bodyStr);

      this.debugInfo += '响应码:' + response.responseCode + '\n';

      if (response.responseCode === 200) {
        this.parseBaiduResponse(response.result.toString());
        this.debugInfo += '成功\n';
      } else {
        this.debugInfo += '失败:' + response.responseCode + '\n';
        this.mockResult();
      }

    } catch (error) {
      this.debugInfo += '错误:' + (error as Error).message + '\n';
      console.error('识别异常:', JSON.stringify(error));
      this.result = '识别失败: ' + (error as Error).message;
      this.mockResult();
    } finally {
      this.isLoading = false;
      if (httpRequest) {
        httpRequest.destroy();
      }
    }
  }

  private doHttpRequest(httpRequest: http.HttpRequest, bodyStr: string): Promise<http.HttpResponse> {
    return new Promise((resolve, reject) => {
      httpRequest.request(
        this.API_URL,
        {
          method: http.RequestMethod.POST,
          header: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + this.API_KEY
          },
          extraData: bodyStr,
          connectTimeout: 30000,
          readTimeout: 60000
        },
        (err: BusinessError | undefined, data: http.HttpResponse | undefined) => {
          if (err) {
            reject(err);
          } else if (data) {
            resolve(data);
          } else {
            reject(new Error('返回数据为空'));
          }
        }
      );
    });
  }

  // 修复：使用 fileUri 转换路径
  private async readFileToBase64(uri: string): Promise<string> {
    try {
      this.debugInfo += '处理URI: ' + uri.substring(0, 40) + '...\n';

      // 直接使用 fileIo 打开（支持 media URI）
      let file = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      let stat = fileIo.statSync(file.fd);

      this.debugInfo += '文件大小: ' + stat.size + '\n';

      if (stat.size === 0) {
        throw new Error('文件为空');
      }

      // 读取到 ArrayBuffer
      let buffer = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buffer);
      fileIo.closeSync(file);

      // 使用 util.Base64Helper 编码（HarmonyOS 5.0 推荐）
      let uint8Array = new Uint8Array(buffer);
      let base64Helper = new util.Base64Helper();
      let base64 = base64Helper.encodeToStringSync(uint8Array);

      this.debugInfo += 'Base64长度: ' + base64.length + '\n';
      return base64;

    } catch (err) {
      this.debugInfo += '读文件失败: ' + JSON.stringify(err) + '\n';
      console.error('文件读取失败:', JSON.stringify(err));
      return '';
    }
  }

  // Base64编码
  private arrayBufferToBase64(buffer: ArrayBuffer): string {
    const base64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let bytes = new Uint8Array(buffer);
    let result = '';
    let i = 0;

    while (i < bytes.length) {
      let byte1 = bytes[i++];
      let byte2 = i < bytes.length ? bytes[i++] : 0;
      let byte3 = i < bytes.length ? bytes[i++] : 0;

      let bitmap = (byte1 << 16) | (byte2 << 8) | byte3;

      result += base64chars.charAt((bitmap >> 18) & 63);
      result += base64chars.charAt((bitmap >> 12) & 63);
      result += i - 2 < bytes.length ? base64chars.charAt((bitmap >> 6) & 63) : '=';
      result += i - 1 < bytes.length ? base64chars.charAt(bitmap & 63) : '=';
    }

    return result;
  }

  private parseBaiduResponse(responseStr: string): void {
    try {
      let res: Record<string, Object> = JSON.parse(responseStr) as Record<string, Object>;

      let choices: Object | undefined = res['choices'];
      if (choices && Array.isArray(choices) && choices.length > 0) {
        let firstChoice: Record<string, Object> = choices[0] as Record<string, Object>;
        let message: Record<string, Object> | undefined = firstChoice['message'] as Record<string, Object>;
        if (message) {
          let content: string = String(message['content']);

          if (content.includes('【害虫/病害名称】')) {
            let lines = content.split('\n');
            let resultLines: string[] = [];
            let suggestionLines: string[] = [];
            let isSuggestion = false;

            for (let line of lines) {
              if (line.includes('【防治建议】')) {
                isSuggestion = true;
                continue;
              }
              if (isSuggestion) {
                suggestionLines.push(line);
              } else {
                resultLines.push(line);
              }
            }

            this.result = resultLines.join('\n');
            this.suggestion = suggestionLines.join('\n');
          } else {
            this.result = content;
            this.suggestion = '请参考上述结果进行防治';
          }
        }
      } else {
        this.result = 'API返回异常';
        this.suggestion = JSON.stringify(res).substring(0, 50);
      }
    } catch (e) {
      this.result = '解析失败';
      this.suggestion = '';
    }
  }

  private mockResult(): void {
    this.result = '【害虫/病害名称】：蚜虫\n【危害程度】：轻度\n【症状描述】：叶片背面聚集，分泌蜜露';
    this.suggestion = '1. 农业防治：清除田间杂草\n2. 物理防治：悬挂黄色粘虫板\n3. 化学防治：吡虫啉1500倍液\n4. 生物防治：保护瓢虫等天敌';
  }
}
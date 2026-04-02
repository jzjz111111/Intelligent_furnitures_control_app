import { detectFieldIssues, ensureSandboxDir } from '../tool/deepseek_service';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { ThemeColors } from '../utils/theme'; // 引入主题色

declare const globalThis: ESObject;
interface AppContextType {
  filesDir?: string;
}

@Entry
@Component
struct DeepseekPage {
  @State private result: string = '点击按钮选择图片并启动识别';
  @State private loading: boolean = false;
  @State private imagePath: string = '';

  async onInit() {
    try {
      const appContext: AppContextType | null = globalThis.context ?? null;
      if (appContext && typeof appContext.filesDir === 'string') {
        await ensureSandboxDir(appContext.filesDir);
        console.info('沙箱目录初始化成功');
      } else {
        console.warn('无法获取 appContext.filesDir');
      }
    } catch (e) {
      if (e instanceof Error) {
        console.error('沙箱目录初始化失败:', e.message);
      } else {
        console.error('沙箱目录初始化失败:', String(e));
      }
    }
  }

  async selectImage() {
    try {
      const photoPicker = new photoAccessHelper.PhotoViewPicker();
      const options: photoAccessHelper.PhotoSelectOptions = {
        MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
        maxSelectNumber: 1,
      };
      const result = await photoPicker.select(options);
      if (result.photoUris.length > 0) {
        this.imagePath = result.photoUris[0];
        this.result = `已选择图片：${this.imagePath}\n\n请点击"开始识别"进行分析`;
      } else {
        this.result = '未选择图片';
      }
    } catch (err) {
      const error = err instanceof Error ? err : new Error(String(err));
      console.error('选择图片失败:', error.message);
      this.result = `选择图片失败：${error.message}`;
    }
  }

  async startRecognition() {
    if (!this.imagePath || this.imagePath.trim() === '') {
      this.result = '请先选择图片或输入图片路径';
      return;
    }

    this.loading = true;
    this.result = '本地 AI 正在分析图像...';

    try {
      const message = await detectFieldIssues(this.imagePath);
      this.result = message;
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : String(err);
      this.result = `识别失败：${errorMessage}`;
    } finally {
      this.loading = false;
    }
  }

  build() {
    Stack() {
      // 背景图（与 homepage 统一）
      Image($r('app.media.SmartFarmBackground'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover);

      // 内容层
      Column() {
        // 标题
        Text('🌱 智慧农田识别')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.textPrimary)
          .margin({ bottom: 32, top: 16 });

        // 输入区域卡片（玻璃拟态）
        Column({ space: 16 }) {
          Row() {
            TextInput({ placeholder: '请输入图片路径或点击右侧按钮选择', text: $$this.imagePath })
              .width('68%')
              .height(48)
              .fontSize(14)
              .fontColor(ThemeColors.textPrimary)
              .placeholderColor(ThemeColors.textTertiary)
              .backgroundColor(ThemeColors.bgGlass) // 玻璃背景
              .borderRadius(12)
              .border({ width: 1, color: ThemeColors.borderLight })
              .padding({ left: 16, right: 16 });

            // 选择图片按钮：白底设计
            Button('选择图片')
              .width('30%')
              .height(48)
              .fontSize(13)
              .fontWeight(FontWeight.Bold)
              .backgroundColor('#FFFFFF') // 白底
              .fontColor(ThemeColors.primary) // 深绿字
              .borderRadius(20)
              .border({ width: 1.5, color: ThemeColors.borderDark })
              .shadow({ color: ThemeColors.shadowDark, radius: 6, offsetX: 0, offsetY: 2 })
              .onClick(() => {
                this.selectImage();
              });
          }
          .width('100%');

          // 开始识别按钮：白底设计（深色不做背景）
          Button('开始识别')
            .width('100%')
            .height(52)
            .borderRadius(26)
            .backgroundColor('#FFFFFF') // 白底，不用深色背景
            .fontColor(ThemeColors.primary) // 深绿字
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .border({ width: 1.5, color: ThemeColors.primary }) // 深绿边框强调
            .shadow({ color: ThemeColors.shadowDark, radius: 8, offsetX: 0, offsetY: 4 })
            .onClick(() => {
              this.startRecognition();
            });
        }
        .width('100%')
        .padding(20)
        .backgroundColor(ThemeColors.cardGlass) // 玻璃卡片背景
        .borderRadius(20)
        .border({ width: 1, color: 'rgba(255,255,255,0.8)' })
        .shadow({ color: ThemeColors.shadowDark, radius: 16, offsetX: 0, offsetY: 8 })
        .margin({ bottom: 20 });

        // 结果显示区域（玻璃拟态卡片）
        Column() {
          Text(this.result)
            .fontSize(15)
            .fontColor(ThemeColors.textPrimary)
            .lineHeight(24)
            .width('100%');

          if (this.loading) {
            Row({ space: 8 }) {
              // 简单的加载动画指示器
              LoadingProgress()
                .width(20)
                .height(20)
                .color(ThemeColors.accent);
              Text('本地 AI 正在分析...')
                .fontSize(14)
                .fontColor(ThemeColors.textSecondary);
            }
            .margin({ top: 12 });
          }
        }
        .width('100%')
        .padding(20)
        .backgroundColor(ThemeColors.cardGlass) // 玻璃背景
        .borderRadius(16)
        .border({ width: 1, color: ThemeColors.borderLight })
        .shadow({ color: ThemeColors.shadowDark, radius: 12, offsetX: 0, offsetY: 4 })
        .layoutWeight(1); // 占据剩余空间
      }
      .padding({ top: 24, left: 20, right: 20, bottom: 32 })
      .alignItems(HorizontalAlign.Center)
      .width('100%')
      .height('100%');
    }
    .width('100%')
    .height('100%');
  }
}
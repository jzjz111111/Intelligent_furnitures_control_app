import { ThemeColors } from '../utils/theme';
import { curves } from '@kit.ArkUI';
import router from '@ohos.router';

// 类型定义
type SceneType = 'lighting' | 'irrigation' | 'pest' | 'environment';

interface SceneItem {
  id: SceneType;
  name: string;
  subtitle: string;
  icon: Resource;
  color: string;
  desc: string;
}

@Entry
@Component
export struct FarmScenePage {
  @State isLightingShow: boolean = false;
  @State isIrrigationShow: boolean = false;
  @State isPestShow: boolean = false;
  @State isEnvironmentShow: boolean = false;
  @State currentScene: SceneType = 'lighting';
  @State panelHeight: string = "0%";
  @State isPageLoaded: boolean = false;

  private sceneList: SceneItem[] = [
    {
      id: 'lighting',
      name: '智慧光照',
      subtitle: 'Smart Lighting',
      icon: $r('app.media.ic_lighting'),
      color: '#F39C12',
      desc: '智能补光系统，根据作物生长周期自动调节光照时长与强度'
    },
    {
      id: 'irrigation',
      name: '智慧灌溉',
      subtitle: 'Smart Irrigation',
      icon: $r('app.media.ic_irrigation'),
      color: '#3498DB',
      desc: '基于土壤湿度传感器数据，精准控制水肥一体化灌溉'
    },
    {
      id: 'pest',
      name: '害虫识别',
      subtitle: 'Pest AI Recognition',
      icon: $r('app.media.ic_pest'),
      color: '#E74C3C',
      desc: 'AI视觉识别技术，实时监测并预警病虫害，自动生成防治方案'
    },
    {
      id: 'environment',
      name: '智慧环境',
      subtitle: 'Environment Monitor',
      icon: $r('app.media.ic_environment'),
      color: '#27AE60',
      desc: '24小时监测温湿度、CO2、PM2.5等环境指标，异常自动告警'
    }
  ];

  aboutToAppear() {
    animateTo({ duration: 600, curve: curves.springMotion() }, () => {
      this.isPageLoaded = true;
    });
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ThemeColors?.bgPrimary || '#F0F9F4')

      // 装饰圆形
      Column()
        .width(300)
        .height(300)
        .backgroundColor(ThemeColors?.primaryLight || '#E8F5E9')
        .borderRadius(150)
        .position({ x: -80, y: -100 })
        .opacity(0.6)
        .blur(30)

      // 主内容
      Column({ space: 20 }) {
        // 标题区
        Column({ space: 8 }) {
          Text("🌾 智慧农场")
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors?.textPrimary || '#2C3E50')

          Text("Smart Farm Control Center")
            .fontSize(14)
            .fontColor(ThemeColors?.textSecondary || '#7F8C8D')
            .letterSpacing(1)
        }
        .margin({ top: 60, bottom: 20 })
        .opacity(this.isPageLoaded ? 1 : 0)
        .scale({ x: this.isPageLoaded ? 1 : 0.8, y: this.isPageLoaded ? 1 : 0.8 })
        .animation({ duration: 600, curve: curves.springMotion() })

        // 四个模块网格
        Grid() {
          ForEach(this.sceneList, (scene: SceneItem) => {
            GridItem() {
              this.SceneCard(scene)
            }
          }, (scene: SceneItem) => scene.id)
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(16)
        .columnsGap(16)
        .padding(20)
        .width('100%')
        .height('auto')
        .layoutWeight(1)
      }
      .width('100%')
      .height('100%')

      // 底部弹层面板 - 纯净版，仅保留 UI 交互
      if (this.isLightingShow || this.isIrrigationShow || this.isPestShow || this.isEnvironmentShow) {
        Column() {
          // 遮罩层
          Blank()
            .width('100%')
            .backgroundColor('rgba(0,0,0,0.4)')
            .onClick(() => this.closeAllPanels())

          // 面板内容 - 只传 onClose
          Column() {
            if (this.isLightingShow) {
              LightingScene({ onClose: () => this.closeAllPanels() })
            } else if (this.isIrrigationShow) {
              SmartIrrigationScene({ onClose: () => this.closeAllPanels() })
            } else if (this.isPestShow) {
              PestRecognitionScene({ onClose: () => this.closeAllPanels() })
            } else if (this.isEnvironmentShow) {
              EnvironmentMonitorScene({ onClose: () => this.closeAllPanels() })
            }
          }
          .width('100%')
          .height(this.panelHeight)
          .backgroundColor(Color.White)
          .borderRadius({ topLeft: 24, topRight: 24 })
          .shadow({ radius: 20, color: 'rgba(0,0,0,0.15)', offsetY: -5 })
          .transition(TransitionEffect.translate({ y: 1000 }).animation({ duration: 400, curve: Curve.EaseOut }))
        }
        .width('100%')
        .height('100%')
        .position({ y: 0 })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  SceneCard(scene: SceneItem) {
    Column({ space: 12 }) {
      Stack() {
        Circle()
          .width(70)
          .height(70)
          .fill(scene.color + '20')
          .blur(1)

        Image(scene.icon)
          .width(36)
          .height(36)
          .fillColor(scene.color)
      }

      Column({ space: 4 }) {
        Text(scene.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors?.textPrimary || '#2C3E50')

        Text(scene.subtitle)
          .fontSize(11)
          .fontColor(ThemeColors?.textTertiary || '#95A5A6')

        Text(scene.desc)
          .fontSize(12)
          .fontColor(ThemeColors?.textSecondary || '#7F8C8D')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }
    }
    .padding(20)
    .width('100%')
    .height(180)
    .backgroundColor(Color.White)
    .borderRadius(20)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 4 })
    .onClick(() => this.openScene(scene.id))
  }

  private openScene(sceneId: SceneType): void {
    // 害虫识别单独跳转到新页面
    if (sceneId === 'pest') {
      router.pushUrl({
        url: 'pages/ai_pest'
      });
      return;
    }

    // 其他三个模块保持原有弹窗逻辑
    this.currentScene = sceneId;
    this.isLightingShow = false;
    this.isIrrigationShow = false;
    this.isPestShow = false;
    this.isEnvironmentShow = false;

    animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
      this.panelHeight = "85%";
      switch(sceneId) {
        case 'lighting':
          this.isLightingShow = true;
          break;
        case 'irrigation':
          this.isIrrigationShow = true;
          break;
        case 'environment':
          this.isEnvironmentShow = true;
          break;
      }
    });
  }

  private closeAllPanels(): void {
    animateTo({ duration: 300, curve: Curve.EaseIn }, () => {
      this.panelHeight = "0%";
      this.isLightingShow = false;
      this.isIrrigationShow = false;
      this.isPestShow = false;
      this.isEnvironmentShow = false;
    });
  }
}

// ==================== 智慧光照场景（纯净版）====================
@Component
struct LightingScene {
  // 只保留 onClose 回调
  onClose: () => void = () => {};

  @State isAutoMode: boolean = true;
  @State lightBrightness: number = 80;

  build() {
    Column({ space: 0 }) {
      Row() {
        Image($r('app.media.ic_back'))
          .width(24)
          .height(24)
          .fillColor(ThemeColors?.textPrimary || '#2C3E50')
          .onClick(this.onClose)

        Text('智慧光照控制')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Toggle({ type: ToggleType.Switch, isOn: this.isAutoMode })
          .selectedColor(ThemeColors?.primary || '#27AE60')
          .onChange((isOn: boolean) => { this.isAutoMode = isOn; })
      }
      .padding(20)
      .width('100%')

      if (this.isAutoMode) {
        Row({ space: 8 }) {
          Text('🤖').fontSize(16)
          Text('自动模式：根据作物生长阶段智能调节光照')
            .fontSize(13)
            .fontColor(ThemeColors?.primary || '#27AE60')
        }
        .padding(12)
        .backgroundColor(ThemeColors?.primaryLight || '#E8F5E9')
        .borderRadius(8)
        .margin({ left: 16, right: 16 })
      }

      Column({ space: 8 }) {
        Row() {
          Text('💡 光照强度').fontSize(16).fontWeight(FontWeight.Medium)
          Text(`${this.lightBrightness}%`)
            .fontSize(16)
            .fontColor(ThemeColors?.primary || '#27AE60')
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Slider({
          value: this.lightBrightness,
          min: 0,
          max: 100,
          step: 5,
          style: SliderStyle.OutSet
        })
          .blockColor(Color.White)
          .trackColor('#E0E0E0')
          .selectedColor(ThemeColors?.primary || '#27AE60')
          .onChange((value: number) => { this.lightBrightness = value; })
      }
      .padding(16)
      .margin(16)
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 8, color: 'rgba(0,0,0,0.05)' })

      Text('光照设备')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ left: 16, top: 8 })
        .alignSelf(ItemAlign.Start)

      // 静态示例设备，移除所有动态数据绑定
      List({ space: 12 }) {
        ListItem() {
          Row({ space: 12 }) {
            Stack() {
              Circle().width(50).height(50).fill('#E8F5E9')
              Image($r('app.media.fill_light')).width(24).height(24).fillColor('#27AE60')
            }
            Column({ space: 4 }) {
              Text('补光灯 #1').fontSize(16).fontWeight(FontWeight.Medium)
              Text('运行中').fontSize(13).fontColor('#27AE60')
            }
            .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: true })
              .selectedColor(ThemeColors?.primary || '#27AE60')
          }
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)' })
        }
      }
      .width('100%')
      .height('auto')
      .padding(16)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}

// ==================== 智慧灌溉场景（纯净版）====================
@Component
struct SmartIrrigationScene {
  onClose: () => void = () => {};
  @State soilMoisture: number = 65;
  @State waterValveOpen: boolean = false;

  build() {
    Column({ space: 16 }) {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24).onClick(this.onClose)
        Text('智慧灌溉系统')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .padding(20)

      Column({ space: 12 }) {
        Text('土壤湿度监测').fontSize(18).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start)

        Row({ space: 20 }) {
          Stack() {
            Circle().width(120).height(120).fill('#E3F2FD')
            Circle().width(100).height(100).fill(Color.White)
            Text(`${this.soilMoisture}%`).fontSize(32).fontWeight(FontWeight.Bold).fontColor('#3498DB')
          }
          Column({ space: 8 }) {
            Text('状态: 湿度适宜').fontSize(16).fontColor('#27AE60')
            Text('上次灌溉: 2小时前').fontSize(13).fontColor('#7F8C8D')
          }
          .layoutWeight(1)
        }
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(16)
      }
      .padding(16)

      Button(this.waterValveOpen ? '💧 停止灌溉' : '💧 立即灌溉')
        .width('90%')
        .height(56)
        .backgroundColor(this.waterValveOpen ? '#E74C3C' : '#3498DB')
        .fontSize(18)
        .borderRadius(28)
        .shadow({ radius: 12, color: 'rgba(52, 152, 219, 0.3)', offsetY: 4 })
        .onClick(() => { this.waterValveOpen = !this.waterValveOpen; })

      Row({ space: 16 }) {
        this.StatCard('今日用水', '120L', '💧', '#3498DB')
        this.StatCard('灌溉次数', '3次', '📊', '#27AE60')
        this.StatCard('节水率', '15%', '🌱', '#F39C12')
      }
      .padding(16)

      List({ space: 12 }) {
        ListItem() {
          Row({ space: 12 }) {
            Text('⏰').fontSize(24)
            Column({ space: 4 }) {
              Text('定时灌溉计划').fontSize(16).fontWeight(FontWeight.Medium)
              Text('每天 08:00, 18:00 自动执行').fontSize(13).fontColor('#7F8C8D')
            }
            .layoutWeight(1)
            Toggle({ type: ToggleType.Switch, isOn: true })
          }
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
        }
      }
      .width('100%')
      .height('auto')
      .padding(16)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  StatCard(label: string, value: string, icon: string, color: string) {
    Column({ space: 4 }) {
      Text(icon).fontSize(28)
      Text(value).fontSize(20).fontWeight(FontWeight.Bold).fontColor(color)
      Text(label).fontSize(12).fontColor('#7F8C8D')
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)' })
  }
}

// ==================== 害虫识别场景（纯净版）====================
@Component
struct PestRecognitionScene {
  onClose: () => void = () => {};
  @State isDetecting: boolean = false;
  @State detectionResult: string = '';
  @State confidence: number = 0;
  @State imageUri: string = '';

  build() {
    Column({ space: 16 }) {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24).onClick(this.onClose)
        Text('🐛 AI害虫识别')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .padding(20)

      Column({ space: 12 }) {
        if (this.imageUri === '') {
          Column({ space: 12 }) {
            Text('📷').fontSize(48)
            Text('点击拍照或上传图片').fontSize(14).fontColor('#7F8C8D')
            Text('支持识别：蚜虫、红蜘蛛、白粉虱等常见害虫')
              .fontSize(12)
              .fontColor('#95A5A6')
          }
          .width('100%')
          .height(200)
          .backgroundColor('#F5F5F5')
          .borderRadius(16)
          .border({ width: 2, color: '#E0E0E0', style: BorderStyle.Dashed })
          .onClick(() => { this.imageUri = 'app.media.sample_farm'; })
        } else {
          Image(this.imageUri)
            .width('100%')
            .height(200)
            .objectFit(ImageFit.Cover)
            .borderRadius(16)
            .onClick(() => { this.imageUri = ''; })
        }

        Button(this.isDetecting ? '🔍 AI识别中...' : '🔍 开始识别')
          .width('100%')
          .height(50)
          .backgroundColor(this.isDetecting ? '#95A5A6' : '#E74C3C')
          .fontSize(16)
          .enabled(!this.isDetecting && this.imageUri !== '')
          .onClick(() => {
            this.isDetecting = true;
            setTimeout(() => {
              this.isDetecting = false;
              this.detectionResult = '发现蚜虫(轻度)';
              this.confidence = 92;
            }, 2000);
          })
      }
      .padding(16)

      if (this.detectionResult !== '') {
        Column({ space: 12 }) {
          Row({ space: 8 }) {
            Text('⚠️').fontSize(24)
            Column({ space: 4 }) {
              Text(this.detectionResult)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#E74C3C')
              Text(`置信度: ${this.confidence}%`).fontSize(14).fontColor('#7F8C8D')
            }
          }
          .padding(16)
          .backgroundColor('#FFEBEE')
          .borderRadius(12)
          .width('100%')

          Column({ space: 8 }) {
            Text('🎯 防治建议').fontSize(16).fontWeight(FontWeight.Bold)
            Text('1. 建议使用黄色粘虫板物理防治\n2. 可使用苦参碱等生物农药喷洒\n3. 保持通风，控制湿度在60%以下')
              .fontSize(14)
              .fontColor('#2C3E50')
              .lineHeight(20)
          }
          .padding(16)
          .backgroundColor('#FFF8E1')
          .borderRadius(12)
          .width('100%')
        }
        .padding(16)
      }

      Text('识别记录')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ left: 16 })
        .alignSelf(ItemAlign.Start)

      List({ space: 8 }) {
        ListItem() {
          Row({ space: 12 }) {
            Text('🐛').fontSize(24)
            Column({ space: 4 }) {
              Text('发现蚜虫(轻)').fontSize(15).fontWeight(FontWeight.Medium)
              Text('昨日 16:45').fontSize(12).fontColor('#95A5A6')
            }
            .layoutWeight(1)
          }
          .padding(12)
          .backgroundColor(Color.White)
          .borderRadius(8)
        }
      }
      .width('100%')
      .height('auto')
      .padding(16)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}

// ==================== 智慧环境监测场景（纯净版）====================
@Component
struct EnvironmentMonitorScene {
  onClose: () => void = () => {};
  @State currentTemp: number = 26.5;
  @State currentHumidity: number = 68;
  @State co2Level: number = 450;
  @State lightIntensity: number = 12000;

  build() {
    Column({ space: 16 }) {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24).onClick(this.onClose)
        Text('🌡️ 环境监测中心')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
      }
      .padding(20)

      Scroll() {
        Column({ space: 16 }) {
          Grid() {
            GridItem() { this.EnvCard('温度', `${this.currentTemp}℃`, '🔥', '#E74C3C', '适宜范围: 20-28℃') }
            GridItem() { this.EnvCard('湿度', `${this.currentHumidity}%`, '💧', '#3498DB', '适宜范围: 60-80%') }
            GridItem() { this.EnvCard('CO2', `${this.co2Level}ppm`, '🌬️', '#27AE60', '适宜范围: 400-800ppm') }
            GridItem() { this.EnvCard('光照', `${this.lightIntensity}Lx`, '☀️', '#F39C12', '适宜范围: 10000-20000Lx') }
          }
          .columnsTemplate('1fr 1fr')
          .rowsGap(12)
          .columnsGap(12)
          .padding(16)

          Column({ space: 12 }) {
            Text('📈 24小时温度趋势')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .alignSelf(ItemAlign.Start)

            Row({ space: 4 }) {
              ForEach([22, 23, 24, 26, 28, 29, 28, 26], (temp: number) => {
                Column() {
                  Blank()
                    .width(30)
                    .height(temp * 3)
                    .backgroundColor(temp > 27 ? '#E74C3C' : '#3498DB')
                    .borderRadius(4)
                  Text(`${temp}°`).fontSize(11).margin({ top: 4 })
                }
              }, (temp: number) => temp.toString())
            }
            .width('100%')
            .padding(12)
            .backgroundColor(Color.White)
            .borderRadius(12)
          }
          .padding(16)

          Column({ space: 12 }) {
            Text('⚠️ 实时告警')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .alignSelf(ItemAlign.Start)

            Row({ space: 12 }) {
              Text('⚠️').fontSize(20)
              Column({ space: 4 }) {
                Text('大棚东侧温度偏高(32℃)').fontSize(14).fontWeight(FontWeight.Medium)
                Text('10:23').fontSize(12).fontColor('#95A5A6')
              }
              .layoutWeight(1)
            }
            .padding(12)
            .backgroundColor('#FFEBEE')
            .borderRadius(8)
          }
          .padding(16)

          Button('📊 导出环境报告')
            .width('90%')
            .height(48)
            .backgroundColor(ThemeColors?.primary || '#27AE60')
            .margin({ bottom: 20 })
            .onClick(() => {})
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  EnvCard(title: string, value: string, icon: string, color: string, subtitle: string) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(icon).fontSize(24)
        Text(title).fontSize(14).fontColor('#7F8C8D')
      }
      .alignSelf(ItemAlign.Start)

      Text(value).fontSize(28).fontWeight(FontWeight.Bold).fontColor(color)
      Text(subtitle).fontSize(11).fontColor('#B0BEC5')
    }
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)' })
    .alignItems(HorizontalAlign.Start)
  }
}
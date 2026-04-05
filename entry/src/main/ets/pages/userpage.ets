// pages/userpage.ets
// 智慧农业 - 个人中心 (修复渲染版)

import { ThemeColors } from '../utils/theme';
import { Device } from '../tool/classes';
import { AccountSetting, AboutProject } from '../tool/component';
import picker from '@ohos.file.picker';
import router from '@ohos.router';
import { LocalStorage } from '../data/LocalStorage';
import { curves, promptAction } from '@kit.ArkUI';

interface QuickItemData {
  title: string;
  icon: string;
  color: string;
}

interface StatData {
  value: string;
  unit: string;
  label: string;
  icon: string;
  color: string;
}

interface MenuItemData {
  title: string;
  icon: string;
  badge: string | null;
  isDanger?: boolean;
  action?: () => void;
}

@Entry
@Component
struct userpage {
  localstorage: LocalStorage = new LocalStorage("userData");

  @State username: string = '';
  @State nickName: string = '智慧农业';
  @State signText: string = '农场主';
  @State avatarUri: string = '';
  @State currentPage: string = 'main';
  @State f_arr: Device[] = [];

  // 动画状态 - 初始化为可见避免渲染问题
  @State avatarScale: number = 1;
  @State avatarGlow: number = 0;
  @State headerExpand: number = 1; // 改为1确保初始可见
  @State menuItemsOpacity: number[] = [1, 1, 1, 1, 1, 1, 1, 1]; // 初始可见
  @State menuItemsTranslate: number[] = [0, 0, 0, 0, 0, 0, 0, 0]; // 初始位置
  @State quickItemsScale: number[] = [1, 1, 1, 1]; // 初始可见
  @State cardElevation: number = 1; // 初始可见

  // 弹窗状态
  @State isNickDialogVisible: boolean = false;
  @State isSignDialogVisible: boolean = false;
  @State tempNick: string = '';
  @State tempSign: string = '';
  @State dialogScale: number = 0.8;
  @State dialogOpacity: number = 0;

  // 按压状态
  @State pressedMenuIndex: number = -1;
  @State pressedQuickIndex: number = -1;

  // 统计数据
  @State statNumbers: number[] = [12, 86, 99.9]; // 直接显示最终值

  aboutToAppear() {
    // 加载用户数据
    this.localstorage.getDate("last_login").then((_User_: string | number | bigint | boolean | object) => {
      this.username = String(_User_ || '');
    });

    AppStorage.setOrCreate('globalAvatar', this.avatarUri);
    AppStorage.setOrCreate('globalNickName', this.nickName);

    // 延迟启动入场动画（确保布局完成）
    setTimeout(() => {
      this.startEntryAnimation();
    }, 100);
  }

  private startEntryAnimation(): void {
    // 头部弹性入场
    this.headerExpand = 0.8;
    animateTo({
      duration: 800,
      curve: curves.springMotion(0.6, 0.8)
    }, () => {
      this.headerExpand = 1;
    });
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // 背景层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ThemeColors.bgPrimary);

      // 主内容层
      if (this.currentPage === 'main') {
        this.MainPage();
      } else if (this.currentPage === 'account') {
        this.AccountPage();
      } else if (this.currentPage === 'about') {
        this.AboutPage();
      }

      // 弹窗层
      this.DialogLayer();
    }
    .width('100%')
    .height('100%');
  }

  // 主页面 - 使用 List 替代 Scroll
  @Builder
  MainPage() {
    Column() {
      // 顶部安全区域
      Row().height(44).width('100%');

      // 使用 List 确保内容正确渲染
      List({ space: 12 }) {
        // 头部卡片
        ListItem() {
          this.HeaderSection()
        }

        // 统计数据
        ListItem() {
          this.StatsSection()
        }

        // 快捷功能
        ListItem() {
          this.QuickAccessSection()
        }

        // 菜单列表
        ListItem() {
          this.MenuSection()
        }

        // 底部占位
        ListItem() {
          Row().height(80).width('100%');
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16 })
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring);
    }
    .width('100%')
    .height('100%');
  }

  // 头部区域 - 简化结构确保渲染
  @Builder
  HeaderSection() {
    Column({ space: 16 }) {
      // 标题栏
      Row() {
        Text("个人中心")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.textPrimary);

        Stack() {
          Text("⚙️")
            .fontSize(20)
            .onClick(() => {
              this.currentPage = 'account';
            });
        }
        .width(40)
        .height(40)
        .backgroundColor(ThemeColors.primaryLight)
        .borderRadius(20);
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween);

      // 用户信息
      Row({ space: 16 }) {
        // 头像
        Stack() {
          // 发光效果
          Circle()
            .width(80)
            .height(80)
            .fill('rgba(0, 245, 160, 0.2)')
            .scale({ x: 1 + this.avatarGlow * 0.2, y: 1 + this.avatarGlow * 0.2 })
            .animation({ duration: 600, curve: curves.springMotion() });

          Image(this.avatarUri || $r("app.media.user"))
            .width(64)
            .height(64)
            .borderRadius(32)
            .backgroundColor(Color.White)
            .border({ width: 3, color: ThemeColors.accent })
            .shadow({ color: ThemeColors.techGlow, radius: 16 })
            .scale({ x: this.avatarScale, y: this.avatarScale })
            .animation({ duration: 300, curve: curves.springMotion() })
            .onClick(() => {
              this.avatarScale = 0.9;
              setTimeout(() => {
                this.avatarScale = 1;
                this.startAvatarPulse();
                this.selectAvatar();
              }, 150);
            });

          // 编辑按钮
          Stack() {
            Text("✏️")
              .fontSize(10);
          }
          .width(24)
          .height(24)
          .backgroundColor(ThemeColors.accent)
          .borderRadius(12)
          .position({ x: 48, y: 48 })
          .onClick(() => {
            this.selectAvatar();
          });
        }
        .width(80)
        .height(80);

        // 用户名称
        Column({ space: 8 }) {
          Row() {
            Text(this.nickName)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeColors.textPrimary);
          }
          .onClick(() => {
            this.tempNick = this.nickName;
            this.showNickDialog();
          });

          Row({ space: 6 }) {
            Text(this.signText)
              .fontSize(13)
              .fontColor(ThemeColors.textSecondary);

            Text("PRO")
              .fontSize(10)
              .fontColor(ThemeColors.accent)
              .fontWeight(FontWeight.Bold)
              .padding({ left: 4, right: 4, top: 2, bottom: 2 })
              .backgroundColor('rgba(0, 245, 160, 0.15)')
              .borderRadius(4);
          }
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor(ThemeColors.primaryLight)
          .borderRadius(12)
          .onClick(() => {
            this.tempSign = this.signText;
            this.showSignDialog();
          });
        }
        .alignItems(HorizontalAlign.Start)
        .flexGrow(1);
      }
      .width('100%');
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeColors.bgCard)
    .borderRadius(20)
    .shadow({ color: ThemeColors.shadowDark, radius: 16, offsetY: 4 })
    .scale({ x: this.headerExpand, y: this.headerExpand })
    .animation({ duration: 800, curve: curves.springMotion() });
  }

  // 统计数据
  @Builder
  StatsSection() {
    Row({ space: 0 }) {
      ForEach([
        { value: '12', unit: '个', label: '设备在线', icon: '📡' },
        { value: '86', unit: '%', label: '土壤湿度', icon: '💧' },
        { value: '99.9', unit: '%', label: '系统稳定', icon: '🛡️' }
      ] as StatData[], (stat: StatData) => {
        Column({ space: 4 }) {
          Text(stat.icon).fontSize(20);
          Row({ space: 2 }) {
            Text(stat.value)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeColors.textPrimary);
            Text(stat.unit)
              .fontSize(11)
              .fontColor(ThemeColors.textTertiary);
          }
          Text(stat.label)
            .fontSize(11)
            .fontColor(ThemeColors.textSecondary);
        }
        .flexGrow(1)
        .padding(12);
      });
    }
    .width('100%')
    .backgroundColor(ThemeColors.bgCard)
    .borderRadius(16)
    .shadow({ color: 'rgba(0,0,0,0.04)', radius: 8 });
  }

  // 快捷入口
  @Builder
  QuickAccessSection() {
    Column({ space: 8 }) {
      Text("快捷功能")
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.textPrimary)
        .width('100%')
        .margin({ bottom: 8 });

      Row({ space: 8 }) {
        ForEach([
          { title: '个人信息', icon: '👤' },
          { title: '农场管理', icon: '🌾' },
          { title: '系统设置', icon: '⚙️' },
          { title: '帮助中心', icon: '❓' }
        ] as QuickItemData[], (item: QuickItemData, index: number) => {
          Column({ space: 6 }) {
            Text(item.icon).fontSize(28);
            Text(item.title)
              .fontSize(12)
              .fontColor(ThemeColors.textSecondary);
          }
          .flexGrow(1)
          .padding(12)
          .backgroundColor(ThemeColors.bgCard)
          .borderRadius(12)
          .shadow({ color: 'rgba(0,0,0,0.04)', radius: 6 })
          .scale({ x: this.pressedQuickIndex === index ? 0.95 : 1, y: this.pressedQuickIndex === index ? 0.95 : 1 })
          .animation({ duration: 100 })
          .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
              this.pressedQuickIndex = index;
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.pressedQuickIndex = -1;
            }
          })
          .onClick(() => {
            this.handleQuickItemClick(index);
          });
        });
      }
      .width('100%');
    }
    .width('100%');
  }

  // 菜单区域
  @Builder
  MenuSection() {
    Column({ space: 8 }) {
      Text("更多功能")
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.textPrimary)
        .width('100%');

      Column({ space: 0 }) {
        ForEach([
          { title: '设备管理', icon: '📡', badge: '3' },
          { title: '地块管理', icon: '🌾', badge: null },
          { title: '数据报表', icon: '📊', badge: 'NEW' },
          { title: '通知设置', icon: '🔔', badge: null },
          { title: '帮助与反馈', icon: '❓', badge: null },
          { title: '账号设置', icon: '👤', badge: null, action: () => this.currentPage = 'account' },
          { title: '关于智慧农田', icon: 'ℹ️', badge: null, action: () => this.currentPage = 'about' },
          { title: '退出登录', icon: '🚪', badge: null, isDanger: true, action: () => this.logout() }
        ] as MenuItemData[], (item: MenuItemData, index: number) => {
          this.MenuItemBuilder(item, index);
        });
      }
      .width('100%')
      .backgroundColor(ThemeColors.bgCard)
      .borderRadius(16)
      .shadow({ color: 'rgba(0,0,0,0.04)', radius: 8 });
    }
    .width('100%');
  }

  @Builder
  MenuItemBuilder(item: MenuItemData, index: number) {
    Row() {
      Row({ space: 12 }) {
        Text(item.icon).fontSize(20);
        Column({ space: 2 }) {
          Text(item.title)
            .fontSize(15)
            .fontColor(item.isDanger ? ThemeColors.danger : ThemeColors.textPrimary);
          if (item.badge) {
            Text(item.badge)
              .fontSize(9)
              .fontColor(Color.White)
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .backgroundColor(item.badge === 'NEW' ? ThemeColors.accent : ThemeColors.techBlue)
              .borderRadius(8);
          }
        }
        .alignItems(HorizontalAlign.Start);
      }
      .flexGrow(1);

      Text("›")
        .fontSize(20)
        .fontColor(item.isDanger ? ThemeColors.danger : ThemeColors.textTertiary);
    }
    .width('100%')
    .padding(14)
    .backgroundColor(this.pressedMenuIndex === index ? ThemeColors.primaryLight : Color.Transparent)
    .borderRadius(index === 0 ? { topLeft: 16, topRight: 16 } :
      index === 7 ? { bottomLeft: 16, bottomRight: 16 } : 0)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressedMenuIndex = index;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressedMenuIndex = -1;
      }
    })
    .onClick(() => {
      if (item.action) {
        item.action();
      }
    });

    if (index < 7) {
      Divider()
        .width('90%')
        .height(0.5)
        .color(ThemeColors.borderLight)
        .opacity(0.5);
    }
  }

  @Builder
  AccountPage() {
    Column() {
      AccountSetting({
        onBack: () => {
          this.currentPage = 'main';
        }
      });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bgPrimary);
  }

  @Builder
  AboutPage() {
    Column() {
      AboutProject({
        onBack: () => {
          this.currentPage = 'main';
        }
      });
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeColors.bgPrimary);
  }

  @Builder
  DialogLayer() {
    Stack() {
      if (this.isNickDialogVisible || this.isSignDialogVisible) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0,0,0,0.5)')
          .opacity(this.dialogOpacity)
          .animation({ duration: 200 })
          .onClick(() => this.hideDialog());
      }

      if (this.isNickDialogVisible) {
        this.NickNameDialog();
      }

      if (this.isSignDialogVisible) {
        this.SignTextDialog();
      }
    }
    .width('100%')
    .height('100%')
    .align(Alignment.Center)
    .zIndex(100);
  }

  @Builder
  NickNameDialog() {
    Column({ space: 16 }) {
      Text("修改用户名")
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.textPrimary);

      TextInput({ text: this.tempNick })
        .width('100%')
        .height(44)
        .backgroundColor(ThemeColors.bgPrimary)
        .borderRadius(8)
        .onChange((value: string) => this.tempNick = value);

      Row({ space: 12 }) {
        Button("取消")
          .width(80)
          .height(36)
          .backgroundColor(ThemeColors.bgPrimary)
          .fontColor(ThemeColors.textSecondary)
          .onClick(() => this.hideDialog());

        Button("确定")
          .width(80)
          .height(36)
          .backgroundColor(ThemeColors.primary)
          .fontColor(Color.White)
          .onClick(() => {
            this.nickName = this.tempNick || this.nickName;
            this.hideDialog();
            promptAction.showToast({ message: '修改成功' });
          });
      }
      .width('100%')
      .justifyContent(FlexAlign.End);
    }
    .width('80%')
    .padding(20)
    .backgroundColor(ThemeColors.bgCard)
    .borderRadius(16)
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: 250, curve: curves.springMotion() });
  }

  @Builder
  SignTextDialog() {
    Column({ space: 16 }) {
      Text("修改签名")
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.textPrimary);

      TextInput({ text: this.tempSign })
        .width('100%')
        .height(44)
        .backgroundColor(ThemeColors.bgPrimary)
        .borderRadius(8)
        .onChange((value: string) => this.tempSign = value);

      Row({ space: 12 }) {
        Button("取消")
          .width(80)
          .height(36)
          .backgroundColor(ThemeColors.bgPrimary)
          .fontColor(ThemeColors.textSecondary)
          .onClick(() => this.hideDialog());

        Button("确定")
          .width(80)
          .height(36)
          .backgroundColor(ThemeColors.accent)
          .fontColor(Color.White)
          .onClick(() => {
            this.signText = this.tempSign || this.signText;
            this.hideDialog();
            promptAction.showToast({ message: '修改成功' });
          });
      }
      .width('100%')
      .justifyContent(FlexAlign.End);
    }
    .width('80%')
    .padding(20)
    .backgroundColor(ThemeColors.bgCard)
    .borderRadius(16)
    .scale({ x: this.dialogScale, y: this.dialogScale })
    .opacity(this.dialogOpacity)
    .animation({ duration: 250, curve: curves.springMotion() });
  }

  private startAvatarPulse(): void {
    this.avatarGlow = 1;
    setTimeout(() => this.avatarGlow = 0, 800);
  }

  private showNickDialog(): void {
    this.tempNick = this.nickName;
    this.isNickDialogVisible = true;
    this.dialogOpacity = 0;
    this.dialogScale = 0.8;
    animateTo({ duration: 200 }, () => {
      this.dialogOpacity = 1;
      this.dialogScale = 1;
    });
  }

  private showSignDialog(): void {
    this.tempSign = this.signText;
    this.isSignDialogVisible = true;
    this.dialogOpacity = 0;
    this.dialogScale = 0.8;
    animateTo({ duration: 200 }, () => {
      this.dialogOpacity = 1;
      this.dialogScale = 1;
    });
  }

  private hideDialog(): void {
    animateTo({ duration: 150 }, () => {
      this.dialogOpacity = 0;
      this.dialogScale = 0.8;
    });
    setTimeout(() => {
      this.isNickDialogVisible = false;
      this.isSignDialogVisible = false;
    }, 150);
  }

  private handleQuickItemClick(index: number): void {
    switch(index) {
      case 0:
        this.showNickDialog();
        break;
      case 1:
        promptAction.showToast({ message: '进入农场管理...' });
        break;
      case 2:
        this.currentPage = 'account';
        break;
      case 3:
        this.currentPage = 'about';
        break;
    }
  }

  private logout(): void {
    this.localstorage.setDate('is_land', false);
    router.replaceUrl({ url: 'pages/Open' });
  }

  private async selectAvatar(): Promise<void> {
    let photoPicker = new picker.PhotoViewPicker();
    let option = new picker.PhotoSelectOptions();
    option.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
    option.maxSelectNumber = 1;

    try {
      let result = await photoPicker.select(option);
      if (result.photoUris.length > 0) {
        this.avatarUri = result.photoUris[0];
        AppStorage.setOrCreate('globalAvatar', this.avatarUri);
        promptAction.showToast({ message: '头像更新成功' });
      }
    } catch (err) {
      console.error("选择头像失败", err);
      promptAction.showToast({ message: '选择失败' });
    }
  }
}

export { userpage };
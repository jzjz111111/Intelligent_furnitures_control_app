import router from '@ohos.router';
import { preferences } from '@kit.ArkData';
import cryptoFramework from '@ohos.security.cryptoFramework';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { ThemeColors } from '../utils/theme';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State password: string = '';
  @State confirmPwd: string = '';
  @State isRegistering: boolean = false;
  @State toastMessage: string = '';
  @State toastColor: string = ThemeColors.primaryLight;
  @State toastBorderColor: string = ThemeColors.primary;
  @State toastTextColor: string = ThemeColors.primaryDark;
  @State showToast: boolean = false;
  @State isRegisterButtonClicked: boolean = false;
  private userPreferences: preferences.Preferences | null = null;

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    this.userPreferences = await preferences.getPreferences(context, 'userData');
  }

  build() {
    Stack() {
      // 背景图（与所有页面统一）
      Image($r('app.media.SmartFarmBackground'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover);

      // 内容层（玻璃拟态卡片）
      Column({ space: 24 }) {
        // Logo/标题区域
        Column({ space: 8 }) {
          Text("🌱")
            .fontSize(48)
          Text("注册账号")
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.textPrimary)
          Text("Create Account")
            .fontSize(14)
            .fontColor(ThemeColors.textSecondary)
            .letterSpacing(2)
        }
        .margin({ bottom: 16 })

        // 用户名输入框（玻璃拟态）
        Row({ space: 12 }) {
          Image($r('app.media.user_icon'))
            .width(20)
            .height(20)
            .fillColor(ThemeColors.textSecondary)
          TextInput({ placeholder: '请输入用户名', text: $$this.username })
            .placeholderColor(ThemeColors.textTertiary)
            .fontColor(ThemeColors.textPrimary)
            .fontSize(15)
            .height(48)
            .backgroundColor(ThemeColors.bgGlass)
            .borderRadius(12)
            .border({ width: 1, color: ThemeColors.borderLight })
            .padding({ left: 16, right: 16 })
            .layoutWeight(1)
        }
        .width("100%")
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor(ThemeColors.cardGlass)
        .borderRadius(16)
        .border({ width: 1, color: ThemeColors.borderLight })

        // 密码输入框（玻璃拟态）
        Row({ space: 12 }) {
          Image($r('app.media.password_icon'))
            .width(20)
            .height(20)
            .fillColor(ThemeColors.textSecondary)
          TextInput({ placeholder: '请输入密码', text: $$this.password })
            .type(InputType.Password)
            .placeholderColor(ThemeColors.textTertiary)
            .fontColor(ThemeColors.textPrimary)
            .fontSize(15)
            .height(48)
            .backgroundColor(ThemeColors.bgGlass)
            .borderRadius(12)
            .border({ width: 1, color: ThemeColors.borderLight })
            .padding({ left: 16, right: 16 })
            .layoutWeight(1)
        }
        .width("100%")
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor(ThemeColors.cardGlass)
        .borderRadius(16)
        .border({ width: 1, color: ThemeColors.borderLight })

        // 确认密码输入框（玻璃拟态）
        Row({ space: 12 }) {
          Image($r('app.media.password_icon'))
            .width(20)
            .height(20)
            .fillColor(ThemeColors.textSecondary)
          TextInput({ placeholder: '请再次输入密码', text: $$this.confirmPwd })
            .type(InputType.Password)
            .placeholderColor(ThemeColors.textTertiary)
            .fontColor(ThemeColors.textPrimary)
            .fontSize(15)
            .height(48)
            .backgroundColor(ThemeColors.bgGlass)
            .borderRadius(12)
            .border({
              width: 1,
              color: (this.password && this.confirmPwd && this.password !== this.confirmPwd)
                ? ThemeColors.danger
                : ThemeColors.borderLight
            })
            .padding({ left: 16, right: 16 })
            .layoutWeight(1)
            .onChange(() => {
              if (this.password && this.confirmPwd && this.password !== this.confirmPwd) {
                this.showCustomToast('两次密码不一致', 'error');
              }
            })
        }
        .width("100%")
        .height(56)
        .padding({ left: 16, right: 16 })
        .backgroundColor(ThemeColors.cardGlass)
        .borderRadius(16)
        .border({ width: 1, color: ThemeColors.borderLight })

        // 立即注册按钮（白底设计，不用深色背景）
        Button(this.isRegistering ? "注册中..." : "立即注册")
          .width("100%")
          .height(52)
          .backgroundColor(this.isRegistering ? ThemeColors.primaryLight : '#FFFFFF')
          .fontColor(this.isRegistering ? ThemeColors.textTertiary : ThemeColors.primary)
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .borderRadius(26)
          .border({
            width: 2,
            color: this.isRegistering ? ThemeColors.borderLight : ThemeColors.primary
          })
          .shadow({ color: ThemeColors.shadowDark, radius: 8, offsetX: 0, offsetY: 4 })
          .enabled(!this.isRegistering)
          .onClick(async () => {
            if (!this.validateForm()) return;
            this.isRegistering = true;
            this.isRegisterButtonClicked = true;
            try {
              const isUnique = await this.checkUsernameUnique();
              if (!isUnique) {
                this.showCustomToast('用户名已被注册', 'error');
                return;
              }
              await this.handleRegister();
            } finally {
              this.isRegistering = false;
            }
          })

        // 返回登录按钮（白底设计）
        Button("返回登录")
          .width("100%")
          .height(52)
          .backgroundColor('#FFFFFF')
          .fontColor(ThemeColors.secondary)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .borderRadius(26)
          .border({ width: 1.5, color: ThemeColors.secondary })
          .shadow({ color: ThemeColors.shadowDark, radius: 6, offsetX: 0, offsetY: 3 })
          .onClick(() => {
            router.replaceUrl({ url: "pages/Open" });
          })
      }
      .width('85%')
      .padding(32)
      .backgroundColor(ThemeColors.cardGlass)
      .borderRadius(24)
      .border({ width: 1, color: 'rgba(255,255,255,0.8)' })
      .shadow({ color: ThemeColors.shadowDark, radius: 24, offsetX: 0, offsetY: 12 })
      .alignItems(HorizontalAlign.Center)

      // Toast 提示（玻璃拟态风格）
      if (this.showToast) {
        Column() {
          Row({ space: 8 }) {
            Text(this.toastMessage)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.toastTextColor)
          }
          .padding({ left: 20, right: 20, top: 12, bottom: 12 })
          .backgroundColor(this.toastColor)
          .borderRadius(20)
          .border({ width: 1, color: this.toastBorderColor })
          .shadow({ color: 'rgba(0,0,0,0.1)', radius: 8, offsetX: 0, offsetY: 4 })
        }
        .width('100%')
        .position({ y: '85%' })
        .alignItems(HorizontalAlign.Center)
        .onClick(() => this.showToast = false)
      }
    }
    .width('100%')
    .height('100%')
  }

  private showCustomToast(message: string, type: 'success' | 'error') {
    if (type === 'success') {
      this.toastColor = ThemeColors.primaryLight;
      this.toastBorderColor = ThemeColors.primary;
      this.toastTextColor = ThemeColors.primaryDark;
    } else {
      this.toastColor = 'rgba(239, 68, 68, 0.15)';
      this.toastBorderColor = ThemeColors.danger;
      this.toastTextColor = ThemeColors.danger;
    }
    this.toastMessage = message;
    this.showToast = true;
    setTimeout(() => this.showToast = false, 1500);
  }

  private validateForm(): boolean {
    const validUsername = /^[a-zA-Z0-9_]{4,20}$/.test(this.username);
    const validPassword = this.password.length >= 6;
    const pwdMatch = this.password === this.confirmPwd;

    if (!validUsername) {
      this.showCustomToast('用户名需为4-20位字母数字', 'error');
      return false;
    }
    if (!validPassword) {
      this.showCustomToast('密码至少需要6位', 'error');
      return false;
    }
    if (!pwdMatch) {
      return false;
    }
    return true;
  }

  private async checkUsernameUnique(): Promise<boolean> {
    if (!this.userPreferences) {
      this.showCustomToast('系统未初始化', 'error');
      return false;
    }

    try {
      const users = await this.userPreferences.get('user_list', '[]') as string;
      const userList: string[] = JSON.parse(users);
      return !userList.includes(this.username);
    } catch (error) {
      this.showCustomToast('用户查询失败', 'error');
      return false;
    }
  }

  private async encryptPassword(plainText: string): Promise<string> {
    try {
      const md = cryptoFramework.createMd('SHA256');
      const input: cryptoFramework.DataBlob = {
        data: new util.TextEncoder().encode(plainText)
      };
      await md.update(input);
      const digest = await md.digest();
      return Array.from(new Uint8Array(digest.data))
        .map((b: number) => b.toString(16).padStart(2, '0'))
        .join('');
    } catch (error) {
      throw new Error('密码加密失败: ' + error.message);
    }
  }

  private async handleRegister() {
    try {
      if (!this.userPreferences) return;

      if (!await this.checkUsernameUnique()) return;

      const encryptedPwd = await this.encryptPassword(this.password);

      const users = await this.userPreferences.get('user_list', '[]') as string;
      const userList: string[] = JSON.parse(users);
      userList.push(this.username);
      await this.userPreferences.put('user_list', JSON.stringify(userList) as preferences.ValueType);

      await this.userPreferences.put(`user_${this.username}`, encryptedPwd as preferences.ValueType);
      await this.userPreferences.flush();

      this.showCustomToast('注册成功！', 'success');
      setTimeout(() => router.replaceUrl({ url: 'pages/Open' }), 1000);

    } catch (error) {
      this.showCustomToast(`注册失败: ${error.message}`, 'error');
    }
  }
}
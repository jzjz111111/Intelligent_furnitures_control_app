import router from '@ohos.router';
import { preferences } from '@kit.ArkData';
import cryptoFramework from '@ohos.security.cryptoFramework';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { ThemeColors } from '../utils/theme';
import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';

interface RegisterRequest {
  username: string;
  password: string;
}

interface ServerResponse {
  code: number;
  data: object | null;
  msg: string;
}

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
    try {
      const url = "http://127.0.0.1:8080/api/user/checkUsername?username=" + encodeURIComponent(this.username);
      let httpRequest = http.createHttp();
      try {
        let response = await httpRequest.request(url, {
          method: http.RequestMethod.GET,
          connectTimeout: 5000,
          readTimeout: 5000
        });

        if (response.responseCode !== 200) {
          return true;
        }

        let result = JSON.parse(response.result as string) as ServerResponse;
        return result.code === 200;
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      console.error('检查用户名失败:', error);
      return true;
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
      throw new Error('密码加密失败: ' + (error as Error).message);
    }
  }

  private async handleRegister() {
    this.isRegistering = true;

    try {
      const encryptedPwd = await this.encryptPassword(this.password);

      const url: string = "http://127.0.0.1:8080/api/user/register";
      console.log('[注册] 开始发送请求:', url);
      console.log('[注册] 请求参数:', JSON.stringify({ username: this.username }));

      const postData: RegisterRequest = {
        username: this.username,
        password: encryptedPwd
      };

      const httpRequest = http.createHttp();
      try {
        const response = await httpRequest.request(url, {
          method: http.RequestMethod.POST,
          header: {
            "Content-Type": "application/json"
          },
          extraData: JSON.stringify(postData),
          connectTimeout: 10000,
          readTimeout: 10000
        });

        console.log('[注册] 收到响应，状态码:', response.responseCode);

        if (response.responseCode !== 200) {
          this.showCustomToast(`服务器异常 (${response.responseCode})`, "error");
          return;
        }

        const result = JSON.parse(response.result as string) as ServerResponse;
        console.log('[注册] 响应数据:', JSON.stringify(result));

        if (result.code !== 200) {
          this.showCustomToast(result.msg || "注册失败", "error");
          return;
        }

        this.showCustomToast('注册成功！', 'success');
        console.log('[注册] 注册成功，跳转到登录页');
        setTimeout(() => router.replaceUrl({ url: 'pages/Open' }), 1000);
      } finally {
        httpRequest.destroy();
      }
    } catch (error) {
      const e = error as BusinessError;
      console.error('[注册] 请求异常:', e.message);
      console.error('[注册] 错误码:', e.code);
      console.error('[注册] 完整错误:', JSON.stringify(e));

      if (e.code === 13900042 || e.message.includes('Timeout')) {
        this.showCustomToast("网络连接超时，请检查后端服务是否启动", "error");
      } else if (e.message.includes('Connection refused')) {
        this.showCustomToast("无法连接到服务器，请确认服务器已启动", "error");
      } else {
        this.showCustomToast(`注册失败: ${e.message}`, 'error');
      }
    } finally {
      this.isRegistering = false;
    }
  }
}

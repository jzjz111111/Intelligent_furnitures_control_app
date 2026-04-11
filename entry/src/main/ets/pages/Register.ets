import router from '@ohos.router';
import { preferences } from '@kit.ArkData';
import cryptoFramework from '@ohos.security.cryptoFramework';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { systemDateTime } from '@kit.BasicServicesKit';
import { curves } from '@kit.ArkUI';
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
  // ========== 表单状态 ==========
  @State username: string = '';
  @State password: string = '';
  @State confirmPwd: string = '';
  @State isRegistering: boolean = false;
  @State showToast: boolean = false;
  @State toastMessage: string = '';
  @State toastColor: string = '#f8d7da';
  @State toastBorderColor: string = '#721c24';
  @State toastTextColor: string = '#721c24';
  private userPreferences: preferences.Preferences | null = null;

  // ========== UI动画状态 ==========
  @State logoScale: number = 0.8;
  @State logoOpacity: number = 0;
  @State formOffsetY: number = 50;
  @State formOpacity: number = 0;
  @State buttonScale: number = 0.9;
  @State buttonOpacity: number = 0;
  @State pressedInput: string = '';

  async aboutToAppear() {
    // 原有功能逻辑
    let _time = systemDateTime.getTime(true)
    console.log("Time::::"+_time)
    const context = getContext(this) as common.UIAbilityContext;
    this.userPreferences = await preferences.getPreferences(context, 'userData');

    // 入场动画序列（与Open.ets一致）
    animateTo({ duration: 600, curve: curves.springMotion() }, () => {
      this.logoScale = 1;
      this.logoOpacity = 1;
    });

    animateTo({ duration: 500, delay: 200, curve: Curve.EaseOut }, () => {
      this.formOffsetY = 0;
      this.formOpacity = 1;
    });

    animateTo({ duration: 400, delay: 400, curve: Curve.EaseOut }, () => {
      this.buttonScale = 1;
      this.buttonOpacity = 1;
    });
  }

  build() {
    Stack() {
      // ========== 背景装饰（与Open.ets一致） ==========
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ThemeColors.bgPrimary)

      // ========== 顶部装饰圆（与Open.ets一致） ==========
      Column()
        .width(300)
        .height(300)
        .backgroundColor(ThemeColors.primaryLight)
        .borderRadius(150)
        .position({ x: -100, y: -100 })
        .opacity(0.5)
        .blur(40)

      Column()
        .width(200)
        .height(200)
        .backgroundColor(ThemeColors.accent)
        .borderRadius(100)
        .position({ x: 250, y: -50 })
        .opacity(0.3)
        .blur(60)

      // ========== 主内容区 ==========
      Column({ space: 24 }) {
        // ========== Logo区域（新增动画，与Open.ets一致） ==========
        Column({ space: 12 }) {
          // 农业图标
          Column() {
            Text("🌱")
              .fontSize(64)
          }
          .width(100)
          .height(100)
          .backgroundColor(ThemeColors.bgCard)
          .borderRadius(50)
          .border({
            width: 3,
            color: ThemeColors.accent,
            style: BorderStyle.Solid
          })
          .shadow({
            color: ThemeColors.techGlow,
            radius: 20,
            offsetX: 0,
            offsetY: 8
          })

          Text("注册账号")
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.textPrimary)

          Text("Create Account")
            .fontSize(14)
            .fontColor(ThemeColors.textSecondary)
        }
        .margin({ top: 60, bottom: 20 })
        .scale({ x: this.logoScale, y: this.logoScale })
        .opacity(this.logoOpacity)
        .animation({ duration: 600, curve: curves.springMotion() })

        // ========== 表单区域（与Open.ets输入框风格统一） ==========
        Column({ space: 20 }) {
          // 用户名输入
          Column({ space: 8 }) {
            Text("用户名")
              .fontSize(14)
              .fontColor(ThemeColors.textSecondary)
              .alignSelf(ItemAlign.Start)
              .margin({ left: 8 })

            Row() {
              Text("👤")
                .fontSize(20)
                .margin({ left: 16, right: 12 })

              TextInput({ placeholder: '请输入用户名', text: $$this.username })
                .placeholderColor(ThemeColors.textTertiary)
                .fontColor(ThemeColors.textPrimary)
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .height(50)
            }
            .width("90%")
            .height(56)
            .backgroundColor(ThemeColors.bgCard)
            .borderRadius(16)
            .border({
              width: 2,
              color: this.pressedInput === 'user' ? ThemeColors.accent : ThemeColors.borderLight
            })
            .shadow({
              color: 'rgba(13, 51, 40, 0.08)',
              radius: 8,
              offsetX: 0,
              offsetY: 2
            })
            .onClick(() => {
              this.pressedInput = 'user';
            })
          }

          // 密码输入
          Column({ space: 8 }) {
            Text("密码")
              .fontSize(14)
              .fontColor(ThemeColors.textSecondary)
              .alignSelf(ItemAlign.Start)
              .margin({ left: 8 })

            Row() {
              Text("🔒")
                .fontSize(20)
                .margin({ left: 16, right: 12 })

              TextInput({ placeholder: '请输入密码', text: $$this.password })
                .type(InputType.Password)
                .placeholderColor(ThemeColors.textTertiary)
                .fontColor(ThemeColors.textPrimary)
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .height(50)
            }
            .width("90%")
            .height(56)
            .backgroundColor(ThemeColors.bgCard)
            .borderRadius(16)
            .border({
              width: 2,
              color: this.pressedInput === 'pwd' ? ThemeColors.accent : ThemeColors.borderLight
            })
            .shadow({
              color: 'rgba(13, 51, 40, 0.08)',
              radius: 8,
              offsetX: 0,
              offsetY: 2
            })
            .onClick(() => {
              this.pressedInput = 'pwd';
            })
          }

          // 确认密码输入
          Column({ space: 8 }) {
            Text("确认密码")
              .fontSize(14)
              .fontColor(ThemeColors.textSecondary)
              .alignSelf(ItemAlign.Start)
              .margin({ left: 8 })

            Row() {
              Text("🔐")
                .fontSize(20)
                .margin({ left: 16, right: 12 })

              TextInput({ placeholder: '请再次输入密码', text: $$this.confirmPwd })
                .type(InputType.Password)
                .placeholderColor(ThemeColors.textTertiary)
                .fontColor(ThemeColors.textPrimary)
                .backgroundColor(Color.Transparent)
                .layoutWeight(1)
                .height(50)
                .onChange(() => {
                  if (this.password && this.confirmPwd && this.password !== this.confirmPwd) {
                    this.showCustomToast('两次密码不一致', 'error');
                  }
                })
            }
            .width("90%")
            .height(56)
            .backgroundColor(ThemeColors.bgCard)
            .borderRadius(16)
            .border({
              width: 2,
              color: this.pressedInput === 'confirm'
                ? ThemeColors.accent
                : (this.password && this.confirmPwd && this.password !== this.confirmPwd)
                  ? ThemeColors.danger || '#ff4d4f'
                  : ThemeColors.borderLight
            })
            .shadow({
              color: 'rgba(13, 51, 40, 0.08)',
              radius: 8,
              offsetX: 0,
              offsetY: 2
            })
            .onClick(() => {
              this.pressedInput = 'confirm';
            })
          }
        }
        .width('100%')
        .translate({ y: this.formOffsetY })
        .opacity(this.formOpacity)
        .animation({ duration: 500, curve: Curve.EaseOut })

        // ========== 按钮区域（与Open.ets风格统一） ==========
        Column({ space: 16 }) {
          // 注册按钮（主题色背景）
          Button() {
            Row({ space: 8 }) {
              if (this.isRegistering) {
                Text("⏳")
                  .fontSize(18)
              } else {
                Text("")
                  .fontSize(18)
              }
              Text(this.isRegistering ? "注册中..." : "立即注册")
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
            }
          }
          .width("90%")
          .height(52)
          .backgroundColor(this.isRegistering ? ThemeColors.textTertiary : ThemeColors.primaryLight
          )
          .borderRadius(26)
          .shadow({
            color: this.isRegistering ? 'rgba(0,0,0,0.1)' : ThemeColors.techGlow,
            radius: this.isRegistering ? 4 : 12,
            offsetX: 0,
            offsetY: this.isRegistering ? 2 : 4
          })
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .opacity(this.buttonOpacity)
          .animation({ duration: 400, curve: Curve.EaseOut })
          .enabled(!this.isRegistering)
          .onClick(async () => {
            if (!this.validateForm()) return;
            this.isRegistering = true;
            try {
              await this.handleRegister();
            } finally {
              this.isRegistering = false;
            }
          })

          // 返回登录按钮（透明背景+边框）
          Button() {
            Row({ space: 8 }) {
              Text("")
                .fontSize(16)
              Text("返回登录")
                .fontSize(14)
            }
          }
          .width("90%")
          .height(48)
          .backgroundColor(Color.Transparent)
          .fontColor(ThemeColors.primary)
          .borderRadius(24)
          .border({
            width: 2,
            color: ThemeColors.primary
          })
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .opacity(this.buttonOpacity)
          .animation({ duration: 400, delay: 100, curve: Curve.EaseOut })
          .onClick(() => {
            router.replaceUrl({ url: "pages/Open" });
          })
        }
        .width('100%')
        .margin({ top: 10 })

        // ========== 底部装饰（与Open.ets一致） ==========
        Row({ space: 20 }) {
          Text("📝 安全注册")
            .fontSize(12)
            .fontColor(ThemeColors.textTertiary)

          Text("|")
            .fontColor(ThemeColors.borderLight)

          Text("v1.0.0")
            .fontSize(12)
            .fontColor(ThemeColors.textTertiary)
        }
        .margin({ top: 40 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)

      // ========== Toast提示（与Open.ets一致） ==========
      if (this.showToast) {
        Column() {
          Row({ space: 8 }) {
            Text(this.toastMessage.includes('成功') ? '✅' : '❌')
              .fontSize(18)

            Text(this.toastMessage)
              .fontSize(14)
              .fontColor(this.toastTextColor)
              .fontWeight(FontWeight.Medium)
          }
          .padding({ left: 20, right: 20, top: 12, bottom: 12 })
          .backgroundColor(this.toastColor)
          .borderRadius(12)
          .border({ width: 1, color: this.toastBorderColor })
          .shadow({
            color: 'rgba(0,0,0,0.15)',
            radius: 10,
            offsetX: 0,
            offsetY: 4
          })
        }
        .width('100%')
        .position({ y: '85%' })
        .alignItems(HorizontalAlign.Center)
        .onClick(() => this.showToast = false)
        .animation({ duration: 300, curve: Curve.EaseOut })
      }
    }
    .width('100%')
    .height('100%')
  }

  // ========== 原有功能方法（保持逻辑不变） ==========
  private showCustomToast(message: string, type: 'success' | 'error') {
    this.toastColor = type === 'success' ? '#d4edda' : '#f8d7da';
    this.toastBorderColor = type === 'success' ? '#155724' : '#721c24';
    this.toastTextColor = type === 'success' ? '#155724' : '#721c24';
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
      this.showCustomToast('两次密码不一致', 'error');
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

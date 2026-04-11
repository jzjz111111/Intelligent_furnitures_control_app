import router from '@ohos.router';
import { preferences } from '@kit.ArkData';
import cryptoFramework from '@ohos.security.cryptoFramework';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { systemDateTime } from '@kit.BasicServicesKit';
import { curves } from '@kit.ArkUI';
import { ThemeColors } from '../utils/theme';
import http from '@ohos.net.http';
import { MyHttpServer } from '../server/HttpServer';


// 登录请求参数接口
interface LoginRequest {
  username: string;
  password: string;
}

interface LoginData {
  userId: number;
  username: string;
}

interface LoginResult {
  code: number;
  msg: string;
  data: LoginData;
}

interface ServerResponse {
  code: number;
  data: object | null;
  msg: string;
}

interface LoginResponseData {
  code: number;
  msg: string;
}

@Entry
@Component
struct NewPage {
  // ========== 原有功能状态（一个不改） ==========
  @State input_userName: string = '';
  @State input_password: string = '';
  @State is_landing: boolean = false;
  @State showToast: boolean = false;
  @State toastMessage: string = '';
  @State toastColor: string = '#721c24';
  @State toastBorderColor: string = '#721c24';
  @State toastTextColor: string = '#721c24';
  private userPreferences: preferences.Preferences | null = null;

  // ========== UI动画状态（新增） ==========
  @State logoScale: number = 0.8;
  @State logoOpacity: number = 0;
  @State formOffsetY: number = 50;
  @State formOpacity: number = 0;
  @State buttonScale: number = 0.9;
  @State buttonOpacity: number = 0;
  @State pressedInput: string = '';

  async aboutToAppear() {
    // ========== 原有功能逻辑（一个不改） ==========
    let _time = systemDateTime.getTime(true)
    console.log("Time::::"+_time)
    const context = getContext(this) as common.UIAbilityContext;
    this.userPreferences = await preferences.getPreferences(context, 'userData');
    const is_land =  await this.userPreferences.get("is_land",false)
    if(is_land){
      router.replaceUrl({ url: "pages/scan_devices" });
    }

    // ========== 入场动画序列（新增） ==========
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
      // ========== 背景装饰（新增） ==========
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(ThemeColors.bgPrimary)

      // ========== 顶部装饰圆（新增） ==========
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
        // ========== Logo区域（新增动画） ==========
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

          Text("智慧农业")
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(ThemeColors.textPrimary)

          Text("Smart Agriculture")
            .fontSize(14)
            .fontColor(ThemeColors.textSecondary)
        }
        .margin({ top: 80, bottom: 20 })
        .scale({ x: this.logoScale, y: this.logoScale })
        .opacity(this.logoOpacity)
        .animation({ duration: 600, curve: curves.springMotion() })

        // ========== 表单区域（新增动画和UI） ==========
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

              TextInput({ placeholder: '请输入用户名', text: this.input_userName })
                .onChange(v => this.input_userName = v)
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

              TextInput({ placeholder: '请输入密码', text: this.input_password })
                .type(InputType.Password)
                .onChange(v => this.input_password = v)
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
        }
        .width('100%')
        .translate({ y: this.formOffsetY })
        .opacity(this.formOpacity)
        .animation({ duration: 500, curve: Curve.EaseOut })

        // ========== 按钮区域（新增动画和UI） ==========
        Column({ space: 16 }) {
          // 登录按钮
          Button() {
            Row({ space: 8 }) {
              if (this.is_landing) {
                Text("⏳")
                  .fontSize(18)
              } else {
                Text("")
                  .fontSize(18)
              }
              Text(this.is_landing ? "登录中..." : "登 录")
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
            }
          }
          .width("90%")
          .height(52)
          .backgroundColor(this.is_landing ? ThemeColors.textTertiary : ThemeColors.primaryLight)
          .borderRadius(26)
          .shadow({
            color: this.is_landing ? 'rgba(0,0,0,0.1)' : ThemeColors.techGlow,
            radius: this.is_landing ? 4 : 12,
            offsetX: 0,
            offsetY: this.is_landing ? 2 : 4
          })
          .scale({ x: this.buttonScale, y: this.buttonScale })
          .opacity(this.buttonOpacity)
          .animation({ duration: 400, curve: Curve.EaseOut })
          .enabled(!this.is_landing)
          .onClick(async () => {
            // ========== 原有功能逻辑（一个不改） ==========
            if (!this.validateInput()) return;
            this.is_landing = true;
            try {
              const success = await this.handleLogin();
              if (success) {
                this.showCustomToast('登录成功', 'success');
                setTimeout(() => {
                  router.replaceUrl({ url: "pages/Index" });
                }, 200);
              }
            } finally {
              this.is_landing = false;
            }
          })

          // 注册按钮
          Button() {
            Row({ space: 8 }) {
              Text("")
                .fontSize(16)
              Text("注册账号")
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
            // ========== 原有功能逻辑（一个不改） ==========
            router.replaceUrl({ url: "pages/Register" });
          })
        }
        .width('100%')
        .margin({ top: 10 })

        // ========== 底部装饰（新增） ==========
        Row({ space: 20 }) {
          Text("🔐 安全登录")
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

      // ========== Toast提示（保持原有逻辑，优化UI） ==========
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

  // ========== 原有功能方法（一个不改） ==========
  private showCustomToast(message: string, type: 'success' | 'error') {
    this.toastColor = type === 'success' ? '#d4edda' : '#f8d7da';
    this.toastBorderColor = type === 'success' ? '#155724' : '#721c24';
    this.toastTextColor = type === 'success' ? '#155724' : '#721c24';
    this.toastMessage = message;
    this.showToast = true;
    setTimeout(() => this.showToast = false, 1000);
  }

  private validateInput(): boolean {
    if (!this.input_userName.trim()) {
      this.showCustomToast('请输入用户名', 'error');
      return false;
    }
    if (!this.input_password.trim()) {
      this.showCustomToast('请输入密码', 'error');
      return false;
    }
    return true;
  }

  /*private async handleLogin(): Promise<boolean> {
    try {
      if (!this.userPreferences) {
        this.showCustomToast('系统未初始化', 'error');
        return false;
      }

      const users = await this.userPreferences.get('user_list', '[]') as string;
      const userList: string[] = JSON.parse(users);
      if (!userList.includes(this.input_userName)) {
        this.showCustomToast('用户不存在', 'error');
        return false;
      }

      const storedPassword = await this.userPreferences.get(`user_${this.input_userName}`, '');
      if (!storedPassword) {
        this.showCustomToast('密码数据异常', 'error');
        return false;
      }

      const encryptedPassword = await this.encryptPassword(this.input_password);
      if (encryptedPassword !== storedPassword) {
        this.showCustomToast('密码错误', 'error');
        return false;
      }

      await this.userPreferences.put('last_login', this.input_userName);
      await this.userPreferences.put("is_land",true)
      await this.userPreferences.flush();
      return true;
    } catch (error) {
      this.showCustomToast(`登录失败: ${error.message}`, 'error');
      return false;
    }
  }*/

  async handleLogin(): Promise<boolean> {
    const encryptedPassword = await this.encryptPassword(this.input_password);

    this.is_landing = true;

    try {
      const url: string = "http://127.0.0.1:8080/api/user/login";
      console.log('==================');
      console.log('[登录] ========== 开始发送请求 ==========');
      console.log('[登录] URL:', url);
      console.log('[登录] 请求参数:', JSON.stringify({ username: this.input_userName }));
      console.log('==================');

      const httpRequest = http.createHttp();
      try {
        console.log('[登录] 正在创建 HTTP 请求...');
        const response = await httpRequest.request(url, {
          method: http.RequestMethod.POST,
          header: {
            "Content-Type": "application/json"
          },
          extraData: JSON.stringify({
            username: this.input_userName,
            password: encryptedPassword  // ✅ 使用加密后的密码
          }),
          connectTimeout: 10000,
          readTimeout: 10000
        });

        console.log('[登录] ✅ 收到响应！');
        console.log('[登录] 状态码:', response.responseCode);
        console.log('[登录] 响应头:', JSON.stringify(response.header));

        if (response.responseCode !== 200) {
          this.showCustomToast(`服务器异常 (${response.responseCode})`, "error");
          return false;
        }

        const result = JSON.parse(response.result as string) as LoginResponseData;
        console.log('[登录] 响应数据:', JSON.stringify(result));

        if (result.code !== 200) {
          this.showCustomToast(result.msg || "登录失败", "error");
          return false;
        }


        await this.userPreferences!.put('last_login', this.input_userName);
        await this.userPreferences!.put("is_land", true);
        await this.userPreferences!.flush();

        console.log('[登录] ✅ 登录成功，跳转首页');
        return true;
      } finally {
        httpRequest.destroy();
      }

    } catch (error) {
      const e = error as BusinessError;
      console.error('==================');
      console.error('[登录] ❌ 请求失败！');
      console.error('[登录] 错误信息:', e.message);
      console.error('[登录] 错误码:', e.code);
      console.error('[登录] 完整错误:', JSON.stringify(e));
      console.error('==================');

      if (e.code === 13900042 || e.message.includes('Timeout')) {
        this.showCustomToast("网络连接超时，请检查后端服务是否启动", "error");
      } else if (e.message.includes('Connection refused')) {
        this.showCustomToast("无法连接到服务器，请确认服务器已启动", "error");
      } else {
        this.showCustomToast("登录失败：" + e.message, "error");
      }
      return false;
    } finally {
      this.is_landing = false;
    }
  }


  // Deleted:private async handleServerApi(api: string, body: LoginRequest): Promise<ServerResponse> {
  // Deleted:const globalThisAny: Record<string, Object | undefined> = globalThis as Record<string, Object | undefined>;
  // Deleted:const serverInstance: Object | undefined = globalThisAny['httpServer'];
  // Deleted:
  // Deleted:if (!serverInstance || !(serverInstance instanceof MyHttpServer)) {
  // Deleted:throw new Error("后端未启动");
  // Deleted:}
  // Deleted:
  // Deleted:const server: MyHttpServer = serverInstance as MyHttpServer;
  // Deleted:const responseStr: string = await server.getMockResponse(api, body);
  // Deleted:const parsedResponse: ServerResponse = JSON.parse(responseStr) as ServerResponse;
  // Deleted:return parsedResponse;
  // Deleted:}


  // ... existing code ...


  // ✅ 直接和后端通信（你这个项目真正的联调方式）
  private async handleServerApi(api: string, body: LoginRequest): Promise<ServerResponse> {
    const globalThisAny: Record<string, Object | undefined> = globalThis as Record<string, Object | undefined>;
    const serverInstance: Object | undefined = AppStorage.get('httpServer') as Object | undefined;


    if (!serverInstance || !(serverInstance instanceof MyHttpServer)) {
      throw new Error("后端未启动");
    }

    const server: MyHttpServer = serverInstance as MyHttpServer;
    const responseStr: string = await server.getMockResponse(api, body);
    const parsedResponse: ServerResponse = JSON.parse(responseStr) as ServerResponse;
    return parsedResponse;
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
}
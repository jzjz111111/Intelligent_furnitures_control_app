import router from '@ohos.router';
import { preferences } from '@kit.ArkData';
import prompt from '@ohos.prompt';
import cryptoFramework from '@ohos.security.cryptoFramework';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State password: string = '';
  @State confirmPwd: string = '';
  @State isRegistering: boolean = false;
  @State toastMessage: string = '';
  @State toastColor: string = '#721c24';
  @State toastBorderColor: string = '#721c24';
  @State toastTextColor: string = '#721c24';
  @State showToast: boolean = false;
  @State isRegisterButtonClicked: boolean = false;
  private userPreferences: preferences.Preferences | null = null;

  async aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    this.userPreferences = await preferences.getPreferences(context, 'userData');
  }

  build() {
    Stack() {

      Column({ space: 20 }) {
        Text("注册")
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 50 })
          .fontColor('#254e7a');


        // 用户名输入
        Row() {
          Image($r('app.media.user_icon'))
            .width(20)
            .height(20)
            .margin({ right: 10 })

          TextInput({ placeholder: '用户名' })
            .onChange(v => this.username = v)
            .width("calc(100% - 100px)")
            .padding({ left: 10, right: 10 })
            .borderRadius(10)
            .border({ width: 1, color: Color.Gray })
        }
        .width("90%")
        .height(50)

        // 密码输入
        Row() {
          Image($r('app.media.password_icon'))
            .width(20)
            .height(20)
            .margin({ right: 10 })

          TextInput({ placeholder: '密码' })
            .type(InputType.Password)
            .onChange(v => this.password = v)
            .width("calc(100% - 100px)")
            .padding({ left: 10, right: 10 })
            .borderRadius(10)
            .border({ width: 1, color: Color.Gray })
        }
        .width("90%")
        .height(50)

        // 确认密码
        Row() {
          Image($r('app.media.password_icon'))
            .width(20)
            .height(20)
            .margin({ right: 10 })

          TextInput({ placeholder: '再次输入密码' })
            .type(InputType.Password)
            .onChange(v => {
              this.confirmPwd = v;
              if (this.password && v !== this.password) {
                this.showCustomToast('两次密码不一致', 'error');
              }
            })
            .width("calc(100% - 100px)")
            .padding({ left: 10, right: 10 })
            .borderRadius(10)
            .border({ width: 1, color: Color.Gray })
        }
        .width("90%")
        .height(50)

        Button('立即注册')
          .width("90%")
          .height(50)
          .backgroundImage(this.isRegisterButtonClicked ? $r('app.media.R_L_bg') : $r('app.media.btn_bg'))
          .backgroundImageSize(ImageSize.Cover)
          .fontColor(this.isRegisterButtonClicked ? Color.Blue : Color.White)
          .border({
            width: 2,
            color: this.isRegisterButtonClicked ? Color.Blue : Color.Transparent
          })
          .borderRadius(10)
          .onClick(async () => {
            if (!this.validateForm()) return;

            this.isRegisterButtonClicked = true;
            this.isRegistering = true;
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
        Button("退出")
          .width("90%")
          .height(50)
          .backgroundImage($r('app.media.btn_bg'))
          .backgroundImageSize(ImageSize.Cover)
          .fontColor(Color.White)
          .borderRadius(10)
          .onClick(() => {
            router.replaceUrl({ url: "pages/Open" });
          });

      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)

      // 自定义Toast
      if (this.showToast) {
        Column() {
          Text(this.toastMessage)
            .fontSize(16)
            .padding(12)
            .backgroundColor(this.toastColor)
            .borderRadius(8)
            .fontColor(this.toastTextColor)
            .border({ width: 1, color: this.toastBorderColor })
        }
        .width('100%')
        .position({ y: '80%' })
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.showToast = false;
        })
      }
    }
  }

  private showCustomToast(message: string, type: 'success' | 'error') {
    this.toastColor = type === 'success' ? '#d4edda' : '#f8d7da';
    this.toastBorderColor = type === 'success' ? '#155724' : '#721c24';
    this.toastTextColor = type === 'success' ? '#155724' : '#721c24';
    this.toastMessage = message;
    this.showToast = true;

    // 自动隐藏
    setTimeout(() => {
      this.showToast = false;
    }, 1000);
  }

  private validateForm(): boolean {
    const validUsername = /^[a-zA-Z0-9_]{4,20}$/.test(this.username);
    const validPassword = this.password.length >= 6;
    const pwdMatch = this.password === this.confirmPwd;

    if (!validUsername) {
      this.showCustomToast('用户名需为4 - 20位字母数字', 'error');
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
      const md: cryptoFramework.Md = cryptoFramework.createMd('SHA256');
      const input: cryptoFramework.DataBlob = {
        data: new util.TextEncoder().encode(plainText)
      };
      await md.update(input);
      const digest: cryptoFramework.DataBlob = await md.digest();
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

      // 二次用户名校验
      if (!await this.checkUsernameUnique()) return;

      // 加密密码
      const encryptedPwd = await this.encryptPassword(this.password);

      // 更新用户列表
      const users = await this.userPreferences.get('user_list', '[]') as string;
      const userList: string[] = JSON.parse(users);
      userList.push(this.username);
      await this.userPreferences.put('user_list', JSON.stringify(userList) as preferences.ValueType);

      // 存储加密凭证
      await this.userPreferences.put(`user_${this.username}`, encryptedPwd as preferences.ValueType);
      await this.userPreferences.flush();

      this.showCustomToast('注册成功！', 'success');
      setTimeout(() => router.replaceUrl({ url: 'pages/Open' }), 1000);

    } catch (error) {
      this.showCustomToast(`注册失败: ${error.message}`, 'error');
    }
  }
}
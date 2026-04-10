import { FarmlandDatabase } from "../data/RdbStorage";
import { _IoTad } from "../pages/scan_devices";
import {  Device, farmland } from "../tool/classes";
import picker from '@ohos.file.picker';
import { ThemeColors } from '../utils/theme';
import common from '@ohos.app.ability.common';

let new_arr_farmlands:farmland[]
let new_arr_f:Device[]
let Farmland_db:FarmlandDatabase = new FarmlandDatabase(globalThis.getContext())
let new_f_R_Id:number


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
        Row(){
          Button('完成')
            .backgroundColor(ThemeColors.primary)
            .fontColor(ThemeColors.bgCard)
            .onClick(async () => {
              if (this.dev_name != '' && this.db) {
                let success = await this.db.insertFarmland(new farmland(this.dev_name, [],this.avatarUri))
                if(success != -1){
                  setTimeout(()=>{
                    this.arr.push(new farmland(this.dev_name, [],this.avatarUri))
                  },500)
                }else{
                  AlertDialog.show({
                    message:"名字重复了哦"
                  })
                }

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
  // 打开相册选择头像
  async selectAvatar() {
    try {
      // 1. 创建选择配置
      let photoOption = new picker.PhotoSelectOptions();

      // 2. 只允许选图片
      photoOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;

      // 3. 最多选1张
      photoOption.maxSelectNumber = 1;

      // 4. 打开相册
      const photoPicker = new picker.PhotoViewPicker();
      const selectResult = await photoPicker.select(photoOption);

      // 5. 获取选中的图片地址
      if (selectResult.photoUris && selectResult.photoUris.length > 0) {
        this.avatarUri = selectResult.photoUris[0];
        console.log("选中头像地址：", this.avatarUri);
      }
    } catch (err) {
      console.error("选择图片失败：", err);
    }
  }
}



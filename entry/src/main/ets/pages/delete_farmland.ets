// pages/delete_farmland.ets
import common from '@ohos.app.ability.common';
import { ThemeColors } from '../utils/theme';
import { farmland } from '../tool/classes';
import { FarmlandDatabase } from '../data/RdbStorage';
import { deleteFarm } from '../../common/api/HttpApi';


@Entry
@Component
struct ConfirmDialog {
  @Link is_show: boolean;
  @Link arr_farmland: farmland[];
  @Link name: string;
  private db: FarmlandDatabase | null = null;

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    this.db = new FarmlandDatabase(context);
  }

  build() {
    Stack() {
      Column()
        .width("100%")
        .height("100%")
        .backgroundColor("rgba(27, 94, 32, 0.4)")
        .onClick(() => {
          animateTo({ duration: 300 }, () => {
            this.is_show = false;
          });
        });
      Column() {
        Image($r('app.media.ic_warning'))
          .fillColor(ThemeColors.danger)
          .width(48)
          .height(48)
          .margin({ top: 24, bottom: 16 });
        Text(`删除「${this.name}」农田？`)
          .fontSize(20)
          .fontColor(ThemeColors.danger)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 });
        Text("删除后农田数据不可恢复，请谨慎操作！")
          .fontSize(14)
          .fontColor(ThemeColors.textSecondary)
          .margin({ bottom: 24 });
        Row() {
          Button('取消')
            .onClick(() => {
              animateTo({ duration: 300 }, () => {
                this.is_show = false;
              });
            })
            .width(120)
            .height(40)
            .backgroundColor(ThemeColors.primaryLight)
            .fontColor(ThemeColors.primaryDark)
            .borderRadius(20)
            .stateEffect(true);
          Button('确认删除')
            /*.onClick(async () => {
              if (this.db) {
                await this.db.deleteFarmlandByName(this.name)
                this.arr_farmland = this.arr_farmland.filter(element => element.name !== this.name);
              }
              animateTo({ duration: 300 }, () => {
                this.is_show = false;
              });
            })*/
            .onClick(async () => {
              try {
                // 1. 找到要删除的农田，获取 zoneId
                const farmToDelete = this.arr_farmland.find(element => element.name === this.name);

                if (!farmToDelete || !farmToDelete.zoneId) {
                  AlertDialog.show({ message: "农田ID不存在" });
                  return;
                }

                // 2. 调用后端删除接口
                const result = await deleteFarm(farmToDelete.zoneId);

                if (result.code === 200) {
                  if (this.db) {
                    await this.db.deleteFarmlandByName(this.name);
                  }
                  // 3. 删除成功后更新本地数组
                  this.arr_farmland = this.arr_farmland.filter(element => element.name !== this.name);
                  AlertDialog.show({ message: "农田删除成功" });
                } else {
                  AlertDialog.show({ message: result.message || "删除失败，请重试" });
                }
              } catch (err) {
                console.error("删除农田失败:", err);
                const errorMessage = err instanceof Error ? err.message : String(err);
                AlertDialog.show({ message: `删除失败：${errorMessage}` });
              } finally {

                animateTo({ duration: 300 }, () => {
                  this.is_show = false;
                });
              }
            })
            .width(120)
            .height(40)
            .margin({ left: 20 })
            .backgroundColor(ThemeColors.danger)
            .fontColor(Color.White)
            .borderRadius(20)
            .stateEffect(true);
        }
        .margin({ bottom: 24 });
      }
      .height("35%")
      .width('80%')
      .backgroundColor(ThemeColors.bgCard)
      .borderRadius(20)
      .shadow({ color: 'rgba(0,0,0,0.2)', radius: 20, offsetX: 0, offsetY: 10 });
    }
    .width("100%")
    .height("100%");
  }
}

@Component
export struct delete_farmland {
  @Link arr_farmland: farmland[];
  @Link _h: string;
  @State is_confirm: boolean = false;
  @State confirm_index: string = '';
  build() {
    Stack() {
      Column() {
        Button("返回")
          .onClick(() => {
            animateTo({ duration: 500 }, () => this._h = "0%");
          })
          .backgroundColor(ThemeColors.primaryLight)
          .fontColor(ThemeColors.primaryDark)
          .borderRadius(20)
          .margin({ top: 16, bottom: 16 });
        List({ space: 12 }) {
          ForEach(this.arr_farmland, (item: farmland) => {
            ListItem() {
              Row() {
                Row({ space: 12 }) {
                  Text("🌾").fontSize(24);
                  Text(item.name)
                    .fontSize(18)
                    .fontColor(ThemeColors.textPrimary)
                    .fontWeight(FontWeight.Medium);
                }
                .layoutWeight(1);
                Button("删除")
                  .onClick(() => this.showDeleteDialog(item.name))
                  .width(80)
                  .height(36)
                  .backgroundColor(ThemeColors.danger + '20')
                  .fontColor(ThemeColors.danger)
                  .borderRadius(18)
                  .borderWidth(1)
                  .borderColor(ThemeColors.danger)
                  .stateEffect(true);
              }
              .width('100%')
              .height(64)
              .padding({ left: 16, right: 16 })
              .backgroundColor(ThemeColors.bgCard)
              .borderRadius(12)
              .shadow({ color: 'rgba(0,0,0,0.05)', radius: 4, offsetX: 0, offsetY: 2 });
            }
            .padding({ top: 4, bottom: 4 });
          });
        }
        .margin({ top: 8 })
        .width('90%')
        .flexGrow(1);
      }
      .height("100%")
      .width("100%")
      .backgroundColor(ThemeColors.bgPrimary);
      if (this.is_confirm) {
        ConfirmDialog({ arr_farmland: this.arr_farmland, is_show: this.is_confirm, name: this.confirm_index });
      }
    }
    .height(this._h)
    .width("100%");
  }
  private showDeleteDialog(item: string) {
    this.confirm_index = item;
    animateTo({ duration: 300 }, () => {
      this.is_confirm = true;
    });
  }
}

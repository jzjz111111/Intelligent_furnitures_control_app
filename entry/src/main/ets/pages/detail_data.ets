// pages/detail_data.ets

import { ThemeColors } from '../utils/theme';
import { McLineChart, Options } from '@mcui/mccharts'

@Entry
@Component
export struct detail_data {
  @Link is_show: boolean
  @Link serOption_humi: Options
  @Link serOption_temp: Options
  @Link serOption_co2: Options
  @State _w: string = "100%"
  @Link _h: string

  build() {
    Column() {
      if (this.is_show) {
        // 返回按钮 - 恢复原来样式（浅绿底，深绿字，无箭头）
        Button("返回")
          .onClick(() => {
            animateTo({ duration: 500 }, () => {
              this._h = "0%"
              this.is_show = false
            })
          })
          .margin({ bottom: 16 })
          .backgroundColor(ThemeColors.primaryLight) // 浅绿底
          .fontColor(ThemeColors.primaryDark) // 深绿字
          .borderRadius(20)

        Scroll() {
          Column({ space: 16 }) {
            this.ChartCard("实时湿度", this.serOption_humi, ThemeColors.techBlue)
            this.ChartCard("实时温度", this.serOption_temp, ThemeColors.primary)
            this.ChartCard("实时CO₂浓度", this.serOption_co2, ThemeColors.secondary)
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width(this._w)
    .height(this.is_show ? "100%" : "0%")
    .backgroundColor(ThemeColors.bgPrimary) // 恢复纯色背景，不用图片
    .padding(this.is_show ? 16 : 0)
  }

  @Builder
  ChartCard(title: string, options: Options, accentColor: string) {
    Column({ space: 12 }) {
      // 标题栏 - 恢复原来样式，只移除右上角小圆点
      Row() {
        Text(title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeColors.textPrimary)

        Blank()

        // 原来这里有右上角小圆点，已移除
        // 保持简洁，不添加其他装饰元素
      }
      .width('100%')

      McLineChart({ options: options })
        .width('100%')
        .height(280)
        .padding(8)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeColors.bgCard) // 纯白卡片背景
    .borderRadius(16)
    .shadow({
      color: 'rgba(102, 187, 106, 0.1)', // 恢复原来浅绿阴影
      radius: 10,
      offsetX: 0,
      offsetY: 4
    })
  }
}
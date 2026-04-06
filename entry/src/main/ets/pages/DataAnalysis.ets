import { McLineChart, McBarChart, McPieChart, Options } from '@mcui/mccharts'

@Entry
@Component
export struct DataAnalysisPage {

  @State tempWeekLine: Options = new Options({
    xAxis: { data: ["周一", "周二", "周三", "周四", "周五", "周六", "周日"] },
    yAxis: { name: '温度(℃)' },
    series: [{
      name: '日均温度',
      data: [18, 20, 22, 21, 23, 22, 21],
      color: "#FF5722",
      arcLineWidth: 100
    }]
  })

  @State soilHumiBar: Options = new Options({
    xAxis: { data: ["农田1", "农田2", "农田3", "农田4", "农田5"] },
    yAxis: { name: '湿度(%)' },
    series: [{
      name: '土壤湿度',
      data: [62, 74, 68, 55, 70],
      color: "#2196F3"
    }]
  })

  @State cropTypePie: Options = new Options({
    series: [{
      name: '种植占比',
      data: [
        { name: "水稻", value: 35 },
        { name: "小麦", value: 25 },
        { name: "玉米", value: 20 },
        { name: "蔬菜", value: 12 },
        { name: "其他", value: 8 }
      ],
      color: "#4CAF50"  //["#4CAF50", "#FF9800", "#FF5722", "#9C27B0", "#607D8B"]
    }]
  })

  @State rainBar: Options = new Options({
    xAxis: { data: ["周一", "周二", "周三", "周四", "周五", "周六", "周日"] },
    yAxis: { name: '降水量(mm)' },
    series: [{
      name: '降水量',
      data: [12, 0, 8, 25, 5, 0, 15],
      color: "#03A9F4"
    }]
  })

  @State lightLine: Options = new Options({
    xAxis: { data: ["周一", "周二", "周三", "周四", "周五", "周六", "周日"] },
    yAxis: { name: '光照(h)' },
    series: [{
      name: '日均光照',
      data: [9, 10, 8, 7, 9, 10, 9],
      color: "#FFC107",
      arcLineWidth: 100
    }]
  })

  @State yieldBar: Options = new Options({
    xAxis: { data: ["农田1", "农田2", "农田3", "农田4", "农田5"] },
    yAxis: { name: '产量(kg)' },
    series: [{
      name: '总产量',
      data: [1200, 1450, 1100, 980, 1300],
      color: "#4CAF50"
    }]
  })

  @State waterFertilizerPie: Options = new Options({
    series: [{
      name: '水肥结构',
      data: [
        { name: "灌溉用水", value: 50 },
        { name: "氮肥", value: 20 },
        { name: "磷肥", value: 15 },
        { name: "钾肥", value: 15 }
      ],
      color:"#0288D1"// ["#0288D1", "#8BC34A", "#FF5722", "#FF9800"]
    }]
  })

  build() {
    Scroll() {
      Column({ space: 12 }) {

        Text("智慧农业 · 数据分析中心")
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 15, bottom: 5 })
        Text("数据驱动种植，科学管理农田")
          .fontSize(15)
          .fontColor("#666")
          .margin({ bottom: 15 })
        Image($r('app.media.position')) // 本地资源引用
          .width('100%')       // 宽度占满屏幕
          .height(200)         // 高度设为180vp（可自行调整）
          .objectFit(ImageFit.Cover) // 图片填满容器，保持比例
          .margin({ bottom: 15 })    // 底部留间距，和标题隔开
          .borderRadius(12)
        Text("🌡  近7日温度变化趋势")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width("90%")
          .textAlign(TextAlign.Start)
        Text("温度稳定是作物健康生长的关键")
          .fontSize(12)
          .fontColor("#888")
          .width("90%")
          .textAlign(TextAlign.Start)
        McLineChart({ options: this.tempWeekLine })
          .width("95%")
          .height(220)

        Text("💧  各农田土壤湿度对比")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width("90%")
          .textAlign(TextAlign.Start)
        Text("湿度均衡可有效减少病虫害发生")
          .fontSize(12)
          .fontColor("#888")
          .width("90%")
          .textAlign(TextAlign.Start)
        McBarChart({ options: this.soilHumiBar })
          .width("95%")
          .height(220)
        Text("🌾  作物类型种植占比")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width("90%")
          .textAlign(TextAlign.Start)
        Text("合理轮作可提升土地利用率与产量")
          .fontSize(12)
          .fontColor("#888")
          .width("90%")
          .textAlign(TextAlign.Start)
        McPieChart({ options: this.cropTypePie })
          .width("95%")
          .height(220)
        Text("🌧  近7日降水量统计")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width("90%")
          .textAlign(TextAlign.Start)
        Text("降水数据指导智能灌溉与排水")
          .fontSize(12)
          .fontColor("#888")
          .width("90%")
          .textAlign(TextAlign.Start)
        McBarChart({ options: this.rainBar })
          .width("95%")
          .height(220)
        Text("☀️  日均光照时长变化")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width("90%")
          .textAlign(TextAlign.Start)
        Text("光照直接影响作物光合作用效率")
          .fontSize(12)
          .fontColor("#888")
          .width("90%")
          .textAlign(TextAlign.Start)
        McLineChart({ options: this.lightLine })
          .width("95%")
          .height(220)
        Text("📦  各农田产量对比")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width("90%")
          .textAlign(TextAlign.Start)
        Text("科学管理提升单产，实现稳产增收")
          .fontSize(12)
          .fontColor("#888")
          .width("90%")
          .textAlign(TextAlign.Start)
        McBarChart({ options: this.yieldBar })
          .width("95%")
          .height(220)
        Text("⚗️  水肥资源使用占比")
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .width("90%")
          .textAlign(TextAlign.Start)
        Text("精细化水肥管理，节约资源提高效益")
          .fontSize(12)
          .fontColor("#888")
          .width("90%")
          .textAlign(TextAlign.Start)
        McPieChart({ options: this.waterFertilizerPie })
          .width("95%")
          .height(220)
        Text("数据赋能农业 · 科技守护丰收")
          .fontSize(14)
          .fontColor("#999")
          .margin({ top: 10, bottom: 30 })
      }
      .width("100%")
    }
    .backgroundColor("#F7F8FA")
  }
}
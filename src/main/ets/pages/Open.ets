@Entry
@Component
struct Open {
  build() {
    Column() {
      Text('智慧农业控制系统')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 24 })
      Text('数据库已初始化，规则服务已启动')
        .margin({ top: 12 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
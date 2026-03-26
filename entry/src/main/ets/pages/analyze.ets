@Entry
@Component
struct Analyze {
  @State message: string = 'Hello World';

  data:string =`{"command_id":"316ea2b8-3065-44db-b2a1-2e8821c72638","response":{"result_code":0,"data":{"temperature":16,"humidity":0,"co2":0,"motion_state":1,"door_state":0,"brightness":0,"1001":0,"1102":1,"2001":0,"3001_2":0,"4001":0,"3001":0,"3001_3":0}}}`
  build() {
    RelativeContainer() {
      Text(this.message)
        .id('AnalyzeHelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(async () => {
          await this.an()
          this.message = 'Welcome';
        })
    }
    .height('100%')
    .width('100%')
  }

  async an(){


    let regex1 = /"data":(.*?)}/
    //{"result_code":0,"data":{"temperature":16,"humidity":0,"co2":0,"motion_state":1,"door_state":0,"brightness":500,"1001":1,"1102":1,"2001":0,"3001_2":0,"4001":0,"3001_1":0,"3001_3":0}}

    console.log("Data::"+this.data)
    let DATA_new = this.data.match(regex1)?.toString()+"}"
    console.log("data:::1"+this.data.match(regex1)?.toString()+"}")
    DATA_new ="{" + DATA_new.match(regex1)?.toString().split("},{")[1]+"}"
    console.log("data:::2"+DATA_new)
    let values:string = JSON.parse(DATA_new)
    console.log("data:::3"+values?.["temperature"])
    console.log("data:::3"+values?.["humidity"])
    return "//{\"result_code\":0,\"data\":{\"temperature\":16,\"humidity\":0,\"co2\":0,\"motion_state\":1,\"door_state\":0,\"brightness\":500,\"1001\":1,\"1102\":1,\"2001\":0,\"3001_2\":0,\"4001\":0,\"3001_1\":0,\"3001_3\":0}}"

  }
}
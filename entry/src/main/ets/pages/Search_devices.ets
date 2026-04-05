//自动搜索设备页面
import { resolveIP, _Udp } from '../tool/UDP'
import util from '@ohos.util';
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { wifi } from '@kit.ConnectivityKit';
import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import preferences from '@ohos.data.preferences';
import { LocalStorage } from '../data/LocalStorage';


let udp:socket.UDPSocket = socket.constructUDPSocketInstance()
@Entry
@Component
export struct search_device{

  @State _text:string = "点击按钮开始搜索"
  @State message:string = ''
  @State List:string[] = []
  @State is_add_list:boolean[] = [false,false,false]
  @State is_add:boolean = false

  @State local:LocalStorage = new LocalStorage("data")
  async aboutToAppear() {
    await this.init()
    const is_search =  await this.local.getDate("is_search")
      if(is_search){
        router.replaceUrl({url:"pages/Index"})
        return
      }

  }
  build() {
    Stack() {
      Column(){
      if (this.List.length != 0) {
        List() {
          ForEach(this.List, (item: string) => {
            ListItem() {
              Row() {
                Text(item)
                Button('+')
                  .onClick(() => {
                    this.is_add = true
                    setTimeout(async () => {
                      await this.local.setDate("is_search",true)
                      AlertDialog.show({ message: "添加成功！！" })
                      router.replaceUrl({url:"pages/Index"})
                    }, 2000)
                  })
              }.width('100%').height("15%").backgroundColor(Color.White).justifyContent(FlexAlign.SpaceEvenly)
            }
            ListItem().height(3).backgroundColor("#00818181")
          })
        }

        Button("再次搜索")
          .onClick(() => {
            this.List = []
          })
      } else {
        Text(this._text)
          .fontSize(30)
        Button("搜索")
          .onClick(async () => {
            this._text = '正在搜索....'
            setTimeout(async () => {
              this.List.push("Hi3861")
              await this.search()
              this.close()
            }, 3000)
            setTimeout(()=>{this.is_add_list[0]=true},800)
            setTimeout(()=>{this.is_add_list[1]=true},1600)
            setTimeout(()=>{this.is_add_list[2]=true},2400)
          })
      }
    }
      if (this.is_add){
        Column(){
          Text("正在添加数据...")
          if (this.is_add_list[0]) {
            Text("项目id：0b37c83e2dba46e08ba5e1da37aeedc8")
          }
          if (this.is_add_list[1]) {
            Text("服务地址：fa8fa44365.st1.iotda-app.cn-north-4.myhuaweicloud.com")
          }
          if (this.is_add_list[2]) {
            Text("网关id：1001")
          }
        }.width("100%").height("100%").backgroundColor("#ff989898")
      }
    }
  }
  async init(){

    let decoder = util.TextDecoder.create('utf-8');
    await udp.bind({port: 8888,
      address: resolveIP(wifi.getIpInfo().ipAddress)})
    udp.setExtraOptions({
      broadcast:true
    })
    udp.on("message",async (data:socket.SocketMessageInfo)=>{
      let str = decoder.decodeToString(new Uint8Array(data.message));
      if(str !="已发送"){
        this.List.push(str)
      }else {

      }
    })

  }
  async search(){
    await udp.send({
      data:`{address:${wifi.getIpInfo().ipAddress},port:8888,action:"search_device"}`,
      address:{address:"255.255.255.255",port:8888}
    })
    await udp.send({data:"已发送",address:{address:wifi.getIpInfo().ipAddress.toString(),port:8888}})
    console.log(`UDP ==Send data >: {address:"255.255.255.255",port:8888}`)
  }
  async close(){
    udp.off("message")
    udp.close()
  }
}
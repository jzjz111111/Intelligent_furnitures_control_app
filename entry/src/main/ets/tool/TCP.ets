import socket from '@ohos.net.socket';
import wifi from '@ohos.wifi';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { On } from '@ohos.UiTest';

//将ip地址转换成 192.168.X.X 格式
function resolveIP(ip:number):string{
  if(ip<0||ip>0xFFFFFFFF){
    return '0'
  }
  return (ip >>>24)+'.'+(ip >> 16 & 0xFF)+'.'+(ip >>8 &0xFF) +'.'+(ip &0xFF);
}

export let Data_Tcp:string = ''
let tcp = socket.constructTCPSocketInstance()
//端口号：

//指令：




export class _Tcp{

  private port:Number = 0
  private to_addr:string = ''
  private localAddr:socket.NetAddress |null = null
  private mixerAddr:socket.TCPConnectOptions |null = null

  constructor(port:number,to_addr:string) {
    this.localAddr = {
      family: 1,
      port: 3866,
      address: resolveIP(wifi.getIpInfo().ipAddress)
    }
    //接收者的ip地址
    this.mixerAddr = {
      address: { address:to_addr,port:port },
      timeout:6000
    }
    this.bindOption()
    this.startListening()
    setTimeout(()=>{
      //tcp.send({ data:'holle' ,address:this.localAddr})
    },5000)

  }
  async bindOption() {
    //绑定
    let promise = tcp.bind(this.localAddr)
    //判断绑定是否成功
    promise.then(() => {
      console.log('tcp bind success')
    }).catch((e: Error) => {
      console.log('tcp bind fail ' + e)
    })

    //连接
    tcp.connect(this.mixerAddr).then(() => {
      console.log('tcp connect success')
      setTimeout(()=>{
        tcp.send(tcpSendOptions).then(() => {
          console.log('TCP send success');
        }).catch((err: Error) => {
          console.log('TCP send fail');
        });
      },2000)

    }).catch((e: Error) => {
      console.log('tcp connect fail ' + JSON.stringify(e))
    })
    let tcpSendOptions: socket.TCPSendOptions = {
      data: 'Hello, server!'
    }

  }
  async send_on(id:number){

    let order :socket.TCPSendOptions= { data:`{"action":"on","ID":${id}}` }

    if(id<2000&&id>999){
      order =  {data:"{\"action\":\"set_brightness\",\"ID\":1001,\"brightness\":5000}"}
    }
    try{
      tcp.send(order)
      console.log(`TCP ==Send ${JSON.stringify(order)} >: ${JSON.stringify(this.mixerAddr)}`)

    }catch (e){
      console.log('TCP ==SendError '+e)
    }

  }
  async send_off(id:number){


    let order :socket.TCPSendOptions= { data:`{"action":"off","ID":${id}}` }
    if(id<2000&&id>999){
      order =  {data:`{"action":"set_brightness","ID":${id},"brightness":1}`}
    }
    try{
      tcp.send(order)
      console.log(`TCP ==Send ${JSON.stringify(order)} >: ${JSON.stringify(this.mixerAddr)}`)

    }catch (e){
      console.log('TCP ==SendError '+e)
    }
  }
  async sendLED_chang(intensity:number,id:number){
    let order :socket.TCPSendOptions= {data:`{"action":"set_brightness","ID":${id},"brightness":`+intensity*1000+"}"}
    try{
      tcp.send(order)
      console.log(`TCP ==Send ${JSON.stringify(order)} >: ${JSON.stringify(this.mixerAddr)}`)

    }catch (e){
      console.log('TCP ==SendError '+e)
    }

  }
  async sendtemperature_control_device_chang(temp:number,id:number){
    let order :socket.TCPSendOptions= {data:`{"action":"set_temp","ID":${id},"temp":`+temp+`}`}
    try{
      tcp.send(order)
      console.log(`TCP ==Send ${JSON.stringify(order)} >: ${JSON.stringify(this.mixerAddr)}`)

    }catch (e){
      console.log('TCP ==SendError '+e)
    }

  }
  async sendtemperature_control_device_dry(id:number){
    let order :socket.TCPSendOptions= {data:`{"action":"set_temperature_control_device_on","ID":${id}}`}
    try{
      tcp.send(order)
      console.log(`TCP ==Send ${JSON.stringify(order)} >: ${JSON.stringify(this.mixerAddr)}`)

    }catch (e){
      console.log('TCP ==SendError '+e)
    }

  }
  async getData(){
    let order :socket.TCPSendOptions = {data:"{\"data\":\"get\"}"}

    try{
      await tcp.send(order)
      console.log(`TCP ==Send ${JSON.stringify(order)} >: ${JSON.stringify(this.mixerAddr)}`)

    }catch (e){
      console.log('TCP ==SendError '+e)
    }
    //Data_Tcp = "{\"temp\":31,\"humi\":50}"
    Data_Tcp = "{\"temp\":20,\"humi\":29}/{\"id\":3001,\"a_temp\":25,\"switch\":1,\"is_dry\":\"1\"}/{\"id\":1001,\"lighting\":5,\"switch\":1}/{\"id\":2001,\"switch\":1}/{\"id\":5001,\"switch\":1}/{\"id\":3002,\"switch\":0}/{\"id\":4001,\"switch\":1}"
    return Data_Tcp
  }

  async startListening() {
    // 后续监听和接收数据的逻辑
    setTimeout(() => {
      let decoder = util.TextDecoder.create('utf-8');

      // 数据接收逻辑
      tcp.on('message', (data) => {
        console.log('TCP ==on message!'+decoder.decodeToString(new Uint8Array(data.message)));
        Data_Tcp = decoder.decodeToString(new Uint8Array(data.message))
        // 处理接收到的数据
        tcp.on('connect', () => {
          console.log("on connect");
        });
        tcp.on('close', () => {
          console.log("on close");
        });
      });

    }, 1000);

  }


  async stop() {


    tcp.close().then(() => {
      console.log('close success');
    }).catch((err: BusinessError) => {
      console.log('close fail');
    });
    tcp.off('message');
    tcp.off('connect');
    tcp.off('close');


  }

}
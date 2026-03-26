import socket from '@ohos.net.socket';
import wifi from '@ohos.wifi';
import util from '@ohos.util';

//将ip地址转换成 192.168.X.X 格式
export function resolveIP(ip:number):string{
  if(ip<0||ip>0xFFFFFFFF){
    return '0'
  }
  return (ip >>>24)+'.'+(ip >> 16 & 0xFF)+'.'+(ip >>8 &0xFF) +'.'+(ip &0xFF);
}

export let udp11 = socket.constructUDPSocketInstance()
//端口号：

export class _Udp{

  private port:Number = 0
  private to_addr:string = ''
  private localAddr:socket.NetAddress |null = null
  private mixerAddr:socket.NetAddress |null = null

  constructor(port:number,to_addr:string) {
    this.localAddr = {
      family: 1,
      port: port,
      address: resolveIP(wifi.getIpInfo().ipAddress)
    }
    //接收者的ip地址
    this.mixerAddr = {
      address:to_addr,
      port:port
    }
    this.bindOption()
    this.startListening()

  }
  async bindOption(){
    //绑定
    let promise = udp11.bind(this.localAddr)

    //判断绑定是否成功
    promise.then(()=>{
      console.log('udp bind success')
    }).catch((e:Error)=>{
      console.log('udp bind fail '+e)
    })

  }
  async sendLEDon(id:number){
    let f_type = ''
    if(id<999) {
      f_type ='device'
    }else if(id<2000){
      f_type = "fillLight"
    }else if(id<3000){
      f_type = "waterValve"
    }

    let order = `{"action":"on","target":"${f_type}"}\r\n`
    try{
      await udp11.send({data:order,address:this.mixerAddr})
      await udp11.send({data:'30:50',address:this.localAddr})

      console.log(`UDP ==Send ${order} >: ${JSON.stringify(this.mixerAddr)}`)

    }catch (e){
      console.log('UDP ==SendError '+e)
    }

  }
  async sendLED_chang(intensity:number){
    let order = `{"lighting",${intensity}}\r\n`
    try{
      await udp11.send({data:order,address:this.mixerAddr})

      console.log(`UDP ==Send ${order} >: ${JSON.stringify(this.mixerAddr)}`)

    }catch (e){
      console.log('UDP ==SendError '+e)
    }

  }

  async sendLEDoff(id:number){
    let f_type = ''
    if(id<999) {
      f_type ='device'
    }else if(id<2000){
      f_type = "fillLight"
    }else if(id<3000){
      f_type = "waterValve"
    }

    let order = `{"action":"off","target":"${f_type}"}\r\n`
    try{
      await udp11.send({data:order,address:this.mixerAddr})

      console.log(`UDP ==Send ${order} >: ${JSON.stringify(this.mixerAddr)}`)

    }catch (e){
      console.log('UDP ==SendError '+e)
    }

  }
  async startListening() {
    // 后续监听和接收数据的逻辑
    let decoder = util.TextDecoder.create('utf-8');
    let reslut:string = ''
      // 数据接收逻辑
    udp11.on('message', async (data) => {
        console.log('UDP ==on message!'+JSON.stringify(data.message.byteLength));
      let str = decoder.decodeToString(new Uint8Array(data.message));
        // 处理接收到的数据
      AlertDialog.show({message:decoder.decodeToString(new Uint8Array(data.message))})
      console.log("UDP ==on:"+str)

    });

  }

  async send_temperature(id:number){


    try{
      await udp11.send({data:'temperature is 0110',address:this.localAddr})

      console.log(`UDP ==Send temperature is 0110 >: ${JSON.stringify(this.localAddr)}`)

    }catch (e){
      console.log('UDP ==SendError '+e)
    }

  }
}


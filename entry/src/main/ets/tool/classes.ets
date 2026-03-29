////////////////////////////************/////////////////////////////////
//农田类
@Observed
export class farmland{
  name:string = ''
  device_s:Device[] = []
  avatar: string = '';
  constructor(name:string,fnt:Device[], avatar: string = '') {
    this.name = name
    this.device_s = fnt
    this.avatar = avatar;
  }
  get_lighting(){
    let max = 0
    for(let f of this.device_s){
      console.log("farmland max: "+f.lighting)
      if( f.lighting > max){
        console.log("farmland max11: "+f.lighting)
        max = f.lighting
      }
    }
    return max
  }
  go_bed(){
    for(let item of this.device_s){
      if(item.type_id < 2000&&item.type_id>999){//如果有补光灯就关掉
        item.close()
      }
    }
  }
  get_up(){
    for(let item of this.device_s){
      if(item.type_id < 2000&&item.type_id>999){//如果有补光灯就关掉
        item.open()
      }
    }
  }
  get_temperature_control_device(){
    for(let item of this.device_s){
      if(item.type_id < 4000&&item.type_id>2999) { //如果有补光灯就关掉
        return item
      }
    }
    return new Device("null",0,0)
  }

  ex_temperature_control_device(){
    for(let f of this.device_s){
      if(f.type_id>2999&&f.type_id<4000)
      {
        return true
      }else {
        return false
      }

    }
    return false
  }
}


/*export class bedroom extends farmland{


  //睡觉函数,可以让补光灯关闭
  go_bed(){
    for(let item of this.device_s){
      if(item.type_id<2000&&item.type_id>999){//如果有补光灯就关掉
        item.close()
      }
    }
  }

}*/
////////////////////////////************/////////////////////////////////


//家居类:
//type=
//00xx:普通家居
//10xx:LED
//20xx:水阀
//30xx:温控设备
//40xx:风扇
//50xx:冰箱
//60XX:扫地机器人
@Observed
export class Device {

  name:string = ''
  switch:number = 0
  type_id:number =0
  constructor(name:string,s:number,type:number) {
    this.name = name
    this.switch = s
    this.type_id = type
  }
  //Led
  public lighting:number = 0
  open(){
    this.switch = 1
    if(this.type_id<2000){this.lighting = 5}
  }
  close(){
    this.switch = 0
    if(this.type_id<2000){this.lighting = 0}
  }

  //temperature_control_device
  public temp:number = 25;
  max_t:number = 30
  min_t:number = 17;
  mode:"zd"|"cs"|"zl"|"zr" = "zd";

  dry(){
    //打开除湿模式(>.<)
  }

  a_turnUp(){
    if(this.max_t>this.temp){
      this.temp++
    }
  }
  a_turnDown(){
    if(this.temp<this.min_t){
      this.temp--
    }
  }

}

export class LED extends Device{
  lighting:number = 100;
  turnUp(){
    if(this.lighting<100){
      this.lighting++
    }
  }
  turnDown(){
    if(this.lighting<100){
      this.lighting--
    }
  }
}


export class temperature_control_device extends Device{





}
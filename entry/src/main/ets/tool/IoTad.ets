import { BusinessError } from '@kit.BasicServicesKit';
import { systemDateTime } from '@kit.BasicServicesKit';
import http from '@ohos.net.http';
// 定义常量
const IAM_ENDPOINT = 'iam.myhuaweicloud.com'; // IAM 服务地址
const IOTDA_ENDPOINT = 'fa8fa44365.st1.iotda-app.cn-north-4.myhuaweicloud.com'; // IoTDA 服务地址
const USERNAME = 'GT-2401_87842262'; // 华为云账号用户名
const PASSWORD = '200626Qq'; // 华为云账号密码
const DOMAIN_NAME = 'GT-2401_87842262'; // 账号所属域名
const PROJECT_NAME = 'cn-north-4'; // 项目名称
const PROJECT_ID = '0b37c83e2dba46e08ba5e1da37aeedc8'; // 项目 ID
export let Data_id_yun:string = ''
export let DATA_new:string = ''


interface _body{
  "auth":_auth
}
interface _auth{
  "identity":_identity,
  "scope":_scope
}
interface _identity{
  "methods":string[],
  "password":_password
}
interface _password{
  "user":_user
}
interface _user{
  "name":string,
  "password":string
  "domain":_domain
}
interface _domain{
  "name":string
}
interface _scope{
  "project":_project
}
interface _project{
  "name":string
}


interface _body4_get_data{
  service_id:string
  command_name:string
  paras:_paras4
}
interface _paras4{}


interface _body1_push_brightness{
  service_id:string
  command_name:string
  paras:_paras
}
interface _paras{ brightness:number }


interface _body3_push_waterValve{
  service_id:string
  command_name:string
  paras:_paras3
}
interface _paras3{ waterValve:string }

interface _body4_push_temperature_control_device{
  service_id:string
  command_name:string
  paras:_paras5
}
interface _paras5{
  temControlDevice:number,
  mode:string,
  state:string
}

interface _body5_push_fan{
  service_id:string
  command_name:string
  paras:_paras6
}
interface _paras6{ fan:string }

export class IoTda{
  Token:string = ''
  DEVICE_ID:string|undefined = "67df87e02902516e866a169d_1001"

  async init() {
    /*let data = a.toString().match(regex)?.toString().split(",{\"result_ code\":0,\"data\":")[1]+"}"
    console.log("data:::"+JSON.parse(data)?.["temperature"])*/

      await this.getToken().then((value)=>{
        if(value == 1){
          this.getDeviceList(this.Token).then((value)=>{
            if(value == 1){
              AlertDialog.show({message:"云端连接成功"})
              return
            }else {
              console.log("IoTad getDeviceList fail!!")
              AlertDialog.show({message:"云端连接失败"})
              return
            }
          })

        }else {
          console.log("IoTad getToken fail!!")
          AlertDialog.show({message:"云端连接失败"})
          return
        }
      })

  }

  async  getToken(){
    const httpRequest = http.createHttp();
    const url = `https://${IAM_ENDPOINT}/v3/auth/tokens`;
    const body:_body = {
      "auth": {
        "identity": {
          "methods": ['password'],
          "password": {
            "user": {
              "name": USERNAME,
              "password": PASSWORD,
              "domain": {
                "name": DOMAIN_NAME,
              },
            },
          },
        },
        "scope": {
          "project": {
            "name": PROJECT_NAME,
          },
        },
      },
    };

    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
        },
        extraData: JSON.stringify(body),
      });

      console.log("resp::::"+JSON.stringify(response))
      if (response.responseCode === 201) {
        const token:string = response.header['x-subject-token'];
        console.log("token is :"+JSON.stringify(response.header))
        console.log("real token is:\n"+token)
        this.Token = token;
        return 1;
      } else {
        console.log('Request URL:', url);
        console.log('Request Body:', JSON.stringify(body));
        console.log('Response Code:', response.responseCode);
        console.log('Response Body:', response.result.toString());
        throw new Error(`Failed to get token: ${response.responseCode}`);
      }
    } catch (error) {
      console.error('Error getting token:', error);
      return -1
    } finally {
      httpRequest.destroy();
    }
  }


  async getDeviceList(token: string) {
  const httpRequest = http.createHttp();
  const url = `https://${IOTDA_ENDPOINT}/v5/iot/${PROJECT_ID}/devices`;

  try {
    const response = await httpRequest.request(url, {
      method: http.RequestMethod.GET,
      header: {
        'Content-Type': 'application/json',
        'X-Auth-Token': token,
      },
    });

    if (response.responseCode === 200) {
      console.log("deviceList::::"+response.result.toString())
      let regex = /"device_id":"(.*?)"/
      console.log("DEVICE_ID:::"+response.result.toString().match(regex)?.toString().split(",")[1])
      this.DEVICE_ID = response.result.toString().match(regex)?.toString().split(",")[1]
      const deviceList:string = JSON.parse(response.result.toString());
      return 1;
    } else {
      throw new Error(`Failed to get device list: ${response.responseCode}`);
    }
  } catch (error) {
    console.error('Error getting device list:', error);
    return -1
  } finally {
    httpRequest.destroy();
  }
}


  async get_data(){

    const httpRequest = http.createHttp();
    const url = `https://${IOTDA_ENDPOINT}/v5/iot/${PROJECT_ID}/devices/${this.DEVICE_ID}/commands`;
    const body :_body4_get_data = {
      service_id: "device_ctrl", // 设备模型中的服务 ID
      command_name: "get_sensor_data", // 命令名称
      paras: {}
    };

    console.log("body:::"+JSON.stringify(body))
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'X-Auth-Token': this.Token,
        },
        extraData: JSON.stringify(body),
      });
      DATA_new = "{\"temperature\":20,\"humidity\":40,\"co2\":88,\"motion_state\":1,\"door_state\":0,\"brightness\":5000,\"1001\":1,\"1102\":1,\"2001\":1,\"3001_2\":20,\"4001\":1,\"3001\":1,\"3001_3\":\"zl\"}"
      console.log("Message sent::"+response.result)
      if (response.responseCode === 200) {
        console.log('Message sent successfully:', response.result.toString());
        let regex = /"response":(.*?)}}}/
        let regex1 = /"data":(.*?)}/

        //{"result_code":0,"data":{"temperature":16,"humidity":0,"co2":0,"motion_state":1,"door_state":0,"brightness":500,"1001":1,"1102":1,"2001":0,"3001_2":0,"4001":0,"3001_1":0,"3001_3":0}}
        try {
          let _time = systemDateTime.getTime(true)
          console.log("Time::::"+_time)
          Data_id_yun = _time.toString()
        } catch(e) {
          let error = e as BusinessError;
          console.info(`Failed to get time. message: ${error.message}, code: ${error.code}`);
        }
        console.log("Data::"+response.result.toString())
        DATA_new = response.result.toString().match(regex1)?.toString()+"}"
        console.log("data:::1"+response.result.toString().match(regex1)?.toString()+"}")
        DATA_new ="{" + DATA_new.match(regex1)?.toString().split("},{")[1]+"}"
        console.log("data:::2"+DATA_new)
        DATA_new = "{\"temperature\":23,\"humidity\":80,\"co2\":26,\"motion_state\":1,\"door_state\":0,\"brightness\":5000,\"1001\":1,\"1102\":1,\"2001\":1,\"3001_2\":20,\"4001\":1,\"3001\":1,\"3001_3\":\"zl\"}"

        return "//{\"result_code\":0,\"data\":{\"temperature\":16,\"humidity\":0,\"co2\":0,\"motion_state\":1,\"door_state\":0,\"brightness\":500,\"1001\":1,\"1102\":1,\"2001\":0,\"3001_2\":0,\"4001\":0,\"3001_1\":0,\"3001_3\":0}}"
        return response.result.toString().match(regex)?.toString().split(",")[1]+"}"

      } else {
        return -1

      }
    } catch (error) {
      console.error('Error sending message:', error);
      return -1
    } finally {
      httpRequest.destroy();
    }
  }


  async set_LED_brightness_by_id(brightness:number,LED_id?:number){

    //https://${IOTDA_ENDPOINT}/v5/iot/${PROJECT_ID}/devices/${this.DEVICE_ID}/commands
    const httpRequest = http.createHttp();
    const url = `https://${IOTDA_ENDPOINT}/v5/iot/${PROJECT_ID}/devices/${this.DEVICE_ID}/commands`;
    const body :_body1_push_brightness = {
      service_id: "device_ctrl", // 设备模型中的服务 ID
      command_name: "set_brightness", // 命令名称
      paras: {
        // 命令参数
        brightness: brightness
      },
    };

    console.log("body:::"+JSON.stringify(body))
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'X-Auth-Token': this.Token,
        },
        extraData: JSON.stringify(body),
      });

      console.log("Message sent::"+response.result)
      if (response.responseCode === 200) {

        console.log('Message sent successfully:', response.result.toString());
        await this.get_data()
        return 1
      } else {
        return -1
      }
    } catch (error) {
      console.error('Error sending message:', error);
      return -1
    } finally {
      httpRequest.destroy();
    }

  }

  async set_waterValve_by_id(commind_on_or_off:string,id?:number){

    const httpRequest = http.createHttp();
    const url = `https://${IOTDA_ENDPOINT}/v5/iot/${PROJECT_ID}/devices/${this.DEVICE_ID}/commands`;
    const body :_body3_push_waterValve = {
      service_id: "device_ctrl", // 设备模型中的服务 ID
      command_name: "set_waterValve", // 命令名称
      paras: {
        // 命令参数
        waterValve:commind_on_or_off
      },
    };

    console.log("body:::"+JSON.stringify(body))
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'X-Auth-Token': this.Token,
        },
        extraData: JSON.stringify(body),
      });

      console.log("Message sent::"+response.result)
      if (response.responseCode === 200) {
        console.log('Message sent successfully:', response.result.toString());
        await this.get_data()
        return 1
      } else {
        return -1
      }
    } catch (error) {
      console.error('Error sending message:', error);
      return -1
    } finally {
      httpRequest.destroy();
    }

  }

  async set_temperature_control_device_by_id(commind:number,state:string,mode:string,id?:number){

    const httpRequest = http.createHttp();
    const url = `https://${IOTDA_ENDPOINT}/v5/iot/${PROJECT_ID}/devices/${this.DEVICE_ID}/commands`;
    const body :_body4_push_temperature_control_device = {
      service_id: "device_ctrl", // 设备模型中的服务 ID
      command_name: "set_temControlDevice", // 命令名称
      paras: {
        // 命令参数
        temControlDevice:commind,
        mode:mode,
        state:state
      },
    };

    console.log("body:::"+JSON.stringify(body))
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'X-Auth-Token': this.Token,
        },
        extraData: JSON.stringify(body),
      });

      console.log("Message sent::"+response.result)
      if (response.responseCode === 200) {
        console.log('Message sent successfully:', response.result.toString());
        await this.get_data()
        return 1
      } else {
        return -1
      }
    } catch (error) {
      console.error('Error sending message:', error);
      return -1
    } finally {
      httpRequest.destroy();
    }

  }

  async set_fan_by_id(commind_on_or_off:string,id?:number){

    const httpRequest = http.createHttp();
    const url = `https://${IOTDA_ENDPOINT}/v5/iot/${PROJECT_ID}/devices/${this.DEVICE_ID}/commands`;
    const body :_body5_push_fan = {
      service_id: "device_ctrl", // 设备模型中的服务 ID
      command_name: "set_fan", // 命令名称
      paras: {
        // 命令参数
        fan:commind_on_or_off
      },
    };

    console.log("body:::"+JSON.stringify(body))
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'X-Auth-Token': this.Token,
        },
        extraData: JSON.stringify(body),
      });

      console.log("Message sent::"+response.result)
      if (response.responseCode === 200) {
        console.log('Message sent successfully:', response.result.toString());
        await this.get_data()
        return 1
      } else {
        return -1
      }
    } catch (error) {
      console.error('Error sending message:', error);
      return -1
    } finally {
      httpRequest.destroy();
    }

  }

}




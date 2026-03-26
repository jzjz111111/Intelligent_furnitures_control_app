import { HttpRequest } from '../data/HttpFuntion';
//import { http } from '@kit.NetworkKit';

import http from '@ohos.net.http';

// 定义常量
const IAM_ENDPOINT = 'iam.myhuaweicloud.com'; // IAM 服务地址
const IOTDA_ENDPOINT = 'fa8fa44365.st1.iotda-app.cn-north-4.myhuaweicloud.com'; // IoTDA 服务地址
const USERNAME = 'GT-2401_87842262'; // 华为云账号用户名
const PASSWORD = '200626Qq'; // 华为云账号密码
const DOMAIN_NAME = 'GT-2401_87842262'; // 账号所属域名
const PROJECT_NAME = 'cn-north-4'; // 项目名称
const PROJECT_ID = '0b37c83e2dba46e08ba5e1da37aeedc8'; // 项目 ID

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
// 获取 Token
async function getToken(): Promise<string> {
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
      return token;
    } else {
      console.log('Request URL:', url);
      console.log('Request Body:', JSON.stringify(body));
      console.log('Response Code:', response.responseCode);
      console.log('Response Body:', response.result.toString());
      throw new Error(`Failed to get token: ${response.responseCode}`);

    }
  } catch (error) {
    console.error('Error getting token:', error);
    return 'error'
  } finally {
    httpRequest.destroy();
  }
}


async function getDeviceMessages(
  token: string,
  deviceId: string,
  startTime?: string,
  endTime?: string,
  limit: number = 10
)  {
  const httpRequest = http.createHttp();
  let url = `https://${IOTDA_ENDPOINT}/v5/iot/${PROJECT_ID}/devices/67df87e02902516e866a169d_1001/messages`;


  try {
    const response = await httpRequest.request(url, {
      method:http.RequestMethod.GET,
      header: {
        'Content-Type': 'application/json',
        'X-Auth-Token': token
      }
    });
    console.log("messages:::"+JSON.stringify(response.result)+JSON.stringify(response.responseCode))
    if (response.responseCode === 200) {
      return JSON.parse(response.result.toString());
    } else {

    }
  } finally {
    httpRequest.destroy();
  }
}
// 获取设备列表
async function getDeviceList(token: string): Promise<string> {
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

      const deviceList:string = JSON.parse(response.result.toString());
      return deviceList;
    } else {
      throw new Error(`Failed to get device list: ${response.responseCode}`);
    }
  } catch (error) {
    console.error('Error getting device list:', error);
    return 'error'
  } finally {
    httpRequest.destroy();
  }
}

interface _body1{
  service_id:string
  command_name:string
  paras:_paras
}
interface _paras{
  brightness:number
}


// 主函数
async function getList() {
  try {
    // 1. 获取 Token
    const token = await getToken();
    console.log('Token:'+ JSON.stringify(token));

    // 2. 获取设备列表
    const deviceList = await getDeviceList(token);
    console.log('Device List:', JSON.stringify(deviceList));
    return JSON.stringify(deviceList)
  } catch (error) {
    console.error('Error:', error);
    return "error"
  }

}

const SMN_ENDPOINT = 'smn.myhuaweicloud.com';
const TOPIC_URN = 'your_topic_urn';
interface _body2{
  protocol: string,
  endpoint: string,
  remark: string,
}



async function push_command(command_name:string,command_content:string,service_id:string){

  const httpRequest = http.createHttp();
  const url = `https://${IOTDA_ENDPOINT}/v5/iot/${PROJECT_ID}/devices/67df87e02902516e866a169d_1001/commands`;
  const body :_body1 = {
    service_id: service_id, // 设备模型中的服务 ID
    command_name: command_name, // 命令名称
    paras: {
      // 命令参数
      brightness: 8888,
    },
  };

  console.log("body:::"+JSON.stringify(body))
  try {
    const response = await httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'X-Auth-Token': await getToken(),
      },
      extraData: JSON.stringify(body),
    });

    console.log("Message sent::"+response.result)
    if (response.responseCode === 200) {
      console.log('Message sent successfully:', response.result.toString());
    } else {
      throw new Error(`Failed to send message: ${response.responseCode}`);
    }
  } catch (error) {
    console.error('Error sending message:', error);
  } finally {
    httpRequest.destroy();
  }

}

interface _body4{
  service_id:string
  command_name:string
  paras:_paras4
}
interface _paras4{

}
async function get_data(name:string,content:string,service_id:string){

  const httpRequest = http.createHttp();
  const url = `https://${IOTDA_ENDPOINT}/v5/iot/${PROJECT_ID}/devices/67df87e02902516e866a169d_1001/commands`;
  const body :_body4 = {
    service_id: service_id, // 设备模型中的服务 ID
    command_name: name, // 命令名称
    paras: { }
  };

  console.log("body:::"+JSON.stringify(body))
  try {
    const response = await httpRequest.request(url, {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json',
        'X-Auth-Token': await getToken(),
      },
      extraData: JSON.stringify(body),
    });

    console.log("Message sent::"+response.result)
    if (response.responseCode === 200) {
      console.log('Message sent successfully:', response.result.toString());
    } else {
      throw new Error(`Failed to send message: ${response.responseCode}`);
    }
  } catch (error) {
    console.error('Error sending message:', error);
  } finally {
    httpRequest.destroy();
  }

}
@Entry
@Component
struct Get_device {
  @State message: string = 'Hello World';


  async aboutToAppear() {
    this.message = await getList()

  }
  build() {
    Column() {
      Text(this.message)
        .id('Get_deviceHelloWorld')
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.message = 'Welcome';
        })
      Button("发指令")
        .onClick(()=>{
          push_command("set_brightness",'50','device_ctrl')
        })
      Button("收消息")
        .onClick(async ()=>{
          get_data("get_sensor_data","","device_ctrl")

          //getDeviceMessages(await getToken(),"67df87e02902516e866a169d_1001")
        })
    }
    .height('100%')
    .width('100%')
  }
}
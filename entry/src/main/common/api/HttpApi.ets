import http from '@ohos.net.http';
import { BusinessError } from '@kit.BasicServicesKit';

// ===================== 接口定义（零 any/unknown） =====================
interface SensorData {
  temperature: number;
  humidity: number;
  co2: number;
}

interface HardwareParams {
  led1?: number;
  led2?: number;
  led3?: number;
  spray?: number;
}

interface ControlRequest {
  serviceId: string;
  commandName: string;
  paras: HardwareParams;
}

// 把 data 明确为 SensorData 或其他具体类型
interface SensorResponse extends BaseResponse {
  data: SensorData;
}

interface BaseResponse {
  code: number;
  message: string;
}

// ===================== 配置 =====================
const BASE_URL: string = "http://10.33.50.235:8080";

// ===================== GET 请求 =====================
export async function GET(url: string): Promise<SensorResponse> {
  let httpRequest = http.createHttp();
  return new Promise<SensorResponse>((resolve, reject) => {
    httpRequest.request(
      BASE_URL + url,
      {
        method: http.RequestMethod.GET,
        header: {
          "Content-Type": "application/json"
        },
        readTimeout: 10000,
        connectTimeout: 10000
      },
      (err: BusinessError, data: http.HttpResponse) => {
        httpRequest.destroy();
        if (!err) {
          try {
            const result: SensorResponse = JSON.parse(data.result as string) as SensorResponse;
            resolve(result);
          } catch (e) {
            reject(e);
          }
        } else {
          reject(err);
        }
      }
    );
  });
}

// ===================== POST 请求 =====================
export async function POST(url: string, body: ControlRequest): Promise<BaseResponse> {
  let httpRequest = http.createHttp();
  return new Promise<BaseResponse>((resolve, reject) => {
    httpRequest.request(
      BASE_URL + url,
      {
        method: http.RequestMethod.POST,
        header: {
          "Content-Type": "application/json"
        },
        extraData: JSON.stringify(body),
        readTimeout: 10000,
        connectTimeout: 10000
      },
      (err: BusinessError, data: http.HttpResponse) => {
        httpRequest.destroy();
        if (!err) {
          try {
            const result: BaseResponse = JSON.parse(data.result as string) as BaseResponse;
            resolve(result);
          } catch (e) {
            reject(e);
          }
        } else {
          reject(err);
        }
      }
    );
  });
}

// ===================== 业务接口 =====================

// 获取传感器数据（移除 unknown，直接用 SensorResponse）
export async function getSensorData(): Promise<SensorData> {
  let response = await GET("/api/sensor/latest");
  return response.data; // 直接返回，不再需要类型断言
}

// 硬件控制（LED、喷雾）
export async function controlHardware(paras: HardwareParams): Promise<BaseResponse> {
  let body: ControlRequest = {
    serviceId: "env_sensor",
    commandName: "dev_ctrl",
    paras: paras
  };
  return POST("/api/hardware/control", body);
}
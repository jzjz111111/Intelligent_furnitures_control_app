//智慧农业 MQTT 硬件交互逻辑


// 所有接口必须提前、显式定义
//光照等级规则接口
interface LightLevelRule {
  lux: number;
  level: number;
}

// 华为云服务信息接口
interface ServiceInfo {
  service_id: string;
  properties: Record<string, number>;
}

//硬件上报完整数据接口
interface DeviceReport {
  services: Array<ServiceInfo>;
}

//传感器数据标准接口（APP内部使用）
export interface SensorData {
  led1: number;
  led2: number;
  led3: number;
  spray: number;
  temperature: number;
  humidity: number;
  co2: number;
  soil_adc: number;
}

//下发指令参数接口
export interface ControlParas {
  led1: number;
  led2: number;
  led3: number;
  spray: number;
}

//下发指令完整结构接口
export interface ControlCommand {
  service_id: string;
  command_name: string;
  paras: ControlParas;
}

//华为云配置接口
export interface CloudSetting {
  SERVICE_ID: string;
  COMMAND_NAME: string;
  REPORT_TOPIC: string;
}

// 常量配置
//光照强度 -> 灯亮度等级映射（可直接修改数值）
const LIGHT_LEVEL_CONFIG: LightLevelRule[] = [
  { lux: 0, level: 0 },
  { lux: 50, level: 1 },
  { lux: 200, level: 2 },
  { lux: 400, level: 3 },
  { lux: 600, level: 4 },
  { lux: 1000, level: 5 }
];

//华为云平台固定配置
const CLOUD_SETTING: CloudSetting = {
  SERVICE_ID: "env_sensor",
  COMMAND_NAME: "dev_ctrl",
  REPORT_TOPIC: "$oc/devices/69c3bc5a7f2e6c302f6089e5/sys/properties/report"
};

// 核心业务类
export class AgricultureMqttLogic {
  // 缓存最新硬件数据
  private latestSensorData: SensorData | null = null;

  /**
   * 【硬件 → APP】解析华为云推送的原始上报数据
   * @param rawJson 硬件上报的原始JSON字符串
   * @return 解析后的标准数据 SensorData
   */
  parseDeviceReport(rawJson: string): SensorData | null {
    try {
      const jsonObj = JSON.parse(rawJson) as DeviceReport;
      const deviceReport: DeviceReport = jsonObj;

      const services: Array<ServiceInfo> = deviceReport.services || [];
      const targetService = services.find((item: ServiceInfo) => {
        return item.service_id === CLOUD_SETTING.SERVICE_ID;
      });

      if (!targetService || !targetService.properties) {
        console.error("解析失败：未找到 env_sensor 服务数据");
        return null;
      }

      const props: Record<string, number> = targetService.properties;
      this.latestSensorData = {
        led1: props.led1 ?? 0,
        led2: props.led2 ?? 0,
        led3: props.led3 ?? 0,
        spray: props.spray ?? 0,
        temperature: props.temperature ?? 0,
        humidity: props.humidity ?? 0,
        co2: props.co2 ?? 0,
        soil_adc: props.soil_adc ?? 0
      };

      console.info("解析硬件数据成功:", JSON.stringify(this.latestSensorData));
      return this.latestSensorData;
    } catch (err) {
      console.error("数据解析异常:", err);
      return null;
    }
  }

  /**
   * 根据光照强度 自动计算灯亮度等级(0-5)
   * @param currentLux 当前光照强度
   * @return 亮度等级
   */
  calcLightLevel(currentLux: number): number {
    for (let i = LIGHT_LEVEL_CONFIG.length - 1; i >= 0; i--) {
      if (currentLux <= LIGHT_LEVEL_CONFIG[i].lux) {
        return LIGHT_LEVEL_CONFIG[i].level;
      }
    }
    return 5; // 默认最高亮度
  }

  /**
   * 【APP → 硬件】生成华为云标准控制指令
   * @param led1 灯1等级 0-5
   * @param led2 灯2等级 0-5
   * @param led3 灯3等级 0-5
   * @param spray 喷雾 0/1
   * @return 下发给硬件的JSON字符串
   */
  buildControlCmd(led1: number, led2: number, led3: number, spray: number): string {
    // 限制数值范围，防止错误指令
    const limit = (val: number): number => Math.max(0, Math.min(5, val));
    const sprayState: number = spray === 1 ? 1 : 0;

    const command: ControlCommand = {
      service_id: CLOUD_SETTING.SERVICE_ID,
      command_name: CLOUD_SETTING.COMMAND_NAME,
      paras: {
        led1: limit(led1),
        led2: limit(led2),
        led3: limit(led3),
        spray: sprayState
      }
    };

    return JSON.stringify(command);
  }

  // 快捷控制方法
  //一键控制所有灯
  setAllLights(level: number): string {
    return this.buildControlCmd(level, level, level, 0);
  }

  //AI识别害虫 → 启动喷雾（保持灯状态不变）
  startPestControl(): string {
    const data: SensorData | null = this.latestSensorData;
    return this.buildControlCmd(
      data?.led1 || 0,
      data?.led2 || 0,
      data?.led3 || 0,
      1
    );
  }

  //停止喷雾
  stopPestControl(): string {
    const data: SensorData | null = this.latestSensorData;
    return this.buildControlCmd(
      data?.led1 || 0,
      data?.led2 || 0,
      data?.led3 || 0,
      0
    );
  }

  //获取最新硬件数据
  getLatestData(): SensorData | null {
    return this.latestSensorData;
  }
}
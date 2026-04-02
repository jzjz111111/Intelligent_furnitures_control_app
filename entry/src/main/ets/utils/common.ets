// utils/common.ets

// ==================== 类型定义 ====================
import { farmland } from '../tool/classes';
// 环境状态返回类型 - 必须显式声明接口
export interface EnvStatusResult {
  color: string;
  text: string;
}



export interface WarnHistoryItem {
  typeText: string;
  data: number;
  time: string;
}

// ==================== 数据模型 ====================

export class Datamodel {
  type: string = '';
  arr: farmland[] = [];
  data: number = 0;
}

// ==================== 常量定义 ====================

// 预定义状态结果对象，避免在 switch 中直接返回字面量
const STATUS_HIGH: EnvStatusResult = { color: '#E57373', text: '偏高' };
const STATUS_LOW: EnvStatusResult = { color: '#FFB74D', text: '偏低' };
const STATUS_OK: EnvStatusResult = { color: '#81C784', text: '适宜' };
const STATUS_UNKNOWN: EnvStatusResult = { color: '#9E9E9E', text: '未知' };
export const max_temp: number = 30;      // 温度阈值
export const max_humi: number = 90;      // 湿度阈值
export const max_co2: number = 1500;     // CO2阈值

// 添加缺失的导出函数
export function resolveIP(ip: string | number): string {
  return String(ip).trim();
}
// ==================== 工具函数 ====================

export function getEnvStatus(value: number, type: 'temp' | 'humi' | 'co2'): EnvStatusResult {
  let result: EnvStatusResult;

  switch (type) {
    case 'temp':
      if (value > 30) {
        result = STATUS_HIGH;
      } else if (value < 15) {
        result = STATUS_LOW;
      } else {
        result = STATUS_OK;
      }
      break;
    case 'humi':
      if (value > 90) {
        result = STATUS_HIGH;
      } else if (value < 40) {
        result = STATUS_LOW;
      } else {
        result = STATUS_OK;
      }
      break;
    case 'co2':
      if (value > 1500) {
        result = STATUS_HIGH;
      } else if (value < 400) {
        result = STATUS_LOW;
      } else {
        result = STATUS_OK;
      }
      break;
    default:
      result = STATUS_UNKNOWN;
  }

  return result;
}
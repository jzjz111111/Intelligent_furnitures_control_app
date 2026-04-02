/**
 * 农业辅助服务工具集（云侧 OCR 方案）
 * 适配 HarmonyOS 5.0.2 模拟器和真机
 */

import { http } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';

/** HTTP 回调类型定义 */
type HttpCallback = (err: Error, data: http.HttpResponse) => void;

/** 请求头构造器（避免直接写对象字面量） */
class RequestHeaderBuilder {
  private headers: Record<string, string> = {};

  set(key: string, value: string): RequestHeaderBuilder {
    this.headers[key] = value;
    return this;
  }

  build(): Record<string, string> {
    return this.headers;
  }
}

/** 农业知识条目类 */
class AgriSolution {
  symptom: string = '';
  cause: string = '';
  solution: string[] = [];
  prevention: string[] = [];

  constructor(symptom: string, cause: string, solution: string[], prevention: string[]) {
    this.symptom = symptom;
    this.cause = cause;
    this.solution = solution;
    this.prevention = prevention;
  }
}

/** 知识库集合类 */
class AgriKnowledgeBaseClass {
  rice_blast: AgriSolution;
  aphid: AgriSolution;
  high_temp: AgriSolution;
  high_humidity: AgriSolution;

  constructor() {
    this.rice_blast = new AgriSolution(
      '稻瘟病：叶片出现梭形病斑，边缘褐色，中央灰白色',
      '真菌感染，高温高湿环境易发，氮肥过多加重病害',
      [
        '立即喷施三环唑或稻瘟灵（按说明书稀释）',
        '排水晒田，降低田间湿度至60%以下',
        '清除病株残体，集中深埋或烧毁',
      ],
      [
        '选用抗病品种（如汕优、威优系列）',
        '合理密植，保持通风透光',
        '避免偏施氮肥，增施磷钾肥',
      ]
    );

    this.aphid = new AgriSolution(
      '蚜虫：叶片卷曲变形，有蜜露（粘液体），植株矮小发黄',
      '温度20-25℃繁殖最快，干旱天气加重危害',
      [
        '喷施吡虫啉10%可湿性粉剂2000倍液',
        '或啶虫脒5%乳油2500倍液',
        '保护瓢虫、草蛉等天敌',
        '黄色粘虫板诱杀（每亩20-30块）',
      ],
      [
        '清除田间杂草，减少虫源',
        '合理灌溉，避免干旱胁迫',
        '轮作倒茬，打破害虫生命周期',
      ]
    );

    this.high_temp = new AgriSolution(
      '高温热害：叶片萎蔫下垂，生长停滞，花粉败育导致空壳',
      '气温持续超过35℃，相对湿度低于60%，通风不良',
      [
        '早晚喷灌降温（上午9点前或下午5点后）',
        '搭建遮阳网（遮光率30-50%，中午使用）',
        '喷施0.2%磷酸二氢钾增强抗性',
        '开启水帘风机（大棚）',
      ],
      [
        '选用耐热品种（如热优、湘早籼等）',
        '调整播期避开高温伏旱',
        '高温来临前浇透水（田间保持水层）',
      ]
    );

    this.high_humidity = new AgriSolution(
      '湿度过高：土壤积水，根系发黄，叶片水渍状，易发病害',
      '排水不畅，连续降雨，灌溉过量，土壤粘重',
      [
        '立即疏通排水沟渠，排除积水',
        '中耕松土，增加土壤透气性',
        '暂停灌溉，改为叶面喷施养分',
        '喷施杀菌剂预防病害（如多菌灵）',
      ],
      [
        '完善排水系统，开挖腰沟、围沟',
        '采用高垄栽培（垄高20-30cm）',
        '安装土壤湿度传感器，精准灌溉',
      ]
    );
  }
}

/** 实例化知识库 */
const AgriKnowledgeBase = new AgriKnowledgeBaseClass();

/** 百度配置类 */
class BaiduConfig {
  apiKey: string = 'BhqMU9gd3cIVkTLPiQgoUDCJ';
  secretKey: string = '6kIbhC2zDs16i4NA4vHabbki0csBt5gl';
  accessToken: string = '';
  expiresAt: number = 0;
}

const BAIDU_OCR_CONFIG = new BaiduConfig();

/** OCR 结果类 */
interface GeneratedTypeLiteralInterface_1 {
  words: string;
}

class CloudOCRResult {
  words_result: Array<GeneratedTypeLiteralInterface_1> = [];
  words_result_num: number = 0;
  error_code?: number;
  error_msg?: string;
}

/** Token 响应类 */
class BaiduTokenResponse {
  access_token: string = '';
  expires_in: number = 0;
}

/** 获取百度 OCR AccessToken */
async function getBaiduAccessToken(): Promise<string> {
  if (BAIDU_OCR_CONFIG.accessToken && Date.now() < BAIDU_OCR_CONFIG.expiresAt) {
    return BAIDU_OCR_CONFIG.accessToken;
  }

  const url =
    `https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials&client_id=${BAIDU_OCR_CONFIG.apiKey}&client_secret=${BAIDU_OCR_CONFIG.secretKey}`;

  return new Promise((resolve, reject) => {
    const httpRequest = http.createHttp();

    const header = new RequestHeaderBuilder()
      .set('Content-Type', 'application/json')
      .set('Accept', 'application/json')
      .build();

    const callback: HttpCallback = (err, data) => {
      if (!err && data.responseCode === 200) {
        const result = JSON.parse(data.result.toString()) as BaiduTokenResponse;
        BAIDU_OCR_CONFIG.accessToken = result.access_token;
        BAIDU_OCR_CONFIG.expiresAt = Date.now() + result.expires_in * 1000;
        resolve(result.access_token);
      } else {
        reject(err || new Error(`HTTP ${data.responseCode}`));
      }
      httpRequest.destroy();
    };

    httpRequest.request(
      url,
      {
        method: http.RequestMethod.POST,
        header,
      },
      callback
    );
  });
}

/** 图片转 Base64 */
async function imageToBase64(imagePath: string): Promise<string> {
  try {
    const file = fileIo.openSync(imagePath, fileIo.OpenMode.READ_ONLY);
    const stat = fileIo.statSync(file.fd);
    const buffer = new ArrayBuffer(stat.size);
    fileIo.readSync(file.fd, buffer);
    fileIo.closeSync(file);

    const uint8Array = new Uint8Array(buffer);
    const base64Helper = new util.Base64Helper();
    return base64Helper.encodeToStringSync(uint8Array);
  } catch (error) {
    console.error('图片转 Base64 失败:', error);
    return '';
  }
}

// 标志，确保沙箱只初始化一次
let sandboxInitialized = false;

// ===== 新增：沙箱初始化辅助函数（传入 filesDir 路径字符串） =====
export async function ensureSandboxDir(filesDir: string): Promise<void> {
  const filePath = `${filesDir}/test.png`;
  try {
    let stat: fileIo.Stat | null;
    try {
      stat = fileIo.statSync(filesDir);
    } catch {
      stat = null;
    }
    if (!stat || !stat.isDirectory) {
      fileIo.mkdirSync(filesDir);
    }

    const file = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
    const content = new Uint8Array([65, 66, 67]);
    fileIo.writeSync(file.fd, content.buffer);
    fileIo.closeSync(file.fd);
    console.info('[DEBUG] 沙箱目录初始化成功，测试文件已写入:', filePath);
  } catch (e) {
    console.error('[DEBUG] 沙箱初始化失败:', (e as Error).message);
  }
}

/** 云侧 OCR 识别 */
interface GeneratedTypeLiteralInterface_2 {
  words: string;
}

export async function recognizeWithCloudOCR(imagePath: string): Promise<string> {
  try {
    if (BAIDU_OCR_CONFIG.apiKey === '你的百度云 API Key') {
      return (
        '【模拟器模式 - 未配置API Key】\n\n' +
          '请先配置百度 OCR API Key 和 Secret Key\n' +
          '配置步骤：\n' +
          '1. 访问 https://cloud.baidu.com/product/ocr\n' +
          '2. 创建应用获取 API Key\n' +
          '3. 修改代码中的 BAIDU_OCR_CONFIG\n\n' +
          '【当前显示模拟数据】\n' +
          '识别到肥料标签：复合肥 N-P-K 15-15-15\n\n' +
          '【施用建议】\n' +
          '1. 根据作物生育期选择肥料类型\n' +
          '2. 避免过量施用，防止烧苗\n' +
          '3. 配合灌溉使用，提高吸收率'
      );
    }

    if (!sandboxInitialized) {
      // 由调用方传入 filesDir，识别这里不再做目录初始化，调用方负责
      sandboxInitialized = true;
    }

    const base64Image = await imageToBase64(imagePath);
    if (!base64Image) {
      return '错误：无法读取图片文件';
    }

    const accessToken = await getBaiduAccessToken();
    const url = `https://aip.baidubce.com/rest/2.0/ocr/v1/general_basic?access_token=${accessToken}`;

    return new Promise((resolve) => {
      const httpRequest = http.createHttp();
      const params = `image=${encodeURIComponent(base64Image)}&detect_direction=true&paragraph=true&probability=false`;

      const header = new RequestHeaderBuilder()
        .set('Content-Type', 'application/x-www-form-urlencoded')
        .set('Accept', 'application/json')
        .build();

      const callback: HttpCallback = (err, data) => {
        if (!err && data.responseCode === 200) {
          const result = JSON.parse(data.result.toString()) as CloudOCRResult;

          if (result.error_code) {
            resolve(`OCR 服务错误：${result.error_msg} (错误码: ${result.error_code})`);
          } else if (!result.words_result_num || result.words_result_num === 0) {
            resolve('未识别到文字，请确保图片清晰');
          } else {
            const text = result.words_result.map((item: GeneratedTypeLiteralInterface_2) => item.words).join('\n');
            resolve(analyzeAgriText(text, '百度OCR'));
          }
        } else {
          resolve(`请求失败：${err?.message || `HTTP ${data.responseCode}`}`);
        }
        httpRequest.destroy();
      };

      httpRequest.request(
        url,
        {
          method: http.RequestMethod.POST,
          header,
          extraData: params,
        },
        callback
      );
    });
  } catch (err) {
    const error = err instanceof Error ? err : new Error(String(err));
    return (
      `识别失败：${error.message}\n\n` +
        '可能原因：\n1. 网络连接失败（模拟器需要主机联网）\n' +
        '2. API Key 配置错误\n' +
        '3. 图片过大（建议压缩至 2MB 以下）'
    );
  }
}

/** 分析文本并返回农资建议 */
function analyzeAgriText(text: string, source: string): string {
  const lowerText = text.toLowerCase();

  let type = '未知';
  if (
    lowerText.includes('农药') ||
    lowerText.includes('杀虫') ||
    lowerText.includes('杀菌') ||
    lowerText.includes('乳油')
  ) {
    type = '农药';
  } else if (
    lowerText.includes('肥料') ||
    lowerText.includes('肥') ||
    lowerText.includes('n-p-k') ||
    lowerText.includes('复合肥')
  ) {
    type = '肥料';
  }

  let advice = '';
  if (type === '农药') {
    advice =
      '【使用建议】\n1. 仔细阅读使用说明和稀释倍数\n2. 佩戴防护手套和口罩\n3. 避开高温时段（上午10点-下午4点）喷施\n4. 遵守安全间隔期';
  } else if (type === '肥料') {
    advice = '【施用建议】\n1. 根据作物生育期选择肥料类型\n2. 避免过量施用，防止烧苗\n3. 配合灌溉使用，提高吸收率';
  } else {
    advice =
      '【提示】\n如需了解具体农资的使用方法，请确保拍摄清晰的标签文字区域，包含产品名称、成分、使用方法等信息。';
  }

  return `【${source} 识别结果】\n${text.substring(0, 200)}${text.length > 200 ? '...' : ''}\n\n【识别类型】${type}\n\n${advice}\n\n— 由云端 AI 生成 —`;
}

/** 农田问题检测（主入口） */
export async function detectFieldIssues(imagePath: string): Promise<string> {
  return recognizeWithCloudOCR(imagePath);
}

/** 本地农业知识库问答 */
export async function queryLocalAI(question: string): Promise<string> {
  const lowerQ = question.toLowerCase();

  if (lowerQ.includes('稻瘟') || lowerQ.includes('病斑') || lowerQ.includes('褐色斑点')) {
    return formatSolution(AgriKnowledgeBase.rice_blast);
  }
  if (lowerQ.includes('蚜虫') || lowerQ.includes('蜜露') || lowerQ.includes('叶片卷曲')) {
    return formatSolution(AgriKnowledgeBase.aphid);
  }
  if (lowerQ.includes('高温') || lowerQ.includes('热害') || lowerQ.includes('降温') || lowerQ.includes('萎蔫')) {
    return formatSolution(AgriKnowledgeBase.high_temp);
  }
  if (lowerQ.includes('湿度') || lowerQ.includes('潮湿') || lowerQ.includes('积水') || lowerQ.includes('排水')) {
    return formatSolution(AgriKnowledgeBase.high_humidity);
  }

  return (
    `【鸿蒙本地农业助手】针对"${question}"的建议：\n\n` +
      '1. 图像诊断：请拍摄清晰叶片/害虫特写，使用"拍照识虫"功能\n' +
      '2. 农资查询：拍摄农药/肥料标签，使用"标签识别"功能\n' +
      '3. 常见咨询：\n' +
      '   • 输入"稻瘟病"获取病害防治方案\n' +
      '   • 输入"蚜虫"获取虫害防治方案\n' +
      '   • 输入"高温"获取降温措施\n' +
      '   • 输入"湿度"获取排水建议\n\n' +
      '【免责声明】本应用使用本地专家系统，建议仅供参考，重大病虫害请咨询当地农技站。'
  );
}

/** 格式化农业知识库内容 */
function formatSolution(info: AgriSolution): string {
  return (
    `【诊断结果】${info.symptom}\n\n` +
      `【病因分析】${info.cause}\n\n` +
      '🆘 **紧急处理措施**\n' +
      `${info.solution.map((s: string, i: number) => `${i + 1}. ${s}`).join('\n')}\n\n` +
      '✅ **长期预防策略**\n' +
      `${info.prevention.map((s: string, i: number) => `${i + 1}. ${s}`).join('\n')}\n\n` +
      '— 由鸿蒙端侧 AI 生成 —'
  );
}

/** 模拟图像识别（供 UI 调试、模拟器使用） */
export async function simulateImageAnalysis(imagePath: string): Promise<string> {
  const fileName = imagePath.split('/').pop() ?? '未知文件';
  return (
    `【图像已接收】${fileName}\n\n` +
      '⚠️ 模拟器模式：VisionKit OCR 需要真机支持\n\n' +
      '请切换至真机测试完整功能，或使用"文字问答"获取农业建议。'
  );
}

/** 保留原 OCR 函数供真机使用（当前委托给云侧 OCR） */
export async function recognizeAgriLabel(imagePath: string): Promise<string> {
  return recognizeWithCloudOCR(imagePath);
}
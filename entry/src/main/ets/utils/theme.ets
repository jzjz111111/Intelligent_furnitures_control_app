interface ThemeColorsType {
  primary: string;
  primaryLight: string;
  primaryDark: string;

  secondary: string;
  accent: string;

  bgPrimary: string;
  bgCard: string;
  bgGlass: string;

  textPrimary: string;
  textSecondary: string;
  textTertiary: string;

  success: string;
  warning: string;
  danger: string;

  techBlue: string;
  techGlow: string;

  // 视觉增强
  primaryGradient: string;
  cardGlass: string;
  dangerGradient: string;

  // 科技感边框与阴影（深绿色系）
  borderLight: string;
  borderDark: string;
  shadowDark: string;
}

export const ThemeColors: ThemeColorsType = {
  // 农业绿 - 深色占比高：深墨绿作为重点色
  primary: '#0D3328',        // 深森林绿：主要深色文字、图标
  primaryLight: '#D8F3DC',   // 浅薄荷绿：次级背景、按钮背景
  primaryDark: '#081C15',    // 极深绿黑：最强强调、标题

  // 辅助色：科技青绿（农业+科技结合）
  secondary: '#1B4332',      // 森林绿：次级强调
  accent: '#00F5A0',         // 霓虹青绿：科技感高亮、脉冲效果

  // 背景：白天模式，浅绿灰色调
  bgPrimary: '#F0F7F4',      // 极浅薄荷灰：主背景（白天模式）
  bgCard: '#FFFFFF',         // 纯白卡片
  bgGlass: 'rgba(255, 255, 255, 0.92)', // 玻璃拟态背景

  // 文字：深绿占比极高，确保可读性
  textPrimary: '#0D3328',    // 深墨绿：主要文字（深色占比重点）
  textSecondary: '#2D6A4F',  // 中森林绿：次级文字
  textTertiary: '#74C69D',   // 淡绿灰：辅助文字

  // 状态色：科技感调整
  success: '#2DDB8D',        // 科技绿：成功状态
  warning: '#FFB703',        // 科技橙：警告
  danger: '#E63946',         // 科技红：危险

  // 科技特效：霓虹绿光（农业科技感）
  techBlue: '#00B4D8',       // 科技青蓝（辅助）
  techGlow: 'rgba(0, 245, 160, 0.45)', // 霓虹绿光晕（农业科技感）

  // 渐变与玻璃
  primaryGradient: 'linear-gradient(135deg, #0D3328 0%, #1B4332 50%, #2D6A4F 100%)', // 深绿渐变
  cardGlass: 'rgba(255, 255, 255, 0.88)', // 玻璃卡片底色
  dangerGradient: 'linear-gradient(135deg, #D62828 0%, #E63946 100%)',

  // 边框与阴影：深绿色系增强轮廓
  borderLight: '#B7E4C7',    // 淡薄荷边框：细微分隔
  borderDark: '#40916C',     // 深绿边框：强调轮廓
  shadowDark: 'rgba(13, 51, 40, 0.18)' // 深墨绿阴影（深色占比重点）
};
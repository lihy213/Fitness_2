import { ExerciseGuide } from '../model/WorkoutModels';

const SPORT_GUIDE = 'https://www.sport.gov.cn/n4/n24581921/index.html';
const RUNNING_GUIDE = 'https://www.sport.gov.cn/n4/n24581921/n24581923/n24581897/n24588458/index.html';
const KNEE_GUIDE = 'https://www.sport.gov.cn/n4/n24581921/n24581943/n25022317/index.html';

export const EXERCISE_GUIDES: ExerciseGuide[] = [
  new ExerciseGuide('squat', '深蹲', '臀腿 / 核心', '杠铃或自重', '进阶',
    ['双脚稳定踩地，膝盖方向与脚尖一致', '保持脊柱中立，下蹲深度服从可控活动度', '起身时同时伸展髋与膝，不要塌腰'], '国家体育总局科学健身指导', SPORT_GUIDE),
  new ExerciseGuide('chest-press', '卧推 / 胸推', '胸 / 肩 / 手臂', '杠铃、哑铃或器械', '入门',
    ['肩胛骨向后下方稳定，脚掌踩稳', '下放过程保持手腕位于肘上方', '不要用弹震借力，保留可控余量'], '国家体育总局科学健身指导', SPORT_GUIDE),
  new ExerciseGuide('deadlift', '硬拉', '臀腿后侧 / 背部', '杠铃或哑铃', '进阶',
    ['髋部向后折叠，负重贴近身体', '收紧躯干并保持脊柱中立', '站起靠髋膝伸展，避免过度后仰'], '国家体育总局科学健身指导', SPORT_GUIDE),
  new ExerciseGuide('row', '划船', '背部 / 手臂', '哑铃、杠铃或器械', '入门',
    ['先稳定躯干，再将肘向后拉', '避免耸肩，顶端轻收肩胛', '全程控制离心，不用腰部甩动'], '国家体育总局科学健身指导', SPORT_GUIDE),
  new ExerciseGuide('overhead-press', '肩上推举', '肩 / 手臂 / 核心', '哑铃或杠铃', '中级',
    ['肋骨保持下沉，避免腰椎过伸', '前臂尽量垂直，负重路径靠近身体', '无痛范围内完成动作'], '国家体育总局科学健身指导', SPORT_GUIDE),
  new ExerciseGuide('push-up', '俯卧撑', '胸 / 肩 / 手臂', '自重', '入门',
    ['头、躯干和腿保持一条直线', '双手稳定，肘部不过度外展', '胸部靠近地面后稳定推起'], '国家体育总局科学健身指导', SPORT_GUIDE),
  new ExerciseGuide('lunge', '箭步蹲', '臀腿', '自重或哑铃', '中级',
    ['前脚全脚掌受力，膝盖跟随脚尖', '躯干稳定，后膝垂直下降', '先用自重掌握平衡再增加负重'], '国家体育总局科学健身指导', SPORT_GUIDE),
  new ExerciseGuide('plank', '平板支撑', '核心 / 肩', '自重', '入门',
    ['肘位于肩下，前臂稳定压地', '收紧臀腹，避免腰部下沉', '保持自然呼吸，动作质量优先于时长'], '国家体育总局科学健身指导', SPORT_GUIDE),
  new ExerciseGuide('running', '跑步', '心肺 / 下肢', '户外或跑步机', '入门',
    ['先用走跑结合建立耐受', '保持自然步幅和可对话强度', '疼痛或明显不适时停止训练'], '国家体育总局跑步课堂', RUNNING_GUIDE),
  new ExerciseGuide('cycling', '骑行', '心肺 / 下肢', '自行车或功率车', '入门',
    ['调整座高，避免膝关节过度屈曲', '初期使用轻阻力与稳定踏频', '户外骑行务必佩戴头盔并遵守交通规则'], '国家体育总局科学健身指导', SPORT_GUIDE),
  new ExerciseGuide('full-body-stretch', '全身拉伸', '全身 / 放松', '瑜伽垫', '入门',
    ['先热身再进入静态拉伸', '保持均匀呼吸，不追求疼痛幅度', '每个姿势在可控范围内停留'], '国家体育总局科学健身视频', SPORT_GUIDE),
  new ExerciseGuide('knee-rehab', '膝关节基础功能训练', '膝 / 臀腿', '弹力带或自重', '康复提示',
    ['康复训练应依据专业评估选择动作', '从无痛范围和低负荷开始', '出现肿胀、卡锁或锐痛时停止并就医'], '国家体育总局膝关节运动处方', KNEE_GUIDE)
];

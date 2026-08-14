import { ExerciseGuide } from '../model/WorkoutModels';

const ACE_LIBRARY = 'https://www.acefitness.org/resources/everyone/exercise-library/';

export const EXERCISE_GUIDES: ExerciseGuide[] = [
  new ExerciseGuide('squat', '深蹲', '臀腿 / 核心', '杠铃或自重', '进阶',
    ['双脚稳定踩地，膝盖方向与脚尖一致', '保持脊柱中立，下蹲深度服从可控活动度', '起身时同时伸展髋与膝，不要塌腰'], 'ACE Exercise Library', ACE_LIBRARY),
  new ExerciseGuide('chest-press', '卧推 / 胸推', '胸 / 肩 / 手臂', '杠铃、哑铃或器械', '入门',
    ['肩胛骨向后下方稳定，脚掌踩稳', '下放过程保持手腕位于肘上方', '不要用弹震借力，保留可控余量'], 'ACE Exercise Library', ACE_LIBRARY),
  new ExerciseGuide('deadlift', '硬拉', '臀腿后侧 / 背部', '杠铃或哑铃', '进阶',
    ['髋部向后折叠，负重贴近身体', '收紧躯干并保持脊柱中立', '站起靠髋膝伸展，避免过度后仰'], 'ACE Exercise Library', ACE_LIBRARY),
  new ExerciseGuide('row', '划船', '背部 / 手臂', '哑铃、杠铃或器械', '入门',
    ['先稳定躯干，再将肘向后拉', '避免耸肩，顶端轻收肩胛', '全程控制离心，不用腰部甩动'], 'ACE Exercise Library', ACE_LIBRARY),
  new ExerciseGuide('overhead-press', '肩上推举', '肩 / 手臂 / 核心', '哑铃或杠铃', '中级',
    ['肋骨保持下沉，避免腰椎过伸', '前臂尽量垂直，负重路径靠近身体', '无痛范围内完成动作'], 'ACE Exercise Library', ACE_LIBRARY),
  new ExerciseGuide('push-up', '俯卧撑', '胸 / 肩 / 手臂', '自重', '入门',
    ['头、躯干和腿保持一条直线', '双手稳定，肘部不过度外展', '胸部靠近地面后稳定推起'], 'ACE Exercise Library', ACE_LIBRARY),
  new ExerciseGuide('lunge', '箭步蹲', '臀腿', '自重或哑铃', '中级',
    ['前脚全脚掌受力，膝盖跟随脚尖', '躯干稳定，后膝垂直下降', '先用自重掌握平衡再增加负重'], 'ACE Exercise Library', ACE_LIBRARY),
  new ExerciseGuide('plank', '平板支撑', '核心 / 肩', '自重', '入门',
    ['肘位于肩下，前臂稳定压地', '收紧臀腹，避免腰部下沉', '保持自然呼吸，动作质量优先于时长'], 'ACE Exercise Library', ACE_LIBRARY)
];


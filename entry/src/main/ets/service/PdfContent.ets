import { ExerciseEntry, WorkoutRecord, WorkoutSet } from '../model/WorkoutModels';

export function buildPdfRecordLines(records: WorkoutRecord[]): string[] {
  const lines: string[] = ['练刻 LIANKE · 健身记录'];
  if (records.length === 0) {
    lines.push('暂无训练记录');
    return lines;
  }
  records.forEach((record: WorkoutRecord) => {
    lines.push(`${record.date}  体重: ${record.bodyWeightKg > 0 ? `${record.bodyWeightKg} kg` : '未记录'}`);
    record.exercises.forEach((exercise: ExerciseEntry) => {
      const duration = exercise.durationMinutes > 0 ? ` / ${exercise.durationMinutes} 分钟` : '';
      lines.push(`  ${exercise.name}${exercise.bodyPart ? ` · ${exercise.bodyPart}` : ''} · ` +
        `${exercise.setDetails.length} 组${duration}`);
      exercise.setDetails.forEach((set: WorkoutSet, index: number) => {
        lines.push(`    第 ${index + 1} 组  ${set.reps} 次 × ${set.weightKg} kg`);
      });
      const metrics = `RPE ${exercise.rpe || '-'} / RIR ${exercise.rir || '-'} / 休息 ${exercise.restSeconds || '-'} 秒`;
      lines.push(`    ${metrics}`);
      if (exercise.tempo || exercise.distanceKm || exercise.caloriesKcal || exercise.averageHeartRate) {
        lines.push(`    节奏 ${exercise.tempo || '-'} / 距离 ${exercise.distanceKm || '-'} km / ` +
          `热量 ${exercise.caloriesKcal || '-'} kcal / 心率 ${exercise.averageHeartRate || '-'} bpm`);
      }
    });
    if (record.feeling.length > 0) {
      lines.push(`  感受: ${record.feeling}`);
    }
    if (record.mediaUris.length > 0) {
      lines.push(`  媒体附件: ${record.mediaUris.length} 个`);
    }
  });
  return lines;
}
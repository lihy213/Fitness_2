import { describe, expect, it } from '@ohos/hypium';
import { ExerciseEntry, WorkoutRecord, WorkoutSet } from '../main/ets/model/WorkoutModels';
import { buildPdfRecordLines } from '../main/ets/service/PdfContent';

export default function pdfContentTest(): void {
  describe('PdfContent', () => {
    it('includesSetsRepsAndWeight', 0, () => {
      const record = new WorkoutRecord('record-1', '2026-08-28');
      const exercise = new ExerciseEntry('exercise-1', '卧推');
      exercise.bodyPart = '胸部';
      exercise.setDetails = [new WorkoutSet('set-1', 8, 60), new WorkoutSet('set-2', 6, 65)];
      record.exercises = [exercise];
      const text = buildPdfRecordLines([record]).join('\n');
      expect(text.includes('卧推 · 胸部 · 2 组')).assertTrue();
      expect(text.includes('第 1 组  8 次 × 60 kg')).assertTrue();
      expect(text.includes('第 2 组  6 次 × 65 kg')).assertTrue();
    });
  });
}
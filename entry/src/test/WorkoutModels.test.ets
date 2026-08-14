import { describe, expect, it } from '@ohos/hypium';
import { ExerciseEntry, dateKey } from '../main/ets/model/WorkoutModels';

export default function workoutModelsTest(): void {
  describe('WorkoutModels', () => {
    it('formatsDateKey', 0, () => {
      expect(dateKey(new Date(2026, 7, 4))).assertEqual('2026-08-04');
    });

    it('createsThreeIndependentSets', 0, () => {
      const exercise = new ExerciseEntry('squat', '深蹲');
      exercise.setDetails[0].reps = 8;
      expect(exercise.setDetails.length).assertEqual(3);
      expect(exercise.setDetails[1].reps).assertEqual(10);
    });
  });
}

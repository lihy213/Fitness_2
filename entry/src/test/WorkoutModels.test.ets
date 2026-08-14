import { describe, expect, it } from '@ohos/hypium';
import { dateKey } from '../main/ets/model/WorkoutModels';

export default function workoutModelsTest(): void {
  describe('WorkoutModels', () => {
    it('formatsDateKey', 0, () => {
      expect(dateKey(new Date(2026, 7, 4))).assertEqual('2026-08-04');
    });
  });
}


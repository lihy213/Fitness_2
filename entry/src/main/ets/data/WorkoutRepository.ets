import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { ExerciseEntry, UserProfile, WorkoutRecord, WorkoutSet, newId } from '../model/WorkoutModels';

const STORE_NAME = 'fitness_records';
const RECORDS_KEY = 'workout_records_v1';
const PROFILE_KEY = 'user_profile_v1';

function normalizeExercise(value: ExerciseEntry): ExerciseEntry {
  const exercise = new ExerciseEntry(value.id || newId('exercise'), value.name || '');
  exercise.bodyPart = value.bodyPart || '';
  exercise.durationMinutes = value.durationMinutes || 0;
  exercise.rpe = value.rpe || 0;
  exercise.rir = value.rir || 0;
  exercise.restSeconds = value.restSeconds || 0;
  exercise.tempo = value.tempo || '';
  exercise.distanceKm = value.distanceKm || 0;
  exercise.caloriesKcal = value.caloriesKcal || 0;
  exercise.averageHeartRate = value.averageHeartRate || 0;
  if (value.setDetails && value.setDetails.length > 0) {
    exercise.setDetails = value.setDetails.map((set: WorkoutSet) =>
      new WorkoutSet(set.id || newId('set'), set.reps || 0, set.weightKg || 0));
  } else {
    const count = value.sets > 0 ? value.sets : 1;
    exercise.setDetails = [];
    for (let index = 0; index < count; index++) {
      exercise.setDetails.push(new WorkoutSet(newId('set'), value.reps || 0, value.weightKg || 0));
    }
  }
  exercise.sets = exercise.setDetails.length;
  exercise.reps = exercise.setDetails.length > 0 ? exercise.setDetails[0].reps : 0;
  exercise.weightKg = exercise.setDetails.length > 0 ? exercise.setDetails[0].weightKg : 0;
  return exercise;
}

export class WorkoutRepository {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async loadAll(): Promise<WorkoutRecord[]> {
    const store = await preferences.getPreferences(this.context, { name: STORE_NAME });
    const raw = await store.get(RECORDS_KEY, '[]');
    if (typeof raw !== 'string' || raw.length === 0) {
      return [];
    }
    try {
      const records = JSON.parse(raw) as WorkoutRecord[];
      records.forEach((record: WorkoutRecord) => {
        record.exercises = (record.exercises || []).map((exercise: ExerciseEntry) => normalizeExercise(exercise));
        record.mediaUris = record.mediaUris || [];
        record.feeling = record.feeling || '';
      });
      return records;
    } catch (error) {
      console.error(`Unable to parse workout records: ${JSON.stringify(error)}`);
      return [];
    }
  }

  async save(record: WorkoutRecord): Promise<WorkoutRecord[]> {
    const records = await this.loadAll();
    const index = records.findIndex((item: WorkoutRecord) => item.date === record.date);
    record.updatedAt = Date.now();
    if (index >= 0) {
      records[index] = record;
    } else {
      records.push(record);
    }
    records.sort((left: WorkoutRecord, right: WorkoutRecord) => right.date.localeCompare(left.date));
    await this.writeAll(records);
    return records;
  }

  async removeByDate(date: string): Promise<WorkoutRecord[]> {
    const records = (await this.loadAll()).filter((item: WorkoutRecord) => item.date !== date);
    await this.writeAll(records);
    return records;
  }

  async loadProfile(): Promise<UserProfile> {
    const store = await preferences.getPreferences(this.context, { name: STORE_NAME });
    const raw = await store.get(PROFILE_KEY, '');
    if (typeof raw !== 'string' || raw.length === 0) {
      return new UserProfile();
    }
    try {
      const saved = JSON.parse(raw) as UserProfile;
      const profile = new UserProfile();
      profile.nickname = saved.nickname || profile.nickname;
      profile.avatarUri = saved.avatarUri || '';
      profile.heightCm = saved.heightCm || 0;
      profile.targetWeightKg = saved.targetWeightKg || 0;
      profile.trainingGoal = saved.trainingGoal || '';
      profile.unit = saved.unit === 'lb' ? 'lb' : 'kg';
      profile.hideWeightInShare = saved.hideWeightInShare !== false;
      profile.cloudSyncEnabled = saved.cloudSyncEnabled === true;
      return profile;
    } catch (error) {
      console.error(`Unable to parse user profile: ${JSON.stringify(error)}`);
      return new UserProfile();
    }
  }

  async saveProfile(profile: UserProfile): Promise<void> {
    const store = await preferences.getPreferences(this.context, { name: STORE_NAME });
    await store.put(PROFILE_KEY, JSON.stringify(profile));
    await store.flush();
  }

  private async writeAll(records: WorkoutRecord[]): Promise<void> {
    const store = await preferences.getPreferences(this.context, { name: STORE_NAME });
    await store.put(RECORDS_KEY, JSON.stringify(records));
    await store.flush();
  }
}

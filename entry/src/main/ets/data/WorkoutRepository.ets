import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { WorkoutRecord } from '../model/WorkoutModels';

const STORE_NAME = 'fitness_records';
const RECORDS_KEY = 'workout_records_v1';

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
      return JSON.parse(raw) as WorkoutRecord[];
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

  private async writeAll(records: WorkoutRecord[]): Promise<void> {
    const store = await preferences.getPreferences(this.context, { name: STORE_NAME });
    await store.put(RECORDS_KEY, JSON.stringify(records));
    await store.flush();
  }
}


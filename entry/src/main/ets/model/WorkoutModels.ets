export class WorkoutSet {
  id: string = '';
  reps: number = 10;
  weightKg: number = 0;

  constructor(id: string, reps: number = 10, weightKg: number = 0) {
    this.id = id;
    this.reps = reps;
    this.weightKg = weightKg;
  }
}

export class ExerciseEntry {
  id: string = '';
  name: string = '';
  bodyPart: string = '';
  sets: number = 3;
  reps: number = 10;
  weightKg: number = 0;
  durationMinutes: number = 0;
  setDetails: WorkoutSet[] = [];
  rpe: number = 0;
  rir: number = 0;
  restSeconds: number = 0;
  tempo: string = '';
  distanceKm: number = 0;
  caloriesKcal: number = 0;
  averageHeartRate: number = 0;

  constructor(id: string, name: string = '') {
    this.id = id;
    this.name = name;
    this.setDetails = [
      new WorkoutSet(newId('set')),
      new WorkoutSet(newId('set')),
      new WorkoutSet(newId('set'))
    ];
  }
}

export class WorkoutRecord {
  id: string = '';
  date: string = '';
  bodyWeightKg: number = 0;
  feeling: string = '';
  exercises: ExerciseEntry[] = [];
  mediaUris: string[] = [];
  updatedAt: number = 0;

  constructor(id: string, date: string) {
    this.id = id;
    this.date = date;
  }
}

export class ExerciseGuide {
  id: string = '';
  name: string = '';
  bodyPart: string = '';
  equipment: string = '';
  level: string = '';
  cues: string[] = [];
  sourceName: string = '';
  sourceUrl: string = '';

  constructor(id: string, name: string, bodyPart: string, equipment: string, level: string,
    cues: string[], sourceName: string, sourceUrl: string) {
    this.id = id;
    this.name = name;
    this.bodyPart = bodyPart;
    this.equipment = equipment;
    this.level = level;
    this.cues = cues;
    this.sourceName = sourceName;
    this.sourceUrl = sourceUrl;
  }
}

export class UserProfile {
  nickname: string = '健身爱好者';
  avatarUri: string = '';
  heightCm: number = 0;
  targetWeightKg: number = 0;
  trainingGoal: string = '';
  unit: string = 'kg';
  hideWeightInShare: boolean = true;
  cloudSyncEnabled: boolean = false;
}

export function dateKey(date: Date): string {
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  const day = `${date.getDate()}`.padStart(2, '0');
  return `${date.getFullYear()}-${month}-${day}`;
}

export function newId(prefix: string): string {
  return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 100000)}`;
}

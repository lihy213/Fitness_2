export class ExerciseEntry {
  id: string = '';
  name: string = '';
  sets: number = 3;
  reps: number = 10;
  weightKg: number = 0;
  durationMinutes: number = 0;

  constructor(id: string, name: string = '') {
    this.id = id;
    this.name = name;
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

export function dateKey(date: Date): string {
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  const day = `${date.getDate()}`.padStart(2, '0');
  return `${date.getFullYear()}-${month}-${day}`;
}

export function newId(prefix: string): string {
  return `${prefix}-${Date.now()}-${Math.floor(Math.random() * 100000)}`;
}


import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { systemShare } from '@kit.ShareKit';
import { WorkoutRepository } from '../data/WorkoutRepository';
import { EXERCISE_GUIDES } from '../data/ExerciseCatalog';
import { ExerciseEntry, ExerciseGuide, UserProfile, WorkoutRecord, WorkoutSet, dateKey, newId } from '../model/WorkoutModels';
import { ExportService } from '../service/ExportService';

const COLOR_TEXT = '#20242C';
const COLOR_MUTED = '#6F7683';
const COLOR_ACCENT = '#38A9FF';
const COLOR_BLUE = '#176BFF';
const COLOR_GLASS = '#D9FFFFFF';
const COLOR_INPUT = '#F2FFFFFF';
const COLOR_SELECTION = '#3338A9FF';

@Extend(TextInput)
function liankeInputStyle() {
  .fontColor(COLOR_TEXT)
  .placeholderColor(COLOR_MUTED)
  .caretColor(COLOR_BLUE)
  .selectedBackgroundColor(COLOR_SELECTION)
  .backgroundColor(COLOR_INPUT)
}

@Extend(TextArea)
function liankeTextAreaStyle() {
  .fontColor(COLOR_TEXT)
  .placeholderColor(COLOR_MUTED)
  .caretColor(COLOR_BLUE)
  .selectedBackgroundColor(COLOR_SELECTION)
  .backgroundColor(COLOR_INPUT)
}

@Component
struct GlassCard {
  @BuilderParam content: () => void;

  build() {
    Column() {
      this.content()
    }
    .width('100%')
    .padding(16)
    .backgroundColor(COLOR_GLASS)
    .backdropBlur(18)
    .borderRadius(22)
    .border({ width: 1, color: '#8FFFFFFF' })
    .shadow({ radius: 18, color: '#1A68758A', offsetY: 8 })
  }
}

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State records: WorkoutRecord[] = [];
  @State selectedDate: string = dateKey(new Date());
  @State displayYear: number = new Date().getFullYear();
  @State displayMonth: number = new Date().getMonth();
  @State bodyWeightText: string = '';
  @State feelingText: string = '';
  @State draftExercises: ExerciseEntry[] = [new ExerciseEntry(newId('exercise'))];
  @State draftMediaUris: string[] = [];
  @State guideQuery: string = '';
  @State profile: UserProfile = new UserProfile();
  @State heightText: string = '';
  @State targetWeightText: string = '';
  @State exportStartDate: string = '';
  @State exportEndDate: string = '';
  @State showSplash: boolean = true;
  private repository?: WorkoutRepository;
  private exporter?: ExportService;

  aboutToAppear(): void {
    const context = this.abilityContext();
    this.repository = new WorkoutRepository(context);
    this.exporter = new ExportService(context);
    this.reloadRecords();
    this.reloadProfile();
    setTimeout(() => this.showSplash = false, 1200);
  }

  private async reloadProfile(): Promise<void> {
    if (!this.repository) {
      return;
    }
    this.profile = await this.repository.loadProfile();
    this.heightText = this.profile.heightCm > 0 ? `${this.profile.heightCm}` : '';
    this.targetWeightText = this.profile.targetWeightKg > 0 ? `${this.profile.targetWeightKg}` : '';
  }

  private async saveProfile(): Promise<void> {
    if (!this.repository) {
      return;
    }
    this.profile.heightCm = Number(this.heightText) || 0;
    this.profile.targetWeightKg = Number(this.targetWeightText) || 0;
    await this.repository.saveProfile(this.profile);
    this.profile = this.profile;
    promptAction.showToast({ message: '个人设置已保存' });
  }

  private async reloadRecords(): Promise<void> {
    if (this.repository) {
      this.records = await this.repository.loadAll();
      this.loadDraftForDate(this.selectedDate);
    }
  }

  private recordForDate(date: string): WorkoutRecord | undefined {
    return this.records.find((record: WorkoutRecord) => record.date === date);
  }

  private loadDraftForDate(date: string): void {
    const record = this.recordForDate(date);
    if (record) {
      this.bodyWeightText = record.bodyWeightKg > 0 ? `${record.bodyWeightKg}` : '';
      this.feelingText = record.feeling;
      this.draftExercises = record.exercises.map((item: ExerciseEntry) => {
        const copy = new ExerciseEntry(item.id, item.name);
        copy.sets = item.sets;
        copy.reps = item.reps;
        copy.weightKg = item.weightKg;
        copy.durationMinutes = item.durationMinutes;
        copy.bodyPart = item.bodyPart;
        copy.setDetails = item.setDetails.map((set: WorkoutSet) => new WorkoutSet(set.id, set.reps, set.weightKg));
        copy.rpe = item.rpe;
        copy.rir = item.rir;
        copy.restSeconds = item.restSeconds;
        copy.tempo = item.tempo;
        copy.distanceKm = item.distanceKm;
        copy.caloriesKcal = item.caloriesKcal;
        copy.averageHeartRate = item.averageHeartRate;
        return copy;
      });
      this.draftMediaUris = record.mediaUris.slice();
    } else {
      this.bodyWeightText = '';
      this.feelingText = '';
      this.draftExercises = [new ExerciseEntry(newId('exercise'))];
      this.draftMediaUris = [];
    }
  }

  private selectDate(date: string): void {
    this.selectedDate = date;
    this.loadDraftForDate(date);
  }

  private updateExercise(index: number, field: string, value: string): void {
    const next = this.draftExercises.slice();
    const item = next[index];
    if (field === 'name') {
      item.name = value;
    } else if (field === 'bodyPart') {
      item.bodyPart = value;
    } else if (field === 'duration') {
      item.durationMinutes = Number(value) || 0;
    } else if (field === 'rpe') {
      item.rpe = Number(value) || 0;
    } else if (field === 'rir') {
      item.rir = Number(value) || 0;
    } else if (field === 'rest') {
      item.restSeconds = Number(value) || 0;
    } else if (field === 'tempo') {
      item.tempo = value;
    } else if (field === 'distance') {
      item.distanceKm = Number(value) || 0;
    } else if (field === 'calories') {
      item.caloriesKcal = Number(value) || 0;
    } else if (field === 'heartRate') {
      item.averageHeartRate = Number(value) || 0;
    }
    this.draftExercises = next;
  }

  private updateSet(exerciseIndex: number, setIndex: number, field: string, value: string): void {
    const next = this.draftExercises.slice();
    const set = next[exerciseIndex].setDetails[setIndex];
    if (field === 'reps') {
      set.reps = Number(value) || 0;
    } else {
      set.weightKg = Number(value) || 0;
    }
    next[exerciseIndex].sets = next[exerciseIndex].setDetails.length;
    this.draftExercises = next;
  }

  private addSet(exerciseIndex: number): void {
    const next = this.draftExercises.slice();
    next[exerciseIndex].setDetails.push(new WorkoutSet(newId('set')));
    next[exerciseIndex].sets = next[exerciseIndex].setDetails.length;
    this.draftExercises = next;
  }

  private removeSet(exerciseIndex: number, setIndex: number): void {
    const next = this.draftExercises.slice();
    const remaining = next[exerciseIndex].setDetails.filter((set: WorkoutSet, index: number) => index !== setIndex);
    next[exerciseIndex].setDetails = remaining.length > 0 ? remaining : [new WorkoutSet(newId('set'))];
    next[exerciseIndex].sets = next[exerciseIndex].setDetails.length;
    this.draftExercises = next;
  }

  private addExercise(): void {
    const next = this.draftExercises.slice();
    next.push(new ExerciseEntry(newId('exercise')));
    this.draftExercises = next;
  }

  private removeExercise(index: number): void {
    const next = this.draftExercises.filter((item: ExerciseEntry, itemIndex: number) => itemIndex !== index);
    this.draftExercises = next.length > 0 ? next : [new ExerciseEntry(newId('exercise'))];
  }

  private mediaPath(value: string): string {
    const separator = value.indexOf('|');
    return separator >= 0 ? value.substring(separator + 1) : value;
  }

  private mediaKind(value: string): string {
    return value.startsWith('video|') ? 'video' : 'image';
  }

  private async chooseMedia(kind: string): Promise<void> {
    try {
      const mediaPicker = new photoAccessHelper.PhotoViewPicker();
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = kind === 'video' ? photoAccessHelper.PhotoViewMIMETypes.VIDEO_TYPE :
        photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = kind === 'video' ? 2 : 6;
      const result = await mediaPicker.select(options);
      this.draftMediaUris = this.draftMediaUris.concat(
        result.photoUris.map((uri: string) => `${kind}|${uri}`));
    } catch (error) {
      console.info(`Media picker closed: ${JSON.stringify(error)}`);
    }
  }

  private removeMedia(index: number): void {
    this.draftMediaUris = this.draftMediaUris.filter((item: string, itemIndex: number) => itemIndex !== index);
  }

  private abilityContext(): common.UIAbilityContext {
    const context = this.getUIContext().getHostContext();
    if (!context) {
      throw new Error('无法获取应用上下文');
    }
    return context as common.UIAbilityContext;
  }

  private shareSummaryText(): string {
    const monthCount = this.monthRecords().length;
    if (this.records.length === 0) {
      return '我开始使用练刻 Fitness 记录训练。每一次训练，都值得被看见。';
    }
    const latest = this.records[0];
    const actionNames = latest.exercises.map((exercise: ExerciseEntry) => exercise.name).join('、');
    const bodyWeight = !this.profile.hideWeightInShare && latest.bodyWeightKg > 0 ? ` · 体重 ${latest.bodyWeightKg} kg` : '';
    return `练刻 LIANKE 训练摘要\n累计记录 ${this.records.length} 天，本月训练 ${monthCount} 次。\n` +
      `最近训练：${latest.date}${actionNames.length > 0 ? ` · ${actionNames}` : ''}${bodyWeight}\n练就人生。`;
  }

  private async shareSummary(): Promise<void> {
    try {
      const record: systemShare.SharedRecord = {
        utd: 'general.plain-text',
        content: this.shareSummaryText(),
        title: '练刻 LIANKE 训练摘要'
      };
      const data = new systemShare.SharedData(record);
      const controller = new systemShare.ShareController(data);
      const options: systemShare.ShareControllerOptions = {
        selectionMode: systemShare.SelectionMode.SINGLE
      };
      await controller.show(this.abilityContext(), options);
    } catch (error) {
      console.error(`Share failed: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: '未完成分享，请重试' });
    }
  }

  private async saveDraft(): Promise<void> {
    if (!this.repository) {
      return;
    }
    const exercises = this.draftExercises.filter((item: ExerciseEntry) => item.name.trim().length > 0);
    if (exercises.length === 0 && this.feelingText.trim().length === 0 && this.bodyWeightText.length === 0 &&
      this.draftMediaUris.length === 0) {
      promptAction.showToast({ message: '请至少填写一项训练内容、体重或感受' });
      return;
    }
    exercises.forEach((exercise: ExerciseEntry) => {
      exercise.sets = exercise.setDetails.length;
      exercise.reps = exercise.setDetails.length > 0 ? exercise.setDetails[0].reps : 0;
      exercise.weightKg = exercise.setDetails.length > 0 ? exercise.setDetails[0].weightKg : 0;
    });
    const existing = this.recordForDate(this.selectedDate);
    const record = new WorkoutRecord(existing ? existing.id : newId('workout'), this.selectedDate);
    record.bodyWeightKg = Number(this.bodyWeightText) || 0;
    record.feeling = this.feelingText.trim();
    record.exercises = exercises;
    record.mediaUris = this.draftMediaUris;
    this.records = await this.repository.save(record);
    promptAction.showToast({ message: '训练记录已保存' });
  }

  private async deleteSelectedRecord(): Promise<void> {
    if (!this.repository || !this.recordForDate(this.selectedDate)) {
      return;
    }
    this.records = await this.repository.removeByDate(this.selectedDate);
    this.loadDraftForDate(this.selectedDate);
    promptAction.showToast({ message: '记录已删除' });
  }

  private daysInDisplayedMonth(): number {
    return new Date(this.displayYear, this.displayMonth + 1, 0).getDate();
  }

  private firstWeekday(): number {
    const day = new Date(this.displayYear, this.displayMonth, 1).getDay();
    return day === 0 ? 6 : day - 1;
  }

  private calendarCells(): number[] {
    const cells: number[] = [];
    const offset = this.firstWeekday();
    for (let index = 0; index < 42; index++) {
      const day = index - offset + 1;
      cells.push(day > 0 && day <= this.daysInDisplayedMonth() ? day : 0);
    }
    return cells;
  }

  private heatmapDays(): number[] {
    const days: number[] = [];
    for (let day = 1; day <= this.daysInDisplayedMonth(); day++) {
      days.push(day);
    }
    return days;
  }

  private displayedDate(day: number): string {
    return dateKey(new Date(this.displayYear, this.displayMonth, day));
  }

  private monthRecords(): WorkoutRecord[] {
    const prefix = `${this.displayYear}-${`${this.displayMonth + 1}`.padStart(2, '0')}`;
    return this.records.filter((record: WorkoutRecord) => record.date.startsWith(prefix));
  }

  private changeMonth(delta: number): void {
    const next = new Date(this.displayYear, this.displayMonth + delta, 1);
    this.displayYear = next.getFullYear();
    this.displayMonth = next.getMonth();
  }

  private filteredGuides(): ExerciseGuide[] {
    const query = this.guideQuery.trim().toLowerCase();
    if (query.length === 0) {
      return EXERCISE_GUIDES;
    }
    return EXERCISE_GUIDES.filter((guide: ExerciseGuide) =>
      `${guide.name}${guide.bodyPart}${guide.equipment}`.toLowerCase().includes(query));
  }

  private updateProfile(field: string, value: string): void {
    const next = this.profile;
    if (field === 'nickname') {
      next.nickname = value;
    } else if (field === 'goal') {
      next.trainingGoal = value;
    }
    this.profile = next;
  }

  private toggleUnit(): void {
    const next = this.profile;
    next.unit = next.unit === 'kg' ? 'lb' : 'kg';
    this.profile = next;
  }

  private setHideWeight(value: boolean): void {
    const next = this.profile;
    next.hideWeightInShare = value;
    this.profile = next;
  }

  private async chooseAvatar(): Promise<void> {
    try {
      const mediaPicker = new photoAccessHelper.PhotoViewPicker();
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const result = await mediaPicker.select(options);
      if (result.photoUris.length > 0) {
        const next = this.profile;
        next.avatarUri = result.photoUris[0];
        this.profile = next;
      }
    } catch (error) {
      console.info(`Avatar picker closed: ${JSON.stringify(error)}`);
    }
  }

  @Builder
  private PageTitle(title: string, subtitle: string) {
    Column({ space: 5 }) {
      Text(title).fontSize(28).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT)
      Text(subtitle).fontSize(13).fontColor(COLOR_MUTED)
    }.alignItems(HorizontalAlign.Start).width('100%')
  }

  @Builder
  private HomePage() {
    Scroll() {
      Column({ space: 14 }) {
        this.PageTitle('练刻', '把每一次训练，留成看得见的进步')
        GlassCard() {
          Row() {
            Column({ space: 3 }) {
              Text(`${this.displayYear} 年 ${this.displayMonth + 1} 月`)
                .fontSize(20).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT)
              Text(`本月已训练 ${this.monthRecords().length} 次`).fontSize(13).fontColor(COLOR_MUTED)
            }.alignItems(HorizontalAlign.Start)
            Blank()
            Button('‹').type(ButtonType.Circle).backgroundColor('#40FFFFFF').fontColor(COLOR_TEXT)
              .onClick(() => this.changeMonth(-1))
            Button('›').type(ButtonType.Circle).backgroundColor('#40FFFFFF').fontColor(COLOR_TEXT)
              .onClick(() => this.changeMonth(1))
          }.width('100%')
          Row() {
            ForEach(['一', '二', '三', '四', '五', '六', '日'], (label: string) => {
              Text(label).width('14.28%').textAlign(TextAlign.Center).fontSize(12).fontColor(COLOR_MUTED)
            })
          }.margin({ top: 16, bottom: 8 })
          Grid() {
            ForEach(this.calendarCells(), (day: number) => {
              GridItem() {
                if (day > 0) {
                  Stack({ alignContent: Alignment.Bottom }) {
                    Text(`${day}`)
                      .fontSize(14)
                      .fontWeight(this.displayedDate(day) === this.selectedDate ? FontWeight.Bold : FontWeight.Normal)
                      .fontColor(this.displayedDate(day) === this.selectedDate ? '#FFFFFF' : COLOR_TEXT)
                      .width(38).height(38).textAlign(TextAlign.Center)
                      .backgroundColor(this.displayedDate(day) === this.selectedDate ? COLOR_BLUE : '#00FFFFFF')
                      .borderRadius(19)
                    if (this.recordForDate(this.displayedDate(day))) {
                      Circle({ width: 6, height: 6 }).fill(COLOR_ACCENT).margin({ bottom: 1 })
                    }
                  }.width('100%').height(44).onClick(() => this.selectDate(this.displayedDate(day)))
                }
              }
            })
          }.columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr').rowsGap(2).height(270)
        }
        GlassCard() {
          Text('本月打卡热力图').fontSize(17).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT).width('100%')
          Grid() {
            ForEach(this.heatmapDays(), (day: number) => {
                GridItem() {
                  Column({ space: 3 }) {
                    Text(`${day}`).fontSize(9)
                      .fontColor(this.recordForDate(this.displayedDate(day)) ? '#FFFFFF' : COLOR_MUTED)
                  }
                  .width(28).height(28).justifyContent(FlexAlign.Center)
                  .backgroundColor(this.recordForDate(this.displayedDate(day)) ? '#F47A8B' : '#18FFFFFF')
                  .borderRadius(7)
                }
              })
          }.columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr').rowsGap(6).columnsGap(6).margin({ top: 12 })
        }
        GlassCard() {
          Row() {
            Column({ space: 3 }) {
              Text(this.selectedDate).fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT)
              Text(this.recordForDate(this.selectedDate) ? '编辑当天训练' : '添加当天训练')
                .fontSize(12).fontColor(COLOR_MUTED)
            }.alignItems(HorizontalAlign.Start)
            Blank()
            if (this.recordForDate(this.selectedDate)) {
              Button('删除').type(ButtonType.Normal).fontSize(12).fontColor(COLOR_ACCENT)
                .backgroundColor('#18E94F64').onClick(() => this.deleteSelectedRecord())
            }
          }.width('100%')
          TextInput({ placeholder: '体重（kg）', text: this.bodyWeightText }).liankeInputStyle()
            .type(InputType.Number).margin({ top: 14 }).onChange((value: string) => this.bodyWeightText = value)
          TextArea({ placeholder: '今天状态如何？记录训练感受…', text: this.feelingText }).liankeTextAreaStyle()
            .height(88).margin({ top: 10 }).onChange((value: string) => this.feelingText = value)
          Text('训练动作').fontSize(15).fontWeight(FontWeight.Medium).fontColor(COLOR_TEXT)
            .width('100%').margin({ top: 16, bottom: 8 })
          ForEach(this.draftExercises, (exercise: ExerciseEntry, index: number) => {
            Column({ space: 9 }) {
              Row({ space: 8 }) {
                TextInput({ placeholder: '动作名称', text: exercise.name }).liankeInputStyle().layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'name', value))
                Button('×').type(ButtonType.Circle).fontColor(COLOR_ACCENT).backgroundColor('#18E94F64')
                  .onClick(() => this.removeExercise(index))
              }
              Row({ space: 7 }) {
                TextInput({ placeholder: '训练部位', text: exercise.bodyPart }).liankeInputStyle().layoutWeight(2)
                  .onChange((value: string) => this.updateExercise(index, 'bodyPart', value))
                TextInput({ placeholder: '分钟', text: `${exercise.durationMinutes}` }).liankeInputStyle().type(InputType.Number).layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'duration', value))
              }
              Text(`逐组记录 · ${exercise.setDetails.length} 组`).fontSize(12).fontColor(COLOR_MUTED).width('100%')
              ForEach(exercise.setDetails, (set: WorkoutSet, setIndex: number) => {
                Row({ space: 7 }) {
                  Text(`${setIndex + 1}`).fontSize(12).fontColor(COLOR_BLUE).width(22).textAlign(TextAlign.Center)
                  TextInput({ placeholder: '次数', text: `${set.reps}` }).liankeInputStyle().type(InputType.Number).layoutWeight(1)
                    .onChange((value: string) => this.updateSet(index, setIndex, 'reps', value))
                  TextInput({ placeholder: '重量 kg', text: `${set.weightKg}` }).liankeInputStyle().type(InputType.Number).layoutWeight(1)
                    .onChange((value: string) => this.updateSet(index, setIndex, 'weight', value))
                  Button('−').type(ButtonType.Circle).width(30).height(30).fontColor(COLOR_MUTED)
                    .backgroundColor('#18FFFFFF').onClick(() => this.removeSet(index, setIndex))
                }
              }, (set: WorkoutSet) => set.id)
              Button('+ 添加一组').type(ButtonType.Normal).fontSize(12).fontColor(COLOR_BLUE)
                .backgroundColor('#18176BFF').onClick(() => this.addSet(index))
              Row({ space: 7 }) {
                TextInput({ placeholder: 'RPE', text: `${exercise.rpe || ''}` }).liankeInputStyle().type(InputType.Number).layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'rpe', value))
                TextInput({ placeholder: 'RIR', text: `${exercise.rir || ''}` }).liankeInputStyle().type(InputType.Number).layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'rir', value))
                TextInput({ placeholder: '休息 秒', text: `${exercise.restSeconds || ''}` }).liankeInputStyle().type(InputType.Number).layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'rest', value))
                TextInput({ placeholder: '节奏 3-1-1', text: exercise.tempo }).liankeInputStyle().layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'tempo', value))
              }
              Row({ space: 7 }) {
                TextInput({ placeholder: '距离 km', text: `${exercise.distanceKm || ''}` }).liankeInputStyle().type(InputType.Number).layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'distance', value))
                TextInput({ placeholder: 'kcal', text: `${exercise.caloriesKcal || ''}` }).liankeInputStyle().type(InputType.Number).layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'calories', value))
                TextInput({ placeholder: '心率 bpm', text: `${exercise.averageHeartRate || ''}` }).liankeInputStyle().type(InputType.Number)
                  .layoutWeight(1).onChange((value: string) => this.updateExercise(index, 'heartRate', value))
              }
            }.padding(10).backgroundColor('#4DFFFFFF').borderRadius(14).margin({ bottom: 9 })
          }, (exercise: ExerciseEntry) => exercise.id)
          Row({ space: 10 }) {
            Button('+ 添加动作').layoutWeight(1).backgroundColor('#1F5876F3').fontColor(COLOR_BLUE)
              .onClick(() => this.addExercise())
            Button('+ 图片').layoutWeight(1).backgroundColor('#1F5876F3').fontColor(COLOR_BLUE)
              .onClick(() => this.chooseMedia('image'))
            Button('+ 视频').layoutWeight(1).backgroundColor('#1F5876F3').fontColor(COLOR_BLUE)
              .onClick(() => this.chooseMedia('video'))
          }.margin({ top: 4 })
          if (this.draftMediaUris.length > 0) {
            Text(`媒体附件 · ${this.draftMediaUris.length}`).fontSize(13).fontColor(COLOR_MUTED)
              .width('100%').margin({ top: 14, bottom: 8 })
            Grid() {
              ForEach(this.draftMediaUris, (media: string, index: number) => {
                GridItem() {
                  Stack({ alignContent: Alignment.TopEnd }) {
                    if (this.mediaKind(media) === 'image') {
                      Image(this.mediaPath(media)).width('100%').height(88).objectFit(ImageFit.Cover).borderRadius(12)
                    } else {
                      Column({ space: 5 }) {
                        Text('▶').fontSize(24).fontColor(COLOR_BLUE)
                        Text('训练视频').fontSize(11).fontColor(COLOR_MUTED)
                      }.width('100%').height(88).justifyContent(FlexAlign.Center)
                        .backgroundColor('#245876F3').borderRadius(12)
                    }
                    Button('×').type(ButtonType.Circle).width(26).height(26).fontSize(13)
                      .backgroundColor('#B820242C').fontColor('#FFFFFF').margin(5)
                      .onClick(() => this.removeMedia(index))
                  }
                }
              }, (media: string) => media)
            }.columnsTemplate('1fr 1fr 1fr').columnsGap(8).rowsGap(8)
          }
          Button('保存训练记录').width('100%').height(48).margin({ top: 14 })
            .backgroundColor(COLOR_TEXT).fontColor('#FFFFFF').onClick(() => this.saveDraft())
        }
      }.padding({ left: 16, right: 16, top: 18, bottom: 28 })
    }.scrollBar(BarState.Off).width('100%').height('100%')
  }

  @Builder
  private GuidePage() {
    Scroll() {
      Column({ space: 14 }) {
        this.PageTitle('健身指导', '先掌握动作，再逐步增加负重')
        TextInput({ placeholder: '搜索动作、部位或器械', text: this.guideQuery }).liankeInputStyle()
          .height(46).backgroundColor(COLOR_GLASS).backdropBlur(16).borderRadius(18)
          .onChange((value: string) => this.guideQuery = value)
        ForEach(this.filteredGuides(), (guide: ExerciseGuide) => {
          GlassCard() {
            Row() {
              Column({ space: 4 }) {
                Text(guide.name).fontSize(20).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT)
                Text(`${guide.bodyPart} · ${guide.equipment}`).fontSize(12).fontColor(COLOR_MUTED)
              }.alignItems(HorizontalAlign.Start)
              Blank()
              Text(guide.level).fontSize(11).fontColor(COLOR_BLUE).padding({ left: 10, right: 10, top: 5, bottom: 5 })
                .backgroundColor('#185876F3').borderRadius(12)
            }.width('100%')
            ForEach(guide.cues, (cue: string, index: number) => {
              Row({ space: 8 }) {
                Circle({ width: 5, height: 5 }).fill(COLOR_ACCENT)
                Text(cue).fontSize(13).fontColor(COLOR_TEXT).layoutWeight(1)
              }.margin({ top: index === 0 ? 14 : 8 })
            })
            Button(`查看 ${guide.sourceName} 教程`)
              .type(ButtonType.Normal).fontSize(12).fontColor(COLOR_BLUE).backgroundColor('#185876F3')
              .margin({ top: 14 })
              .onClick(() => this.abilityContext().openLink(guide.sourceUrl))
          }
        }, (guide: ExerciseGuide) => guide.id)
        Text('动作指导仅用于一般健身教育，疼痛、伤病或特殊健康状况请咨询专业人士。')
          .fontSize(11).fontColor(COLOR_MUTED).textAlign(TextAlign.Center).padding(12)
      }.padding({ left: 16, right: 16, top: 18, bottom: 28 })
    }.scrollBar(BarState.Off).width('100%').height('100%')
  }

  private async runExport(type: string): Promise<void> {
    if (!this.exporter) {
      return;
    }
    try {
      if (this.exportStartDate && this.exportEndDate && this.exportStartDate > this.exportEndDate) {
        promptAction.showToast({ message: '开始日期不能晚于结束日期' });
        return;
      }
      const selected = this.records.filter((record: WorkoutRecord) =>
        (!this.exportStartDate || record.date >= this.exportStartDate) &&
        (!this.exportEndDate || record.date <= this.exportEndDate));
      if (type === 'csv') {
        await this.exporter.exportCsv(selected);
      } else {
        await this.exporter.exportPdf(selected, this.exportStartDate, this.exportEndDate);
      }
      promptAction.showToast({ message: '导出成功' });
    } catch (error) {
      console.error(`Export failed: ${error}`);
      promptAction.showToast({ message: '未完成导出，请重试' });
    }
  }

  private parseExportDate(value: string): Date {
    if (!value) {
      return new Date();
    }
    const parts = value.split('-');
    return new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
  }

  private showExportDatePicker(target: string): void {
    const current = target === 'start' ? this.exportStartDate : this.exportEndDate;
    const earliest = target === 'end' && this.exportStartDate ? this.parseExportDate(this.exportStartDate) :
      new Date(2000, 0, 1);
    const latest = target === 'start' && this.exportEndDate ? this.parseExportDate(this.exportEndDate) : new Date();
    CalendarPickerDialog.show({
      selected: current ? this.parseExportDate(current) : new Date(),
      start: earliest,
      end: latest,
      onAccept: (value: Date) => {
        if (target === 'start') {
          this.exportStartDate = dateKey(value);
        } else {
          this.exportEndDate = dateKey(value);
        }
      }
    });
  }
  @Builder
  private ProfilePage() {
    Scroll() {
      Column({ space: 14 }) {
        this.PageTitle('个人档案', '本机优先，设置由你掌控')
        GlassCard() {
          Row({ space: 14 }) {
            Stack() {
              if (this.profile.avatarUri) {
                Image(this.profile.avatarUri).width(68).height(68).objectFit(ImageFit.Cover).borderRadius(34)
              } else {
                Circle({ width: 68, height: 68 }).fill('#24176BFF')
                Text('练').fontSize(25).fontWeight(FontWeight.Bold).fontColor(COLOR_BLUE)
              }
            }
            Column({ space: 5 }) {
              Text(this.profile.nickname || '健身爱好者').fontSize(20).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT)
              Text(`累计记录 ${this.records.length} 天`).fontSize(13).fontColor(COLOR_MUTED)
            }.alignItems(HorizontalAlign.Start)
            Blank()
            Button('头像').fontSize(12).backgroundColor('#18176BFF').fontColor(COLOR_BLUE)
              .onClick(() => this.chooseAvatar())
          }.width('100%')
          TextInput({ placeholder: '昵称', text: this.profile.nickname }).liankeInputStyle().margin({ top: 14 })
            .onChange((value: string) => this.updateProfile('nickname', value))
          Row({ space: 8 }) {
            TextInput({ placeholder: '身高 cm', text: this.heightText }).liankeInputStyle().type(InputType.Number).layoutWeight(1)
              .onChange((value: string) => this.heightText = value)
            TextInput({ placeholder: `目标体重 ${this.profile.unit}`, text: this.targetWeightText }).liankeInputStyle().type(InputType.Number)
              .layoutWeight(1).onChange((value: string) => this.targetWeightText = value)
          }.margin({ top: 8 })
          TextInput({ placeholder: '训练目标，例如增肌 / 减脂 / 体能', text: this.profile.trainingGoal }).liankeInputStyle()
            .margin({ top: 8 }).onChange((value: string) => this.updateProfile('goal', value))
          Row({ space: 10 }) {
            Button(`单位 ${this.profile.unit}`).layoutWeight(1).backgroundColor('#18176BFF').fontColor(COLOR_BLUE)
              .onClick(() => this.toggleUnit())
            Button('保存个人设置').layoutWeight(2).backgroundColor(COLOR_BLUE).fontColor('#FFFFFF')
              .onClick(() => this.saveProfile())
          }.margin({ top: 10 })
        }
        GlassCard() {
          Text('导出记录').fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT).width('100%')
          Text('点击开始和结束日期，从日历中选择报告范围；留空表示全部。').fontSize(12).fontColor(COLOR_MUTED)
            .width('100%').margin({ top: 5, bottom: 10 })
          Row({ space: 8 }) {
            Button(this.exportStartDate || '选择开始日期').layoutWeight(1).height(44)
              .fontColor(this.exportStartDate ? COLOR_TEXT : COLOR_MUTED).backgroundColor(COLOR_INPUT)
              .onClick(() => this.showExportDatePicker('start'))
            Button(this.exportEndDate || '选择结束日期').layoutWeight(1).height(44)
              .fontColor(this.exportEndDate ? COLOR_TEXT : COLOR_MUTED).backgroundColor(COLOR_INPUT)
              .onClick(() => this.showExportDatePicker('end'))
            Button('清除').height(44).fontColor(COLOR_BLUE).backgroundColor('#18176BFF')
              .onClick(() => {
                this.exportStartDate = '';
                this.exportEndDate = '';
              })
          }
          Row({ space: 10 }) {
            Button('导出 CSV').layoutWeight(1).backgroundColor('#1838A9FF').fontColor(COLOR_BLUE)
              .onClick(() => this.runExport('csv'))
            Button('导出 PDF').layoutWeight(1).backgroundColor('#18E94F64').fontColor(COLOR_ACCENT)
              .onClick(() => this.runExport('pdf'))
          }.margin({ top: 10 })
        }
        GlassCard() {
          Text('隐私与数据').fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT).width('100%')
          Text('训练数据保存在 App 私有空间；媒体仅保留系统相册引用，删除记录不会删除相册原文件。')
            .fontSize(13).fontColor(COLOR_MUTED).lineHeight(21).width('100%').margin({ top: 10 })
          Row() {
            Text('分享时隐藏体重').fontSize(13).fontColor(COLOR_TEXT)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.profile.hideWeightInShare })
              .selectedColor(COLOR_BLUE).onChange((value: boolean) => this.setHideWeight(value))
          }.width('100%').margin({ top: 12 })
        }
        GlassCard() {
          Text('账号与备份').fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT).width('100%')
          Text('华为账号登录、云同步、应用锁/生物识别和加密导出需要 AppGallery Connect 服务配置，当前保留接口，尚未启用。')
            .fontSize(13).fontColor(COLOR_MUTED).lineHeight(21).width('100%').margin({ top: 10 })
          Button('华为账号与云备份 · 待配置').width('100%').margin({ top: 12 })
            .enabled(false).backgroundColor('#16176BFF').fontColor(COLOR_MUTED)
        }
        GlassCard() {
          Text('分享').fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT).width('100%')
          Text(this.profile.hideWeightInShare ? '当前分享不包含体重、感受或媒体。' : '当前分享包含最近体重，不包含感受或媒体。')
            .fontSize(13).fontColor(COLOR_MUTED).lineHeight(21).width('100%').margin({ top: 10 })
          Button('分享训练摘要').width('100%').margin({ top: 14 })
            .backgroundColor('#1F5876F3').fontColor(COLOR_BLUE).onClick(() => this.shareSummary())
        }
        Text('练刻 LIANKE · 0.2.3').fontSize(11).fontColor(COLOR_MUTED).margin({ top: 6 })
      }.padding({ left: 16, right: 16, top: 18, bottom: 28 })
    }.scrollBar(BarState.Off).width('100%').height('100%')
  }

  @Builder
  private TabLabel(icon: string, label: string, index: number) {
    Column({ space: 3 }) {
      Text(icon).fontSize(20).fontColor(this.currentTab === index ? COLOR_BLUE : COLOR_MUTED)
      Text(label).fontSize(10).fontColor(this.currentTab === index ? COLOR_BLUE : COLOR_MUTED)
    }.width('100%').height(54).justifyContent(FlexAlign.Center)
  }

  build() {
    Stack() {
      Column().width('100%').height('100%')
        .linearGradient({ angle: 145, colors: [['#EAF6FF', 0], ['#F8FCFF', 0.5], ['#E3F1FF', 1]] })
      Circle({ width: 230, height: 230 }).fill('#30176BFF').blur(55).position({ x: -80, y: 70 })
      Circle({ width: 260, height: 260 }).fill('#2438A9FF').blur(62).position({ x: 230, y: 410 })
      Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
        TabContent() { this.HomePage() }.tabBar(this.TabLabel('◫', '主页', 0))
        TabContent() { this.GuidePage() }.tabBar(this.TabLabel('◇', '指导', 1))
        TabContent() { this.ProfilePage() }.tabBar(this.TabLabel('○', '个人', 2))
      }
      .barHeight(66)
      .barBackgroundColor('#E8FFFFFF')
      .barBackgroundBlurStyle(BlurStyle.Thick)
      .onChange((index: number) => this.currentTab = index)
      .width('100%').height('100%')
      if (this.showSplash) {
        Column({ space: 14 }) {
          Image($r('app.media.lianke_logo_mark_v2')).width(190).height(190).objectFit(ImageFit.Contain)
          Text('练刻').fontSize(38).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          Text('LIANKE').fontSize(14).letterSpacing(4).fontColor('#DCEBFF')
          Text('练就人生').fontSize(18).fontWeight(FontWeight.Medium).fontColor('#FFFFFF').margin({ top: 10 })
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
        .backgroundColor('#176BFF').zIndex(10)
      }
    }.width('100%').height('100%')
  }
}

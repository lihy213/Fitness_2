import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { systemShare } from '@kit.ShareKit';
import { WorkoutRepository } from '../data/WorkoutRepository';
import { EXERCISE_GUIDES } from '../data/ExerciseCatalog';
import { ExerciseEntry, ExerciseGuide, WorkoutRecord, dateKey, newId } from '../model/WorkoutModels';
import { ExportService } from '../service/ExportService';

const COLOR_TEXT = '#20242C';
const COLOR_MUTED = '#6F7683';
const COLOR_ACCENT = '#E94F64';
const COLOR_BLUE = '#5876F3';
const COLOR_GLASS = '#D9FFFFFF';

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
  private repository?: WorkoutRepository;
  private exporter?: ExportService;

  aboutToAppear(): void {
    const context = this.abilityContext();
    this.repository = new WorkoutRepository(context);
    this.exporter = new ExportService(context);
    this.reloadRecords();
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
    } else if (field === 'sets') {
      item.sets = Number(value) || 0;
    } else if (field === 'reps') {
      item.reps = Number(value) || 0;
    } else if (field === 'weight') {
      item.weightKg = Number(value) || 0;
    } else if (field === 'duration') {
      item.durationMinutes = Number(value) || 0;
    }
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
      const context = this.abilityContext();
      const mediaDirectory = `${context.filesDir}/workout-media`;
      fileIo.mkdirSync(mediaDirectory, true);
      const imported: string[] = [];
      result.photoUris.forEach((uri: string, index: number) => {
        const extension = kind === 'video' ? 'mp4' : 'jpg';
        const path = `${mediaDirectory}/${Date.now()}-${index}.${extension}`;
        fileIo.copyFileSync(uri, path, 0);
        imported.push(`${kind}|${path}`);
      });
      this.draftMediaUris = this.draftMediaUris.concat(imported);
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
    return `练刻 Fitness 训练摘要\n累计记录 ${this.records.length} 天，本月训练 ${monthCount} 次。\n` +
      `最近训练：${latest.date}${actionNames.length > 0 ? ` · ${actionNames}` : ''}`;
  }

  private async shareSummary(): Promise<void> {
    try {
      const record: systemShare.SharedRecord = {
        utd: 'general.plain-text',
        content: this.shareSummaryText(),
        title: '练刻 Fitness 训练摘要'
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
    if (exercises.length === 0 && this.feelingText.trim().length === 0 && this.bodyWeightText.length === 0) {
      promptAction.showToast({ message: '请至少填写一项训练内容、体重或感受' });
      return;
    }
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
          TextInput({ placeholder: '体重（kg）', text: this.bodyWeightText })
            .type(InputType.Number).margin({ top: 14 }).onChange((value: string) => this.bodyWeightText = value)
          TextArea({ placeholder: '今天状态如何？记录训练感受…', text: this.feelingText })
            .height(88).margin({ top: 10 }).onChange((value: string) => this.feelingText = value)
          Text('训练动作').fontSize(15).fontWeight(FontWeight.Medium).fontColor(COLOR_TEXT)
            .width('100%').margin({ top: 16, bottom: 8 })
          ForEach(this.draftExercises, (exercise: ExerciseEntry, index: number) => {
            Column({ space: 8 }) {
              Row({ space: 8 }) {
                TextInput({ placeholder: '动作名称', text: exercise.name }).layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'name', value))
                Button('×').type(ButtonType.Circle).fontColor(COLOR_ACCENT).backgroundColor('#18E94F64')
                  .onClick(() => this.removeExercise(index))
              }
              Row({ space: 7 }) {
                TextInput({ placeholder: '组', text: `${exercise.sets}` }).type(InputType.Number).layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'sets', value))
                TextInput({ placeholder: '次', text: `${exercise.reps}` }).type(InputType.Number).layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'reps', value))
                TextInput({ placeholder: 'kg', text: `${exercise.weightKg}` }).type(InputType.Number).layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'weight', value))
                TextInput({ placeholder: '分钟', text: `${exercise.durationMinutes}` }).type(InputType.Number).layoutWeight(1)
                  .onChange((value: string) => this.updateExercise(index, 'duration', value))
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
        TextInput({ placeholder: '搜索动作、部位或器械', text: this.guideQuery })
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
      if (type === 'excel') {
        await this.exporter.exportExcel(this.records);
      } else {
        await this.exporter.exportPdf(this.records);
      }
      promptAction.showToast({ message: '导出成功' });
    } catch (error) {
      console.error(`Export failed: ${JSON.stringify(error)}`);
      promptAction.showToast({ message: '未完成导出，请重试' });
    }
  }

  @Builder
  private ProfilePage() {
    Scroll() {
      Column({ space: 14 }) {
        this.PageTitle('个人', '你的训练数据，当前只保存在本机')
        GlassCard() {
          Row({ space: 14 }) {
            Stack() {
              Circle({ width: 64, height: 64 }).fill('#245876F3')
              Text('练').fontSize(24).fontWeight(FontWeight.Bold).fontColor(COLOR_BLUE)
            }
            Column({ space: 5 }) {
              Text('健身爱好者').fontSize(20).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT)
              Text(`累计记录 ${this.records.length} 天`).fontSize(13).fontColor(COLOR_MUTED)
            }.alignItems(HorizontalAlign.Start)
          }.width('100%')
        }
        GlassCard() {
          Text('导出记录').fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT).width('100%')
          Text('由系统文件选择器决定保存位置，不会自动上传。').fontSize(12).fontColor(COLOR_MUTED)
            .width('100%').margin({ top: 5, bottom: 14 })
          Row({ space: 10 }) {
            Button('导出 Excel').layoutWeight(1).backgroundColor('#1880B24A').fontColor('#4F8222')
              .onClick(() => this.runExport('excel'))
            Button('导出 PDF').layoutWeight(1).backgroundColor('#18E94F64').fontColor(COLOR_ACCENT)
              .onClick(() => this.runExport('pdf'))
          }
        }
        GlassCard() {
          Text('隐私与数据').fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT).width('100%')
          Text('训练记录和选中的媒体副本均保存在 App 私有空间，不会自动上传。卸载应用会清除本地数据；请定期导出备份。')
            .fontSize(13).fontColor(COLOR_MUTED).lineHeight(21).width('100%').margin({ top: 10 })
        }
        GlassCard() {
          Text('分享').fontSize(18).fontWeight(FontWeight.Bold).fontColor(COLOR_TEXT).width('100%')
          Text('默认只分享累计天数、本月次数和最近动作，不包含体重、感受或媒体。')
            .fontSize(13).fontColor(COLOR_MUTED).lineHeight(21).width('100%').margin({ top: 10 })
          Button('分享训练摘要').width('100%').margin({ top: 14 })
            .backgroundColor('#1F5876F3').fontColor(COLOR_BLUE).onClick(() => this.shareSummary())
        }
        Text('练刻 Fitness · 0.1.0').fontSize(11).fontColor(COLOR_MUTED).margin({ top: 6 })
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
        .linearGradient({ angle: 145, colors: [['#E9EEF8', 0], ['#F7EDEF', 0.5], ['#E7F2F0', 1]] })
      Circle({ width: 230, height: 230 }).fill('#305876F3').blur(55).position({ x: -80, y: 70 })
      Circle({ width: 260, height: 260 }).fill('#28E94F64').blur(62).position({ x: 230, y: 410 })
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
    }.width('100%').height('100%')
  }
}

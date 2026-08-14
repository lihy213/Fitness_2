import { Context } from '@kit.AbilityKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { pdfService } from '@kit.PDFKit';
import { ExerciseEntry, WorkoutRecord, WorkoutSet } from '../model/WorkoutModels';

function csvCell(value: string): string {
  return `"${value.replace(/"/g, '""')}"`;
}

function recordLines(records: WorkoutRecord[]): string[] {
  const lines: string[] = ['练刻 LIANKE · 健身记录'];
  if (records.length === 0) {
    lines.push('暂无训练记录');
    return lines;
  }
  records.forEach((record: WorkoutRecord) => {
    lines.push(`${record.date}  体重: ${record.bodyWeightKg > 0 ? `${record.bodyWeightKg} kg` : '未记录'}`);
    record.exercises.forEach((exercise: ExerciseEntry) => {
      const duration = exercise.durationMinutes > 0 ? ` / ${exercise.durationMinutes} 分钟` : '';
      lines.push(`  ${exercise.name}${exercise.bodyPart ? ` · ${exercise.bodyPart}` : ''}${duration}`);
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

export class ExportService {
  private context: Context;

  constructor(context: Context) {
    this.context = context;
  }

  async exportCsv(records: WorkoutRecord[]): Promise<string> {
    const header = ['日期', '动作', '训练部位', '第几组', '次数', '重量(kg)', '时长(分钟)', 'RPE', 'RIR',
      '休息(秒)', '节奏', '距离(km)', '卡路里(kcal)', '平均心率(bpm)', '体重(kg)', '训练感受', '媒体数'];
    const rows: string[] = [header.map((value: string) => csvCell(value)).join(',')];
    records.forEach((record: WorkoutRecord) => {
      const exercises = record.exercises.length > 0 ? record.exercises : [new ExerciseEntry('empty', '休息 / 未填写动作')];
      exercises.forEach((exercise: ExerciseEntry) => {
        const setDetails = exercise.setDetails.length > 0 ? exercise.setDetails : [new WorkoutSet('empty', 0, 0)];
        setDetails.forEach((set: WorkoutSet, index: number) => {
          const values = [record.date, exercise.name, exercise.bodyPart, `${index + 1}`, `${set.reps}`,
            `${set.weightKg}`, `${exercise.durationMinutes}`, `${exercise.rpe}`, `${exercise.rir}`,
            `${exercise.restSeconds}`, exercise.tempo, `${exercise.distanceKm}`, `${exercise.caloriesKcal}`,
            `${exercise.averageHeartRate}`, `${record.bodyWeightKg}`, record.feeling, `${record.mediaUris.length}`];
          rows.push(values.map((value: string) => csvCell(value)).join(','));
        });
      });
    });
    const uri = await this.chooseDestination('Lianke-Records.csv', 'CSV 表格|.csv');
    this.writeText(uri, `\uFEFF${rows.join('\r\n')}`);
    return uri;
  }

  async exportPdf(records: WorkoutRecord[], startDate: string, endDate: string): Promise<string> {
    const temporaryPath = `${this.context.tempDir}/Lianke-Records.pdf`;
    const document = new pdfService.PdfDocument();
    if (!document.createDocument(595, 842)) {
      throw new Error('无法创建 PDF 文档');
    }
    const font = new pdfService.FontInfo();
    font.fontName = 'HarmonyOS Sans SC';
    const normal = new pdfService.TextStyle();
    normal.fontInfo = font;
    normal.textSize = 11;
    normal.textColor = 0xFF20242C;
    const title = new pdfService.TextStyle();
    title.fontInfo = font;
    title.textSize = 18;
    title.textColor = 0xFF20242C;
    title.isBold = true;
    let page = document.getPage(0);
    page.addTextObject('练刻 LIANKE', 42, 735, title);
    page.addTextObject('练就人生 · TRAIN WITH INTENT', 42, 700, normal);
    page.addTextObject(`报告范围  ${startDate || '最早记录'} — ${endDate || '最新记录'}`, 42, 650, normal);
    page.addTextObject(`训练天数  ${records.length}`, 42, 620, title);
    page.addTextObject(`训练频率  ${'█'.repeat(Math.min(records.length, 20)) || '暂无记录'}`, 42, 575, normal);
    page.addTextObject('以下内容由本机训练记录生成，不会自动上传。', 42, 520, normal);
    page.release();
    page = document.insertBlankPage(document.getPageCount(), 595, 842);
    let y = 800;
    const lines = recordLines(records);
    lines.forEach((line: string, index: number) => {
      if (y < 45) {
        page.release();
        page = document.insertBlankPage(document.getPageCount(), 595, 842);
        y = 800;
      }
      page.addTextObject(line, 42, y, index === 0 ? title : normal);
      y -= index === 0 ? 34 : 20;
    });
    records.forEach((record: WorkoutRecord) => {
      record.mediaUris.forEach((media: string) => {
        if (!media.startsWith('image|')) {
          return;
        }
        if (y < 220) {
          page.release();
          page = document.insertBlankPage(document.getPageCount(), 595, 842);
          y = 800;
        }
        page.addImageObject(media.substring('image|'.length), 42, y - 160, 240, 150);
        y -= 175;
      });
    });
    page.release();
    if (!document.saveDocument(temporaryPath)) {
      document.releaseDocument();
      throw new Error('无法保存 PDF 文档');
    }
    document.releaseDocument();
    const uri = await this.chooseDestination('Lianke-Records.pdf', 'PDF 文档|.pdf');
    fileIo.copyFileSync(temporaryPath, uri, 0);
    fileIo.unlinkSync(temporaryPath);
    return uri;
  }

  private async chooseDestination(fileName: string, suffix: string): Promise<string> {
    const documentPicker = new picker.DocumentViewPicker(this.context);
    const options = new picker.DocumentSaveOptions();
    options.newFileNames = [fileName];
    options.fileSuffixChoices = [suffix];
    const result = await documentPicker.save(options);
    if (result.length === 0) {
      throw new Error('未选择保存位置');
    }
    return result[0];
  }

  private writeText(uri: string, content: string): void {
    const file = fileIo.openSync(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd, content);
    fileIo.closeSync(file);
  }
}

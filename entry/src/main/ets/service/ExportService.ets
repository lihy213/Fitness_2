import { Context } from '@kit.AbilityKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { pdfService } from '@kit.PDFKit';
import { ExerciseEntry, WorkoutRecord } from '../model/WorkoutModels';

function xmlEscape(value: string): string {
  return value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;').replace(/'/g, '&apos;');
}

function excelCell(value: string, type: string = 'String'): string {
  return `<Cell><Data ss:Type="${type}">${xmlEscape(value)}</Data></Cell>`;
}

function recordLines(records: WorkoutRecord[]): string[] {
  const lines: string[] = ['练刻 Fitness - 健身记录'];
  if (records.length === 0) {
    lines.push('暂无训练记录');
    return lines;
  }
  records.forEach((record: WorkoutRecord) => {
    lines.push(`${record.date}  体重: ${record.bodyWeightKg > 0 ? `${record.bodyWeightKg} kg` : '未记录'}`);
    record.exercises.forEach((exercise: ExerciseEntry) => {
      const duration = exercise.durationMinutes > 0 ? ` / ${exercise.durationMinutes} 分钟` : '';
      lines.push(`  ${exercise.name}: ${exercise.sets} 组 × ${exercise.reps} 次 × ${exercise.weightKg} kg${duration}`);
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

  async exportExcel(records: WorkoutRecord[]): Promise<string> {
    let rows = '<Row>' + excelCell('日期') + excelCell('动作') + excelCell('组数') + excelCell('次数') +
      excelCell('重量(kg)') + excelCell('时长(分钟)') + excelCell('体重(kg)') + excelCell('训练感受') +
      excelCell('媒体数') + '</Row>';
    records.forEach((record: WorkoutRecord) => {
      const exercises = record.exercises.length > 0 ? record.exercises : [new ExerciseEntry('empty', '休息 / 未填写动作')];
      exercises.forEach((exercise: ExerciseEntry) => {
        rows += '<Row>' + excelCell(record.date) + excelCell(exercise.name) + excelCell(`${exercise.sets}`, 'Number') +
          excelCell(`${exercise.reps}`, 'Number') + excelCell(`${exercise.weightKg}`, 'Number') +
          excelCell(`${exercise.durationMinutes}`, 'Number') + excelCell(`${record.bodyWeightKg}`, 'Number') +
          excelCell(record.feeling) + excelCell(`${record.mediaUris.length}`, 'Number') + '</Row>';
      });
    });
    const content = `<?xml version="1.0" encoding="UTF-8"?><?mso-application progid="Excel.Sheet"?>` +
      `<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" ` +
      `xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"><Worksheet ss:Name="健身记录"><Table>${rows}</Table>` +
      `</Worksheet></Workbook>`;
    const uri = await this.chooseDestination('Fitness-Records.xls', 'Excel 工作簿|.xls');
    this.writeText(uri, content);
    return uri;
  }

  async exportPdf(records: WorkoutRecord[]): Promise<string> {
    const temporaryPath = `${this.context.tempDir}/Fitness-Records.pdf`;
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
    page.release();
    if (!document.saveDocument(temporaryPath)) {
      document.releaseDocument();
      throw new Error('无法保存 PDF 文档');
    }
    document.releaseDocument();
    const uri = await this.chooseDestination('Fitness-Records.pdf', 'PDF 文档|.pdf');
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


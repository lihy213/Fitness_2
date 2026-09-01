import { Context } from '@kit.AbilityKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { pdfService } from '@kit.PDFKit';
import { ExerciseEntry, WorkoutRecord, WorkoutSet } from '../model/WorkoutModels';
import { buildPdfRecordLines } from './PdfContent';
import { fitPdfImageToBox, PdfImageLayout } from './PdfLayout';

function csvCell(value: string): string {
  return `"${value.replace(/"/g, '""')}"`;
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
    const temporaryPath = `${this.context.tempDir}/Lianke-Records-${Date.now()}.pdf`;
    const temporaryImages: string[] = [];
    const document = new pdfService.PdfDocument();
    let documentCreated = false;
    let documentReleased = false;
    let stage = 'createDocument';
    try {
      if (!document.createDocument(595, 842)) {
        throw new Error('无法创建 PDF 文档');
      }
      documentCreated = true;
      stage = 'configureFont';
      const font = new pdfService.FontInfo();
      font.fontName = 'HarmonyOS Sans SC';
      font.fontPath = '/system/fonts/HarmonyOS_Sans_SC.ttf';
      const normal = new pdfService.TextStyle();
      normal.fontInfo = font;
      normal.textSize = 11;
      normal.textColor = 0x2C2420;
      const title = new pdfService.TextStyle();
      title.fontInfo = font;
      title.textSize = 18;
      title.textColor = 0xFF6B17;
      title.isBold = true;
      stage = 'getCoverPage';
      let page = document.getPage(0);
      try {
        stage = 'drawCoverText';
        page.addTextObject('练刻 LIANKE', 42, 735, title);
        page.addTextObject('练就人生 · TRAIN WITH INTENT', 42, 700, normal);
        page.addTextObject(`报告范围  ${startDate || '最早记录'} — ${endDate || '最新记录'}`, 42, 650, normal);
        page.addTextObject(`训练天数  ${records.length}`, 42, 620, title);
        page.addTextObject(`训练频率  ${'█'.repeat(Math.min(records.length, 20)) || '暂无记录'}`, 42, 575, normal);
        page.addTextObject('以下内容由本机训练记录生成，不会自动上传。', 42, 520, normal);
        page.release();
        page = document.insertBlankPage(document.getPageCount(), 595, 842);
        let y = 800;
        stage = 'drawRecordText';
        const lines = buildPdfRecordLines(records);
        lines.forEach((line: string, index: number) => {
          if (y < 45) {
            page.release();
            page = document.insertBlankPage(document.getPageCount(), 595, 842);
            y = 800;
          }
          page.addTextObject(line, 42, y, index === 0 ? title : normal);
          y -= index === 0 ? 34 : 20;
        });
        stage = 'drawImages';
        let imageIndex = 0;
        for (let recordIndex = 0; recordIndex < records.length; recordIndex++) {
          const mediaUris = records[recordIndex].mediaUris;
          for (let mediaIndex = 0; mediaIndex < mediaUris.length; mediaIndex++) {
            const media = mediaUris[mediaIndex];
            if (!media.startsWith('image|')) {
              continue;
            }
            try {
              const imagePath = this.copyImageToTemp(media.substring('image|'.length), imageIndex++);
              temporaryImages.push(imagePath);
              const layout = await this.fitImageToBox(imagePath, 511, 320);
              if (y - layout.height < 45) {
                page.release();
                page = document.insertBlankPage(document.getPageCount(), 595, 842);
                y = 800;
              }
              const x = (595 - layout.width) / 2;
              page.addImageObject(imagePath, x, y - layout.height, layout.width, layout.height);
              y -= layout.height + 20;
            } catch (error) {
              console.warn(`PDF image skipped: ${JSON.stringify(error)}`);
            }
          }
        }
      } finally {
        page.release();
      }
      stage = 'saveTemporaryPdf';
      if (!document.saveDocument(temporaryPath)) {
        throw new Error('无法保存 PDF 文档');
      }
      document.releaseDocument();
      documentReleased = true;
      stage = 'chooseDestination';
      const uri = await this.chooseDestination('Lianke-Records.pdf', 'PDF 文档|.pdf');
      stage = 'copyToDestination';
      this.copyFileToDestination(temporaryPath, uri);
      return uri;
    } catch (error) {
      console.error(`PDF export failed at ${stage}: ${error}`);
      throw new Error(`PDF 导出失败（${stage}）：${error}`);
    } finally {
      if (documentCreated && !documentReleased) {
        document.releaseDocument();
      }
      temporaryImages.forEach((path: string) => this.removeTemporaryFile(path));
      this.removeTemporaryFile(temporaryPath);
    }
  }

  private async fitImageToBox(path: string, maxWidth: number, maxHeight: number): Promise<PdfImageLayout> {
    const source = image.createImageSource(path);
    try {
      const info = source.getImageInfoSync();
      if (info.size.width <= 0 || info.size.height <= 0) {
        throw new Error('无法读取图片尺寸');
      }
      return fitPdfImageToBox(info.size.width, info.size.height, maxWidth, maxHeight);
    } finally {
      await source.release();
    }
  }
  private copyImageToTemp(uri: string, index: number): string {
    const lower = uri.toLowerCase();
    const suffix = lower.includes('.png') ? 'png' : lower.includes('.webp') ? 'webp' : 'jpg';
    const destinationPath = `${this.context.tempDir}/Lianke-Pdf-Image-${Date.now()}-${index}.${suffix}`;
    const source = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    try {
      const destination = fileIo.openSync(destinationPath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      try {
        fileIo.copyFileSync(source.fd, destination.fd, 0);
      } finally {
        fileIo.closeSync(destination);
      }
    } finally {
      fileIo.closeSync(source);
    }
    return destinationPath;
  }

  private copyFileToDestination(sourcePath: string, destinationUri: string): void {
    const source = fileIo.openSync(sourcePath, fileIo.OpenMode.READ_ONLY);
    try {
      const destination = fileIo.openSync(destinationUri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
      try {
        fileIo.copyFileSync(source.fd, destination.fd, 0);
      } finally {
        fileIo.closeSync(destination);
      }
    } finally {
      fileIo.closeSync(source);
    }
  }

  private removeTemporaryFile(path: string): void {
    try {
      fileIo.unlinkSync(path);
    } catch (error) {
      console.info(`Temporary export file cleanup skipped: ${JSON.stringify(error)}`);
    }
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

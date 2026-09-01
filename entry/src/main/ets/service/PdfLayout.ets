export class PdfImageLayout {
  width: number;
  height: number;

  constructor(width: number, height: number) {
    this.width = width;
    this.height = height;
  }
}

export function fitPdfImageToBox(sourceWidth: number, sourceHeight: number,
  maxWidth: number, maxHeight: number): PdfImageLayout {
  if (sourceWidth <= 0 || sourceHeight <= 0 || maxWidth <= 0 || maxHeight <= 0) {
    throw new Error('图片尺寸必须大于零');
  }
  const scale = Math.min(maxWidth / sourceWidth, maxHeight / sourceHeight, 1);
  return new PdfImageLayout(sourceWidth * scale, sourceHeight * scale);
}

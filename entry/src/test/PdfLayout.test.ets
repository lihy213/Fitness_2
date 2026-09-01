import { describe, expect, it } from '@ohos/hypium';
import { fitPdfImageToBox } from '../main/ets/service/PdfLayout';

export default function pdfLayoutTest(): void {
  describe('PdfLayout', () => {
    it('fitsLandscapeWithoutChangingRatio', 0, () => {
      const layout = fitPdfImageToBox(1000, 500, 500, 300);
      expect(layout.width).assertEqual(500);
      expect(layout.height).assertEqual(250);
    });

    it('fitsPortraitWithoutChangingRatio', 0, () => {
      const layout = fitPdfImageToBox(500, 1000, 500, 300);
      expect(layout.width).assertEqual(150);
      expect(layout.height).assertEqual(300);
    });

    it('doesNotUpscaleSmallImages', 0, () => {
      const layout = fitPdfImageToBox(100, 50, 500, 300);
      expect(layout.width).assertEqual(100);
      expect(layout.height).assertEqual(50);
    });
  });
}

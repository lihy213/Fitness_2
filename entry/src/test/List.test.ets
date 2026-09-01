import workoutModelsTest from './WorkoutModels.test';
import pdfLayoutTest from './PdfLayout.test';
import pdfContentTest from './PdfContent.test';

export default function testsuite(): void {
  workoutModelsTest();
  pdfLayoutTest();
  pdfContentTest();
}

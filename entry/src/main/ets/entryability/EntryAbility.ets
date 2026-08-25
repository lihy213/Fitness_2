import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0xF17;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // The current visual system is light-only. Keep controls readable when the phone uses dark mode.
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    hilog.info(DOMAIN, 'Lianke', 'Application created');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.getMainWindowSync().setWindowSystemBarProperties({
      statusBarColor: '#EAF6FF',
      statusBarContentColor: '#20242C',
      navigationBarColor: '#F8FCFF',
      navigationBarContentColor: '#20242C'
    }).catch((error: Error) => {
      hilog.warn(DOMAIN, 'Lianke', 'Failed to apply light system bars: %{public}s', JSON.stringify(error));
    });
    windowStage.loadContent('pages/Index', (error) => {
      if (error.code) {
        hilog.error(DOMAIN, 'Lianke', 'Failed to load content: %{public}s', JSON.stringify(error));
      }
    });
  }
}

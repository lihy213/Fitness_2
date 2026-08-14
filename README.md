# 练刻 Fitness

面向 HarmonyOS 6.0 及以上的本地优先健身记录应用。首版使用 ArkTS + ArkUI 开发，支持训练日历、动作/组数/重量/时长记录、体重与训练感受、图片/视频附件、月度打卡热力图、动作指导，以及 Excel/PDF 导出。

## 当前功能

- 首页：月历、训练日期红点、月度次数、打卡热力图。
- 记录：按日期新增或编辑多个动作，记录组数、次数、重量和时长。
- 日记：记录体重、训练感受，并把从系统相册选择的图片或视频复制到应用私有目录。
- 健身指导：内置首批常用动作要点、器械、难度和权威教程入口。
- 个人：本地数据说明、隐私保护的训练摘要分享、Excel 与 PDF 导出。
- 数据：当前保存在应用沙箱的 Preferences 中，不上传服务器。

## 技术基线

- DevEco Studio 6.1.1 Beta1（本机环境）
- HarmonyOS SDK API 24 编译
- `compatibleSdkVersion: 20`，支持 HarmonyOS 6.0+
- Stage 模型、ArkTS、ArkUI

## 构建

1. 使用 DevEco Studio 打开仓库根目录。
2. 等待工程同步完成。
3. 在 DevEco Studio 中配置自动签名或个人调试签名。
4. 选择手机或模拟器，运行 `entry` 模块。

命令行构建（Windows，工具路径按实际安装目录调整）：

```powershell
& 'C:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat' --mode module -p product=default assembleHap
```

## 项目结构

```text
entry/src/main/ets/
├── data/                 # 本地仓储与动作库
├── entryability/         # 应用入口
├── model/                # 可迁移的数据模型
├── pages/                # 三页主界面
└── service/              # Excel/PDF 导出
```

产品方案、验收口径和待确认事项见 [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md) 与 [docs/PRODUCT_DECISIONS_NEEDED.md](docs/PRODUCT_DECISIONS_NEEDED.md)。

# 练刻 LIANKE

面向 HarmonyOS 6.0 及以上的本地优先健身记录应用。使用 ArkTS + ArkUI 开发，支持训练日历、逐组数据、训练指标、体重与感受、相册附件、月度热力图、中文动作指导、CSV/PDF 导出和本地个人档案。

## 当前功能

- 首页：月历、训练日期红点、月度次数、打卡热力图。
- 记录：按日期新增或编辑多个动作，每组分别记录次数和重量，并记录训练部位、时长、RPE/RIR、休息、节奏、距离、卡路里与心率。
- 日记：记录体重、训练感受，并引用系统相册中的图片或视频；删除记录不会删除相册原文件。
- 健身指导：覆盖器械、自重、跑步、骑行、拉伸与康复提示，并链接国家体育总局中文科普视频。
- 个人：本地编辑昵称、头像、身高、目标体重、训练目标和 kg/lb 单位；分享时可隐藏体重。
- 导出：按自定义日期范围导出 UTF-8 CSV，或导出含封面、训练频率摘要和图片的 PDF。
- 数据：当前保存在应用沙箱的 Preferences 中，不上传服务器。
- 品牌：明亮冰蓝玻璃拟态、原创“弯臂举哑铃”Logo、启动文案“练就人生”。

## 技术基线

- DevEco Studio 6.1.1 Beta1（本机环境）
- HarmonyOS SDK API 24 编译
- `compatibleSdkVersion: 20`，支持 HarmonyOS 6.0+
- Stage 模型、ArkTS、ArkUI

## 构建

1. 使用 DevEco Studio 打开仓库根目录。
2. 等待工程同步完成。
3. 选择 HarmonyOS 6.0+ 手机或模拟器，运行 `entry` 模块；仅构建无须签名，真机/发布按 DevEco 提示配置证书。

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
└── service/              # CSV/PDF 导出
```

当前 HAP 为未签名构建。华为账号登录、云同步、云备份、生物识别应用锁和加密导出已在界面与领域层预留，接入前仍需 AppGallery Connect 项目、服务开关和证书信息。

产品方案、验收口径和待确认事项见 [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md) 与 [docs/PRODUCT_DECISIONS_NEEDED.md](docs/PRODUCT_DECISIONS_NEEDED.md)。

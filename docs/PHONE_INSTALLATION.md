# nova 14 ultra 真机安装

模拟器阶段可以使用未签名 HAP；nova 14 ultra（HarmonyOS 6）真机安装需要调试签名。

## 首次连接

1. 在手机“设置 > 关于手机”连续点击版本号，开启开发者模式。
2. 在“开发者选项”开启 USB 调试。
3. USB 连接电脑后，在手机上确认 RSA/调试授权提示，并保持手机亮屏。
4. 在 DevEco Studio 的 `Project Structure > Signing` 为 `default` 产品完成调试签名。证书只保存在本机，不要提交到 Git。

## 安装与启动

项目根目录执行：

```powershell
.\scripts\install-phone.ps1
```

脚本会构建 HAP、检测 HDC 设备、安装并启动 `com.lihy213.fitness`。同时连接模拟器和手机时，先运行 `hdc list targets`，再指定手机序列号：

```powershell
.\scripts\install-phone.ps1 -Target <手机序列号>
```

如果提示未发现设备，重新确认 USB 调试授权；如果提示签名错误，回到 DevEco Studio 完成调试签名后重新构建。

# Wi-Fi 5G IOT APP 框架

一個為物聯網、Wi-Fi和5G設備管理設計的模組化Flutter應用框架。此框架提供統一的方法來建立可控制和監控各種類型智能設備的移動應用程式。

## 概述

此框架設計以模組化為核心，讓開發者能夠創建適用於不同產品線的應用程式，包括Wi-Fi設備、5G設備和IoT系統。架構遵循基於元件的方法，提供可在不同產品實現中共享的可重用模組。

### 主要特點

- **多產品支援**：支援Wi-Fi、5G和IoT產品線
- **模組化UI元件**：跨不同設備類型的可重用UI元素
- **一致的API整合**：統一的設備、雲端和第三方API連接方法
- **標準化的初始化和運行時流程**：設備設置和管理的通用模式
- **統一的設計風格**：簡潔灰色調，方形元素設計

## 目前實現功能

- **設備初始化流程**：完整的Wi-Fi設備設定嚮導
- **帳戶設定**：用戶名和密碼設定界面
- **連線類型選擇**：支持DHCP、Static IP和PPPoE
- **SSID設定**：Wi-Fi網絡名稱和安全選項配置
- **QR碼掃描**：支援透過QR碼快速添加設備
- **Wi-Fi掃描**：自動發現可用的Wi-Fi設備
- **多設備型號配置**：通過JSON文件支援不同設備型號

## 專案結構

框架組織為層次結構：

```
lib/
├── main.dart                            # 應用程式入口點
├── shared/
    ├── config/
    │   └── flows/
    │       └── initialization/
    │           └── wifi.json            # Wi-Fi 初始化流程配置
    └── ui/
        ├── components/
        │   └── basic/                   # 基礎UI組件
        │       ├── AccountPasswordComponent.dart  # 帳戶密碼設定組件
        │       ├── ConnectionTypeComponent.dart   # 連線類型選擇組件
        │       ├── SetSSIDComponent.dart         # SSID設定組件
        │       ├── StepperComponent.dart         # 步驟導航組件
        │       ├── SummaryComponent.dart         # 設定摘要組件
        │       ├── FinishingWizardComponent.dart # 完成嚮導組件
        │       └── WifiScannerComponent.dart     # Wi-Fi掃描組件
        └── pages/
            └── initialization/          # 初始化相關頁面
                ├── InitializationPage.dart        # 初始化主頁面
                ├── QrCodeScannerPage.dart         # QR碼掃描頁面
                ├── WifiConnectionPage.dart        # Wi-Fi連線頁面
                ├── WifiSettingFlowPage.dart       # Wi-Fi設定流程頁面
                └── LoginPage.dart                 # 登入頁面
```

## 開始使用

### 前置需求

- Flutter SDK (版本 3.7.2 或更高)
- Dart SDK (與Flutter版本兼容)
- Android Studio 或 Visual Studio Code 並安裝Flutter插件
- 以下套件：
   - wifi_scan: Wi-Fi網絡掃描
   - mobile_scanner: QR碼掃描
   - json序列化相關套件

### 安裝

1. 複製專案庫：
   ```bash
   git clone https://github.com/yourusername/wifi-5g-iot-app.git
   ```

2. 進入專案目錄：
   ```bash
   cd wifi-5g-iot-app
   ```

3. 安裝依賴：
   ```bash
   flutter pub get
   ```

4. 運行應用：
   ```bash
   flutter run
   ```

## 設計風格

此框架採用簡潔的灰色基調設計風格：

- **主色調**：白色和灰色
- **按鈕樣式**：方形，無圓角，灰色背景
- **元件佈局**：清晰的邊界和簡潔的元素間距
- **統一文字樣式**：標題 32px，副標題 22px，正文 16px

## 開發指南

### 使用標準元件

框架提供多種預先定義的UI元件，可無縫集成到您的應用中：

- **StepperComponent**：步驟導航元件，支援從JSON文件動態配置
- **WifiScannerComponent**：掃描並顯示Wi-Fi設備
- **各種表單元件**：AccountPassword、ConnectionType、SetSSID等

### 擴展流程

通過修改 `wifi.json` 配置文件，可以輕鬆擴展或修改設備初始化流程：

```json
{
  "models": {
    "A": {
      "steps": [
        {
          "id": 1,
          "name": "帳戶",
          "next": 2,
          "components": ["AccountPasswordComponent"]
        },
        // 添加更多步驟...
      ]
    }
  }
}
```

### 添加新的設備型號

1. 在 `wifi.json` 中添加新型號定義
2. 為該型號實現特定的組件和流程
3. 確保在設備選擇頁面中註冊新型號

## 待實現功能

1. **設備API整合**：實現與實際硬體的通信
2. **儀表板/設備狀態監控**：設備運行狀態顯示
3. **高級設定選項**：更多針對特定設備的設定
4. **設備管理功能**：添加和管理多設備
5. **多設備協同控制**：IoT設備間的聯動

## 貢獻

1. Fork 此專案
2. 創建您的功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交您的更改 (`git commit -m '添加一些功能'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 開啟Pull Request

## 文檔

完整文檔可在 `docs/` 目錄中找到：
- [專案結構與組件說明](./docs/01-app-structure.md)
- [UI 組件使用指南](./docs/02-ui-components-guide.md)
- [Wi-Fi 設定流程實作指南](./docs/03-wifi-setting-flow-guide.md)
- [UI 佈局風格指南](./docs/04-ui-components-design-guide.md)

## 許可證

本專案採用 Apache 許可證 2.0 版 - 詳見 LICENSE 文件。
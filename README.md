# Wi-Fi 5G IoT App 框架

一個模組化的 Flutter 應用框架，專為物聯網、Wi-Fi 和 5G 設備管理設計，支援多產品線的設備控制與監控。

## 概述

- **目標**：提供統一、可重用的框架，用於開發控制 Wi-Fi、5G 和 IoT 設備的移動應用。
- **設計理念**：模組化架構，支援跨產品線的 UI 和 API 整合。
- **核心特點**：
    - 多產品支援（Wi-Fi、5G、IoT）
    - 可重用模組化 UI 元件
    - 統一 API 整合（設備、雲端、第三方）
    - 標準化初始化與運行流程
    - 統一紫色漸層色調、現代化設計
    - 完整安全機制（初始密碼、API 認證）
    - 響應式設計，支援不同螢幕尺寸
    - 網絡拓撲圖視覺化顯示

## 目前實現功能

### 設備初始化與設定
- **設備初始化**：Wi-Fi 設備設定嚮導
- **帳戶設定**：用戶名與密碼設定，包含複雜度驗證
- **連線類型**：DHCP、Static IP、PPPoE 三種連線方式
- **SSID 配置**：Wi-Fi 網絡名稱與多種安全選項（WPA2/WPA3）
- **靜態 IP 設定**：IP 位址、子網路遮罩、閘道、DNS 設定
- **PPPoE 設定**：撥號上網帳號密碼設定

### 設備發現與連接
- **QR 碼掃描**：快速添加設備支援相機掃描
- **Wi-Fi 掃描**：自動發現可用設備，顯示信號強度
- **手動輸入**：支援手動輸入設備資訊
- **設備列表**：顯示已發現設備的詳細資訊

### 安全機制
- **初始密碼計算**：基於 SSID、序號、鹽值的 HMAC-SHA256 計算
- **SRP 安全登入**：零知識證明協議，支援安全遠程密碼認證
- **JWT 認證**：API 訪問授權機制
- **密碼變更**：支援使用 SRP 協議變更密碼
- **通訊加密**：HTTP 請求加密保護

### 使用者介面
- **響應式設計**：適應不同螢幕尺寸和方向
- **現代化主題**：紫色漸層設計風格
- **多步驟嚮導**：動態步驟導航系統
- **網絡拓撲圖**：視覺化顯示設備連接關係
- **即時速度監控**：網絡速度圖表顯示
- **進度顯示**：設定流程進度條與完成狀態

### 網絡管理
- **設備拓撲**：視覺化網絡拓撲圖，支援有線/無線連接顯示
- **多設備管理**：支援路由器、擴展器、終端設備管理
- **連接狀態監控**：即時顯示設備連接狀態
- **網絡效能監控**：即時速度圖表與統計資訊

## 專案結構

```
lib/
├── main.dart                            # 應用程式入口點
├── shared/
│   ├── api/                             # API 服務層
│   │   ├── wifi_api_service.dart        # Wi-Fi API 服務封裝
│   │   └── wifi_api/                    # Wi-Fi API 詳細實現
│   │       ├── login_process.dart       # 登入處理流程
│   │       ├── password_service.dart    # 密碼服務
│   │       ├── models/                  # API 模型
│   │       │   ├── session_info.dart   # 會話資訊模型
│   │       │   └── login_result.dart   # 登入結果模型
│   │       └── services/               # API 服務
│   │           ├── auth_service.dart   # 認證服務
│   │           ├── http_service.dart   # HTTP 服務
│   │           └── srp_service.dart    # SRP 認證服務
│   ├── connection/                      # 連接相關類
│   │   ├── abs_api_request.dart         # API 請求抽象類
│   │   ├── api_service.dart             # API 服務實現
│   │   ├── connection_utils.dart        # 連接工具類
│   │   ├── login_process.dart           # 登入流程
│   │   └── change_pwd_process.dart      # 密碼變更流程
│   ├── config/                          # 配置文件
│   │   ├── api/
│   │   │   └── wifi.json                # API 端點配置
│   │   ├── flows/
│   │   │   └── initialization/
│   │   │       └── wifi.json            # Wi-Fi 初始化流程配置
│   │   └── app_config.json              # 應用程式全域配置
│   ├── models/                          # 數據模型
│   │   └── StaticIpConfig.dart          # 靜態 IP 配置模型
│   ├── theme/                           # 主題設定
│   │   └── app_theme.dart               # 應用程式主題設定
│   ├── utils/                           # 工具類
│   │   ├── resource.dart                # 資源管理
│   │   ├── srp_helper.dart              # SRP 協議幫助類
│   │   ├── utility.dart                 # 通用工具
│   │   └── validators.dart              # 驗證工具
│   └── ui/
│       ├── components/                  # UI 組件
│       │   └── basic/                   # 基礎 UI 組件
│       │       ├── AccountPasswordComponent.dart     # 帳戶密碼設定組件
│       │       ├── ConnectionTypeComponent.dart      # 連線類型選擇組件
│       │       ├── FinishingWizardComponent.dart     # 完成嚮導組件
│       │       ├── SetSSIDComponent.dart             # SSID 設定組件
│       │       ├── StepperComponent.dart             # 步驟導航組件
│       │       ├── SummaryComponent.dart             # 設定摘要組件
│       │       ├── WifiScannerComponent.dart         # Wi-Fi 掃描組件
│       │       └── NetworkTopologyComponent.dart    # 網絡拓撲圖組件
│       └── pages/                       # 頁面
│           ├── initialization/          # 初始化相關頁面
│           │   ├── InitializationPage.dart         # 初始化主頁面
│           │   ├── LoginPage.dart                  # 登入頁面
│           │   ├── QrCodeScannerPage.dart          # QR 碼掃描頁面
│           │   ├── WifiConnectionPage.dart         # Wi-Fi 連線頁面
│           │   └── WifiSettingFlowPage.dart        # Wi-Fi 設定流程頁面
│           └── test/                    # 測試與範例頁面
│               ├── NetworkTopoView.dart            # 網絡拓撲視圖頁面
│               ├── SrpLoginModifiedTestPage.dart   # SRP 登入測試頁面
│               ├── SrpLoginTestPage.dart           # SRP 登入標準測試頁面
│               ├── TestPage.dart                   # 通用測試頁面
│               ├── TestPasswordPage.dart           # 密碼測試頁面
│               └── theme_test_page.dart            # 主題測試頁面
└── docs/                                # 技術文檔
    ├── 01-app-structure.md              # 專案結構與組件說明
    ├── 02-ui-components-guide.md        # UI 組件使用指南
    ├── 03-wifi-setting-flow-guide.md    # Wi-Fi 設定流程實作指南
    ├── 04-ui-components-design-guide.md # UI 佈局風格指南
    ├── 05-api-integration-guide.md      # API 整合指南
    ├── 06-security-implementation-guide.md # 安全機制實現指南
    └── README.md                        # 文檔索引
```

## 開始使用

### 前置需求

- Flutter SDK (≥3.7.2)
- Dart SDK (與 Flutter 兼容)
- Android Studio / VS Code + Flutter 插件

### 必要套件依賴

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 網絡相關
  http: ^1.1.0
  connectivity_plus: ^5.0.2
  network_info_plus: ^4.1.0
  wifi_scan: ^0.4.1
  wifi_iot: ^0.3.19
  
  # 掃描功能
  mobile_scanner: ^3.5.7
  
  # 安全與加密
  crypto: ^3.0.3
  srp: ^3.1.0
  hex: ^0.2.0
  convert: ^3.1.1
  
  # 資料持久化
  flutter_secure_storage: ^9.0.0
  
  # 同步控制
  synchronized: ^3.1.0
  
  # 設備資訊
  device_info_plus: ^9.1.1
  permission_handler: ^11.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### 安裝步驟

1. 複製專案：

    ```bash
    git clone https://github.com/yourusername/wifi-5g-iot-app.git
    ```

2. 進入目錄：

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

### 配置設定

#### 全域配置
修改 `lib/shared/config/app_config.json` 來調整應用程式行為：

```json
{
  "bypassAllRestrictions": false
}
```

#### API 端點配置
修改 `lib/shared/config/api/wifi.json` 設定 API 端點：

```json
{
  "baseUrl": "http://192.168.1.1",
  "apiVersion": "/api/v1",
  "timeoutSeconds": 10,
  "endpoints": {
    "systemInfo": {
      "path": "$apiVersion/system/info",
      "method": "get",
      "description": "獲取系統資訊"
    }
  }
}
```

## 設計風格

### 色彩系統
- **主色調**：紫色 (#9747FF) 和深藍色 (#162140)
- **背景色**：淺灰色 (#D9D9D9) 和卡片背景色 (#EEEEEE)
- **狀態色**：成功 (#4CAF50)、警告 (#FFC107)、錯誤 (#F44336)、資訊 (#2196F3)

### 設計元素
- **按鈕樣式**：方形或微圓角，帶紫色漸層背景
- **卡片設計**：毛玻璃效果，帶漸層邊框
- **元件佈局**：清晰的邊界和簡潔的元素間距
- **響應式設計**：支援不同螢幕尺寸自動調整

### 文字系統
- **標題**：28px (heading1)、24px (heading2)、20px (heading3)
- **內文**：16px (bodyLarge)、14px (bodyMedium)、12px (bodySmall)
- **按鈕文字**：16px 粗體
- **字體**：預設使用系統字體，支援多語言

### 漸層效果
- **主要漸層**：從深藍色 (#162140) 到紫色 (#9747FF)
- **卡片漸層**：透明度漸變，創造毛玻璃效果
- **按鈕漸層**：紫色系漸層，提供視覺層次

## 安全機制

### 初始密碼計算
```dart
// 基於設備資訊計算初始密碼
final password = await PasswordService.calculateInitialPassword(
  providedSSID: 'MyNetwork',
  serialNumber: 'ABC123456789',
  loginSalt: 'randomSaltValue',
);
```

### SRP 安全登入
```dart
// 使用 SRP 協議進行安全登入
final result = await WifiApiService.loginWithSRP(
  'admin',
  'calculatedPassword',
);
```

### JWT 認證
```dart
// 設定 JWT 令牌用於 API 存取
WifiApiService.setJwtToken(jwtToken);

// 使用認證的 API 呼叫
final data = await WifiApiService.getSystemInfo();
```

## 開發指南

### 使用標準元件

#### StepperComponent - 步驟導航
```dart
StepperComponent(
  configPath: 'lib/shared/config/flows/initialization/wifi.json',
  modelType: 'Micky',
  onStepChanged: (step) => print('Current step: $step'),
  controller: stepperController,
  isLastStepCompleted: false,
)
```

#### WifiScannerComponent - WiFi 掃描
```dart
WifiScannerComponent(
  maxDevicesToShow: 10,
  onScanComplete: (devices, error) {
    // 處理掃描結果
  },
  onDeviceSelected: (device) {
    // 處理設備選擇
  },
  autoScan: true,
)
```

#### NetworkTopologyComponent - 網絡拓撲圖
```dart
NetworkTopologyComponent(
  gatewayName: 'Router',
  devices: networkDevices,
  deviceConnections: connectionInfo,
  showInternet: true,
  onDeviceSelected: (device) {
    // 處理設備點擊
  },
)
```

### 擴展流程

#### 添加新設備型號配置
在 `wifi.json` 中添加新的設備型號：

```json
{
  "models": {
    "NewDevice": {
      "steps": [
        {
          "id": 1,
          "name": "Setup",
          "components": ["CustomComponent"],
          "detail": ["Custom Option 1", "Custom Option 2"]
        }
      ],
      "type": "JSON",
      "API": "CustomAPI"
    }
  }
}
```

#### 創建自訂元件
```dart
class CustomComponent extends StatefulWidget {
  final Function(bool)? onValidationChanged;
  final double? height;
  
  const CustomComponent({
    Key? key,
    this.onValidationChanged,
    this.height,
  }) : super(key: key);
  
  @override
  State<CustomComponent> createState() => _CustomComponentState();
}
```

### API 服務使用

#### 基本 API 呼叫
```dart
// 獲取系統資訊
final systemInfo = await WifiApiService.getSystemInfo();

// 更新無線設定
await WifiApiService.updateWirelessBasic({
  'vaps': [{
    'ssid': 'MyNetwork',
    'security_type': 'sae', // WPA3
    'password': 'SecurePassword'
  }]
});

// 更新網路設定
await WifiApiService.updateWanEth({
  'connection_type': 'static_ip',
  'static_ip_addr': '192.168.1.100',
  'static_ip_mask': '255.255.255.0',
  'static_ip_gateway': '192.168.1.1'
});
```

#### 完整的設定流程
```dart
// 1. 開始設定嚮導
await WifiApiService.configStart();

// 2. 更新各種設定
await WifiApiService.updateWirelessBasic(wirelessConfig);
await WifiApiService.updateWanEth(wanConfig);

// 3. 變更密碼
await WifiApiService.changePasswordWithSRP(
  username: 'admin',
  newPassword: 'NewSecurePassword',
);

// 4. 完成設定
await WifiApiService.configFinish();
```

### 主題系統使用

#### 使用預定義主題元件
```dart
final AppTheme appTheme = AppTheme();

// 建立標準卡片
appTheme.whiteBoxTheme.buildStandardCard(
  width: 300,
  height: 200,
  child: YourContentWidget(),
)

// 建立按鈕
appTheme.whiteBoxTheme.buildStandardButton(
  width: 150,
  height: 50,
  text: 'Click Me',
  onPressed: () => print('Button pressed'),
)

// 建立文字輸入框
appTheme.whiteBoxTheme.buildBlurredTextField(
  width: 300,
  hintText: 'Enter text',
  controller: textController,
)
```

### 驗證系統

#### IP 位址驗證
```dart
final validators = Validators();

// 驗證 IP 位址格式
bool isValid = validators.isIpValidate('192.168.1.1');

// 檢查是否為廣播地址
bool isBroadcast = validators.isBroadcastIp('192.168.1.255');

// 驗證是否為同一子網路
bool isSameSubnet = validators.isSameSubnet(
  '192.168.1.10', 
  '192.168.1.20', 
  '255.255.255.0'
);
```

#### 密碼強度驗證
```dart
// 檢查密碼複雜度
bool hasUpper = Validators.hasUpperCaseLetter(password);
bool hasLower = Validators.hasLowerCaseLetter(password);
bool hasDigit = Validators.hasDigit(password);
bool hasSpecial = Validators.hasSpecialChar(password);
```

## 測試與除錯

### 測試頁面
- **NetworkTopoView**：測試網絡拓撲圖顯示
- **TestPasswordPage**：測試密碼計算與驗證
- **SrpLoginTestPage**：測試 SRP 登入功能
- **theme_test_page**：測試主題元件顯示

### 除錯模式
在 `app_config.json` 中設定 `bypassAllRestrictions: true` 可以：
- 跳過網絡連接檢查
- 繞過認證流程
- 加速測試與開發

### 日誌系統
應用程式使用 `print()` 語句進行除錯輸出：
```dart
// API 呼叫日誌
print('API 請求: $endpoint');
print('回應狀態: ${response.statusCode}');

// 狀態變更日誌
print('步驟更新: $currentStep');
print('表單驗證: $isValid');
```

## 效能最佳化

### 網絡請求最佳化
- 10 秒請求超時設定
- 自動重試機制
- 連接狀態檢查
- 並行 API 呼叫支援

### UI 效能最佳化
- 響應式設計避免重複建構
- 圖片載入錯誤處理
- 列表項目延遲載入
- 記憶體洩漏防護

### 資料快取
- 使用 `flutter_secure_storage` 安全儲存敏感資料
- 會話資訊持久化
- API 回應快取機制

## 待實現功能

### 核心功能
- **設備儀表板**：即時狀態監控與管理介面
- **高級設定**：設備特定進階選項設定
- **多設備管理**：支援大量設備的批次管理
- **設備群組**：邏輯群組化管理相關設備

### 網絡管理
- **頻寬管理**：QoS 設定與頻寬限制
- **家長控制**：時間控制與內容過濾
- **訪客網絡**：獨立的訪客 Wi-Fi 設定
- **網絡診斷**：自動網絡問題檢測與修復

### 監控與分析
- **使用統計**：詳細的網絡使用分析
- **效能監控**：即時網絡效能指標
- **歷史紀錄**：長期趨勢分析
- **警報系統**：異常狀況自動通知

### 進階功能
- **協同控制**：IoT 設備聯動與自動化
- **固件升級**：設備韌體自動更新
- **備份還原**：設定檔案備份與還原
- **遠端管理**：透過雲端進行遠端設備管理

### 整合功能
- **雲端同步**：設定與狀態雲端同步
- **第三方整合**：智慧家庭平台整合
- **API 開放**：提供開發者 API 介面
- **語音控制**：語音助手整合支援

## 疑難排解

### 常見問題

#### 連接問題
- **無法連接設備**：檢查是否連接到正確的 Wi-Fi 網絡
- **API 請求超時**：確認設備 IP 位址正確，網絡連接穩定
- **認證失敗**：驗證帳號密碼，檢查初始密碼計算

#### UI 問題
- **畫面顯示異常**：清除應用程式快取，重新啟動
- **響應式佈局問題**：檢查不同螢幕尺寸的適配
- **主題顏色錯誤**：確認主題配置檔案正確載入

#### 效能問題
- **應用程式卡頓**：檢查記憶體使用量，關閉不必要的背景任務
- **網絡請求緩慢**：調整請求超時設定，檢查網絡品質

### 除錯工具
- 使用 Flutter Inspector 檢查 UI 層級
- 啟用 Flutter 效能疊加層監控效能
- 使用 `flutter logs` 查看即時日誌
- 利用 Android Studio / VS Code 的除錯功能

## 貢獻指南

### 開發流程
1. Fork 專案
2. 創建功能分支：`git checkout -b feature/amazing-feature`
3. 遵循程式碼風格指南
4. 撰寫測試案例
5. 提交更改：`git commit -m '添加功能: 簡要描述'`
6. 推送分支：`git push origin feature/amazing-feature`
7. 開啟 Pull Request

### 程式碼風格
- 遵循 Dart 官方程式碼風格
- 使用有意義的變數和函數名稱
- 添加詳細的中文註解
- 保持函數簡潔，單一職責
- 使用類型註解提高程式可讀性

### 測試要求
- 新功能必須包含對應的測試案例
- 確保所有現有測試通過
- 測試覆蓋率應保持在合理水平
- 包含整合測試驗證端到端功能

## 版本管理系統

### 版本號格式：`X.Y.Z.MMDD`

- **第一位 (主版本號 X)**：正式釋出版本
    - `0`: 開發中或測試版本
    - `1`: 第一個正式釋出版本
    - 後續遞增代表重大功能更新或架構變更

- **第二位 (子版本號 Y)**：Layout 設計版本
    - UI 設計或 layout 有較大變更時增加
    - 整體界面架構定版後增加

- **第三位 (小版本號 Z)**：例行更新版本
    - 每週推進會議更新
    - 功能小幅調整或錯誤修復時增加

- **後四位 (日期 MMDD)**：Layout 定版日期
    - 格式：月月日日 (例如：0523 代表 5月23日)

### 版本歷史

#### v0.1.0.0523 (當前版本)
**發布日期**：2024年5月23日  
**版本類型**：開發測試版

**主要功能**：
- ✅ 基礎 Wi-Fi 設備設定功能
- ✅ SRP 安全登入機制
- ✅ 響應式 UI 設計
- ✅ 網絡拓撲視覺化
- ✅ 多步驟設定嚮導
- ✅ QR 碼掃描支援
- ✅ 初始密碼計算機制
- ✅ JWT 認證系統
- ✅ 毛玻璃效果 UI 設計
- ✅ 紫色漸層主題風格

**技術特性**：
- 模組化架構設計
- JSON 配置驅動的流程控制
- 完整的表單驗證系統
- 響應式佈局適配不同螢幕
- 統一的主題管理系統

## 文檔

詳細文檔位於 `docs/` 目錄：

- **[專案結構說明](docs/01-app-structure.md)**：詳細的架構與組件說明
- **[UI 組件指南](docs/02-ui-components-guide.md)**：可重用組件的使用方法
- **[設定流程指南](docs/03-wifi-setting-flow-guide.md)**：Wi-Fi 設定流程實作
- **[設計風格指南](docs/04-ui-components-design-guide.md)**：UI 設計規範與風格
- **[API 整合指南](docs/05-api-integration-guide.md)**：API 服務整合方法
- **[安全機制指南](docs/06-security-implementation-guide.md)**：安全功能實作詳情

## 授權條款

本專案採用 Apache License 2.0 授權條款。詳情請參見 [LICENSE](LICENSE) 檔案。

## 聯絡資訊

- **專案維護者**：[Your Name]
- **電子郵件**：[your.email@example.com]
- **問題回報**：[GitHub Issues](https://github.com/yourusername/wifi-5g-iot-app/issues)
- **功能建議**：[GitHub Discussions](https://github.com/yourusername/wifi-5g-iot-app/discussions)

---

**注意**：本框架仍在積極開發中，API 和功能可能會有變動。建議在生產環境使用前進行充分測試。

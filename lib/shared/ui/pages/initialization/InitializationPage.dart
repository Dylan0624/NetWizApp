import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:whitebox/shared/ui/pages/initialization/QrCodeScannerPage.dart';
import 'package:whitebox/shared/ui/components/basic/WifiScannerComponent.dart';
import 'package:whitebox/shared/ui/pages/initialization/WifiSettingFlowPage.dart';
import 'package:whitebox/shared/theme/app_theme.dart'; // 引入 AppTheme

class InitializationPage extends StatefulWidget {
  const InitializationPage({super.key});

  @override
  State<InitializationPage> createState() => _InitializationPageState();
}

class _InitializationPageState extends State<InitializationPage> {
  List<WiFiAccessPoint> discoveredDevices = [];
  bool isScanning = false;
  String? scanError;

  // WifiScannerComponent 的控制器
  final WifiScannerController _scannerController = WifiScannerController();

  // 創建 AppTheme 實例
  final AppTheme _appTheme = AppTheme();

  // 處理掃描完成
  void _handleScanComplete(List<WiFiAccessPoint> devices, String? error) {
    setState(() {
      discoveredDevices = devices;
      scanError = error;
      isScanning = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
// 建立使用圖片的功能按鈕
  Widget _buildImageActionButton({
    required String label,
    required String imagePath,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: _appTheme.whiteBoxTheme.buildStandardCard(
        width: 100, // 根據設計稿寬度
        height: 100, // 根據設計稿高度
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 45,
              height: 45,
              color: Colors.white, // 如果需要變更顏色
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10, // 根據設計稿字體大小
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  // 處理裝置選擇
  void _handleDeviceSelected(WiFiAccessPoint device) {
    // 當選擇裝置時，導航到 WifiSettingFlowPage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WifiSettingFlowPage()),
    );
  }

  // 開啟掃描 QR 碼頁面
  void _openQrCodeScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrCodeScannerPage()),
    );

    if (result != null) {
      // 處理 QR 碼掃描結果
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR 碼掃描結果: $result')),
      );
    }
  }

  // 手動新增頁面 - 現在打開 WifiSettingFlowPage
  void _openManualAdd() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WifiSettingFlowPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent, // 確保 Scaffold 是透明的
      body: Container(
        // 設置背景圖片
        decoration: BackgroundDecorator.imageBackground(
          imagePath: AppBackgrounds.mainBackground, // 使用您的背景圖片
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // WiFi 裝置列表區域 - 高度調小
              Positioned(
                top: 238, // 根據設計稿精確定位
                left: 20,
                child: SizedBox(
                  width: screenSize.width * 0.9,
                  height: 400, // 減小列表高度
                  child: WifiScannerComponent(
                    controller: _scannerController,
                    maxDevicesToShow: 8, // 限制顯示數量
                    height: 400, // 直接傳入高度
                    onScanComplete: _handleScanComplete,
                    onDeviceSelected: _handleDeviceSelected,
                  ),
                ),
              ),

              // 頂部按鈕區域
              Positioned(
                top: 98, // 根據設計稿精確定位
                left: 20,
                child: Row(
                  children: [
                    // QR 碼掃描按鈕
                    _buildImageActionButton(
                      label: 'QRcode',
                      imagePath: 'assets/images/icon/QRcode.png',
                      onPressed: _openQrCodeScanner,
                    ),

                    const SizedBox(width: 30), // 按鈕間距

                    // 手動新增按鈕 - 使用自定義圖片
                    _buildImageActionButton(
                      label: 'Manual Input',
                      imagePath: 'assets/images/icon/manual_input.png', // 基本圖片路徑
                      onPressed: _openManualAdd,
                    ),
                  ],
                ),
              ),

              // 底部搜尋按鈕
              Positioned(
                bottom: 50, // 根據設計稿放在底部
                left: 40,
                right: 40,
                child: _buildSearchButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 建立功能按鈕 - 使用標準漸層卡片，根據設計稿精確設置樣式
  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: _appTheme.whiteBoxTheme.buildStandardCard(
        width: 100, // 根據設計稿寬度
        height: 100, // 根據設計稿高度
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12, // 根據設計稿字體大小
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: isScanning ? null : () {
        setState(() {
          isScanning = true;
        });
        _scannerController.startScan();
      },
      child: Container(
        height: 50, // 根據設計稿高度
        decoration: BoxDecoration(
          color: const Color(0xFF9747FF), // 根據設計稿顏色
          borderRadius: BorderRadius.circular(4), // 根據設計稿圓角
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
              Text(
                isScanning ? 'Scanning...' : 'Search',
                style: const TextStyle(
                  fontSize: 20, // 根據設計稿字體大小
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
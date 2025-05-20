import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:whitebox/shared/ui/pages/initialization/WifiConnectionPage.dart';
import 'package:whitebox/shared/ui/pages/initialization/QrCodeScannerPage.dart';
import 'package:whitebox/shared/ui/pages/initialization/InitializationPage.dart';
import 'package:whitebox/shared/ui/pages/initialization/WifiSettingFlowPage.dart';
import 'package:whitebox/shared/ui/pages/initialization/LoginPage.dart';
import 'package:whitebox/shared/ui/pages/test/TestPage.dart';
import 'package:whitebox/shared/ui/pages/test/TestPasswordPage.dart';
import 'package:whitebox/shared/ui/pages/test/SrpLoginTestPage.dart';
import 'package:whitebox/shared/ui/pages/test/SrpLoginModifiedTestPage.dart';
import 'package:whitebox/shared/ui/pages/test/theme_test_page.dart';
import 'package:whitebox/shared/theme/app_theme.dart'; // 導入主題

// 全局背景設置，可以在應用的任何地方訪問
class BackgroundSettings {
  static String currentBackground = AppBackgrounds.mainBackground;
  static double blurRadius = 0.0;
  static BackgroundMode backgroundMode = BackgroundMode.normal;
  static bool showBackground = true;
}

void main() {
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null && !message.contains('A RenderFlex overflowed')) {
      print(message);
    }
  };
  // 關閉調試標記和檢查
  debugPaintSizeEnabled = false;
  debugPaintBaselinesEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugPaintPointersEnabled = false;
  debugRepaintRainbowEnabled = false;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhiteBox App',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFFD9D9D9),
        fontFamily: 'Segoe UI', // 設定全局字體為 Segoe UI
      ),
      // 使用自定義的頁面路由構建器，為每個頁面套用背景
      builder: (context, child) {
        return AppBackgroundWrapper(child: child ?? Container());
      },
      home: const InitializationPage(),
    );
  }
}

// 創建一個背景包裝器，用於套用全局背景
class AppBackgroundWrapper extends StatelessWidget {
  final Widget child;

  const AppBackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 如果不顯示背景，直接返回子組件
    if (!BackgroundSettings.showBackground) {
      return child;
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(BackgroundSettings.currentBackground),
          fit: BoxFit.cover,
          // 根據背景模式應用適當的效果
          colorFilter: BackgroundSettings.backgroundMode != BackgroundMode.normal
              ? ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken)
              : null,
        ),
      ),
      child: BackgroundSettings.blurRadius > 0
          ? BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: BackgroundSettings.blurRadius,
          sigmaY: BackgroundSettings.blurRadius,
        ),
        child: child,
      )
          : child,
    );
  }
}

// 如果需要為個別頁面關閉背景，可以創建一個無背景的頁面包裝器
class NoBackgroundPage extends StatelessWidget {
  final Widget child;

  const NoBackgroundPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // 臨時關閉背景
    BackgroundSettings.showBackground = false;

    return Builder(
        builder: (context) {
          // 使用 addPostFrameCallback 確保在頁面離開時恢復背景設置
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 設置一個延遲，確保在導航完成後恢復背景設置
            Future.delayed(Duration.zero, () {
              BackgroundSettings.showBackground = true;
            });
          });

          return child;
        }
    );
  }
}
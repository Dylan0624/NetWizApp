// lib/shared/api/wifi_api_service.dart
// 簡化後的 WiFi API 服務，引入資料夾內的功能

import 'dart:convert';
import 'package:http/http.dart' as http;

// 引入 wifi_api 資料夾內的功能
import 'wifi_api/login_process.dart';
import 'wifi_api/password_service.dart';

// 保留原本的結果類
class FirstLoginResult {
  final bool success;
  final String message;
  final String? sessionId;
  final String? csrfToken;
  final String? jwtToken;
  final String? calculatedPassword;
  final Map<String, dynamic>? systemInfo;
  final Map<String, dynamic>? loginResponse;

  FirstLoginResult({
    required this.success,
    required this.message,
    this.sessionId,
    this.csrfToken,
    this.jwtToken,
    this.calculatedPassword,
    this.systemInfo,
    this.loginResponse,
  });
}

/// WiFi API 服務類 - 簡化版
class WifiApiService {
  // API 相關設定
  static String baseUrl = 'http://192.168.1.1';
  static String apiVersion = '/api/v1';

  // JWT Token 儲存
  static String? _jwtToken;

  // 儲存 API 路徑映射
  static final Map<String, String> _endpoints = {
    'systemInfo': '/api/v1/system/info',
    'networkStatus': '/api/v1/network/status',
    'wirelessBasic': '/api/v1/wireless/basic',
    'wanEth': '/api/v1/network/wan_eth',
    'userLogin': '/api/v1/user/login',
    'configStart': '/api/v1/config/start',
    'configFinish': '/api/v1/config/finish',
    'wizardChangePassword': '/api/v1/wizard/change_password',
  };

  // 動態方法映射，保留原有 call 方法的兼容性
  static final Map<String, Function> _dynamicMethods = {
    'getSystemInfo': () => _get(_endpoints['systemInfo']!),
    'getNetworkStatus': () => _get(_endpoints['networkStatus']!),
    'getWirelessBasic': () => _get(_endpoints['wirelessBasic']!),
    'getWanEth': () => _get(_endpoints['wanEth']!),
    'postConfigStart': () => _post(_endpoints['configStart']!, {}),
    'postConfigFinish': () => _post(_endpoints['configFinish']!, {}),
    'postUserLogin': (data) => _post(_endpoints['userLogin']!, data),
    'updateWirelessBasic': (data) => _put(_endpoints['wirelessBasic']!, data),
    'updateWanEth': (data) => _put(_endpoints['wanEth']!, data),
    'updateWizardChangePassword': (data) => _put(_endpoints['wizardChangePassword']!, data),
  };

  /// 設置 JWT Token
  static void setJwtToken(String token) {
    _jwtToken = token;
  }

  /// 獲取 JWT Token
  static String? getJwtToken() {
    return _jwtToken;
  }

  /// 獲取標準請求標頭
  static Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_jwtToken != null && _jwtToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_jwtToken';
    }

    return headers;
  }

  /// 發送 GET 請求
  static Future<Map<String, dynamic>> _get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return json.decode(response.body);
      } else {
        throw Exception('請求失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('GET 請求錯誤: $e');
      rethrow;
    }
  }

  /// 發送 POST 請求
  static Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return json.decode(response.body);
      } else {
        throw Exception('請求失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('POST 請求錯誤: $e');
      rethrow;
    }
  }

  /// 發送 PUT 請求
  static Future<Map<String, dynamic>> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(),
        body: json.encode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return json.decode(response.body);
      } else {
        throw Exception('請求失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('PUT 請求錯誤: $e');
      rethrow;
    }
  }

  /// 動態調用方法 - 保留原有的 call 功能
  static Future<Map<String, dynamic>> call(String methodName, [dynamic params]) async {
    if (!_dynamicMethods.containsKey(methodName)) {
      throw Exception('方法 "$methodName" 不存在');
    }

    if (params != null) {
      return await _dynamicMethods[methodName]!(params);
    } else {
      return await _dynamicMethods[methodName]!();
    }
  }

  // ============ 簡化的 API 方法 ============

  /// 獲取系統資訊
  static Future<Map<String, dynamic>> getSystemInfo() async {
    return await _get(_endpoints['systemInfo']!);
  }

  /// 獲取網路狀態
  static Future<Map<String, dynamic>> getNetworkStatus() async {
    return await _get(_endpoints['networkStatus']!);
  }

  /// 獲取無線基本設定
  static Future<Map<String, dynamic>> getWirelessBasic() async {
    return await _get(_endpoints['wirelessBasic']!);
  }

  /// 更新無線基本設定
  static Future<Map<String, dynamic>> updateWirelessBasic(Map<String, dynamic> config) async {
    return await _put(_endpoints['wirelessBasic']!, config);
  }

  /// 獲取以太網廣域網路設定
  static Future<Map<String, dynamic>> getWanEth() async {
    return await _get(_endpoints['wanEth']!);
  }

  /// 更新以太網廣域網路設定
  static Future<Map<String, dynamic>> updateWanEth(Map<String, dynamic> config) async {
    return await _put(_endpoints['wanEth']!, config);
  }

  /// 開始設定
  static Future<Map<String, dynamic>> configStart() async {
    return await _post(_endpoints['configStart']!, {});
  }

  /// 完成設定
  static Future<Map<String, dynamic>> configFinish() async {
    return await _post(_endpoints['configFinish']!, {});
  }

  /// 變更密碼
  static Future<Map<String, dynamic>> changePassword(Map<String, dynamic> passwordData) async {
    return await _put(_endpoints['wizardChangePassword']!, passwordData);
  }

  /// 計算初始密碼 - 使用 PasswordService
  static Future<String> calculateInitialPassword({
    String? providedSSID,
    String? serialNumber,
    String? loginSalt,
  }) async {
    // 如果缺少必要參數，嘗試從系統資訊獲取
    if (serialNumber == null || loginSalt == null) {
      final systemInfo = await getSystemInfo();
      serialNumber ??= systemInfo['serial_number'];
      loginSalt ??= systemInfo['login_salt'];
    }

    // 使用 PasswordService 計算初始密碼
    return PasswordService.calculateInitialPassword(
      providedSSID: providedSSID,
      serialNumber: serialNumber,
      loginSalt: loginSalt,
    );
  }

  /// 使用初始密碼登入
  static Future<Map<String, dynamic>> loginWithInitialPassword({
    String? providedSSID,
    String? serialNumber,
    String? loginSalt,
    String? username,
  }) async {
    try {
      // 計算初始密碼
      String password = await calculateInitialPassword(
        providedSSID: providedSSID,
        serialNumber: serialNumber,
        loginSalt: loginSalt,
      );

      // 如果沒有提供用戶名，嘗試從系統資訊獲取
      if (username == null) {
        final systemInfo = await getSystemInfo();
        username = systemInfo['default_user'] ?? 'admin';
      }

      // 執行登入
      Map<String, dynamic> loginData = {
        'user': username,
        'password': password,
      };

      final response = await _post(_endpoints['userLogin']!, loginData);

      // 儲存 JWT 令牌
      if (response.containsKey('token')) {
        setJwtToken(response['token']);
      } else if (response.containsKey('jwt')) {
        setJwtToken(response['jwt']);
      }

      return response;
    } catch (e) {
      print('初始密碼登入錯誤: $e');
      rethrow;
    }
  }

  /// 執行 SRP 登入流程 - 使用 LoginProcess
  static Future<LoginResult> loginWithSRP(String username, String password) async {
    // 創建 LoginProcess 實例並執行登入流程
    final loginProcess = LoginProcess(username, password, baseUrl: baseUrl);
    final result = await loginProcess.startSRPLoginProcess();

    // 如果登入成功並獲取到 JWT 令牌，儲存它
    if (result.returnStatus && result.session.jwtToken != null) {
      setJwtToken(result.session.jwtToken!);
    }

    return result;
  }

  /// 執行完整的首次登入流程
  static Future<FirstLoginResult> performFirstLogin({
    String? providedSSID,
    String username = 'admin',
  }) async {
    try {
      // 步驟 1: 獲取系統資訊
      final systemInfo = await getSystemInfo();

      // 檢查系統資訊是否完整
      if (!systemInfo.containsKey('serial_number') || !systemInfo.containsKey('login_salt')) {
        return FirstLoginResult(
            success: false,
            message: '無法從系統資訊中獲取序列號或登入鹽值',
            systemInfo: systemInfo
        );
      }

      // 獲取必要參數
      final serialNumber = systemInfo['serial_number'];
      final loginSalt = systemInfo['login_salt'];
      final defaultUser = systemInfo['default_user'] ?? username;

      // 步驟 2: 計算初始密碼
      final password = await calculateInitialPassword(
        providedSSID: providedSSID,
        serialNumber: serialNumber,
        loginSalt: loginSalt,
      );

      // 步驟 3: 嘗試登入
      final loginData = {
        'user': defaultUser,
        'password': password,
      };

      final loginResponse = await _post(_endpoints['userLogin']!, loginData);

      // 檢查登入結果
      bool loginSuccess = false;
      String message = '登入失敗';

      if (loginResponse.containsKey('token')) {
        loginSuccess = true;
        message = '登入成功，獲取到 JWT 令牌';
        setJwtToken(loginResponse['token']);
      } else if (loginResponse.containsKey('jwt')) {
        loginSuccess = true;
        message = '登入成功，獲取到 JWT 令牌';
        setJwtToken(loginResponse['jwt']);
      } else if (loginResponse.containsKey('status') && loginResponse['status'] == 'success') {
        loginSuccess = true;
        message = '登入成功';
      }

      return FirstLoginResult(
        success: loginSuccess,
        message: message,
        jwtToken: getJwtToken(),
        calculatedPassword: password,
        systemInfo: systemInfo,
        loginResponse: loginResponse,
      );
    } catch (e) {
      return FirstLoginResult(
        success: false,
        message: '首次登入過程中發生錯誤: $e',
      );
    }
  }
}
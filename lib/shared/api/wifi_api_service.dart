import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/services.dart' show rootBundle;


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
/// WiFi API 服務類
class WifiApiService {
  // API 相關設定
  static String baseUrl = 'http://192.168.1.1';
  static String apiVersion = '/api/v1';
  static int timeoutSeconds = 10;

  // API 端點映射表
  static final Map<String, ApiEndpoint> _endpoints = {};

  // 初始化狀態
  static bool _isInitialized = false;

  // 動態方法呼叫處理器
  static final Map<String, Function> _dynamicMethods = {};

  // JWT Token，用於身份驗證
  static String? _jwtToken;

  // 預設 Hash 數組
  static const List<String> DEFAULT_HASHES = [
    '1a2b3c4d5e6f708192a3b4c5d6e7f8091a2b3c4d5e6f708192a3b4c5d6e7f809',
    '9876543210abcdef9876543210abcdef9876543210abcdef9876543210abcdef',
    'fedcba9876543210fedcba9876543210fedcba9876543210fedcba9876543210',
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
    '7890abcdef1234567890abcdef1234567890abcdef1234567890abcdef123456',
  ];

  /// 初始化 API 服務
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 讀取 API 配置文件
      final jsonString = await rootBundle.loadString('lib/shared/config/api/wifi.json');
      final config = json.decode(jsonString);

      // 設置基本配置
      baseUrl = config['baseUrl'] ?? baseUrl;
      apiVersion = config['apiVersion'] ?? apiVersion;
      timeoutSeconds = config['timeoutSeconds'] ?? timeoutSeconds;

      // 解析端點
      final endpointsMap = config['endpoints'] as Map<String, dynamic>;

      endpointsMap.forEach((key, value) {
        if (value is String) {
          final endpoint = value.toString().replaceAll('\$apiVersion', apiVersion);
          _endpoints[key] = ApiEndpoint(path: endpoint);
        } else if (value is Map<String, dynamic>) {
          final path = value['path'].toString().replaceAll('\$apiVersion', apiVersion);
          _endpoints[key] = ApiEndpoint.fromJson({...value, 'path': path});
        }

        // 為每個端點動態建立方法
        _createDynamicMethod(key);
      });

      _isInitialized = true;
      print('WifiApiService 初始化成功，載入了 ${_endpoints.length} 個 API 端點');
    } catch (e) {
      print('WifiApiService 初始化失敗: $e');
      _setupDefaultEndpoints();
    }
  }

  /// 設置預設端點（向後兼容）
  static void _setupDefaultEndpoints() {
    final defaultEndpoints = {
      'configStart': '$apiVersion/config/start',
      'configFinish': '$apiVersion/config/finish',
      'systemInfo': '$apiVersion/system/info',
      'wan5g': '$apiVersion/network/wan_5g',
      'wanEth': '$apiVersion/network/wan_eth',
      'networkStatus': '$apiVersion/network/status',
      'wirelessBasic': '$apiVersion/wireless/basic',
      'wirelessAdvanced': '$apiVersion/wireless/advanced',
      'wizardChangePassword': '$apiVersion/wizard/change_password',
      'wizardWanEth': '$apiVersion/wizard/wan_eth',
      'userLogin': '$apiVersion/user/login',
    };

    defaultEndpoints.forEach((key, path) {
      _endpoints[key] = ApiEndpoint(path: path);
      _createDynamicMethod(key);
    });

    _isInitialized = true;
    print('使用預設 API 端點');
  }

  /// 為端點動態建立方法
  static void _createDynamicMethod(String endpointKey) {
    final methodName = _endpointToMethodName(endpointKey);

    _dynamicMethods['get$methodName'] = ([Map<String, dynamic>? params]) async {
      final endpoint = _endpoints[endpointKey]!;
      return await get(endpoint.path, queryParams: params);
    };

    _dynamicMethods['post$methodName'] = (Map<String, dynamic>? data) async {
      final endpoint = _endpoints[endpointKey]!;
      return await post(endpoint.path, data: data);
    };

    _dynamicMethods['update$methodName'] = (Map<String, dynamic>? data) async {
      final endpoint = _endpoints[endpointKey]!;
      return await put(endpoint.path, data: data);
    };

    _dynamicMethods['delete$methodName'] = (Map<String, dynamic>? data) async {
      final endpoint = _endpoints[endpointKey]!;
      return await delete(endpoint.path, data: data);
    };
  }

  /// 將端點鍵轉換為方法名稱（駝峰命名法）
  static String _endpointToMethodName(String key) {
    final parts = key.split('_');
    String result = parts[0];

    for (int i = 1; i < parts.length; i++) {
      if (parts[i].isNotEmpty) {
        result += parts[i][0].toUpperCase() + parts[i].substring(1);
      }
    }

    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }

    return result;
  }

  /// 獲取API端點配置
  static ApiEndpoint? getEndpointConfig(String key) {
    if (!_isInitialized) {
      _setupDefaultEndpoints();
    }

    return _endpoints[key];
  }

  /// 獲取API端點路徑
  static String getEndpoint(String key) {
    if (!_isInitialized) {
      _setupDefaultEndpoints();
    }

    if (!_endpoints.containsKey(key)) {
      print('警告: API端點 "$key" 不存在，請檢查配置');
      return '';
    }
    return _endpoints[key]!.path;
  }

  /// 設置 JWT Token
  static void setJwtToken(String token) {
    _jwtToken = token;
  }

  /// 獲取 JWT Token
  static String? getJwtToken() {
    return _jwtToken;
  }

  /// 獲取通用的 Headers
  static Map<String, String> getHeaders() {
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
  static Future<Map<String, dynamic>> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      var uri = Uri.parse('$baseUrl$endpoint');

      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
      }

      final response = await http.get(
        uri,
        headers: getHeaders(),
      ).timeout(Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      print('GET 請求錯誤: $e');
      rethrow;
    }
  }

  /// 發送 POST 請求
  static Future<Map<String, dynamic>> post(String endpoint, {Map<String, dynamic>? data}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.post(
        url,
        headers: getHeaders(),
        body: data != null ? json.encode(data) : null,
      ).timeout(Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      print('POST 請求錯誤: $e');
      rethrow;
    }
  }

  /// 發送 PUT 請求
  static Future<Map<String, dynamic>> put(String endpoint, {Map<String, dynamic>? data}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.put(
        url,
        headers: getHeaders(),
        body: data != null ? json.encode(data) : null,
      ).timeout(Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      print('PUT 請求錯誤: $e');
      rethrow;
    }
  }

  /// 發送 DELETE 請求
  static Future<Map<String, dynamic>> delete(String endpoint, {Map<String, dynamic>? data}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final response = await http.delete(
        url,
        headers: getHeaders(),
        body: data != null ? json.encode(data) : null,
      ).timeout(Duration(seconds: timeoutSeconds));

      return _handleResponse(response);
    } catch (e) {
      print('DELETE 請求錯誤: $e');
      rethrow;
    }
  }

  /// 處理 HTTP 回應
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};

      String responseBody = response.body;
      int jsonStart = responseBody.indexOf('{');
      if (jsonStart > 0) {
        responseBody = responseBody.substring(jsonStart);
      }

      return json.decode(responseBody);
    } else {
      try {
        final errorData = json.decode(response.body);
        throw ApiException(
          statusCode: response.statusCode,
          errorCode: errorData['status_code'] ?? 'unknown',
          message: errorData['message'] ?? 'Unknown error',
        );
      } catch (e) {
        throw ApiException(
          statusCode: response.statusCode,
          errorCode: 'parse_error',
          message: 'Failed to parse error response: ${response.body}',
        );
      }
    }
  }

  /// 動態調用方法
  static Future<Map<String, dynamic>> call(String methodName, [dynamic params]) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_dynamicMethods.containsKey(methodName)) {
      throw Exception('方法 "$methodName" 不存在');
    }

    return await _dynamicMethods[methodName]!(params);
  }

  /// 獲取所有可用的 API 方法名稱
  static List<String> getAllMethodNames() {
    if (!_isInitialized) {
      _setupDefaultEndpoints();
    }
    return _dynamicMethods.keys.toList();
  }

  /// 獲取當前連接的 SSID
  static Future<String?> getCurrentSSID() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.wifi) {
        final info = NetworkInfo();
        final ssid = await info.getWifiName();

        if (ssid != null && ssid.isNotEmpty) {
          return ssid.replaceAll('"', '');
        }
      }
      return null;
    } catch (e) {
      print('獲取SSID錯誤: $e');
      return null;
    }
  }

  /// 計算組合編號
  static int _calculateCombinationIndex(String serialNumber) {
    // 計算序號的 SHA256
    Digest digest = sha256.convert(utf8.encode(serialNumber));
    String hexDigest = digest.toString();
    print('序號 SHA256: $hexDigest');

    // 取最後一個字節（最後兩個字符）
    String lastByte = hexDigest.substring(hexDigest.length - 2);
    int lastByteValue = int.parse(lastByte, radix: 16);
    print('最後字節（十六進制）: $lastByte, 十進制: $lastByteValue');

    // 對 6 取餘
    int combinationIndex = lastByteValue % 6;
    print('計算的組合編號: $combinationIndex');

    return combinationIndex;
  }

  /// 16進制字符串轉換為位元組數組
  static List<int> _hexToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  /// 計算初始密碼
  static Future<String> calculateInitialPassword({
    String? providedSSID,
    String? serialNumber,
    String? loginSalt,
  }) async {
    Map<String, dynamic> systemInfo;
    String ssid;
    String salt;
    String serial;

    try {
      // 如果沒有提供SSID，嘗試獲取當前連接的SSID
      if (providedSSID == null) {
        final currentSSID = await getCurrentSSID();
        if (currentSSID != null) {
          ssid = currentSSID;
        } else {
          systemInfo = await call('getSystemInfo');
          ssid = systemInfo['model_name'] ?? 'UNKNOWN';
        }
      } else {
        ssid = providedSSID;
      }
      print('使用 SSID: $ssid');

      // 如果沒有提供序號或鹽值，從系統信息中獲取
      if (serialNumber == null || loginSalt == null) {
        systemInfo = await call('getSystemInfo');
        salt = loginSalt ?? systemInfo['login_salt'];
        serial = serialNumber ?? systemInfo['serial_number'];
        if (salt == null || serial == null) {
          throw Exception('無法獲取必要的系統信息');
        }
      } else {
        salt = loginSalt;
        serial = serialNumber;
      }
      print('使用序號: $serial');
      print('使用 Salt: $salt');

      // 計算組合編號
      int combinationIndex = _calculateCombinationIndex(serial);

      // 選擇預設 Hash 作為 HMAC Key
      String defaultHash = DEFAULT_HASHES[combinationIndex];
      print('選擇的 Hash (組合編號 $combinationIndex): $defaultHash');

      // 拆分 Salt 為前段和後段
      String saltFront = '';
      String saltBack = '';
      if (salt.length >= 64) {
        saltFront = salt.substring(0, 32); // 前 128 位元 (32 個十六進位字符)
        saltBack = salt.substring(32);     // 後 128 位元
      } else {
        // 如果 salt 長度不足，使用全部作為前段，後段留空
        saltFront = salt;
        saltBack = '';
      }

      print('Salt 前段 (前 128 位元): $saltFront');
      print('Salt 後段 (後 128 位元): $saltBack');

      // 根據組合編號生成消息
      String message = '';
      String messageDesc = '';

      switch (combinationIndex) {
        case 0:
          message = ssid + saltFront + saltBack;
          messageDesc = 'SSID + Salt 前段 + Salt 後段';
          break;
        case 1:
          message = ssid + saltBack + saltFront;
          messageDesc = 'SSID + Salt 後段 + Salt 前段';
          break;
        case 2:
          message = saltFront + ssid + saltBack;
          messageDesc = 'Salt 前段 + SSID + Salt 後段';
          break;
        case 3:
          message = saltFront + saltBack + ssid;
          messageDesc = 'Salt 前段 + Salt 後段 + SSID';
          break;
        case 4:
          message = saltBack + ssid + saltFront;
          messageDesc = 'Salt 後段 + SSID + Salt 前段';
          break;
        case 5:
          message = saltBack + saltFront + ssid;
          messageDesc = 'Salt 後段 + Salt 前段 + SSID';
          break;
        default:
        // 預設情況使用簡單的 Salt + SSID
          message = salt + ssid;
          messageDesc = 'Salt + SSID (預設)';
      }

      print('消息組合方式: $messageDesc');
      print('生成的消息: $message');

      // 計算 HMAC-SHA256，使用 UTF-8 編碼的 Hash
      List<int> keyBytes = utf8.encode(defaultHash);
      List<int> messageBytes = utf8.encode(message);
      Hmac hmacSha256 = Hmac(sha256, keyBytes);
      Digest digest = hmacSha256.convert(messageBytes);
      String result = digest.toString();
      print('HMAC-SHA256 結果: $result');

      // 返回 HEX 格式結果
      return result;
    } catch (e) {
      print('計算初始密碼錯誤: $e');
      rethrow;
    }
  }

  /// 使用初始密碼登入並獲取token
  static Future<Map<String, dynamic>> loginWithInitialPassword({
    String? providedSSID,
    String? serialNumber,
    String? loginSalt,
    String? username,
  }) async {
    try {
      String password = await calculateInitialPassword(
        providedSSID: providedSSID,
        serialNumber: serialNumber,
        loginSalt: loginSalt,
      );

      String user;
      if (username == null) {
        final systemInfo = await call('getSystemInfo');
        user = systemInfo['default_user'] ?? 'admin';
      } else {
        user = username;
      }

      Map<String, dynamic> loginData = {
        'user': user,
        'password': password,
      };

      final response = await call('postUserLogin', loginData);

      if (response.containsKey('token')) {
        setJwtToken(response['token']);
      }

      return response;
    } catch (e) {
      print('初始密碼登入錯誤: $e');
      rethrow;
    }
  }


  /// 執行完整的首次登入流程
  ///
  /// 步驟：
  /// 1. 獲取系統資訊
  /// 2. 計算初始密碼
  /// 3. 使用初始密碼登入
  ///
  /// 返回一個 FirstLoginResult 物件，包含所有相關資訊
  static Future<FirstLoginResult> performFirstLogin({
  String? providedSSID,
  String username = 'admin',
  }) async {
  try {
  // 步驟 1: 獲取系統資訊
  final systemInfo = await call('getSystemInfo');

  // 檢查系統資訊
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
  String? currentSSID;
  if (providedSSID == null) {
  // 嘗試獲取當前連接的SSID
  currentSSID = await getCurrentSSID();
  }

  // 使用設備型號作為SSID的備用方案
  final modelName = systemInfo['model_name'] ?? 'UNKNOWN';
  final ssid = providedSSID ?? currentSSID ?? modelName;

  // 計算密碼
  final password = await calculateInitialPassword(
  providedSSID: ssid,
  serialNumber: serialNumber,
  loginSalt: loginSalt,
  );

  // 步驟 3: 使用計算出的密碼嘗試登入
  final loginData = {
  'user': defaultUser,
  'password': password,
  };

  final loginResponse = await call('postUserLogin', loginData);

  // 檢查登入是否成功
  bool loginSuccess = false;
  String message = '登入失敗';

  // 檢查不同的登入成功指標
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

  /// 獲取系統資訊
  static Future<Map<String, dynamic>> getSystemInfo() async {
  return await call('getSystemInfo');
  }

  /// 獲取網路狀態
  static Future<Map<String, dynamic>> getNetworkStatus() async {
  return await call('getNetworkStatus');
  }

  /// 獲取無線基本設定
  static Future<Map<String, dynamic>> getWirelessBasic() async {
  return await call('getWirelessBasic');
  }

  /// 更新無線基本設定
  static Future<Map<String, dynamic>> updateWirelessBasic(Map<String, dynamic> config) async {
  return await call('updateWirelessBasic', config);
  }

  /// 獲取以太網廣域網路設定
  static Future<Map<String, dynamic>> getWanEth() async {
  return await call('getWanEth');
  }

  /// 更新以太網廣域網路設定
  static Future<Map<String, dynamic>> updateWanEth(Map<String, dynamic> config) async {
  return await call('updateWanEth', config);
  }

  /// 開始設定
  static Future<Map<String, dynamic>> configStart() async {
  return await call('postConfigStart');
  }

  /// 完成設定
  static Future<Map<String, dynamic>> configFinish() async {
  return await call('postConfigFinish');
  }

  /// 登入（SRP 方式）
  static Future<Map<String, dynamic>> login(Map<String, dynamic> loginData) async {
  return await call('postUserLogin', loginData);
  }

  /// 變更密碼（精靈模式）
  static Future<Map<String, dynamic>> changePassword(Map<String, dynamic> passwordData) async {
  return await call('updateWizardChangePassword', passwordData);
  }
}

/// API 端點配置類
class ApiEndpoint {
  final String path;
  final ApiMethod defaultMethod;
  final Map<String, dynamic> defaultData;

  ApiEndpoint({
    required this.path,
    this.defaultMethod = ApiMethod.get,
    this.defaultData = const {},
  });

  factory ApiEndpoint.fromJson(Map<String, dynamic> json) {
    ApiMethod method = ApiMethod.get;
    if (json.containsKey('method')) {
      switch (json['method'].toString().toLowerCase()) {
        case 'post':
          method = ApiMethod.post;
          break;
        case 'put':
          method = ApiMethod.put;
          break;
        case 'delete':
          method = ApiMethod.delete;
          break;
        default:
          method = ApiMethod.get;
      }
    }

    return ApiEndpoint(
      path: json['path'] ?? '',
      defaultMethod: method,
      defaultData: json['defaultData'] ?? {},
    );
  }
}

/// API 請求方法枚舉
enum ApiMethod {
  get,
  post,
  put,
  delete
}

/// API 異常類，用於處理 API 錯誤
class ApiException implements Exception {
  final int statusCode;
  final String errorCode;
  final String message;

  ApiException({required this.statusCode, required this.errorCode, required this.message});

  @override
  String toString() => 'ApiException: [$statusCode][$errorCode] $message';
}
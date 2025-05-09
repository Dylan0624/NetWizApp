import 'package:flutter/material.dart';
import 'package:whitebox/shared/api/wifi_api_service.dart';
import 'package:whitebox/shared/ui/pages/test/SrpLoginModifiedTestPage.dart';

class FirstLoginTestPage extends StatefulWidget {
  const FirstLoginTestPage({super.key});

  @override
  State<FirstLoginTestPage> createState() => _FirstLoginTestPageState();
}

class _FirstLoginTestPageState extends State<FirstLoginTestPage> {
  // 預設固定參數
  final String defaultDeviceModel = 'MICKY001';  // 預設設備型號
  final String defaultSSID = 'EG180BE-9CF1';  // 預設 SSID

  // 存儲測試日誌
  List<String> logs = [];
  bool isLoading = false;
  bool isCalculatingOnly = false; // 標記是否只計算密碼而不進行登入
  final _scrollController = ScrollController();
  String _statusMessage = "點擊按鈕開始測試";

  // 測試結果
  bool _loginSuccess = false;
  String? _calculatedPassword;
  String? _jwtToken;
  String? _usedSSID;
  String? _serialNumber;
  String? _salt;
  Map<String, dynamic>? _systemInfo;
  Map<String, dynamic>? _loginResponse;

  // 輸入控制器
  late TextEditingController _ssidController;
  final TextEditingController _usernameController = TextEditingController(text: "admin");
  final TextEditingController _serialNumberController = TextEditingController(text: "");
  final TextEditingController _saltController = TextEditingController(text: "");

  // 設定測試選項
  bool _showAdvancedOptions = false;
  bool _useSystemInfo = true;
  bool _useDefaultSSID = true; // 是否使用預設SSID

  @override
  void initState() {
    super.initState();
    // 初始化SSID控制器，設置預設值
    _ssidController = TextEditingController(text: defaultSSID);
    _serialNumberController.text = defaultDeviceModel;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _ssidController.dispose();
    _usernameController.dispose();
    _serialNumberController.dispose();
    _saltController.dispose();
    super.dispose();
  }

  // 日誌輸出並滾動
  void _addLog(String message) {
    setState(() {
      logs.add(message);
    });

    // 確保日誌滾動到底部
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    debugPrint(message);
  }

  // 更新狀態消息
  void _updateStatus(String status) {
    setState(() {
      _statusMessage = status;
    });
  }

  // 只計算密碼而不進行登入
  Future<void> _calculatePasswordOnly() async {
    setState(() {
      logs = [];
      isLoading = true;
      isCalculatingOnly = true;
      _loginSuccess = false;
      _calculatedPassword = null;
      _jwtToken = null;
      _usedSSID = _useDefaultSSID ? defaultSSID : null;
      _serialNumber = _useSystemInfo ? null : _serialNumberController.text;
      _salt = null;
      _systemInfo = null;
      _loginResponse = null;
      _updateStatus("正在計算初始密碼...");
    });

    _addLog('開始計算初始密碼...');

    try {
      // 從輸入框獲取值，優先使用預設SSID
      final String? providedSSID = _useDefaultSSID
          ? defaultSSID
          : (_ssidController.text.isNotEmpty ? _ssidController.text : null);

      final String? serialNumber = _useSystemInfo || _serialNumberController.text.isEmpty
          ? null
          : _serialNumberController.text;

      final String? loginSalt = _useSystemInfo || _saltController.text.isEmpty
          ? null
          : _saltController.text;

      _addLog('使用提供的 SSID: $providedSSID');

      if (serialNumber != null) {
        _addLog('使用提供的序號: $serialNumber');
      } else {
        _addLog('未提供序號，將從系統資訊獲取');
      }

      if (loginSalt != null) {
        _addLog('使用提供的 Salt: $loginSalt');
      } else {
        _addLog('未提供 Salt，將從系統資訊獲取');
      }

      // 如果需要從系統獲取參數，先獲取系統資訊
      if (_useSystemInfo || serialNumber == null || loginSalt == null) {
        _addLog('\n步驟 1: 獲取系統資訊...');
        final systemInfo = await WifiApiService.getSystemInfo();
        _systemInfo = systemInfo;

        _addLog('系統資訊:');
        systemInfo.forEach((key, value) {
          _addLog('  $key: $value');
        });

        // 保存序號和Salt以供顯示
        _serialNumber = serialNumber ?? systemInfo['serial_number'];
        _salt = loginSalt ?? systemInfo['login_salt'];
      } else {
        _serialNumber = serialNumber;
        _salt = loginSalt;
      }

      // 計算密碼
      _addLog('\n步驟 2: 計算初始密碼...');
      final password = await WifiApiService.calculateInitialPassword(
        providedSSID: providedSSID,
        serialNumber: _serialNumber,
        loginSalt: _salt,
      );

      setState(() {
        isLoading = false;
        _calculatedPassword = password;
        // 保存使用的SSID
        _usedSSID = providedSSID;
      });

      _updateStatus("密碼計算完成！");
      _addLog('計算得到的密碼: $password');

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _updateStatus("計算密碼過程中發生錯誤");
      _addLog('計算密碼錯誤: $e');
    }
  }

  // 執行一鍵登入測試
  Future<void> _performFirstLogin() async {
    // 重置狀態
    setState(() {
      logs = [];
      isLoading = true;
      isCalculatingOnly = false;
      _loginSuccess = false;
      _calculatedPassword = null;
      _jwtToken = null;
      _usedSSID = _useDefaultSSID ? defaultSSID : null;
      _serialNumber = _useSystemInfo ? null : _serialNumberController.text;
      _salt = null;
      _systemInfo = null;
      _loginResponse = null;
      _updateStatus("正在執行首次登入流程...");
    });

    _addLog('開始執行首次登入流程...');

    try {
      // 從輸入框獲取值，優先使用預設SSID
      final String? providedSSID = _useDefaultSSID
          ? defaultSSID
          : (_ssidController.text.isNotEmpty ? _ssidController.text : null);

      final String username = _usernameController.text.isNotEmpty ? _usernameController.text : 'admin';

      final String? serialNumber = _useSystemInfo || _serialNumberController.text.isEmpty
          ? null
          : _serialNumberController.text;

      final String? loginSalt = _useSystemInfo || _saltController.text.isEmpty
          ? null
          : _saltController.text;

      _addLog('使用提供的 SSID: $providedSSID');

      if (serialNumber != null) {
        _addLog('使用提供的序號: $serialNumber');
      } else {
        _addLog('未提供序號，將從系統資訊獲取');
      }

      if (loginSalt != null) {
        _addLog('使用提供的 Salt: $loginSalt');
      } else {
        _addLog('未提供 Salt，將從系統資訊獲取');
      }

      _addLog('使用的用戶名: $username');

      // 調用一鍵登入 API
      _addLog('\n步驟 1: 獲取系統資訊...');

      // 如果使用了手動設置的參數，我們需要先計算密碼然後手動登入
      if (!_useSystemInfo && (serialNumber != null || loginSalt != null)) {
        // 獲取系統資訊，可能依然需要獲取一些未指定的參數
        final systemInfo = await WifiApiService.getSystemInfo();
        _systemInfo = systemInfo;

        _serialNumber = serialNumber ?? systemInfo['serial_number'];
        _salt = loginSalt ?? systemInfo['login_salt'];

        // 計算密碼
        _addLog('\n步驟 2: 計算初始密碼...');
        final password = await WifiApiService.calculateInitialPassword(
          providedSSID: providedSSID,
          serialNumber: _serialNumber,
          loginSalt: _salt,
        );
        _calculatedPassword = password;

        // 保存使用的SSID
        _usedSSID = providedSSID;

        _addLog('計算得到的密碼: $password');

        // 進行登入
        _addLog('\n步驟 3: 嘗試登入...');
        final loginData = {
          'user': username,
          'password': password,
        };

        final loginResponse = await WifiApiService.call('postUserLogin', loginData);
        _loginResponse = loginResponse;

        // 檢查登入是否成功
        bool loginSuccess = false;
        String message = '登入失敗';

        if (loginResponse.containsKey('token')) {
          loginSuccess = true;
          message = '登入成功，獲取到 JWT 令牌';
          WifiApiService.setJwtToken(loginResponse['token']);
          _jwtToken = loginResponse['token'];
        } else if (loginResponse.containsKey('jwt')) {
          loginSuccess = true;
          message = '登入成功，獲取到 JWT 令牌';
          WifiApiService.setJwtToken(loginResponse['jwt']);
          _jwtToken = loginResponse['jwt'];
        } else if (loginResponse.containsKey('status') && loginResponse['status'] == 'success') {
          loginSuccess = true;
          message = '登入成功';
        }

        setState(() {
          isLoading = false;
          _loginSuccess = loginSuccess;
        });

        _updateStatus(loginSuccess ? "登入成功！" : "登入失敗: $message");

        if (loginSuccess) {
          _addLog('登入成功!');
          if (_jwtToken != null) {
            _addLog('獲取到 JWT 令牌');
          }
        } else {
          _addLog('登入失敗: $message');
        }
      } else {
        // 使用標準的一鍵登入流程
        final result = await WifiApiService.performFirstLogin(
          providedSSID: providedSSID,
          username: username,
        );

        // 保存和顯示結果
        setState(() {
          isLoading = false;
          _loginSuccess = result.success;
          _calculatedPassword = result.calculatedPassword;
          _jwtToken = result.jwtToken;
          _systemInfo = result.systemInfo;
          _loginResponse = result.loginResponse;

          // 保存序號和Salt以供顯示
          if (result.systemInfo != null) {
            _serialNumber = result.systemInfo!['serial_number'];
            _salt = result.systemInfo!['login_salt'];
          }

          // 保存使用的SSID
          _usedSSID = providedSSID;
        });

        _updateStatus(result.success ? "登入成功！" : "登入失敗: ${result.message}");

        // 記錄詳細過程
        _addLog('\n步驟 2: 計算初始密碼...');
        if (result.calculatedPassword != null) {
          _addLog('計算得到的密碼: ${result.calculatedPassword}');
        } else {
          _addLog('密碼計算失敗');
        }

        _addLog('\n步驟 3: 嘗試登入...');
        if (result.success) {
          _addLog('登入成功!');
          if (result.jwtToken != null) {
            _addLog('獲取到 JWT 令牌');
          }
        } else {
          _addLog('登入失敗: ${result.message}');
        }
      }

      // 記錄詳細的回應數據
      if (_systemInfo != null) {
        _addLog('\n系統資訊:');
        _systemInfo!.forEach((key, value) {
          _addLog('  $key: $value');
        });
      }

      if (_loginResponse != null) {
        _addLog('\n登入回應:');
        _loginResponse!.forEach((key, value) {
          _addLog('  $key: $value');
        });
      }

    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _updateStatus("執行過程中發生錯誤");
      _addLog('執行過程中發生錯誤: $e');
    }
  }

  // 使用計算好的密碼進行SRP登入測試
  void _testSrpLoginWithPassword() {
    if (_calculatedPassword == null || _calculatedPassword!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先計算密碼')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SrpLoginModifiedTestPage.withPassword(_calculatedPassword!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首次登入一鍵測試'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 狀態顯示
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              color: _calculatedPassword != null
                  ? (_loginSuccess ? Colors.green[100] : Colors.orange[100])
                  : Colors.blue[50],
              child: Column(
                children: [
                  Icon(
                    _calculatedPassword != null
                        ? (_loginSuccess ? Icons.check_circle : Icons.info)
                        : Icons.info,
                    size: 50,
                    color: _calculatedPassword != null
                        ? (_loginSuccess ? Colors.green : Colors.orange)
                        : Colors.blue,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _calculatedPassword != null
                          ? (_loginSuccess ? Colors.green[800] : Colors.orange[800])
                          : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // 輸入表單及結果
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '測試選項',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAdvancedOptions = !_showAdvancedOptions;
                          });
                        },
                        child: Text(
                          _showAdvancedOptions ? '隱藏高級選項' : '顯示高級選項',
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // SSID 選項
                  Row(
                    children: [
                      Checkbox(
                        value: _useDefaultSSID,
                        onChanged: (value) {
                          setState(() {
                            _useDefaultSSID = value ?? true;
                            if (_useDefaultSSID) {
                              _ssidController.text = defaultSSID;
                            }
                          });
                        },
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _useDefaultSSID = !_useDefaultSSID;
                              if (_useDefaultSSID) {
                                _ssidController.text = defaultSSID;
                              }
                            });
                          },
                          child: Text('使用預設 SSID: $defaultSSID'),
                        ),
                      ),
                    ],
                  ),

                  // 自訂 SSID 輸入框 (根據選項顯示)
                  if (!_useDefaultSSID) ...[
                    const SizedBox(height: 8),
                    const Text('SSID', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ssidController,
                      decoration: const InputDecoration(
                        hintText: '輸入自訂 SSID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // 用戶名
                  const Text('用戶名', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: 'admin',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 高級選項 (可收起)
                  if (_showAdvancedOptions) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _useSystemInfo,
                                onChanged: (value) {
                                  setState(() {
                                    _useSystemInfo = value ?? true;
                                    if (!_useSystemInfo) {
                                      _serialNumberController.text = defaultDeviceModel;
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _useSystemInfo = !_useSystemInfo;
                                      if (!_useSystemInfo) {
                                        _serialNumberController.text = defaultDeviceModel;
                                      }
                                    });
                                  },
                                  child: const Text('使用系統提供的參數 (序號和Salt)'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (!_useSystemInfo) ...[
                            // 序號輸入
                            const Text('序號', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _serialNumberController,
                              decoration: const InputDecoration(
                                hintText: '設備序號',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Salt 輸入
                            const Text('Salt (可選)', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _saltController,
                              decoration: const InputDecoration(
                                hintText: '登入鹽值 (如果留空將從系統獲取)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 執行測試按鈕
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _calculatePasswordOnly,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: isLoading && isCalculatingOnly
                                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                : const Text('只計算密碼', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _performFirstLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: isLoading && !isCalculatingOnly
                                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                : const Text('一鍵登入測試', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 如果計算了密碼，顯示結果
                  if (_calculatedPassword != null) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _loginSuccess ? Colors.green[50] : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _loginSuccess ? Colors.green : Colors.orange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _loginSuccess ? '登入成功！' : '密碼計算完成',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _loginSuccess ? Colors.green : Colors.orange[800],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('使用的 SSID: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(_usedSSID ?? 'UNKNOWN', style: const TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          if (_serialNumber != null) ...[
                            Row(
                              children: [
                                const Text('序號: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(_serialNumber!, style: const TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                          ],
                          if (_salt != null) ...[
                            Row(
                              children: [
                                const Text('Salt: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(_salt!,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                          ],
                          Row(
                            children: [
                              const Text('用戶名: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(_usernameController.text, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Text('密碼: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Expanded(
                                child: SelectableText(
                                  _calculatedPassword ?? '未獲取到密碼',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_jwtToken != null) ...[
                            const SizedBox(height: 10),
                            const Text('JWT Token: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            SelectableText(
                              _jwtToken!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],

                          // 如果只計算了密碼，提供進行SRP登入測試的按鈕
                          if (!_loginSuccess && _calculatedPassword != null) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _testSrpLoginWithPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('使用此密碼測試SRP登入'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 測試日誌標題
                  const Text(
                    '測試日誌',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // 日誌區域
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(8),
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(5),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Text(
                  logs.join('\n'),
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
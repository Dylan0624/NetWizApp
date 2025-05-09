import 'package:flutter/material.dart';
import 'package:whitebox/shared/api/login_process.dart'; // 引入登入處理類
import 'dart:convert'; // 用於 JSON 格式化
import 'dart:io'; // 用於 HTTP 請求

class SrpLoginModifiedTestPage extends StatefulWidget {
  final String initialPassword;

  const SrpLoginModifiedTestPage({Key? key}) : initialPassword = "", super(key: key);
  const SrpLoginModifiedTestPage.withPassword(this.initialPassword, {Key? key}) : super(key: key);

  @override
  State<SrpLoginModifiedTestPage> createState() => _SrpLoginModifiedTestPageState();
}

class _SrpLoginModifiedTestPageState extends State<SrpLoginModifiedTestPage> {
  String _statusMessage = "點擊按鈕開始測試";
  bool _isLoading = false;
  bool _loginSuccess = false;
  String _logOutput = "準備開始測試...";
  final _scrollController = ScrollController();

  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _baseUrlController;

  String _sessionId = "";
  String _csrfToken = "";

  // HttpClient 用於發送手動請求
  final HttpClient _httpClient = HttpClient();

  @override
  void initState() {
    super.initState();
    // 初始化控制器並設置初始值
    _usernameController = TextEditingController(text: "admin");
    _passwordController = TextEditingController(
        text: widget.initialPassword.isNotEmpty ? widget.initialPassword : "ceb81a924d4b2ece0f552a2a1d56c3c5cbfd864107a69c9a3acbde5e71727b9c"
    );
    _baseUrlController = TextEditingController(text: "http://192.168.1.1");

    if (widget.initialPassword.isNotEmpty) {
      _logAdd("已自動填入計算得到的密碼：${widget.initialPassword}");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  // 日誌輸出並滾動
  void _logAdd(String msg) {
    setState(() {
      _logOutput += "\n$msg";
    });

    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 更新狀態消息
  void _updateStatus(String status) {
    setState(() {
      _statusMessage = status;
    });
  }

  // 驗證表單
  bool _validateForm() {
    if (_usernameController.text.isEmpty) {
      _updateStatus("請輸入用戶名");
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _updateStatus("請輸入密碼");
      return false;
    }
    if (_baseUrlController.text.isEmpty) {
      _updateStatus("請輸入基本 URL");
      return false;
    }
    return true;
  }

  // 發送 HTTP 請求並記錄
  Future<String> _makeHttpRequest(String url, String method, {Map<String, String>? headers, Object? body}) async {
    _logAdd("\n===== 發送 HTTP 請求 =====");
    _logAdd("URL: $url");
    _logAdd("方法: $method");
    if (headers != null) {
      _logAdd("請求頭: ${jsonEncode(headers)}");
    }
    if (body != null) {
      _logAdd("請求體: ${body is String ? body : jsonEncode(body)}");
    }

    try {
      final request = await _httpClient.openUrl(method, Uri.parse(url));

      // 添加請求頭
      if (headers != null) {
        headers.forEach((key, value) {
          request.headers.set(key, value);
        });
      }

      // 添加請求體
      if (body != null) {
        request.headers.contentType = ContentType.json;
        if (body is String) {
          request.write(body);
        } else {
          request.write(jsonEncode(body));
        }
      }

      // 發送請求並獲取響應
      final response = await request.close();

      _logAdd("\n===== 收到 HTTP 響應 =====");
      _logAdd("狀態碼: ${response.statusCode}");
      _logAdd("響應頭:");
      response.headers.forEach((name, values) {
        _logAdd("  $name: $values");
      });

      // 讀取響應體
      final responseBody = await response.transform(utf8.decoder).join();

      try {
        // 嘗試格式化 JSON
        final jsonData = jsonDecode(responseBody);
        _logAdd("響應體(JSON):");
        _logAdd(const JsonEncoder.withIndent('  ').convert(jsonData));
      } catch (e) {
        // 不是 JSON，直接顯示
        _logAdd("響應體:");
        _logAdd(responseBody);
      }

      _logAdd("===== HTTP 響應結束 =====");

      return responseBody;
    } catch (e) {
      _logAdd("HTTP 請求錯誤: $e");
      rethrow;
    }
  }

  // 搜索 JWT 令牌
  void _searchForJwtInLogs() {
    _logAdd("\n===== 搜索可能的 JWT 令牌 =====");

    // JWT 格式的正則表達式 (修改為更寬鬆的匹配以捕獲各種格式)
    final RegExp jwtRegex = RegExp(r'[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}');

    // 搜索日誌中的所有匹配項
    final matches = jwtRegex.allMatches(_logOutput);

    if (matches.isEmpty) {
      _logAdd("未找到符合 JWT 格式的令牌");
    } else {
      _logAdd("找到 ${matches.length} 個可能的 JWT 令牌:");
      int tokenCount = 1;
      for (final match in matches) {
        final token = _logOutput.substring(match.start, match.end);
        _logAdd("令牌 $tokenCount: $token");
        tokenCount++;

        // 嘗試解碼 JWT
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            // 解碼頭部
            try {
              final normalizedHeader = _base64Normalize(parts[0]);
              final headerBytes = base64Decode(normalizedHeader);
              final headerJson = utf8.decode(headerBytes);
              _logAdd("  頭部解碼: $headerJson");
            } catch (e) {
              _logAdd("  頭部解碼失敗: $e");
            }

            // 解碼載荷
            try {
              final normalizedPayload = _base64Normalize(parts[1]);
              final payloadBytes = base64Decode(normalizedPayload);
              final payloadJson = utf8.decode(payloadBytes);
              _logAdd("  載荷解碼: $payloadJson");
            } catch (e) {
              _logAdd("  載荷解碼失敗: $e");
            }
          }
        } catch (e) {
          _logAdd("  解碼失敗: $e");
        }
      }
    }

    // 嘗試查找其他認證相關信息
    _searchForAuthTokens();
  }

  // 搜索其他可能的認證令牌
  void _searchForAuthTokens() {
    _logAdd("\n===== 搜索其他認證令牌 =====");

    // 搜索常見的認證令牌關鍵字
    final tokenKeywords = [
      "token", "auth", "bearer", "access_token", "id_token",
      "refresh_token", "session", "sessionid", "csrf"
    ];

    for (final keyword in tokenKeywords) {
      // 修正正則表達式
      final RegExp regex = RegExp('"$keyword"\\s*:\\s*"[^"]*"', caseSensitive: false);
      final matches = regex.allMatches(_logOutput);

      if (matches.isNotEmpty) {
        _logAdd("找到關鍵字 '$keyword' 的匹配:");
        for (final match in matches) {
          final fullMatch = _logOutput.substring(match.start, match.end);
          _logAdd("  $fullMatch");
        }
      }
    }
  }

  // 標準化 base64 以便解碼
  String _base64Normalize(String input) {
    String output = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      case 1:
        output += '===';
        break;
    }
    return output;
  }

  // 開始 SRP 登入流程
  Future<void> startSRPLoginProcess() async {
    if (_isLoading) return;
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
      _loginSuccess = false;
      _logOutput = "開始 SRP 登入流程...";
      _sessionId = "";
      _csrfToken = "";
    });

    try {
      // 獲取輸入參數
      final username = _usernameController.text;
      final password = _passwordController.text;
      final baseUrl = _baseUrlController.text;

      _logAdd("使用以下參數:");
      _logAdd("用戶名: $username");
      _logAdd("密碼: $password");
      _logAdd("基礎 URL: $baseUrl");

      // 捕獲 Flutter 錯誤
      FlutterError.onError = (FlutterErrorDetails details) {
        _logAdd("Flutter 錯誤: ${details.exception}");
      };

      // 記錄開始時間
      final startTime = DateTime.now();
      _logAdd("開始時間: $startTime");

      // 嘗試發送手動測試請求
      try {
        await _makeHttpRequest("$baseUrl/api/v1/login/params?username=$username", "GET");
      } catch (e) {
        _logAdd("測試請求失敗: $e");
      }

      // 開始登入流程
      _updateStatus("正在執行 SRP 登入流程...");
      _logAdd("\n===== 開始 SRP 登入流程 =====");

      // 創建 LoginProcess 實例
      final loginProcess = LoginProcess(username, password, baseUrl: baseUrl);

      // 調用 LoginProcess 中的 startSRPLoginProcess 方法
      final loginResult = await loginProcess.startSRPLoginProcess();

      // 記錄結束時間
      final endTime = DateTime.now();
      _logAdd("結束時間: $endTime");
      _logAdd("用時: ${endTime.difference(startTime).inMilliseconds} 毫秒");

      // 處理登入結果
      if (loginResult.returnStatus) {
        _updateStatus("登入成功！");
        _logAdd("\n===== 登入成功 =====");
        _logAdd("會話 ID: ${loginResult.session.sessionId}");
        _logAdd("CSRF 令牌: ${loginResult.session.csrfToken}");

        // 記錄完整的響應結果
        _logAdd("\n===== 完整響應結果 =====");
        _logAdd("會話 ID: ${loginResult.session.sessionId}");
        _logAdd("CSRF 令牌: ${loginResult.session.csrfToken}");
        _logAdd("返回狀態: ${loginResult.returnStatus}");
        _logAdd("消息: ${loginResult.msg}");

        // 嘗試記錄響應對象的所有屬性
        _logAdd("\n===== 響應對象屬性 =====");
        try {
          final props = loginResult.toString();
          _logAdd("對象字符串表示: $props");
        } catch (e) {
          _logAdd("獲取對象屬性失敗: $e");
        }

        setState(() {
          _loginSuccess = true;
          _sessionId = loginResult.session.sessionId;
          _csrfToken = loginResult.session.csrfToken;
        });

        // 搜索日誌中可能的 JWT 令牌
        _searchForJwtInLogs();

        // 登入成功後，嘗試獲取其他可能的 API 響應
        _logAdd("\n===== 嘗試獲取附加 API 響應 =====");
        try {
          await _makeHttpRequest("$baseUrl/api/v1/device/info", "GET",
              headers: {
                "Cookie": "sessionid=${loginResult.session.sessionId}",
                "X-CSRF-Token": loginResult.session.csrfToken
              }
          );
          _logAdd("獲取設備信息成功");
        } catch (e) {
          _logAdd("獲取設備信息失敗: $e");
        }
      } else {
        _updateStatus("登入失敗: ${loginResult.msg}");
        _logAdd("\n===== 登入失敗 =====");
        _logAdd("失敗原因: ${loginResult.msg}");
      }
    } catch (e) {
      _updateStatus("登入過程出錯: ${e.toString().split('\n')[0]}");
      _logAdd("\n===== 登入過程中發生錯誤 =====");
      _logAdd("錯誤詳情: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });

      // 搜索日誌中可能的 JWT 令牌和其他認證信息（無論成功失敗）
      _searchForJwtInLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SRP 登入測試 (記錄回傳)'),
        backgroundColor: Colors.blue,
        actions: [
          // 添加清除日誌按鈕
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            tooltip: '清除日誌',
            onPressed: () {
              setState(() {
                _logOutput = "日誌已清除...";
              });
            },
          ),
          // 添加複製日誌按鈕
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '複製日誌',
            onPressed: () {
              // 使用剪貼板複製功能
              // Clipboard.setData(ClipboardData(text: _logOutput));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('日誌已複製到剪貼板'))
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 狀態顯示
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              color: _loginSuccess ? Colors.green[100] : Colors.blue[50],
              child: Column(
                children: [
                  Icon(
                    _loginSuccess ? Icons.check_circle : Icons.info,
                    size: 50,
                    color: _loginSuccess ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _loginSuccess ? Colors.green[800] : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // 輸入表單
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('基本 URL', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _baseUrlController,
                    decoration: const InputDecoration(
                      hintText: 'http://192.168.1.1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('用戶名', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      hintText: '用戶名',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text('密碼', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: '密碼',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : startSRPLoginProcess,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                          : const Text('執行 SRP 登入測試', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),

            // 如果登入成功，顯示會話信息
            if (_loginSuccess) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '會話信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('會話 ID: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: SelectableText(_sessionId),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Text('CSRF 令牌: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: SelectableText(_csrfToken),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 日誌輸出（增加高度使其顯示更多內容）
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(8),
              height: 400, // 增加高度
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: SelectableText( // 使用 SelectableText 以便於複製
                        _logOutput,
                        style: const TextStyle(
                          color: Colors.green,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
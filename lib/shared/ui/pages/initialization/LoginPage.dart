import 'package:flutter/material.dart';
import 'package:whitebox/shared/theme/app_theme.dart';
import 'package:whitebox/shared/api/wifi_api_service.dart';

class LoginPage extends StatefulWidget {
  final Function()? onLoginSuccess;
  final Function()? onBackPressed;
  final bool showBackButton;
  final String fixedAccount; // 添加固定帳號參數

  const LoginPage({
    Key? key,
    this.onLoginSuccess,
    this.onBackPressed,
    this.showBackButton = true,
    this.fixedAccount = 'admin', // 默認為 'admin'
  }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AppTheme _appTheme = AppTheme();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 焦點節點
  final FocusNode _passwordFocusNode = FocusNode();

  bool _passwordVisible = false;
  bool _isPasswordError = false;
  bool _isFormValid = false;

  // ===== 所有比例參數 =====
  // 整體布局
  final double _topSpaceRatio = 0.06; // 頂部空白高度比例
  final double _titleHeightRatio = 0.05; // 標題高度比例
  final double _titleSpaceRatio = 0.03; // 標題下方間距比例
  final double _cardHeightRatio = 0.40; // 卡片高度比例
  final double _cardToButtonSpaceRatio = 0.15; // 卡片到按鈕的間距比例

  // 卡片內部
  final double _cardPaddingRatio = 0.05; // 卡片內部邊距比例
  final double _userTitleToAccountSpaceRatio = 0.025; // User標題到Account間的間距比例
  final double _inputFieldsSpaceRatio = 0.025; // 輸入框之間的間距比例
  final double _labelToInputSpaceRatio = 0.008; // 標籤到輸入框的間距比例
  final double _inputExtraBottomSpaceRatio = 0.015; // 輸入框底部額外間距比例

  // 輸入框尺寸
  final double _inputFieldHeightRatio = 0.06; // 輸入框高度比例

  // 文字大小
  final double _mainTitleFontSize = 28.0; // 主標題字體大小
  final double _userTitleFontSize = 24.0; // User標題字體大小
  final double _labelFontSize = 18.0; // 標籤字體大小
  final double _inputTextFontSize = 16.0; // 輸入框文字大小
  final double _errorTextFontSize = 12.0; // 錯誤提示文字大小

  // 按鈕相關
  final double _buttonHeightRatio = 0.07; // 按鈕高度比例
  final double _buttonSpacingRatio = 0.02; // 按鈕間距比例
  final double _bottomMarginRatio = 0.02; // 底部邊距比例
  final double _horizontalPaddingRatio = 0.05; // 水平邊距比例
  final double _buttonBorderRadius = 8.0; // 按鈕圓角
  final double _buttonTextFontSize = 18.0; // 按鈕文字大小

  // 圖標尺寸
  final double _visibilityIconSize = 25.0; // 可見性圖標大小

  @override
  void initState() {
    super.initState();

    // 初始化時設定固定帳號
    _accountController.text = widget.fixedAccount;

    _passwordController.addListener(() {
      _validatePassword();
      _validateForm();
    });

    // 添加焦點監聽
    _passwordFocusNode.addListener(_handlePasswordFocus);

    // 初始化後檢查表單是否有效
    _validateForm();
  }

  @override
  void dispose() {
    _passwordFocusNode.removeListener(_handlePasswordFocus);
    _passwordFocusNode.dispose();
    _scrollController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 處理密碼輸入框獲得焦點
  void _handlePasswordFocus() {
    if (_passwordFocusNode.hasFocus) {
      // 延遲執行，確保鍵盤已完全彈出
      Future.delayed(Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          // 滾動到合適的位置
          _scrollController.animateTo(
            80.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _validatePassword() {
    // 驗證密碼
    final password = _passwordController.text;
    setState(() {
      _isPasswordError = password.isEmpty;
    });
  }

  void _validateForm() {
    // 驗證表單，帳號已固定，只需檢查密碼
    setState(() {
      _isFormValid = _passwordController.text.isNotEmpty;
    });
  }

  void _handleLogin() async {
    if (!_isFormValid) {
      // 如果表單無效，顯示提示
      _validatePassword();
      return;
    }

    // 顯示載入提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logging in...')),
    );

    try {
      // 使用 SRP 登入，傳入固定帳號和使用者輸入的密碼
      final loginResult = await WifiApiService.loginWithSRP(
        widget.fixedAccount, // 使用固定的帳號
        _passwordController.text, // 使用者輸入的密碼
      );

      // 處理登入結果
      if (loginResult.success) {
        // 儲存 JWT 令牌（如果需要）
        if (loginResult.jwtToken != null) {
          WifiApiService.setJwtToken(loginResult.jwtToken!);
        }

        // 呼叫 onLoginSuccess 回調
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        } else {
          // 如果沒有提供回調，顯示成功提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login successful: ${loginResult.message}')),
          );
        }
      } else {
        // 顯示錯誤提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${loginResult.message}')),
        );
        setState(() {
          _isPasswordError = true;
        });
      }
    } catch (e) {
      // 處理異常
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
      setState(() {
        _isPasswordError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: screenSize.width,
            height: screenSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // 整體垂直居中
              children: [
                // 標題
                Container(
                  height: screenSize.height * _titleHeightRatio,
                  alignment: Alignment.center,
                  child: Text(
                    "Account",
                    style: TextStyle(
                      fontSize: _mainTitleFontSize,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: screenSize.height * _titleSpaceRatio),

                // 中間區域 - 使用 StandardCard，占總高度的比例
                _appTheme.whiteBoxTheme.buildStandardCard(
                  width: screenSize.width * 0.9,
                  height: screenSize.height * _cardHeightRatio,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: EdgeInsets.all(screenSize.width * _cardPaddingRatio),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User 標籤
                          Text(
                            "User",
                            style: TextStyle(
                              fontSize: _userTitleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          SizedBox(height: screenSize.height * _userTitleToAccountSpaceRatio),

                          // Account 標籤和輸入框（固定並禁用）
                          _buildDisabledUserField(),

                          SizedBox(height: screenSize.height * _inputFieldsSpaceRatio),

                          // Password 標籤和輸入框
                          _buildLabelWithPasswordField(
                            label: 'Password',
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            isVisible: _passwordVisible,
                            isError: _isPasswordError,
                            errorText: 'Please enter password',
                            labelFontSize: _labelFontSize,
                            errorFontSize: _errorTextFontSize,
                            labelToInputSpace: screenSize.height * _labelToInputSpaceRatio,
                            inputHeight: screenSize.height * _inputFieldHeightRatio,
                            iconSize: _visibilityIconSize,
                            onVisibilityChanged: (visible) {
                              setState(() {
                                _passwordVisible = visible;
                              });
                            },
                          ),

                          // 給鍵盤彈出時的額外空間
                          SizedBox(height: screenSize.height * _inputExtraBottomSpaceRatio),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenSize.height * _cardToButtonSpaceRatio), // 卡片與按鈕之間的間距

                // 底部導航按鈕
                _buildNavigationButtons(
                  buttonHeight: screenSize.height * _buttonHeightRatio,
                  buttonSpacing: screenSize.width * _buttonSpacingRatio,
                  horizontalPadding: screenSize.width * _horizontalPaddingRatio,
                  buttonBorderRadius: _buttonBorderRadius,
                  buttonTextFontSize: _buttonTextFontSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 構建導航按鈕
  Widget _buildNavigationButtons({
    required double buttonHeight,
    required double buttonSpacing,
    required double horizontalPadding,
    required double buttonBorderRadius,
    required double buttonTextFontSize,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 返回按鈕使用紫色邊框樣式
          if (widget.showBackButton)
            Expanded(
              child: GestureDetector(
                onTap: widget.onBackPressed,
                child: Container(
                  width: double.infinity,
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(buttonBorderRadius),
                    color: AppColors.primary.withOpacity(0.2),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Back',
                      style: TextStyle(
                        fontSize: buttonTextFontSize,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (widget.showBackButton)
            SizedBox(width: buttonSpacing),

          // 下一步按鈕
          Expanded(
            child: GestureDetector(
              onTap: _handleLogin,
              child: _appTheme.whiteBoxTheme.buildSimpleColorButton(
                width: double.infinity,
                height: buttonHeight,
                borderRadius: BorderRadius.circular(buttonBorderRadius),
                child: Center(
                  child: Text(
                    'Next',
                    style: TextStyle(
                      fontSize: buttonTextFontSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 構建固定且禁用的帳號輸入框
  Widget _buildDisabledUserField() {
    final screenSize = MediaQuery.of(context).size;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: TextStyle(
            fontSize: _labelFontSize,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),

        SizedBox(height: screenSize.height * _labelToInputSpaceRatio),

        // 使用自定義的輸入框，設置為禁用狀態
        CustomTextField(
          width: double.infinity,
          height: screenSize.height * _inputFieldHeightRatio,
          controller: _accountController,
          enabled: false, // 禁用輸入
          borderColor: AppColors.primary,
          borderOpacity: 0.7,
          backgroundColor: Colors.grey, // 使用灰色背景
          backgroundOpacity: 0.3, // 降低透明度，使其看起來更像禁用狀態
          enableBlur: false, // 不使用模糊效果
          textStyle: TextStyle(
            fontSize: _inputTextFontSize,
            color: Colors.grey[400], // 使用灰色文字
          ),
        ),
      ],
    );
  }

  // 構建帶標籤的密碼輸入框
  Widget _buildLabelWithPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isVisible,
    required bool isError,
    required String errorText,
    required Function(bool) onVisibilityChanged,
    required double labelFontSize,
    required double errorFontSize,
    required double labelToInputSpace,
    required double inputHeight,
    required double iconSize,
    FocusNode? focusNode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標籤
        Text(
          label,
          style: TextStyle(
            fontSize: labelFontSize,
            fontWeight: FontWeight.normal,
            color: isError ? AppColors.error : Colors.white,
          ),
        ),

        SizedBox(height: labelToInputSpace),

        // 輸入框
        Container(
          width: double.infinity,
          height: inputHeight,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border.all(
              color: isError ? AppColors.error : AppColors.primary,
              width: 1.0,
            ),
          ),
          child: Stack(
            children: [
              TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: !isVisible,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontSize: _inputTextFontSize,
                  color: Colors.white,
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: isError ? AppColors.error : Colors.white,
                      size: iconSize,
                    ),
                    onPressed: () {
                      onVisibilityChanged(!isVisible);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // 錯誤提示
        if (isError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorText,
              style: TextStyle(
                fontSize: errorFontSize,
                color: AppColors.error,
              ),
            ),
          ),
      ],
    );
  }
}
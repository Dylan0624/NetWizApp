import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:whitebox/shared/ui/components/basic/StepperComponent.dart';
import 'package:whitebox/shared/ui/components/basic/AccountPasswordComponent.dart';
import 'package:whitebox/shared/ui/components/basic/ConnectionTypeComponent.dart';
import 'package:whitebox/shared/ui/components/basic/SetSSIDComponent.dart';
import 'package:whitebox/shared/ui/components/basic/SummaryComponent.dart';
import 'package:whitebox/shared/ui/components/basic/FinishingWizardComponent.dart';
import 'package:whitebox/shared/ui/pages/initialization/InitializationPage.dart';
import 'package:whitebox/shared/models/StaticIpConfig.dart';

class WifiSettingFlowPage extends StatefulWidget {
  const WifiSettingFlowPage({super.key});

  @override
  State<WifiSettingFlowPage> createState() => _WifiSettingFlowPageState();
}

class _WifiSettingFlowPageState extends State<WifiSettingFlowPage> {
  // 基本設定
  String currentModel = 'Micky';
  int currentStepIndex = 0;
  bool isLastStepCompleted = false;
  bool isShowingFinishingWizard = false;
  bool isLoading = true;
  bool isCurrentStepComplete = false;
  bool _isUpdatingStep = false;

  // 省略號動畫
  String _ellipsis = '';
  late Timer _ellipsisTimer;

  // 表單狀態
  Map<String, dynamic> stepsConfig = {};
  StaticIpConfig staticIpConfig = StaticIpConfig();
  String userName = '';
  String password = '';
  String confirmPassword = '';
  String connectionType = 'DHCP';
  String ssid = '';
  String securityOption = 'WPA3 Personal';
  String ssidPassword = '';
  String pppoeUsername = '';
  String pppoePassword = '';

  // 控制器
  late PageController _pageController;
  final StepperController _stepperController = StepperController();

  // 完成精靈的步驟名稱
  final List<String> _processNames = [
    'Process 01', 'Process 02', 'Process 03', 'Process 04', 'Process 05',
  ];

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _pageController = PageController(initialPage: currentStepIndex);
    _stepperController.addListener(_onStepperControllerChanged);
    _startEllipsisAnimation();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stepperController.removeListener(_onStepperControllerChanged);
    _stepperController.dispose();
    _ellipsisTimer.cancel();
    super.dispose();
  }

  // 省略號動畫
  void _startEllipsisAnimation() {
    _ellipsisTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _ellipsis = _ellipsis.length < 3 ? _ellipsis + '.' : '';
      });
    });
  }

  // 步驟控制器監聽
  void _onStepperControllerChanged() {
    if (_isUpdatingStep) return;

    final newStep = _stepperController.currentStep;
    if (newStep != currentStepIndex) {
      _isUpdatingStep = true;
      setState(() {
        currentStepIndex = newStep;
        isCurrentStepComplete = false;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(newStep);
        }
      });
      _isUpdatingStep = false;
    }
  }

  // 載入配置
  Future<void> _loadConfig() async {
    try {
      setState(() => isLoading = true);

      final String configPath = 'lib/shared/config/flows/initialization/wifi.json';
      final String jsonContent = await rootBundle.loadString(configPath);

      setState(() {
        stepsConfig = json.decode(jsonContent);
        isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _syncStepperState());
    } catch (e) {
      print('載入配置出錯: $e');
      setState(() {
        isLoading = false;
        stepsConfig = {};
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _showErrorDialog());
    }
  }

  // 顯示錯誤對話框
  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('配置載入失敗'),
          content: const Text('無法載入設定流程，請確認 wifi.json 檔案是否存在並格式正確。'),
          actions: <Widget>[
            TextButton(
              child: const Text('確定'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  // 同步 Stepper 狀態
  void _syncStepperState() {
    _isUpdatingStep = true;
    _stepperController.jumpToStep(currentStepIndex);
    _isUpdatingStep = false;
  }

  // 更新當前步驟
  void _updateCurrentStep(int stepIndex) {
    if (_isUpdatingStep || stepIndex == currentStepIndex) return;

    _isUpdatingStep = true;
    setState(() {
      currentStepIndex = stepIndex;
      isCurrentStepComplete = false;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          stepIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
      if (stepIndex < _getCurrentModelSteps().length - 1) {
        isLastStepCompleted = false;
      }
    });

    _stepperController.jumpToStep(stepIndex);
    _isUpdatingStep = false;
  }

  // 處理表單變更
  void _handleFormChanged(String user, String pwd, String confirmPwd, bool isValid) {
    setState(() {
      userName = user;
      password = pwd;
      confirmPassword = confirmPwd;
      isCurrentStepComplete = isValid;
    });
  }

  // 驗證表單
  bool _validateForm() {
    List<String> detailOptions = _getStepDetailOptions();

    if (detailOptions.isEmpty) {
      detailOptions = ['User', 'Password', 'Confirm Password'];
    }

    if (detailOptions.contains('User') && userName.isEmpty) {
      return false;
    }

    if (detailOptions.contains('Password')) {
      if (password.isEmpty || password.length < 8 || password.length > 32) {
        return false;
      }

      final RegExp validChars = RegExp(r'^[\x21\x23-\x2F\x30-\x39\x3A-\x3B\x3D\x3F-\x40\x41-\x5A\x5B\x5D-\x60\x61-\x7A\x7B-\x7E]+$');
      if (!validChars.hasMatch(password)) {
        return false;
      }
    }

    if (detailOptions.contains('Confirm Password') &&
        (confirmPassword.isEmpty || confirmPassword != password)) {
      return false;
    }

    return true;
  }

  // 獲取當前步驟詳細選項
  List<String> _getStepDetailOptions() {
    List<String> detailOptions = [];
    final steps = _getCurrentModelSteps();

    if (steps.isNotEmpty && currentStepIndex < steps.length) {
      var currentStep = steps[currentStepIndex];
      if (currentStep.containsKey('detail')) {
        detailOptions = List<String>.from(currentStep['detail']);
      }
    }

    return detailOptions;
  }

  // 處理連接類型變更
  void _handleConnectionTypeChanged(String type, bool isComplete, StaticIpConfig? config, PPPoEConfig? pppoeConfig) {
    setState(() {
      connectionType = type;
      isCurrentStepComplete = isComplete;

      if (config != null) {
        staticIpConfig = config;
      }

      if (pppoeConfig != null) {
        pppoeUsername = pppoeConfig.username;
        pppoePassword = pppoeConfig.password;
      }
    });
  }

  // 處理 SSID 表單變更
  void _handleSSIDFormChanged(String newSsid, String newSecurityOption, String newPassword, bool isValid) {
    setState(() {
      ssid = newSsid;
      securityOption = newSecurityOption;
      ssidPassword = newPassword;
      isCurrentStepComplete = isValid;
    });
  }

  // 處理下一步操作
  void _handleNext() {
    final steps = _getCurrentModelSteps();
    if (steps.isEmpty) return;
    final currentComponents = _getCurrentStepComponents();

    // 只對非最後一步進行表單驗證
    if (currentStepIndex < steps.length - 1) {
      if (!_validateCurrentStep(currentComponents)) {
        return;
      }

      _isUpdatingStep = true;
      setState(() {
        currentStepIndex++;
        isCurrentStepComplete = false;
      });
      _stepperController.jumpToStep(currentStepIndex);
      _pageController.animateToPage(
        currentStepIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _isUpdatingStep = false;
    }
    // 最後一步（摘要頁）不需要驗證，直接進入完成精靈
    else if (currentStepIndex == steps.length - 1 && !isLastStepCompleted) {
      _isUpdatingStep = true;
      setState(() {
        isLastStepCompleted = true;
        isShowingFinishingWizard = true;
      });
      _stepperController.jumpToStep(currentStepIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _stepperController.notifyListeners();
      });
      _isUpdatingStep = false;
    }
  }

  // 驗證當前步驟
  bool _validateCurrentStep(List<String> currentComponents) {
    // 檢查 AccountPasswordComponent
    if (currentComponents.contains('AccountPasswordComponent')) {
      if (!_validateForm()) {
        List<String> detailOptions = _getStepDetailOptions();
        if (detailOptions.isEmpty) {
          detailOptions = ['User', 'Password', 'Confirm Password'];
        }

        String errorMessage = _getAccountPasswordError(detailOptions);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        return false;
      }
      setState(() {
        isCurrentStepComplete = true;
      });
    }

    // 檢查 ConnectionTypeComponent
    else if (currentComponents.contains('ConnectionTypeComponent')) {
      if (!isCurrentStepComplete) {
        String errorMessage = _getConnectionTypeError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        return false;
      }
    }

    // 檢查 SetSSIDComponent
    else if (currentComponents.contains('SetSSIDComponent')) {
      if (!isCurrentStepComplete) {
        String errorMessage = _getSSIDError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        return false;
      }
    }

    return true;
  }

  // 獲取帳戶密碼錯誤訊息
  String _getAccountPasswordError(List<String> detailOptions) {
    if (detailOptions.contains('User') && userName.isEmpty) {
      return 'Please enter a username';
    } else if (detailOptions.contains('Password')) {
      if (password.isEmpty) {
        return 'Please enter a password';
      } else if (password.length < 8) {
        return 'Password must be at least 8 characters';
      } else if (password.length > 32) {
        return 'Password must be 64 characters or less';
      } else {
        final RegExp validChars = RegExp(r'^[\x21\x23-\x2F\x30-\x39\x3A-\x3B\x3D\x3F-\x40\x41-\x5A\x5B\x5D-\x60\x61-\x7A\x7B-\x7E]+$');
        if (!validChars.hasMatch(password)) {
          return 'Password contains invalid characters';
        }
      }
    }

    if (detailOptions.contains('Confirm Password')) {
      if (confirmPassword.isEmpty) {
        return 'Please confirm your password';
      } else if (confirmPassword != password) {
        return 'Passwords do not match';
      }
    }

    return 'Please complete all required fields';
  }

  // 獲取連接類型錯誤訊息
  String _getConnectionTypeError() {
    if (connectionType == 'Static IP') {
      if (staticIpConfig.ipAddress.isEmpty) {
        return 'Please enter an IP address';
      } else if (staticIpConfig.subnetMask.isEmpty) {
        return 'Please enter a subnet mask';
      } else if (staticIpConfig.gateway.isEmpty) {
        return 'Please enter a gateway address';
      } else if (staticIpConfig.primaryDns.isEmpty) {
        return 'Please enter a DNS server address';
      }
    } else if (connectionType == 'PPPoE') {
      if (pppoeUsername.isEmpty) {
        return 'Please enter a PPPoE username';
      } else if (pppoePassword.isEmpty) {
        return 'Please enter a PPPoE password';
      }
    }

    return 'Please complete all required fields';
  }

  // 獲取 SSID 錯誤訊息
  String _getSSIDError() {
    // 驗證 SSID
    if (ssid.isEmpty) {
      return 'Please enter an SSID';
    } else if (ssid.length > 64) {
      return 'SSID must be 64 characters or less';
    } else {
      // 驗證 SSID 字符
      final RegExp validChars = RegExp(
          r'^[\x21\x23-\x2F\x30-\x39\x3A-\x3B\x3D\x3F-\x40\x41-\x5A\x5B\x5D-\x60\x61-\x7A\x7B-\x7E]+$'
      );
      if (!validChars.hasMatch(ssid)) {
        return 'SSID contains invalid characters';
      }
    }

    // 驗證密碼
    if (securityOption != 'no authentication' && securityOption != 'Enhanced Open (OWE)') {
      if (ssidPassword.isEmpty) {
        return 'Please enter a password';
      } else if (ssidPassword.length < 8) {
        return 'Password must be at least 8 characters';
      } else if (ssidPassword.length > 64) {
        return 'Password must be 64 characters or less';
      } else {
        // 驗證密碼字符
        final RegExp validChars = RegExp(
            r'^[\x21\x23-\x2F\x30-\x39\x3A-\x3B\x3D\x3F-\x40\x41-\x5A\x5B\x5D-\x60\x61-\x7A\x7B-\x7E]+$'
        );
        if (!validChars.hasMatch(ssidPassword)) {
          return 'Password contains invalid characters';
        }
      }
    }

    return 'Please complete all required fields';
  }

  // 處理返回操作
  void _handleBack() {
    if (currentStepIndex > 0) {
      _isUpdatingStep = true;
      setState(() {
        currentStepIndex--;
        isCurrentStepComplete = false;
        isLastStepCompleted = false; // 重置最後一步完成狀態
      });
      _stepperController.jumpToStep(currentStepIndex);
      _pageController.animateToPage(
        currentStepIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _isUpdatingStep = false;
    }
  }

  // 處理精靈完成
  void _handleWizardCompleted() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const InitializationPage()),
          (route) => false,
    );
  }

  // 獲取當前模型步驟
  List<dynamic> _getCurrentModelSteps() {
    if (stepsConfig.isEmpty ||
        !stepsConfig.containsKey('models') ||
        !stepsConfig['models'].containsKey(currentModel) ||
        !stepsConfig['models'][currentModel].containsKey('steps')) {
      return [];
    }
    return stepsConfig['models'][currentModel]['steps'];
  }

  // 獲取當前步驟組件
  List<String> _getCurrentStepComponents({int? stepIndex}) {
    final index = stepIndex ?? currentStepIndex;
    final steps = _getCurrentModelSteps();
    if (steps.isEmpty || index >= steps.length) {
      return [];
    }
    var currentStep = steps[index];
    if (!currentStep.containsKey('components')) {
      return [];
    }
    return List<String>.from(currentStep['components']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: Column(
          children: [
            // Stepper 區域
            Expanded(
              flex: 30,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: StepperComponent(
                  configPath: 'lib/shared/config/flows/initialization/wifi.json',
                  modelType: currentModel,
                  onStepChanged: _updateCurrentStep,
                  controller: _stepperController,
                  isLastStepCompleted: isLastStepCompleted,
                ),
              ),
            ),
            // 主內容區域
            Expanded(
              flex: 108,
              child: isShowingFinishingWizard
                  ? _buildFinishingWizard()
                  : Column(
                children: [
                  // 步驟標題
                  Expanded(
                    flex: 12,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Text(
                        _getCurrentStepName(),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.normal),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // 步驟內容
                  Expanded(
                    flex: 95,
                    child: _buildPageView(),
                  ),
                ],
              ),
            ),
            // 導航按鈕
            if (!isShowingFinishingWizard)
              Expanded(
                flex: 38,
                child: _buildNavigationButtons(),
              ),
          ],
        ),
      ),
    );
  }

  // 完成精靈介面
  Widget _buildFinishingWizard() {
    return Column(
      children: [
        Expanded(
          flex: 12,
          child: Container(
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              'Finishing Wizard$_ellipsis',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.normal),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Expanded(
          flex: 95,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: FinishingWizardComponent(
                  processNames: _processNames,
                  totalDurationSeconds: 10,
                  onCompleted: _handleWizardCompleted,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 獲取當前步驟名稱
  String _getCurrentStepName() {
    final steps = _getCurrentModelSteps();
    if (steps.isNotEmpty && currentStepIndex < steps.length) {
      return steps[currentStepIndex]['name'] ?? 'Step ${currentStepIndex + 1}';
    }
    return 'Step ${currentStepIndex + 1}';
  }

  // 構建頁面視圖
  Widget _buildPageView() {
    final steps = _getCurrentModelSteps();
    if (steps.isEmpty) {
      return const Center(child: Text('沒有可用的步驟'));
    }

    return PageView.builder(
      controller: _pageController,
      physics: const ClampingScrollPhysics(),
      itemCount: steps.length,
      onPageChanged: (index) {
        if (_isUpdatingStep || index == currentStepIndex) return;
        _isUpdatingStep = true;
        setState(() {
          currentStepIndex = index;
          isCurrentStepComplete = false;
        });
        _stepperController.jumpToStep(index);
        _isUpdatingStep = false;
      },
      itemBuilder: (context, index) {
        return SizedBox.expand(
          child: _buildStepContent(index),
        );
      },
    );
  }

  // 構建步驟內容
  Widget _buildStepContent(int index) {
    final componentNames = _getCurrentStepComponents(stepIndex: index);
    final steps = _getCurrentModelSteps();

    // 如果是最後一個步驟，顯示摘要
    if (index == steps.length - 1) {
      return SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: SummaryComponent(
            username: userName,
            connectionType: connectionType,
            ssid: ssid,
            securityOption: securityOption,
            password: ssidPassword,
            staticIpConfig: connectionType == 'Static IP' ? staticIpConfig : null,
            pppoeUsername: connectionType == 'PPPoE' ? pppoeUsername : null,
            pppoePassword: connectionType == 'PPPoE' ? pppoePassword : null,
            onNextPressed: _handleNext,
            onBackPressed: _handleBack,
          ),
        ),
      );
    }

    // 創建當前步驟的組件
    List<Widget> components = [];
    for (String componentName in componentNames) {
      Widget? component = _createComponentByName(componentName);
      if (component != null) {
        components.add(component);
      }
    }

    if (components.isNotEmpty) {
      return SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: components,
          ),
        ),
      );
    }

    // 沒有定義組件的步驟
    return Container(
      color: Colors.grey[200],
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step ${index + 1} Content',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text('This step has no defined components. Please use the buttons below to continue.'),
        ],
      ),
    );
  }

  // 構建導航按鈕
  Widget _buildNavigationButtons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: TextButton(
                onPressed: currentStepIndex > 0 ? _handleBack : null,
                child: const Text(
                  'Back',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: TextButton(
                onPressed: _handleNext,
                child: const Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 根據名稱創建組件
  Widget? _createComponentByName(String componentName) {
    List<String> detailOptions = _getStepDetailOptions();

    switch (componentName) {
      case 'AccountPasswordComponent':
        return AccountPasswordComponent(
          displayOptions: detailOptions.isNotEmpty ? detailOptions : const ['User', 'Password', 'Confirm Password'],
          onFormChanged: _handleFormChanged,
          onNextPressed: _handleNext,
          onBackPressed: _handleBack,
        );
      case 'ConnectionTypeComponent':
        return ConnectionTypeComponent(
          displayOptions: detailOptions.isNotEmpty ? detailOptions : const ['DHCP', 'Static IP', 'PPPoE'],
          onSelectionChanged: _handleConnectionTypeChanged,
          onNextPressed: _handleNext,
          onBackPressed: _handleBack,
        );
      case 'SetSSIDComponent':
        return SetSSIDComponent(
          displayOptions: detailOptions.isNotEmpty ? detailOptions : const ['no authentication', 'Enhanced Open (OWE)', 'WPA2 Personal', 'WPA3 Personal', 'WPA2/WPA3 Personal', 'WPA2 Enterprise'],
          onFormChanged: _handleSSIDFormChanged,
          onNextPressed: _handleNext,
          onBackPressed: _handleBack,
        );
      case 'SummaryComponent':
        return SummaryComponent(
          username: userName,
          connectionType: connectionType,
          ssid: ssid,
          securityOption: securityOption,
          password: ssidPassword,
          staticIpConfig: connectionType == 'Static IP' ? staticIpConfig : null,
          pppoeUsername: connectionType == 'PPPoE' ? pppoeUsername : null,
          pppoePassword: connectionType == 'PPPoE' ? pppoePassword : null,
          onNextPressed: _handleNext,
          onBackPressed: _handleBack,
        );
      default:
        print('不支援的組件名稱: $componentName');
        return null;
    }
  }
}
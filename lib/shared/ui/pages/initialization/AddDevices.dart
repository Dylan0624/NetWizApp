import 'package:flutter/material.dart';

class AddDevicesScreen extends StatefulWidget {
  const AddDevicesScreen({super.key});

  @override
  State<AddDevicesScreen> createState() => _AddDevicesScreenState();
}

class _AddDevicesScreenState extends State<AddDevicesScreen> {
  // 用來存儲設備方塊的列表
  List<Widget> deviceBoxes = [];

  // 添加設備方塊的方法
  void addDevice() {
    setState(() {
      deviceBoxes.add(DeviceBox());
    });
  }

  @override
  Widget build(BuildContext context) {
    // 獲取屏幕尺寸
    final size = MediaQuery.of(context).size;

    // 計算可顯示區域的寬高
    final containerWidth = size.width * 0.7; // 從0.2到0.8，寬度為0.6
    final containerHeight = size.height * 0.7; // 從0.1到0.8，高度為0.7

    // 一行可以放置的方塊數量（固定為3）
    const int boxesPerRow = 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Devices'),
        backgroundColor: Colors.grey[200],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 顯示區域（從屏幕頂部0.1到0.8的區域）
            Container(
              margin: EdgeInsets.only(
                top: size.height * 0.05,
                left: size.width * 0.1,
                right: size.width * 0.1,
              ),
              width: containerWidth,
              height: containerHeight,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: boxesPerRow, // 一行三個
                  childAspectRatio: 1, // 保持方形比例
                  crossAxisSpacing: 20, // 水平間距
                  mainAxisSpacing: 10, // 垂直間距
                ),
                itemCount: deviceBoxes.length,
                itemBuilder: (context, index) {
                  return deviceBoxes[index];
                },
              ),
            ),

            // 添加設備按鈕
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30.0, left: 20.0, right: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: addDevice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDDDDDD),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                      ),
                      child: const Text(
                        'Add Devices',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFDDDDDD),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );
  }
}
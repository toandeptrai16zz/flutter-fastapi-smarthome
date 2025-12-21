import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSwitched = false; // Trạng thái đèn

  @override
  void initState() {
    super.initState();
    _loadStatus(); // Mở app lên là check trạng thái ngay
  }

  void _loadStatus() async {
    bool status = await ApiService.getStatus();
    setState(() {
      isSwitched = status;
    });
  }

  void _onTap() async {
    // 1. Gọi API đổi trạng thái ngược lại
    bool success = await ApiService.toggleDevice(!isSwitched);
    
    // 2. Nếu thành công thì đổi màu trên màn hình
    if (success) {
      setState(() {
        isSwitched = !isSwitched;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã ${isSwitched ? 'BẬT' : 'TẮT'} đèn!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi kết nối Server!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Nền tối cho ngầu
      appBar: AppBar(
        title: const Text("IoT Controller"), 
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon bóng đèn
            GestureDetector(
              onTap: _onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSwitched ? Colors.yellow.withOpacity(0.2) : Colors.black,
                  boxShadow: isSwitched
                      ? [BoxShadow(color: Colors.yellow, blurRadius: 50, spreadRadius: 10)]
                      : [],
                ),
                child: Icon(
                  Icons.lightbulb,
                  size: 100,
                  color: isSwitched ? Colors.yellow : Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 50),
            // Nút bấm phía dưới
            ElevatedButton(
              onPressed: _onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSwitched ? Colors.yellow : Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                isSwitched ? "ĐANG BẬT" : "ĐANG TẮT",
                style: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
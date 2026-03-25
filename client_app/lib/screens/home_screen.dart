import 'package:flutter/material.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool led1Status = false;
  bool led2Status = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void _loadStatus() async {
    bool status1 = await ApiService.getStatus("led_1");
    bool status2 = await ApiService.getStatus("led_2");
    
    if (mounted) {
      setState(() {
        led1Status = status1;
        led2Status = status2;
        isLoading = false;
      });
    }
  }

  void _onToggleLed(String deviceId, bool currentStatus) async {
    // Hiển thị loading nhẹ hoặc disable nút
    bool success = await ApiService.toggleDevice(deviceId, !currentStatus);
    
    if (success) {
      setState(() {
        if (deviceId == "led_1") led1Status = !currentStatus;
        if (deviceId == "led_2") led2Status = !currentStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã ${!currentStatus ? 'BẬT' : 'TẮT'} $deviceId!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi kết nối Server!")),
      );
    }
  }

  Widget _buildLedCard(String title, String deviceId, bool status) {
    return GestureDetector(
      onTap: () => _onToggleLed(deviceId, status),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          boxShadow: status 
              ? [BoxShadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 20, spreadRadius: 2)]
              : [],
          border: Border.all(color: status ? Colors.yellow : Colors.grey[800]!, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  size: 50,
                  color: status ? Colors.yellow : Colors.grey[600],
                ),
                const SizedBox(width: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: status ? Colors.yellow : Colors.white,
                  ),
                ),
              ],
            ),
            Switch(
              value: status,
              activeColor: Colors.yellow,
              onChanged: (val) => _onToggleLed(deviceId, status),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text("SmartHome Dashboard"), 
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.yellow))
        : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Devices Control",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 30),
            _buildLedCard("Đèn Phòng Khách", "led_1", led1Status),
            _buildLedCard("Đèn Phòng Ngủ", "led_2", led2Status),
          ],
        ),
    );
  }
}
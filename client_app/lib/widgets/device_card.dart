import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DeviceCard extends StatelessWidget {
  final String name;
  final String room;
  final IconData icon;
  final bool isOn;
  final bool isOffline;
  final String statusText;
  final VoidCallback onTap;
  final ValueChanged<bool>? onToggle;
  final Color activeColor;

  const DeviceCard({
    super.key,
    required this.name,
    required this.room,
    required this.icon,
    this.isOn = false,
    this.isOffline = false,
    required this.statusText,
    required this.onTap,
    this.onToggle,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isOffline ? null : onTap, // Offline thì không bấm được
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (isOn && !isOffline) ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.backgroundDark,
                  child: Icon(
                    icon,
                    color: isOffline ? AppColors.textSecondary : (isOn ? activeColor : Colors.white),
                    size: 20,
                  ),
                ),
                if (!isOffline)
                  SizedBox(
                    height: 24,
                    width: 40,
                    child: Switch(
                      value: isOn,
                      onChanged: onToggle,
                      activeColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withOpacity(0.5),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: AppColors.backgroundDark,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  )
                else
                  const Icon(Icons.wifi_off, color: AppColors.offline, size: 20)
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: isOffline ? AppColors.textSecondary : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  room,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isOffline ? "Offline" : statusText,
              style: TextStyle(
                color: isOffline ? AppColors.offline : (isOn ? activeColor : AppColors.textSecondary),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
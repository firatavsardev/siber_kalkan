// ============================================================
// SiberKalkan - Tehdit Kartı Widget
// Dosya Yolu: lib/widgets/threat_card.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:siber_kalkan/models/threat_log.dart';
import 'package:siber_kalkan/utils/constants.dart';

class ThreatCard extends StatelessWidget {
  final ThreatLog threat;
  final VoidCallback? onTap;

  const ThreatCard({
    super.key,
    required this.threat,
    this.onTap,
  });

  Color get _threatColor {
    if (threat.threatLevel >= 80) return AppColors.dangerRed;
    if (threat.threatLevel >= 60) return AppColors.warningOrange;
    if (threat.threatLevel >= 40) return const Color(0xFFFFA726);
    return AppColors.primaryGreen;
  }

  IconData get _threatIcon {
    if (threat.threatLevel >= 60) return Icons.dangerous_rounded;
    if (threat.threatLevel >= 40) return Icons.warning_amber_rounded;
    return Icons.check_circle_rounded;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} dk önce';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} saat önce';
    } else {
      return '${diff.inDays} gün önce';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: threat.isDangerous ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _threatColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tehdit İkonu
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _threatColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _threatIcon,
                  color: _threatColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),

              // İçerik
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst satır: Gönderici + Zaman
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            threat.sender,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(threat.timestamp),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // SMS İçeriği
                    Text(
                      threat.content,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Tehdit seviyesi + badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _threatColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${threat.threatLevelText} (${threat.threatLevel}%)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _threatColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (threat.matchedKeywords.isNotEmpty)
                          Text(
                            '${threat.matchedKeywords.length} kelime eşleşti',
                            style: AppTextStyles.caption.copyWith(fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Okunmadı göstergesi
              if (!threat.isRead)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.dangerRed,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

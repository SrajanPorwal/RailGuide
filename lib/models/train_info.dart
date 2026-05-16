// ============================================================
// RailGuide — Train Information Model
// models/train_info.dart
// ============================================================

import 'dart:ui'; // ← MUST be at top before any class declarations

class TrainInfo {
  final String trainNumber;
  final String trainName;
  final String platformNumber;
  final String arrivalTime;
  final String status;
  final int delayMinutes;

  const TrainInfo({
    required this.trainNumber,
    required this.trainName,
    required this.platformNumber,
    required this.arrivalTime,
    required this.status,
    this.delayMinutes = 0,
  });

  static List<TrainInfo> mockTrains() => [
        const TrainInfo(
          trainNumber: '12627',
          trainName: 'Karnataka Express',
          platformNumber: '1',
          arrivalTime: '14:35',
          status: 'On Time',
        ),
        const TrainInfo(
          trainNumber: '16536',
          trainName: 'Gol Gumbaz Express',
          platformNumber: '2',
          arrivalTime: '15:10',
          status: 'Delayed',
          delayMinutes: 20,
        ),
        const TrainInfo(
          trainNumber: '22691',
          trainName: 'Rajdhani Express',
          platformNumber: '1',
          arrivalTime: '16:00',
          status: 'On Time',
        ),
      ];

  Color get statusColor {
    switch (status) {
      case 'On Time':
        return const Color(0xFF22C55E);
      case 'Delayed':
        return const Color(0xFFF59E0B);
      case 'Cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
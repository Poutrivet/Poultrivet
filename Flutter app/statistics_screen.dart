import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'api_service.dart';

class StatisticsScreen extends StatefulWidget {
const StatisticsScreen({super.key});

@override
State<StatisticsScreen> createState() => _StatisticsScreenState();
}
class _StatisticsScreenState extends State<StatisticsScreen> {
static const Color primaryGreen = Color(0xFF2ECC71);
static const Color lightGreen = Color(0xFFE8F8F0);
static const Color bgColor = Color(0xFFF0F2F0);
static const Color cardColor = Colors.white;
static const Color darkText = Color(0xFF1A1A1A);
static const Color greyText = Color(0xFF888888);
static const Color redRisk = Color(0xFFE74C3C);
static const Color orangeRisk = Color(0xFFF39C12);
bool _isLoading = true;
String? _error;
int _highRisk = 0;
int _mediumRisk = 0;
int _lowRisk = 0;
int _totalDistricts = 0;
String _mostCommonDisease = '';
int _touchedDonutIndex = -1;
List<dynamic> _top5Districts = [];
Map<String, dynamic> _diseaseFrequency = {};


@override
void initState() {
super.initState();
_loadData();
}
Future<void> _loadData() async {
try {
setState(() {
_isLoading = true;
_error = null;
});

final data = await ApiService.getSummary();

setState(() {
_highRisk = data['high_risk_count'] ?? 0;
_mediumRisk = data['medium_risk_count'] ?? 0;
_lowRisk = data['low_risk_count'] ?? 0;
_totalDistricts = data['total_monitored'] ?? 0;
_mostCommonDisease = data['most_common_disease'] ?? '';
_top5Districts = data['top5_risk_districts'] ?? [];
_diseaseFrequency =
Map<String, dynamic>.from(data['disease_frequency'] ?? {});
_isLoading = false;
});
} catch (e) {
setState(() {
_error = e.toString();
_isLoading = false;
});
}
}
@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: bgColor,
appBar: AppBar(
backgroundColor: bgColor,
elevation: 0,
centerTitle: true,
leading: IconButton(
icon: const Icon(Icons.menu, color: darkText),
onPressed: () {},
),
title: const Text(
'PoulVet',
style: TextStyle(
color: primaryGreen,
fontWeight: FontWeight.bold,
fontSize: 20,
),
),


actions: [
    Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: darkText),
          onPressed: () {},
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  ],
),

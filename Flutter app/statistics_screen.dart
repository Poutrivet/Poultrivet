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

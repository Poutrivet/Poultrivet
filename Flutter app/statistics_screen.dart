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

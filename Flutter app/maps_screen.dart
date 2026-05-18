import 'package:flutter/material.dart';
import 'api_service.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  static const Color primaryGreen = Color(0xFF2ECC71);
  static const Color lightGreen = Color(0xFFE8F8F0);
  static const Color bgColor = Color(0xFFF0F2F0);
  static const Color cardColor = Colors.white;
  static const Color darkText = Color(0xFF1A1A1A);
  static const Color greyText = Color(0xFF888888);
  static const Color redRisk = Color(0xFFE74C3C);
  static const Color orangeRisk = Color(0xFFF39C12);

  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  bool _hasSearched = false;
  String? _error;
  Map<String, dynamic>? _districtData;

  final List<String> _quickDistricts = [
    'Kampala',
    'Wakiso',
    'Mukono',
    'Jinja',
    'Gulu',
    'Mbarara',
    'Masaka',
    'Mbale',
    'Ntenjeru',
    'Bugabula',
    'Mityana',
    'Oyam',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


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
Future<void> _searchDistrict(String name) async {
    if (name.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _error = null;
      _districtData = null;
    });
    try {
      final data = await ApiService.getDistrict(name.trim());
      setState(() {
        _districtData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('not found')
            ? 'District "$name" not found.\nCheck spelling and try again.'
            : 'Connection error. Check your internet.';
        _isLoading = false;
      });
    }
  }

  Color _getRiskColor(String? level) {
    switch (level?.toUpperCase()) {
      case 'HIGH':
        return redRisk;
      case 'MEDIUM':
        return orangeRisk;
      case 'LOW':
        return primaryGreen;
      default:
        return greyText;
    }
  }

  IconData _getRiskIcon(String? level) {
    switch (level?.toUpperCase()) {
      case 'HIGH':
        return Icons.warning_amber_rounded;
      case 'MEDIUM':
        return Icons.info_outline;
      case 'LOW':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
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
  

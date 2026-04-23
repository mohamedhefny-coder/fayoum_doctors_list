import 'package:flutter/material.dart';

import '../models/doctor_model.dart';
import '../services/doctor_database_service.dart';
import '../widgets/doctor_summary_card.dart';
import 'doctor_detail_screen.dart';

class EmergencyDoctorsScreen extends StatefulWidget {
  final Color headerColor;

  const EmergencyDoctorsScreen({super.key, required this.headerColor});

  @override
  State<EmergencyDoctorsScreen> createState() => _EmergencyDoctorsScreenState();
}

class _EmergencyDoctorsScreenState extends State<EmergencyDoctorsScreen> {
  final _doctorService = DoctorDatabaseService();
  List<Doctor>? _doctors;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doctors = await _doctorService.getEmergency24hDoctors();
      if (!mounted) return;
      setState(() {
        _doctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('طوارئ 24 ساعة'),
          backgroundColor: widget.headerColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDoctors,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('حدث خطأ: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDoctors,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    final doctors = _doctors ?? [];

    if (doctors.isEmpty) {
      return const Center(
        child: Text(
          'لا يوجد أطباء طوارئ 24 ساعة حالياً',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDoctors,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: doctors.length,
        itemBuilder: (context, index) {
          final doctor = doctors[index];
          return DoctorSummaryCard(
            doctor: doctor,
            cardColor: widget.headerColor,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorDetailScreen(
                    doctor: doctor,
                    cardColor: widget.headerColor,
                  ),
                ),
              );

              if (result == true) {
                _loadDoctors();
              }
            },
          );
        },
      ),
    );
  }
}

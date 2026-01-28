import 'package:flutter/material.dart';
import '../services/doctor_database_service.dart';
import '../models/doctor_model.dart';
import 'doctor_detail_screen.dart';
import '../widgets/doctor_summary_card.dart';

class SpecialtyDoctorsScreen extends StatefulWidget {
  final String specialtyName;
  final Color specialtyColor;

  const SpecialtyDoctorsScreen({
    super.key,
    required this.specialtyName,
    required this.specialtyColor,
  });

  @override
  State<SpecialtyDoctorsScreen> createState() => _SpecialtyDoctorsScreenState();
}

class _SpecialtyDoctorsScreenState extends State<SpecialtyDoctorsScreen> {
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
      final doctors = await _doctorService.getDoctorsBySpecialty(widget.specialtyName);
      if (mounted) {
        setState(() {
          _doctors = doctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: Text(widget.specialtyName),
          backgroundColor: widget.specialtyColor,
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
          'لا يوجد أطباء في هذا التخصص حالياً',
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
          return _DoctorCard(
            doctor: doctors[index],
            cardColor: _getColorForIndex(index),
            onDoctorUpdated: _loadDoctors,
          );
        },
      ),
    );
  }

  // دالة لتوليد ألوان مختلفة للبطاقات
  Color _getColorForIndex(int index) {
    // جميع البطاقات باللون الأزرق
    return const Color(0xFF007FFF);
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final Color cardColor;
  final VoidCallback onDoctorUpdated;

  const _DoctorCard({
    required this.doctor,
    required this.cardColor,
    required this.onDoctorUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorSummaryCard(
      doctor: doctor,
      cardColor: cardColor,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DoctorDetailScreen(doctor: doctor, cardColor: cardColor),
          ),
        );
        
        // إذا عاد المستخدم من صفحة التفاصيل بعد التعديل، قم بتحديث القائمة
        if (result == true) {
          onDoctorUpdated();
        }
      },
    );
  }
}

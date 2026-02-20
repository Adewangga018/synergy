import 'package:flutter/material.dart';
import 'package:synergy/models/volunteer_activity.dart';
import 'package:synergy/services/volunteer_service.dart';
import 'package:synergy/constants/app_colors.dart';
import 'package:intl/intl.dart';

class AddEditVolunteerPage extends StatefulWidget {
  final VolunteerActivity? activity;

  const AddEditVolunteerPage({
    super.key,
    this.activity,
  });

  @override
  State<AddEditVolunteerPage> createState() => _AddEditVolunteerPageState();
}

class _AddEditVolunteerPageState extends State<AddEditVolunteerPage> {
  final _formKey = GlobalKey<FormState>();
  final _volunteerService = VolunteerService();
  final _activityNameController = TextEditingController();
  final _roleController = TextEditingController();
  
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSaving = false;

  bool get _isEdit => widget.activity != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _activityNameController.text = widget.activity!.activityName;
      _roleController.text = widget.activity!.role;
      _startDate = widget.activity!.startDate ?? DateTime.now();
      _endDate = widget.activity!.endDate;
    }
  }

  @override
  void dispose() {
    _activityNameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal Mulai',
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate,
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal Selesai',
    );

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _clearEndDate() {
    setState(() => _endDate = null);
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate dates
    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal selesai tidak boleh lebih awal dari tanggal mulai'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final activityName = _activityNameController.text.trim();
      final role = _roleController.text.trim();

      if (_isEdit) {
        await _volunteerService.updateActivity(
          activityId: widget.activity!.id,
          activityName: activityName,
          role: role,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        await _volunteerService.createActivity(
          activityName: activityName,
          role: role,
          startDate: _startDate,
          endDate: _endDate,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Volunteer/Kegiatan' : 'Tambah Volunteer/Kegiatan',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveActivity,
              tooltip: 'Simpan',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Nama Kegiatan
            TextFormField(
              controller: _activityNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Kegiatan/Volunteer',
                hintText: 'Contoh: Relawan Bencana Alam, Bakti Sosial',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.volunteer_activism),
              ),
              textCapitalization: TextCapitalization.words,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kegiatan harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Peran
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Peran/Posisi',
                hintText: 'Contoh: Koordinator, Relawan, Panitia',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Peran harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tanggal Mulai
            InkWell(
              onTap: _selectStartDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Mulai',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  dateFormat.format(_startDate),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tanggal Selesai
            InkWell(
              onTap: _selectEndDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Tanggal Selesai (Opsional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.event),
                  suffixIcon: _endDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearEndDate,
                          tooltip: 'Hapus tanggal selesai',
                        )
                      : const Icon(Icons.calendar_today),
                  helperText: _endDate == null ? 'Masih berlangsung hingga sekarang' : null,
                ),
                child: Text(
                  _endDate != null ? dateFormat.format(_endDate!) : 'Belum selesai',
                  style: TextStyle(
                    fontSize: 16,
                    color: _endDate == null ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Badge
            if (_endDate == null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kegiatan sedang berlangsung',
                        style: TextStyle(
                          color: Colors.green[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kegiatan sudah selesai',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Durasi: ${_calculateDuration()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Info Card
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Kosongkan tanggal selesai jika kegiatan masih berlangsung',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateDuration() {
    if (_endDate == null) return '-';
    
    final diff = _endDate!.difference(_startDate).inDays;
    if (diff < 7) {
      return '$diff hari';
    } else if (diff < 30) {
      final weeks = (diff / 7).floor();
      return '$weeks minggu';
    } else if (diff < 365) {
      final months = (diff / 30).floor();
      return '$months bulan';
    } else {
      final years = (diff / 365).floor();
      final remainingMonths = ((diff % 365) / 30).floor();
      return remainingMonths > 0 ? '$years tahun $remainingMonths bulan' : '$years tahun';
    }
  }
}

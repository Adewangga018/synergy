import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synergy/models/organization.dart';
import 'package:synergy/services/organization_service.dart';
import 'package:synergy/constants/app_colors.dart';

class AddEditOrganizationPage extends StatefulWidget {
  final Organization? organization;

  const AddEditOrganizationPage({
    super.key,
    this.organization,
  });

  @override
  State<AddEditOrganizationPage> createState() => _AddEditOrganizationPageState();
}

class _AddEditOrganizationPageState extends State<AddEditOrganizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _organizationService = OrganizationService();
  final _orgNameController = TextEditingController();
  final _positionController = TextEditingController();
  
  OrganizationScale _selectedScale = OrganizationScale.department;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;

  bool get _isEdit => widget.organization != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _orgNameController.text = widget.organization!.orgName;
      _positionController.text = widget.organization!.position;
      _selectedScale = widget.organization!.scale ?? OrganizationScale.department;
      _startDate = widget.organization!.startDate;
      _endDate = widget.organization!.endDate;
    }
  }

  @override
  void dispose() {
    _orgNameController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal Mulai',
    );
    if (selectedDate != null) {
      setState(() => _startDate = selectedDate);
    }
  }

  Future<void> _pickEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih Tanggal Selesai',
    );
    if (selectedDate != null) {
      setState(() => _endDate = selectedDate);
    }
  }

  Future<void> _saveOrganization() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final orgName = _orgNameController.text.trim();
      final position = _positionController.text.trim();

      if (_isEdit) {
        await _organizationService.updateOrganization(
          organizationId: widget.organization!.id,
          orgName: orgName,
          scale: _selectedScale,
          position: position,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        await _organizationService.createOrganization(
          orgName: orgName,
          scale: _selectedScale,
          position: position,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Organisasi' : 'Tambah Organisasi',
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
              onPressed: _saveOrganization,
              tooltip: 'Simpan',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Nama Organisasi
            TextFormField(
              controller: _orgNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Organisasi',
                hintText: 'Contoh: HMPS Informatika',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.corporate_fare),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama organisasi harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Skala Organisasi
            DropdownButtonFormField<OrganizationScale>(
              value: _selectedScale,
              decoration: const InputDecoration(
                labelText: 'Skala Organisasi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.layers),
              ),
              items: OrganizationScale.values.map((scale) {
                return DropdownMenuItem(
                  value: scale,
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: Organization.getScaleColor(scale),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(scale.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedScale = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Jabatan
            TextFormField(
              controller: _positionController,
              decoration: const InputDecoration(
                labelText: 'Jabatan',
                hintText: 'Contoh: Ketua, Anggota, Koordinator',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jabatan harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tanggal Mulai (Optional)
            InkWell(
              onTap: _pickStartDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Mulai (Opsional)',
                  hintText: 'Pilih tanggal mulai',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _startDate != null 
                      ? DateFormat('d MMMM yyyy').format(_startDate!) 
                      : 'Belum dipilih',
                  style: TextStyle(
                    color: _startDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tanggal Selesai (Optional)
            InkWell(
              onTap: _pickEndDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Selesai (Opsional)',
                  hintText: 'Pilih tanggal selesai atau kosongkan jika masih aktif',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event_available),
                ),
                child: Text(
                  _endDate != null 
                      ? DateFormat('d MMMM yyyy').format(_endDate!) 
                      : 'Masih Aktif',
                  style: TextStyle(
                    color: _endDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            if (_startDate != null && _endDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Durasi: ${_endDate!.difference(_startDate!).inDays} hari',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Skala organisasi menunjukkan cakupan organisasi (Jurusan/Fakultas/Kampus/Eksternal)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
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
}

import 'package:flutter/material.dart';
import 'package:synergy/models/course_schedule.dart';
import 'package:synergy/services/course_schedule_service.dart';
import 'package:synergy/constants/app_colors.dart';

class AddEditCourseSchedulePage extends StatefulWidget {
  final CourseSchedule? schedule;

  const AddEditCourseSchedulePage({
    super.key,
    this.schedule,
  });

  @override
  State<AddEditCourseSchedulePage> createState() => _AddEditCourseSchedulePageState();
}

class _AddEditCourseSchedulePageState extends State<AddEditCourseSchedulePage> {
  final _formKey = GlobalKey<FormState>();
  final _scheduleService = CourseScheduleService();
  final _courseNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _lecturerController = TextEditingController();
  final _roomController = TextEditingController();
  final _notesController = TextEditingController();
  
  DayOfWeek _selectedDay = DayOfWeek.monday;
  ClassType _selectedClassType = ClassType.lecture;
  int _selectedSemester = 1;
  int _selectedCredits = 3;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isSaving = false;

  bool get _isEdit => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _courseNameController.text = widget.schedule!.courseName;
      _courseCodeController.text = widget.schedule!.courseCode;
      _lecturerController.text = widget.schedule!.lecturer;
      _roomController.text = widget.schedule!.room;
      _notesController.text = widget.schedule!.notes ?? '';
      _selectedDay = widget.schedule!.dayOfWeek;
      _selectedClassType = widget.schedule!.classType;
      _selectedSemester = widget.schedule!.semester;
      _selectedCredits = widget.schedule!.credits;
      _startTime = widget.schedule!.startTime;
      _endTime = widget.schedule!.endTime;
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _lecturerController.dispose();
    _roomController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStartTime) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = selectedTime;
          // Auto-adjust end time if it's before start time
          if (_endTime.hour < _startTime.hour || 
              (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 2) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = selectedTime;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate time range
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waktu selesai harus lebih besar dari waktu mulai'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final courseName = _courseNameController.text.trim();
      final courseCode = _courseCodeController.text.trim();
      final lecturer = _lecturerController.text.trim();
      final room = _roomController.text.trim();
      final notes = _notesController.text.trim();

      if (_isEdit) {
        await _scheduleService.updateSchedule(
          scheduleId: widget.schedule!.id,
          courseName: courseName,
          courseCode: courseCode,
          lecturer: lecturer,
          dayOfWeek: _selectedDay,
          startTime: _startTime,
          endTime: _endTime,
          room: room,
          semester: _selectedSemester,
          credits: _selectedCredits,
          classType: _selectedClassType,
          notes: notes.isEmpty ? null : notes,
        );
      } else {
        await _scheduleService.createSchedule(
          courseName: courseName,
          courseCode: courseCode,
          lecturer: lecturer,
          dayOfWeek: _selectedDay,
          startTime: _startTime,
          endTime: _endTime,
          room: room,
          semester: _selectedSemester,
          credits: _selectedCredits,
          classType: _selectedClassType,
          notes: notes.isEmpty ? null : notes,
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
        title: Text(_isEdit ? 'Edit Jadwal Kuliah' : 'Tambah Jadwal Kuliah',
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
              onPressed: _saveSchedule,
              tooltip: 'Simpan',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Nama Mata Kuliah
            TextFormField(
              controller: _courseNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Mata Kuliah',
                hintText: 'Contoh: Pemrograman Web',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama mata kuliah harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Kode Mata Kuliah
            TextFormField(
              controller: _courseCodeController,
              decoration: const InputDecoration(
                labelText: 'Kode Mata Kuliah',
                hintText: 'Contoh: IF184701',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kode mata kuliah harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dosen Pengampu
            TextFormField(
              controller: _lecturerController,
              decoration: const InputDecoration(
                labelText: 'Dosen Pengampu',
                hintText: 'Contoh: Dr. John Doe, S.Kom., M.T.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Dosen pengampu harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Row: Semester & SKS
            Row(
              children: [
                // Semester
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedSemester,
                    decoration: const InputDecoration(
                      labelText: 'Semester',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                    items: List.generate(8, (index) {
                      final semester = index + 1;
                      return DropdownMenuItem(
                        value: semester,
                        child: Text('Semester $semester'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSemester = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                // SKS
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _selectedCredits,
                    decoration: const InputDecoration(
                      labelText: 'SKS',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.assessment),
                    ),
                    items: List.generate(6, (index) {
                      final credits = index + 1;
                      return DropdownMenuItem(
                        value: credits,
                        child: Text('$credits SKS'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCredits = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Hari & Tipe Kelas
            Row(
              children: [
                // Hari
                Expanded(
                  child: DropdownButtonFormField<DayOfWeek>(
                    value: _selectedDay,
                    decoration: const InputDecoration(
                      labelText: 'Hari',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: DayOfWeek.values.map((day) {
                      return DropdownMenuItem(
                        value: day,
                        child: Text(day.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedDay = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                
                // Tipe Kelas
                Expanded(
                  child: DropdownButtonFormField<ClassType>(
                    value: _selectedClassType,
                    decoration: const InputDecoration(
                      labelText: 'Tipe Kelas',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.class_),
                    ),
                    items: ClassType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedClassType = value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Waktu Mulai & Selesai
            Row(
              children: [
                // Waktu Mulai
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Waktu Mulai',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      child: Text(
                        _formatTimeOfDay(_startTime),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Waktu Selesai
                Expanded(
                  child: InkWell(
                    onTap: () => _pickTime(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Waktu Selesai',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time_filled),
                      ),
                      child: Text(
                        _formatTimeOfDay(_endTime),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Ruangan
            TextFormField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Ruangan',
                hintText: 'Contoh: IF-101, Lab Komputer 1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.room),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ruangan harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Catatan (Opsional)
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (Opsional)',
                hintText: 'Catatan tambahan tentang jadwal ini',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
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
                        'Atur jadwal kuliah Anda dengan lengkap untuk memudahkan pengelolaan waktu',
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

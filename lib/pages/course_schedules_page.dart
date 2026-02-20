import 'package:flutter/material.dart';
import 'package:synergy/models/course_schedule.dart';
import 'package:synergy/services/course_schedule_service.dart';
import 'package:synergy/pages/add_edit_course_schedule_page.dart';
import 'package:synergy/constants/app_colors.dart';

class CourseSchedulesPage extends StatefulWidget {
  const CourseSchedulesPage({super.key});

  @override
  State<CourseSchedulesPage> createState() => _CourseSchedulesPageState();
}

class _CourseSchedulesPageState extends State<CourseSchedulesPage> with SingleTickerProviderStateMixin {
  final _scheduleService = CourseScheduleService();
  final _searchController = TextEditingController();
  
  late TabController _tabController;
  List<CourseSchedule> _schedules = [];
  Map<DayOfWeek, List<CourseSchedule>> _groupedSchedules = {};
  bool _isLoading = true;
  String _searchQuery = '';
  int? _selectedSemester;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadSchedules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final schedules = await _scheduleService.getSchedules();
      final grouped = await _scheduleService.getSchedulesGroupedByDay();
      setState(() {
        _schedules = schedules;
        _groupedSchedules = grouped;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    var filtered = _schedules;

    // Filter by semester
    if (_selectedSemester != null) {
      filtered = filtered.where((s) => s.semester == _selectedSemester).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((schedule) {
        final query = _searchQuery.toLowerCase();
        return schedule.courseName.toLowerCase().contains(query) ||
            schedule.courseCode.toLowerCase().contains(query) ||
            schedule.lecturer.toLowerCase().contains(query) ||
            schedule.room.toLowerCase().contains(query);
      }).toList();
    }

    // Group filtered schedules by day
    final grouped = <DayOfWeek, List<CourseSchedule>>{};
    for (final day in DayOfWeek.values) {
      grouped[day] = filtered
          .where((s) => s.dayOfWeek == day)
          .toList()
        ..sort((a, b) {
          final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
          final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
          return aMinutes.compareTo(bMinutes);
        });
    }

    setState(() => _groupedSchedules = grouped);
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _applyFilters();
  }

  void _onSemesterChanged(int? semester) {
    setState(() => _selectedSemester = semester);
    _applyFilters();
  }

  Future<void> _navigateToAddEdit([CourseSchedule? schedule]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCourseSchedulePage(schedule: schedule),
      ),
    );

    if (result == true) {
      _loadSchedules();
    }
  }

  Future<void> _deleteSchedule(CourseSchedule schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal'),
        content: Text('Yakin ingin menghapus "${schedule.courseName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _scheduleService.deleteSchedule(schedule.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Jadwal berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
          _loadSchedules();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getClassTypeColor(ClassType type) {
    switch (type) {
      case ClassType.lecture:
        return Colors.blue;
      case ClassType.lab:
        return Colors.orange;
      case ClassType.seminar:
        return Colors.purple;
      case ClassType.workshop:
        return Colors.green;
      case ClassType.other:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kuliah', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: DayOfWeek.values.map((day) {
            final count = _groupedSchedules[day]?.length ?? 0;
            return Tab(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.displayName.substring(0, 3),
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (count > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search and Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Cari mata kuliah, kode, dosen, ruangan...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Semester Filter
                      Row(
                        children: [
                          const Icon(Icons.filter_list, size: 20),
                          const SizedBox(width: 8),
                          const Text('Semester: ', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              value: _selectedSemester,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Semua')),
                                for (int i = 1; i <= 8; i++)
                                  DropdownMenuItem(value: i, child: Text('Semester $i')),
                              ],
                              onChanged: _onSemesterChanged,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab View
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: DayOfWeek.values.map((day) {
                      final daySchedules = _groupedSchedules[day] ?? [];
                      
                      if (daySchedules.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada jadwal\npada hari ${day.displayName}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: daySchedules.length,
                        itemBuilder: (context, index) {
                          final schedule = daySchedules[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              leading: Container(
                                width: 50,
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                decoration: BoxDecoration(
                                  color: _getClassTypeColor(schedule.classType).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _getClassTypeColor(schedule.classType),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      CourseSchedule.formatTime(schedule.startTime),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: _getClassTypeColor(schedule.classType),
                                        height: 1.1,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_downward,
                                      size: 8,
                                      color: _getClassTypeColor(schedule.classType),
                                    ),
                                    Text(
                                      CourseSchedule.formatTime(schedule.endTime),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: _getClassTypeColor(schedule.classType),
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(
                                schedule.courseName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  
                                  // Course Code & Credits
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          schedule.courseCode,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${schedule.credits} SKS',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getClassTypeColor(schedule.classType).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          schedule.classType.displayName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _getClassTypeColor(schedule.classType),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  
                                  // Lecturer
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          schedule.lecturer,
                                          style: const TextStyle(fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  
                                  // Room
                                  Row(
                                    children: [
                                      const Icon(Icons.room, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        schedule.room,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.school, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Semester ${schedule.semester}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _navigateToAddEdit(schedule);
                                  } else if (value == 'delete') {
                                    _deleteSchedule(schedule);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Hapus', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _navigateToAddEdit(schedule),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(),
        tooltip: 'Tambah Jadwal',
        child: const Icon(Icons.add),
      ),
    );
  }
}

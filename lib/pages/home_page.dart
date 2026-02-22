import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:synergy/models/user_profile.dart';
import 'package:synergy/models/calendar_event.dart';
import 'package:synergy/models/event_conflict.dart';
import 'package:synergy/models/user_task.dart';
import 'package:synergy/services/auth_service.dart';
import 'package:synergy/services/calendar_service.dart';
import 'package:synergy/services/motivational_quote_service.dart';
import 'package:synergy/services/user_task_service.dart';
import 'package:synergy/services/notification_service.dart';
import 'package:synergy/constants/app_colors.dart';
import 'package:synergy/pages/widgets/conflict_notification_card.dart';
import 'account_page.dart';
import 'personal_notes_page.dart';
import 'competitions_page.dart';
import 'volunteer_activities_page.dart';
import 'organizations_page.dart';
import 'documents_page.dart';
import 'projects_page.dart';
import 'course_schedules_page.dart';
import 'calendar_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  final _calendarService = CalendarService();
  final _quoteService = MotivationalQuoteService();
  final _taskService = UserTaskService();
  final _notificationService = NotificationService();
  final _menuScrollController = ScrollController();
  UserProfile? _userProfile;
  bool _isLoading = true;
  String _motivationalQuote = '';
  Map<DateTime, List<CalendarEvent>> _weekEvents = {};
  Map<DateTime, List<UserTask>> _weekTasks = {};
  List<EventConflict> _todayConflicts = [];
  DateTime _focusedWeekStart = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _loadUserProfile(); // Load profile first, then load quote inside
    _selectedDay = DateTime.now();
    _focusedWeekStart = _getWeekStart(DateTime.now());
    _loadWeekEvents();
    _loadTodayConflicts();
    _setupNotifications();
  }

  /// Setup notification permissions dan daily schedule
  Future<void> _setupNotifications() async {
    try {
      // Request permission (penting untuk Android 13+)
      final granted = await _notificationService.requestPermission();
      
      if (granted) {
        print('✅ Notification permission granted');
        
        // Schedule daily morning check (07:00 AM)
        await _notificationService.scheduleDailyConflictCheck();
      } else {
        print('❌ Notification permission denied');
      }
    } catch (e) {
      print('Error setting up notifications: $e');
    }
  }

  @override
  void dispose() {
    _menuScrollController.dispose();
    super.dispose();
  }

  void _scrollMenuRight() {
    if (_menuScrollController.hasClients) {
      final maxScroll = _menuScrollController.position.maxScrollExtent;
      final currentScroll = _menuScrollController.offset;
      final scrollAmount = currentScroll + 280.0; // Scroll ~3 cards ke kanan
      
      _menuScrollController.animateTo(
        scrollAmount > maxScroll ? maxScroll : scrollAmount,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollMenuLeft() {
    if (_menuScrollController.hasClients) {
      final currentScroll = _menuScrollController.offset;
      final scrollAmount = currentScroll - 280.0; // Scroll ~3 cards ke kiri
      
      _menuScrollController.animateTo(
        scrollAmount < 0 ? 0 : scrollAmount,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  DateTime _getWeekStart(DateTime date) {
    // Get Monday of the week
    return date.subtract(Duration(days: date.weekday - 1));
  }

  Future<void> _loadWeekEvents() async {
    try {
      final weekStart = _focusedWeekStart;
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      final events = await _calendarService.getAllEvents(
        startDate: weekStart,
        endDate: weekEnd,
      );

      final Map<DateTime, List<CalendarEvent>> eventMap = {};
      
      for (final event in events) {
        final date = DateTime(
          event.startTime.year,
          event.startTime.month,
          event.startTime.day,
        );
        if (eventMap[date] == null) {
          eventMap[date] = [];
        }
        eventMap[date]!.add(event);
      }

      // Load tasks for the week
      final taskMap = <DateTime, List<UserTask>>{};
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final tasks = await _taskService.getTasksForDate(date);
        if (tasks.isNotEmpty) {
          final normalizedDate = DateTime(date.year, date.month, date.day);
          taskMap[normalizedDate] = tasks;
        }
      }

      if (mounted) {
        setState(() {
          _weekEvents = eventMap;
          _weekTasks = taskMap;
        });
      }

      // Schedule reminders untuk event hari ini
      await _scheduleEventReminders(eventMap);
    } catch (e) {
      // Silently fail, events just won't show
      if (mounted) {
        setState(() {
          _weekEvents = {};
          _weekTasks = {};
        });
      }
    }
  }

  /// Schedule reminder 30 menit sebelum setiap event hari ini
  Future<void> _scheduleEventReminders(Map<DateTime, List<CalendarEvent>> eventMap) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Ambil event hari ini
      final todayEvents = eventMap[today] ?? [];
      
      if (todayEvents.isEmpty) {
        print('📅 No events today to schedule reminders');
        return;
      }

      // Schedule reminder untuk setiap event
      await _notificationService.scheduleAllEventReminders(todayEvents);
    } catch (e) {
      print('Error scheduling event reminders: $e');
      // Silently fail
    }
  }

  Future<void> _loadTodayConflicts() async {
    try {
      final now = DateTime.now();
      print('🔍 [CONFLICT DETECTOR] Checking conflicts for: ${DateFormat('yyyy-MM-dd').format(now)}');
      
      final conflicts = await _calendarService.detectConflicts(
        startDate: DateTime(now.year, now.month, now.day),
        endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      );

      print('🔍 [CONFLICT DETECTOR] Found ${conflicts.length} conflicts');
      for (var conflict in conflicts) {
        print('   ⚠️ ${conflict.academicEvent.title} vs ${conflict.conflictingEvent.title} at ${conflict.conflictTimeRange}');
      }

      if (mounted) {
        setState(() {
          _todayConflicts = conflicts;
        });
      }

      // Send notification jika ada konflik
      if (conflicts.isNotEmpty) {
        String details;
        if (conflicts.length == 1) {
          final conflict = conflicts.first;
          details = '${conflict.academicEvent.title} bentrok dengan ${conflict.conflictingEvent.title}';
        } else {
          details = 'Ada ${conflicts.length} bentrok jadwal. Tap untuk lihat detail.';
        }

        await _notificationService.sendConflictNotification(
          conflictCount: conflicts.length,
          conflictDetails: details,
        );

        // Schedule pre-conflict warnings (1 jam sebelum konflik)
        for (var conflict in conflicts) {
          await _notificationService.schedulePreConflictWarning(
            academicTitle: conflict.academicEvent.title,
            conflictTitle: conflict.conflictingEvent.title,
            conflictTime: conflict.conflictStartTime,
          );
        }
      }
    } catch (e) {
      print('❌ [CONFLICT DETECTOR] Error loading conflicts: $e');
      // Silently fail, conflicts just won't show
      if (mounted) {
        setState(() {
          _todayConflicts = [];
        });
      }
    }
  }

  Future<void> _loadRandomQuote() async {
    try {
      // Smart daily quote: Generate 1x per hari saja
      // Jika hari ini sudah ada quote -> pakai dari DB (cepat!)
      // Jika belum ada -> generate baru via Gemini AI
      // 
      // FITUR BARU: Deteksi mahasiswa tingkat akhir (semester 7-8)
      // untuk memberikan quotes motivasi khusus Tugas Akhir
      final quote = await _quoteService.getOrGenerateDailyQuote(
        userId: _userProfile?.id,
      );
      
      if (mounted) {
        setState(() {
          _motivationalQuote = quote;
        });
      }
    } catch (e) {
      print('Error loading quote: $e');
      // Jika gagal, gunakan fallback
      if (mounted) {
        setState(() {
          _motivationalQuote = _quoteService.getFallbackQuote();
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
        // Load quote after profile is available for TA detection
        await _loadRandomQuote();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat profil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAccount() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AccountPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo-synergy.png',
          height: 40,
          fit: BoxFit.contain,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (context, error, stackTrace) {
            // Fallback jika logo tidak ada
            return const Text('Synergy', style: TextStyle(color: Colors.white));
          },
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: _navigateToAccount,
            tooltip: 'Akun Saya',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('Gagal memuat profil'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Motivational Hero Banner - Scrollable
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF013880), // Biru ITS Gelap
                              Color(0xFF0078C1), // Biru ITS Terang
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.wb_sunny,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Halo ${_userProfile!.namaPanggilan}, Gimana kabarmu?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.format_quote,
                                    color: Colors.white70,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _motivationalQuote,
                                      textAlign: TextAlign.justify,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.5,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content: Conflict Alerts + Calendar + Menu
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Conflict Notification (jika ada)
                            if (_todayConflicts.isNotEmpty)
                              ConflictNotificationCard(
                                conflicts: _todayConflicts,
                                userNickname: _userProfile?.namaPanggilan ?? 'Cak Arjuna',
                              ),

                            // Debug Info (hanya muncul jika tidak ada konflik - untuk development)
                            if (_todayConflicts.isEmpty)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.info.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 16,
                                      color: AppColors.info,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Tidak ada konflik jadwal hari ini',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.info,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // Week Calendar Section
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Minggu Ini',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            _buildWeekCalendar(),
                            
                            // Divider dengan gradient
                            const SizedBox(height: 8),
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.grey.withOpacity(0.3),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),

                            // Menu Section dengan scroll indicator
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.apps,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Menu',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: Stack(
                                children: [
                                  ListView(
                                    controller: _menuScrollController,
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    children: [
                                      _buildMenuItem(
                                        icon: Icons.note_alt,
                                        title: 'Catatan\nPribadi',
                                        color: AppColors.primary,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const PersonalNotesPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      _buildMenuItem(
                                        icon: Icons.emoji_events,
                                        title: 'Perlombaan',
                                        color: AppColors.primary,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const CompetitionsPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      _buildMenuItem(
                                        icon: Icons.volunteer_activism,
                                        title: 'Volunteer',
                                        color: AppColors.primary,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const VolunteerActivitiesPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      _buildMenuItem(
                                        icon: Icons.corporate_fare,
                                        title: 'Organisasi',
                                        color: AppColors.primary,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const OrganizationsPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      _buildMenuItem(
                                        icon: Icons.folder,
                                        title: 'Dokumen',
                                        color: AppColors.primary,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const DocumentsPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      _buildMenuItem(
                                        icon: Icons.work,
                                        title: 'Projects',
                                        color: AppColors.primary,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const ProjectsPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      _buildMenuItem(
                                        icon: Icons.schedule,
                                        title: 'Jadwal\nKuliah',
                                        color: AppColors.primary,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const CourseSchedulesPage(),
                                            ),
                                          );
                                        },
                                      ),
                                      _buildMenuItem(
                                        icon: Icons.calendar_month,
                                        title: 'Kalender',
                                        color: AppColors.primary,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) => const CalendarPage(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  // Tombol navigasi kiri
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Colors.white.withOpacity(0.0),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _scrollMenuLeft,
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: AppColors.primary.withOpacity(0.3),
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary.withOpacity(0.15),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.chevron_left,
                                                size: 20,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Tombol navigasi kanan
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.0),
                                            Colors.white,
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _scrollMenuRight,
                                            borderRadius: BorderRadius.circular(20),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: AppColors.primary.withOpacity(0.3),
                                                  width: 1.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.primary.withOpacity(0.15),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.chevron_right,
                                                size: 20,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWeekCalendar() {
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
          children: [
            // Week navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: AppColors.primary,
                    onPressed: () {
                      setState(() {
                        _focusedWeekStart = _focusedWeekStart.subtract(const Duration(days: 7));
                      });
                      _loadWeekEvents();
                    },
                  ),
                ),
                Text(
                  _getWeekRangeText(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right),
                    color: AppColors.primary,
                    onPressed: () {
                      setState(() {
                        _focusedWeekStart = _focusedWeekStart.add(const Duration(days: 7));
                      });
                      _loadWeekEvents();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Days of the week
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                final date = _focusedWeekStart.add(Duration(days: index));
                final normalizedDate = DateTime(date.year, date.month, date.day);
                final isToday = normalizedDate == todayNormalized;
                final isSelected = _selectedDay != null && 
                    DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day) == normalizedDate;
                final events = _weekEvents[normalizedDate] ?? [];
                final tasks = _weekTasks[normalizedDate] ?? [];
                final totalItems = events.length + tasks.length;
                final hasEvents = totalItems > 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = date;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        gradient: isSelected 
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withOpacity(0.8),
                                ],
                              )
                            : null,
                        color: isSelected 
                            ? null
                            : isToday 
                                ? AppColors.primary.withOpacity(0.08)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isToday && !isSelected
                            ? Border.all(
                                color: AppColors.primary.withOpacity(0.4), 
                                width: 1.5,
                              )
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getDayName(date.weekday),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Event indicator dots
                          if (hasEvents)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (totalItems <= 3)
                                  ...List.generate(
                                    totalItems,
                                    (i) => Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : AppColors.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : AppColors.secondary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$totalItems',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: isSelected ? AppColors.primary : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            // Selected day events
            if (_selectedDay != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildSelectedDayEvents(),
            ],
          ],
        ),
    );
  }

  String _getWeekRangeText() {
    final weekEnd = _focusedWeekStart.add(const Duration(days: 6));
    final monthStart = _getMonthName(_focusedWeekStart.month);
    final monthEnd = _getMonthName(weekEnd.month);
    
    if (_focusedWeekStart.month == weekEnd.month) {
      return '${_focusedWeekStart.day}-${weekEnd.day} $monthStart ${_focusedWeekStart.year}';
    } else {
      return '${_focusedWeekStart.day} $monthStart - ${weekEnd.day} $monthEnd ${_focusedWeekStart.year}';
    }
  }

  String _getDayName(int weekday) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }

  Widget _buildSelectedDayEvents() {
    final selectedDate = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
    );
    final events = _weekEvents[selectedDate] ?? [];
    final tasks = _weekTasks[selectedDate] ?? [];
    final totalItems = events.length + tasks.length;

    if (totalItems == 0) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Tidak ada kegiatan',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$totalItems kegiatan',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        // Show tasks first
        ...tasks.take(2).map((task) {
          final timeStr = task.dueTime != null ? task.formattedTime! : 'Sepanjang hari';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: task.priority.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 16,
                            color: task.isCompleted ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$timeStr • Task',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        // Then show events
        ...events.take(3 - tasks.take(2).length).map((event) {
          final timeStr = DateFormat('HH:mm').format(event.startTime);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getEventColor(event.source),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$timeStr • ${_getSourceName(event.source)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (totalItems > 3)
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CalendarPage(),
                ),
              );
            },
            child: Text('Lihat semua $totalItems kegiatan'),
          ),
      ],
    );
  }

  Color _getEventColor(EventSource source) {
    switch (source) {
      case EventSource.courseSchedule:
        return const Color(0xFF00897B);
      case EventSource.competition:
        return const Color(0xFFFFB300);
      case EventSource.volunteer:
        return const Color(0xFF4CAF50);
      case EventSource.organization:
        return const Color(0xFF013880);
      case EventSource.project:
        return const Color(0xFFFF6F00);
      case EventSource.manual:
        return const Color(0xFFE91E63);
      case EventSource.document:
        return const Color(0xFF9C27B0);
      case EventSource.note:
        return const Color(0xFF0078C1);
    }
  }

  String _getSourceName(EventSource source) {
    switch (source) {
      case EventSource.courseSchedule:
        return 'Jadwal Kuliah';
      case EventSource.competition:
        return 'Perlombaan';
      case EventSource.volunteer:
        return 'Volunteer';
      case EventSource.organization:
        return 'Organisasi';
      case EventSource.project:
        return 'Project';
      case EventSource.manual:
        return 'Google Calendar';
      case EventSource.document:
        return 'Dokumen';
      case EventSource.note:
        return 'Catatan';
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Calculate width to show exactly 4 items on screen (screen width / 4)
    return SizedBox(
      width: MediaQuery.of(context).size.width / 4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

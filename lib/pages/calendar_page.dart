import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:synergy/models/calendar_event.dart';
import 'package:synergy/services/calendar_service.dart';
import 'package:synergy/services/google_calendar_service.dart';
import 'package:synergy/constants/app_colors.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _calendarService = CalendarService();
  final _googleCalendarService = GoogleCalendarService();

  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CalendarEvent>> _events = {};
  bool _isLoading = true;
  bool _isGoogleSignedIn = false;
  Set<EventSource> _selectedFilters = EventSource.values.toSet();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadEvents();
    _checkGoogleSignIn();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _calendarService.getEventsForMonth(
        _focusedDay.year,
        _focusedDay.month,
      );

      // Load Google Calendar events if signed in
      if (_isGoogleSignedIn) {
        final googleEvents = await _googleCalendarService.getGoogleCalendarEvents(
          startDate: DateTime(_focusedDay.year, _focusedDay.month, 1),
          endDate: DateTime(_focusedDay.year, _focusedDay.month + 1, 0),
        );

        // Merge Google Calendar events
        for (final event in googleEvents) {
          final date = DateTime(
            event.startTime.year,
            event.startTime.month,
            event.startTime.day,
          );
          if (events[date] == null) {
            events[date] = [];
          }
          events[date]!.add(event);
        }
      }

      setState(() {
        _events = events;
        _isLoading = false;
      });

      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat kalender: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkGoogleSignIn() async {
    final isSignedIn = await _googleCalendarService.signInSilently();
    setState(() {
      _isGoogleSignedIn = isSignedIn;
    });
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    final allEvents = _events[date] ?? [];
    
    // Apply filters
    return allEvents.where((event) => _selectedFilters.contains(event.source)).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      setState(() {
        _calendarFormat = format;
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _loadEvents();
  }

  Future<void> _jumpToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedDay,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      helpText: 'Pilih Tanggal',
      cancelText: 'Batal',
      confirmText: 'OK',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDay = picked;
        _focusedDay = picked;
      });
      _selectedEvents.value = _getEventsForDay(picked);
      _loadEvents();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: EventSource.values.map((source) {
                    return CheckboxListTile(
                      title: Row(
                        children: [
                          Icon(source.icon, color: source.color, size: 20),
                          const SizedBox(width: 8),
                          Text(source.displayName),
                        ],
                      ),
                      value: _selectedFilters.contains(source),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedFilters.add(source);
                          } else {
                            _selectedFilters.remove(source);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedFilters.length == EventSource.values.length) {
                        _selectedFilters.clear();
                      } else {
                        _selectedFilters = EventSource.values.toSet();
                      }
                    });
                  },
                  child: Text(_selectedFilters.length == EventSource.values.length 
                      ? 'Hapus Semua' 
                      : 'Pilih Semua'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    this.setState(() {
                      _selectedEvents.value = _getEventsForDay(_selectedDay!);
                    });
                  },
                  child: const Text('Terapkan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDateIndonesian(DateTime date) {
    const daysIndonesian = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    const monthsIndonesian = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final dayName = daysIndonesian[date.weekday - 1];
    final monthName = monthsIndonesian[date.month - 1];
    
    return '$dayName, ${date.day} $monthName ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            onPressed: _jumpToDate,
            tooltip: 'Pilih Tanggal',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar widget
                TableCalendar<CalendarEvent>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  eventLoader: _getEventsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                  ),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: _onFormatChanged,
                  onPageChanged: _onPageChanged,
                ),

                const Divider(height: 1),

                // Selected day's events
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _formatDateIndonesian(_selectedDay!),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Events list
                Expanded(
                  child: ValueListenableBuilder<List<CalendarEvent>>(
                    valueListenable: _selectedEvents,
                    builder: (context, events, _) {
                      if (events.isEmpty) {
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
                                'Tidak ada event\npada tanggal ini',
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
                        itemCount: events.length,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: event.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  event.icon,
                                  color: event.color,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                event.title,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (!event.isAllDay && event.endTime != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime!)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  if (event.location != null)
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            event.location!,
                                            style: const TextStyle(fontSize: 12),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  if (event.description != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        event.description!,
                                        style: const TextStyle(fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: event.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  event.source.displayName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: event.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              isThreeLine: event.description != null || event.location != null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

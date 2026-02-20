import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:synergy/models/calendar_event.dart';

class GoogleCalendarService {
  static final GoogleCalendarService _instance = GoogleCalendarService._internal();
  factory GoogleCalendarService() => _instance;
  GoogleCalendarService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      calendar.CalendarApi.calendarScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  calendar.CalendarApi? _calendarApi;

  /// Check if user is signed in to Google
  bool get isSignedIn => _currentUser != null;

  /// Get current user email
  String? get userEmail => _currentUser?.email;

  /// Sign in to Google Account
  Future<bool> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return false;

      _currentUser = account;
      
      // Get authenticated HTTP client
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      _calendarApi = calendar.CalendarApi(httpClient);
      return true;
    } catch (e) {
      print('Error signing in to Google: $e');
      return false;
    }
  }

  /// Sign out from Google Account
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _calendarApi = null;
  }

  /// Silent sign in (for auto-login)
  Future<bool> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) return false;

      _currentUser = account;
      
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return false;

      _calendarApi = calendar.CalendarApi(httpClient);
      return true;
    } catch (e) {
      print('Error silent sign in: $e');
      return false;
    }
  }

  /// Sync a single event to Google Calendar
  Future<String?> syncEventToGoogle(CalendarEvent event) async {
    if (_calendarApi == null || !isSignedIn) {
      throw Exception('Not signed in to Google');
    }

    try {
      final calendarEvent = calendar.Event(
        summary: event.title,
        description: event.description,
        location: event.location,
        start: event.isAllDay
            ? calendar.EventDateTime(
                date: DateTime(
                  event.startTime.year,
                  event.startTime.month,
                  event.startTime.day,
                ),
              )
            : calendar.EventDateTime(dateTime: event.startTime),
        end: event.endTime != null
            ? (event.isAllDay
                ? calendar.EventDateTime(
                    date: DateTime(
                      event.endTime!.year,
                      event.endTime!.month,
                      event.endTime!.day,
                    ),
                  )
                : calendar.EventDateTime(dateTime: event.endTime))
            : calendar.EventDateTime(
                dateTime: event.startTime.add(const Duration(hours: 1)),
              ),
        colorId: _getColorIdForSource(event.source),
        source: calendar.EventSource(
          title: 'Synergy App',
          url: event.source.displayName,
        ),
      );

      // If event already has Google Calendar ID, update it
      if (event.googleCalendarEventId != null) {
        final updated = await _calendarApi!.events.update(
          calendarEvent,
          'primary',
          event.googleCalendarEventId!,
        );
        return updated.id;
      } else {
        // Create new event
        final created = await _calendarApi!.events.insert(
          calendarEvent,
          'primary',
        );
        return created.id;
      }
    } catch (e) {
      print('Error syncing event to Google Calendar: $e');
      return null;
    }
  }

  /// Sync multiple events to Google Calendar
  Future<Map<String, String?>> syncEventsToGoogle(List<CalendarEvent> events) async {
    final Map<String, String?> results = {};

    for (final event in events) {
      final googleEventId = await syncEventToGoogle(event);
      results[event.id] = googleEventId;
    }

    return results;
  }

  /// Delete event from Google Calendar
  Future<bool> deleteEventFromGoogle(String googleEventId) async {
    if (_calendarApi == null || !isSignedIn) {
      throw Exception('Not signed in to Google');
    }

    try {
      await _calendarApi!.events.delete('primary', googleEventId);
      return true;
    } catch (e) {
      print('Error deleting event from Google Calendar: $e');
      return false;
    }
  }

  /// Get events from Google Calendar (for displaying manual events)
  Future<List<CalendarEvent>> getGoogleCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_calendarApi == null || !isSignedIn) {
      return [];
    }

    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 30));
      final end = endDate ?? now.add(const Duration(days: 90));

      final events = await _calendarApi!.events.list(
        'primary',
        timeMin: start.toUtc(),
        timeMax: end.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      final calendarEvents = <CalendarEvent>[];

      for (final event in events.items ?? []) {
        // Skip events created by Synergy App
        if (event.source?.title == 'Synergy App') continue;

        final startDateTime = event.start?.dateTime ?? 
            (event.start?.date != null 
                ? DateTime(
                    event.start!.date!.year,
                    event.start!.date!.month,
                    event.start!.date!.day,
                  )
                : null);

        final endDateTime = event.end?.dateTime ?? 
            (event.end?.date != null 
                ? DateTime(
                    event.end!.date!.year,
                    event.end!.date!.month,
                    event.end!.date!.day,
                  )
                : null);

        if (startDateTime != null) {
          calendarEvents.add(CalendarEvent(
            id: event.id ?? '',
            source: EventSource.manual,
            title: event.summary ?? 'No Title',
            description: event.description,
            startTime: startDateTime,
            endTime: endDateTime,
            location: event.location,
            isAllDay: event.start?.date != null,
            googleCalendarEventId: event.id,
          ));
        }
      }

      return calendarEvents;
    } catch (e) {
      print('Error fetching Google Calendar events: $e');
      return [];
    }
  }

  /// Get color ID for event source (Google Calendar colors)
  String _getColorIdForSource(EventSource source) {
    switch (source) {
      case EventSource.courseSchedule:
        return '10'; // Green
      case EventSource.competition:
        return '11'; // Red
      case EventSource.volunteer:
        return '6';  // Orange
      case EventSource.organization:
        return '3';  // Purple
      case EventSource.document:
        return '9';  // Blue
      case EventSource.project:
        return '2';  // Sage
      case EventSource.note:
        return '5';  // Yellow
      case EventSource.manual:
        return '8';  // Gray
    }
  }

  /// Sync all events from Synergy to Google Calendar
  Future<SyncResult> syncAllToGoogle(List<CalendarEvent> events) async {
    if (!isSignedIn) {
      return SyncResult(
        success: false,
        synced: 0,
        failed: 0,
        message: 'Not signed in to Google',
      );
    }

    int synced = 0;
    int failed = 0;

    for (final event in events) {
      final result = await syncEventToGoogle(event);
      if (result != null) {
        synced++;
      } else {
        failed++;
      }
    }

    return SyncResult(
      success: true,
      synced: synced,
      failed: failed,
      message: 'Synced $synced events, $failed failed',
    );
  }

  /// Check if Google Calendar integration is available
  Future<bool> checkAvailability() async {
    try {
      final isAvailable = await _googleSignIn.isSignedIn();
      return isAvailable;
    } catch (e) {
      return false;
    }
  }
}

/// Result of sync operation
class SyncResult {
  final bool success;
  final int synced;
  final int failed;
  final String message;

  SyncResult({
    required this.success,
    required this.synced,
    required this.failed,
    required this.message,
  });
}

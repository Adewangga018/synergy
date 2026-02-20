/// Utility untuk kalkulasi rentang tanggal semester berdasarkan angkatan
class SemesterCalculator {
  /// Calculate semester date range based on angkatan (tahun masuk)
  /// 
  /// Logika:
  /// - Semester 1, 3, 5, 7 (Ganjil): Juli - Desember
  /// - Semester 2, 4, 6, 8 (Genap): Januari - Juni
  /// - Angkatan 2022, Semester 1 = Juli-Desember 2022
  /// - Angkatan 2022, Semester 7 = Juli-Desember 2025
  static SemesterPeriod getSemesterPeriod(int angkatan, int semester) {
    if (semester < 1 || semester > 8) {
      throw ArgumentError('Semester harus antara 1-8');
    }

    // Hitung tahun berdasarkan semester
    // Semester 1-2 = tahun 1 (angkatan)
    // Semester 3-4 = tahun 2 (angkatan + 1)
    // dst...
    final yearOffset = (semester - 1) ~/ 2; // Integer division
    final targetYear = angkatan + yearOffset;

    // Cek apakah semester ganjil atau genap
    final isOddSemester = semester % 2 == 1;

    DateTime startDate;
    DateTime endDate;

    if (isOddSemester) {
      // Semester ganjil: Juli - Desember
      startDate = DateTime(targetYear, 7, 1); // 1 Juli
      endDate = DateTime(targetYear, 12, 31, 23, 59, 59); // 31 Desember
    } else {
      // Semester genap: Januari - Juni (TAHUN BERIKUTNYA setelah semester ganjil)
      startDate = DateTime(targetYear + 1, 1, 1); // 1 Januari
      endDate = DateTime(targetYear + 1, 6, 30, 23, 59, 59); // 30 Juni
    }

    return SemesterPeriod(
      semester: semester,
      startDate: startDate,
      endDate: endDate,
      isOdd: isOddSemester,
    );
  }

  /// Get current semester based on angkatan and current date
  static int getCurrentSemester(int angkatan) {
    final now = DateTime.now();
    final yearsSinceEntry = now.year - angkatan;
    
    // Tentukan semester berdasarkan bulan
    int baseSemester;
    if (now.month >= 7) {
      // Juli-Desember = semester ganjil
      baseSemester = (yearsSinceEntry * 2) + 1;
    } else {
      // Januari-Juni = semester genap
      baseSemester = (yearsSinceEntry * 2);
    }

    // Batasi maksimal semester 8
    return baseSemester > 8 ? 8 : (baseSemester < 1 ? 1 : baseSemester);
  }

  /// Check if a date is within semester period
  static bool isDateInSemester(DateTime date, int angkatan, int semester) {
    final period = getSemesterPeriod(angkatan, semester);
    return date.isAfter(period.startDate.subtract(const Duration(days: 1))) &&
           date.isBefore(period.endDate.add(const Duration(days: 1)));
  }

  /// Get semester name in Indonesian
  static String getSemesterName(int semester) {
    final type = semester % 2 == 1 ? 'Ganjil' : 'Genap';
    return 'Semester $semester ($type)';
  }

  /// Get all semester periods for an angkatan (1-8)
  static List<SemesterPeriod> getAllSemesterPeriods(int angkatan) {
    return List.generate(
      8,
      (index) => getSemesterPeriod(angkatan, index + 1),
    );
  }

  /// Format semester period as string
  static String formatSemesterPeriod(int angkatan, int semester) {
    final period = getSemesterPeriod(angkatan, semester);
    final months = period.isOdd ? 'Juli - Desember' : 'Januari - Juni';
    return '${getSemesterName(semester)}\n$months ${period.startDate.year}';
  }

  /// Check if semester is currently active
  static bool isSemesterActive(int angkatan, int semester) {
    final now = DateTime.now();
    final period = getSemesterPeriod(angkatan, semester);
    return now.isAfter(period.startDate) && now.isBefore(period.endDate);
  }

  /// Get academic year string (e.g., "2025/2026")
  static String getAcademicYear(int angkatan, int semester) {
    final period = getSemesterPeriod(angkatan, semester);
    if (period.isOdd) {
      // Ganjil: Juli 2025 - Desember 2025 → "2025/2026"
      return '${period.startDate.year}/${period.startDate.year + 1}';
    } else {
      // Genap: Januari 2026 - Juni 2026 → "2025/2026"
      return '${period.startDate.year - 1}/${period.startDate.year}';
    }
  }
}

/// Model for semester period
class SemesterPeriod {
  final int semester;
  final DateTime startDate;
  final DateTime endDate;
  final bool isOdd;

  SemesterPeriod({
    required this.semester,
    required this.startDate,
    required this.endDate,
    required this.isOdd,
  });

  /// Get duration in days
  int get durationInDays => endDate.difference(startDate).inDays;

  /// Get semester type (Ganjil/Genap)
  String get type => isOdd ? 'Ganjil' : 'Genap';

  /// Get months name
  String get monthsName => isOdd ? 'Juli - Desember' : 'Januari - Juni';

  /// Check if date is in this period
  bool containsDate(DateTime date) {
    return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
           date.isBefore(endDate.add(const Duration(days: 1)));
  }

  /// Check if this semester is currently active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Get progress percentage
  double get progress {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;

    final totalDays = durationInDays;
    final passedDays = now.difference(startDate).inDays;
    return passedDays / totalDays;
  }

  @override
  String toString() {
    return 'Semester $semester ($type): ${startDate.toString().split(' ')[0]} - ${endDate.toString().split(' ')[0]}';
  }
}

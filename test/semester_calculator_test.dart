import 'package:synergy/utils/semester_calculator.dart';

/// Contoh penggunaan Semester Calculator
void main() {
  print('=== SEMESTER CALCULATOR DEMO ===\n');

  // Angkatan 2022
  final angkatan = 2022;

  // Test untuk setiap semester
  print('📚 Rentang Semester untuk Angkatan $angkatan:');
  print('-' * 50);
  
  for (int sem = 1; sem <= 8; sem++) {
    final period = SemesterCalculator.getSemesterPeriod(angkatan, sem);
    final academicYear = SemesterCalculator.getAcademicYear(angkatan, sem);
    final isActive = period.isActive;
    
    print('${SemesterCalculator.getSemesterName(sem)}');
    print('  📅 Periode: ${period.monthsName}');
    print('  📆 Tanggal: ${_formatDate(period.startDate)} - ${_formatDate(period.endDate)}');
    print('  🎓 Tahun Akademik: $academicYear');
    print('  ✅ Status: ${isActive ? "AKTIF" : "Tidak Aktif"}');
    if (isActive) {
      print('  📊 Progress: ${(period.progress * 100).toStringAsFixed(1)}%');
    }
    print('');
  }

  // Test semester saat ini
  print('\n🎯 Semester Aktif Saat Ini:');
  print('-' * 50);
  final currentSem = SemesterCalculator.getCurrentSemester(angkatan);
  final currentPeriod = SemesterCalculator.getSemesterPeriod(angkatan, currentSem);
  print('Semester: $currentSem');
  print('Periode: ${currentPeriod.monthsName} ${currentPeriod.startDate.year}');
  print('Progress: ${(currentPeriod.progress * 100).toStringAsFixed(1)}%');

  // Test cek tanggal
  print('\n🔍 Test: Cek apakah tanggal ada di semester:');
  print('-' * 50);
  final testDate = DateTime(2025, 8, 15); // 15 Agustus 2025
  print('Tanggal test: ${_formatDate(testDate)}');
  
  for (int sem = 1; sem <= 8; sem++) {
    final isIn = SemesterCalculator.isDateInSemester(testDate, angkatan, sem);
    if (isIn) {
      print('✅ Tanggal ada di Semester $sem');
      print('   ${SemesterCalculator.formatSemesterPeriod(angkatan, sem)}');
    }
  }
}

String _formatDate(DateTime date) {
  final months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

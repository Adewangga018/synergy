-- ==========================================
-- POPULATE MOTIVATIONAL QUOTES
-- ==========================================
-- Isi database dengan 50+ quotes motivasi berkualitas
-- Alternative dari generate via OpenAI (GRATIS!)

-- Quotes untuk Mahasiswa ITS
-- Berbagai tema: general, UTS, UAS, awal semester, libur, organisasi, dll

-- Clear existing quotes (optional - uncomment jika ingin reset)
-- DELETE FROM motivational_quotes;

-- ==========================================
-- GENERAL QUOTES (Umum)
-- ==========================================
INSERT INTO motivational_quotes (quote_text, theme, relevance_context, is_active, display_priority) VALUES
('Jangan bandingkan progress-mu dengan orang lain. Setiap orang punya timeline-nya sendiri.', 'general', 'Untuk mahasiswa yang sering membandingkan diri dengan teman', true, 100),
('Konsisten mengerjakan hal kecil setiap hari lebih powerful daripada semangat sesaat yang besar.', 'general', 'Mendorong konsistensi dalam belajar', true, 95),
('IPK tinggi itu bagus, tapi jangan lupa develop soft skills dan mental health juga.', 'general', 'Mengingatkan keseimbangan hidup mahasiswa', true, 90),
('Failure is not the opposite of success, it is part of success. Gagal itu biasa, belajar dari kesalahan itu luar biasa.', 'general', 'Menghadapi kegagalan dengan positif', true, 85),
('Kamu nggak harus jadi yang terbaik, yang penting jadi versi terbaik dari dirimu sendiri.', 'general', 'Mengurangi pressure perfeksionisme', true, 80),
('Rest is productive. Istirahat bukan berarti malas, tapi investasi energi untuk besok.', 'general', 'Mengajarkan pentingnya istirahat', true, 75),
('Jangan tunggu motivasi datang. Discipline beats motivation every time.', 'general', 'Mendorong disiplin', true, 70),
('Small steps every day leads to big results. Progress beats perfection.', 'general', 'Fokus pada progress incremental', true, 65),
('Your mental health is more important than your GPA. Jaga keseimbangan!', 'general', 'Prioritas kesehatan mental', true, 60),
('Kalau hari ini belum produktif, besok masih ada kesempatan. Tomorrow is a new day.', 'general', 'Untuk hari yang kurang produktif', true, 55);

-- ==========================================
-- UTS QUOTES (Ujian Tengah Semester)
-- ==========================================
INSERT INTO motivational_quotes (quote_text, theme, relevance_context, is_active, display_priority) VALUES
('UTS bukan tentang hafalan, tapi tentang pemahaman. Pahami konsepnya, bukan cuma ngafalin.', 'UTS', 'Persiapan UTS yang efektif', true, 100),
('Mulai belajar dari sekarang 30 menit sehari lebih efektif daripada SKS (Sistem Kebut Semalam).', 'UTS', 'Anti-procrastination saat UTS', true, 95),
('UTS is just a checkpoint, bukan finish line. Tetap santai tapi serius.', 'UTS', 'Mengurangi anxiety UTS', true, 90),
('Review materi setiap habis kuliah 15 menit saja. Pas UTS tinggal refresh, bukan belajar dari nol.', 'UTS', 'Strategi belajar efisien', true, 85),
('Jangan cuma belajar sendirian. Diskusi bareng teman bisa bikin paham lebih cepat.', 'UTS', 'Belajar collaborative', true, 80),
('Sleep is important. Begadang belajar tapi otak nggak fresh sama aja sia-sia.', 'UTS', 'Pentingnya tidur saat UTS', true, 75),
('Focus on understanding, not memorizing. Kalau paham, jawaban akan flow natural.', 'UTS', 'Cara belajar yang benar', true, 70),
('Buat jadwal belajar yang realistis. 8 jam sehari? Nggak sustainable. 2-3 jam focused study lebih efektif.', 'UTS', 'Time management UTS', true, 65);

-- ==========================================
-- UAS QUOTES (Ujian Akhir Semester)
-- ==========================================
INSERT INTO motivational_quotes (quote_text, theme, relevance_context, is_active, display_priority) VALUES
('UAS adalah marathon, bukan sprint. Pace yourself, jangan langsung all-out dari awal.', 'UAS', 'Strategi menghadapi UAS', true, 100),
('Udah sampai sini, jangan menyerah sekarang. Tinggal dikit lagi, you can do this!', 'UAS', 'Motivasi saat mendekati UAS', true, 95),
('Belajar itu penting, tapi jangan sampai sakit. Health comes first, grades come second.', 'UAS', 'Jaga kesehatan saat UAS', true, 90),
('Review mistakes dari UTS. Itu adalah cheat sheet terbaik untuk UAS.', 'UAS', 'Belajar dari kesalahan UTS', true, 85),
('Satu semester lagi selesai! Berikan yang terbaik, tapi ingat batas kemampuanmu.', 'UAS', 'Menjelang akhir semester', true, 80),
('Fokus pada mata kuliah yang paling berpengaruh ke IPK. Strategic studying > belajar semua secara equal.', 'UAS', 'Prioritas belajar UAS', true, 75),
('Past paper adalah harta karun. Kerjakan soal-soal tahun lalu untuk pattern recognition.', 'UAS', 'Latihan soal UAS', true, 70);

-- ==========================================
-- AWAL SEMESTER QUOTES
-- ==========================================
INSERT INTO motivational_quotes (quote_text, theme, relevance_context, is_active, display_priority) VALUES
('Fresh start, new opportunities! Semester ini akan lebih baik dari yang kemarin.', 'awal-semester', 'Semangat awal semester', true, 100),
('Buat goals yang spesifik dan measurable untuk semester ini. "Belajar rajin" terlalu vague.', 'awal-semester', 'Goal setting awal semester', true, 95),
('Kenalan sama teman baru, expand your network. Connections matter as much as grades.', 'awal-semester', 'Networking awal semester', true, 90),
('Datang ke kelas pertama itu penting. First impression to dosen matters.', 'awal-semester', 'Kehadiran awal semester', true, 85),
('Install sistem organisasi dari awal: calendar, to-do list, note-taking method. Future you will thank you.', 'awal-semester', 'Persiapan organisasi', true, 80),
('Jangan tunggu tugas menumpuk. Kerjakan sedikit-sedikit dari awal semester.', 'awal-semester', 'Anti-procrastination', true, 75);

-- ==========================================
-- LIBUR SEMESTER QUOTES
-- ==========================================
INSERT INTO motivational_quotes (quote_text, theme, relevance_context, is_active, display_priority) VALUES
('Libur bukan berarti berhenti belajar. Ini waktu terbaik untuk develop skill baru di luar kuliah.', 'libur', 'Produktif saat libur', true, 100),
('Ikut bootcamp, magang, atau proyek sampingan. Experience > Teori.', 'libur', 'Self-development saat libur', true, 95),
('Rest and recharge. Libur juga boleh buat santai dan quality time sama keluarga.', 'libur', 'Work-life balance', true, 90),
('Baca buku non-akademik. Fiction, biografi, self-help apapun yang bikin kamu tertarik.', 'libur', 'Reading habit', true, 85),
('Explore hobi baru. Kamu bukan cuma mahasiswa, kamu juga manusia yang butuh fun.', 'libur', 'Hobi dan passion', true, 80);

-- ==========================================
-- ORGANISASI QUOTES
-- ==========================================
INSERT INTO motivational_quotes (quote_text, theme, relevance_context, is_active, display_priority) VALUES
('Organisasi ngajarin skill yang kuliah nggak ajarin: leadership, komunikasi, manajemen konflik.', 'organisasi', 'Value organisasi', true, 100),
('Balance antara organisasi dan kuliah itu seni. Keduanya penting, tapi akademik tetap prioritas.', 'organisasi', 'Balance org dan akademik', true, 95),
('Di organisasi, kamu belajar dari failures. Dan itu valuable banget.', 'organisasi', 'Learning from org experience', true, 90),
('Active di organisasi bukan cuma untuk CV, tapi untuk develop diri dan networking.', 'organisasi', 'Tujuan organisasi', true, 85),
('Leadership bukan soal jabatan, tapi soal impact. Kontribusi kecil pun bermakna.', 'organisasi', 'Definisi kepemimpinan', true, 80);

-- ==========================================
-- KOMPETISI QUOTES
-- ==========================================
INSERT INTO motivational_quotes (quote_text, theme, relevance_context, is_active, display_priority) VALUES
('Ikut lomba bukan soal menang, tapi soal learning experience dan testing your limits.', 'kompetisi', 'Mindset kompetisi', true, 100),
('Kalah di kompetisi? Feedback gratisan untuk improve. Winners learn from defeats.', 'kompetisi', 'Belajar dari kekalahan', true, 95),
('Preparation is key. Start early, jangan tunggu deadline untuk mulai prepare.', 'kompetisi', 'Persiapan lomba', true, 90),
('Teamwork makes the dream work. Pilih tim yang solid, bukan yang cuma terkenal.', 'kompetisi', 'Team building', true, 85),
('Menang itu bonus, yang penting kamu challenge diri sendiri keluar dari comfort zone.', 'kompetisi', 'Growth mindset', true, 80);

-- ==========================================
-- MOTIVASI PRODUKTIVITAS
-- ==========================================
INSERT INTO motivational_quotes (quote_text, theme, relevance_context, is_active, display_priority) VALUES
('Productive ≠ Busy. Fokus pada impact, bukan aktivitas.', 'produktivitas', 'Definisi produktivitas', true, 100),
('Pomodoro technique works: 25 menit fokus, 5 menit break. Try it!', 'produktivitas', 'Teknik belajar', true, 95),
('Eliminate distraction: HP mode silent, social media di-block sementara. Deep work needs deep focus.', 'produktivitas', 'Fokus dan konsentrasi', true, 90),
('Deadline is not the enemy, procrastination is. Start now, even just 5 minutes.', 'produktivitas', 'Anti-procrastination', true, 85),
('Morning routine sets the tone for the day. Wake up early, win the day.', 'produktivitas', 'Morning routine', true, 80);

SELECT 'Successfully inserted ' || COUNT(*) || ' motivational quotes!' as message 
FROM motivational_quotes 
WHERE is_active = true;

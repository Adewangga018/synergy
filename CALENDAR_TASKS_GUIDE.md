# 📋 Fitur Aktivitas/Tugas di Kalender

## ✨ Fitur Baru

Anda sekarang bisa menambahkan **Aktivitas/Tugas** ke kalender untuk menandai jadwal yang bersifat momentual (sementara/sesekali) seperti:
- ✅ Deadline tugas kuliah
- ✅ Janji dengan dosen
- ✅ Beli keperluan kampus
- ✅ Review materi ujian
- ✅ Bimbingan TA
- ✅ Dan aktivitas lainnya

## 🎯 Keunggulan

| Fitur | Aktivitas/Tugas | Event Reguler |
|-------|----------------|---------------|
| **Bisa diselesaikan** | ✅ Ya (checkbox) | ❌ Tidak |
| **Prioritas** | ✅ Rendah/Sedang/Tinggi | ❌ Tidak ada |
| **Waktu opsional** | ✅ Ya (bisa tanpa jam) | ❌ Harus ada |
| **Purpose** | Task yang bisa di-complete | Jadwal tetap (kuliah, etc) |
| **Visual** | Checkbox + strikethrough | Icon + color badge |

## 📦 File yang Ditambahkan

### 1. Model
- [lib/models/user_task.dart](lib/models/user_task.dart)
  - Model untuk task dengan priority, completion status, due date/time

### 2. Service
- [lib/services/user_task_service.dart](lib/services/user_task_service.dart)
  - CRUD operations untuk tasks
  - Methods: create, update, delete, toggle completion
  - Query by date, month, priority, status

### 3. UI Pages
- [lib/pages/add_edit_task_page.dart](lib/pages/add_edit_task_page.dart)
  - Form untuk create/edit task
  - Support delete, priority selection, date/time picker

### 4. Database Schema
- [supabase_user_tasks_setup.sql](supabase_user_tasks_setup.sql)
  - Table `user_tasks` dengan RLS policies
  - Indexes untuk performance
  - Helper functions (get_tasks_for_date, get_overdue_tasks, etc)

### 5. Integration
- [lib/pages/calendar_page.dart](lib/pages/calendar_page.dart) (Updated)
  - Integrated tasks with events in calendar view
  - FAB button untuk add task
  - Checkbox untuk mark task as completed
  - Separate sections untuk tasks dan events

## 🚀 Cara Setup

### Step 1: Setup Database

1. Buka Supabase Dashboard → SQL Editor
2. Copy paste isi file [supabase_user_tasks_setup.sql](supabase_user_tasks_setup.sql)
3. Klik "Run" atau tekan Ctrl+Enter
4. Verify tabel `user_tasks` muncul di Table Editor

### Step 2: Test di Aplikasi

```bash
flutter pub get
flutter run
```

## 📱 Cara Pakai

### Menambah Task Baru

1. **Dari Kalender Page**:
   - Klik tombol **+ (FAB)** di kanan bawah
   - Atau pilih tanggal → klik "Tambah Task" jika tidak ada event/task

2. **Isi Form**:
   - **Judul**: Nama task (wajib)
   - **Deskripsi**: Detail task (opsional)
   - **Tanggal**: Deadline task
   - **Waktu**: Jam deadline (opsional - boleh kosong)
   - **Prioritas**: Rendah (🟢), Sedang (🟠), Tinggi (🔴)

3. **Simpan**: Klik "Simpan Task"

### Menyelesaikan Task

- **Di Kalender**: Centang checkbox di sebelah kiri task
- Task akan di-strikethrough dan warnanya berubah abu-abu

### Edit atau Hapus Task

1. **Tap task** yang ingin di-edit
2. Update informasi task
3. Klik "Update Task" atau "Hapus" (icon trash di AppBar)

## 📊 Struktur Data

### Table: `user_tasks`

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | UUID | ❌ | Primary key (auto-generated) |
| `user_id` | UUID | ❌ | Reference ke auth.users |
| `title` | TEXT | ❌ | Judul task |
| `description` | TEXT | ✅ | Deskripsi detail |
| `due_date` | DATE | ❌ | Tanggal deadline |
| `due_time` | TIME | ✅ | Waktu deadline (opsional) |
| `is_completed` | BOOLEAN | ❌ | Status selesai (default: false) |
| `priority` | TEXT | ❌ | 'low', 'medium', 'high' |
| `created_at` | TIMESTAMPTZ | ❌ | Waktu dibuat |
| `updated_at` | TIMESTAMPTZ | ❌ | Waktu diupdate (auto-update) |

### RLS Policies

✅ Users can only:
- **View** their own tasks
- **Insert** their own tasks
- **Update** their own tasks
- **Delete** their own tasks

## 🎨 UI/UX Features

### Calendar Page View

```
┌─────────────────────────────────────┐
│  Kalender                    📅 🔍  │
├─────────────────────────────────────┤
│       [Calendar Widget]              │
├─────────────────────────────────────┤
│  Senin, 24 Februari 2026            │
├─────────────────────────────────────┤
│  📋 Aktivitas/Tugas (2)              │
│  ┌──────────────────────────────┐   │
│  │ ☑ Selesaikan BAB 1 TA       │   │
│  │   🕐 14:00                   │   │
│  │   Tinggi 🔴                  │   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │ ☐ Review materi UTS          │   │
│  │   Sedang 🟠                  │   │
│  └──────────────────────────────┘   │
│                                      │
│  📅 Event (1)                        │
│  ┌──────────────────────────────┐   │
│  │ 📚 Kuliah Algoritma          │   │
│  │   🕐 08:00 - 10:00           │   │
│  │   📍 Gedung A101             │   │
│  └──────────────────────────────┘   │
│                                      │
│                                 [+]  │ ← FAB untuk add task
└─────────────────────────────────────┘
```

### Task Card Features

- **Checkbox**: Klik untuk mark as completed
- **Title**: Bold, strikethrough jika completed
- **Time**: Tampil jika ada due time
- **Description**: Tampil jika ada
- **Priority Badge**: Icon + warna sesuai priority
- **Tap**: Buka edit page

### Priority Colors

- 🟢 **Rendah** (Low): Green - untuk task yang tidak urgent
- 🟠 **Sedang** (Medium): Orange - task normal
- 🔴 **Tinggi** (High): Red - task urgent/penting

## 🔧 Service Methods

### UserTaskService

```dart
// Get all tasks
final tasks = await _taskService.getAllTasks();

// Get tasks untuk tanggal tertentu
final tasks = await _taskService.getTasksForDate(DateTime.now());

// Get tasks untuk bulan (untuk calendar)
final tasksByDate = await _taskService.getTasksForMonth(2026, 2);

// Get pending tasks
final pending = await _taskService.getPendingTasks();

// Get completed tasks
final completed = await _taskService.getCompletedTasks();

// Get overdue tasks
final overdue = await _taskService.getOverdueTasks();

// Create new task
final newTask = await _taskService.createTask(task);

// Update task
final updatedTask = await _taskService.updateTask(task);

// Toggle completion
await _taskService.toggleTaskCompletion(taskId, true);

// Delete task
await _taskService.deleteTask(taskId);

// Get statistics
final stats = await _taskService.getTasksCount();
// Returns: { 'total': 10, 'pending': 5, 'completed': 3, 'overdue': 2 }
```

## 📈 Best Practices

### Kapan Pakai Task vs Event?

**Gunakan Task untuk**:
- ✅ Aktivitas yang bisa di-complete (ada start & finish)
- ✅ Deadline tugas, assignment, project
- ✅ To-do items yang punya tanggal
- ✅ Reminder untuk beli/buat sesuatu
- ✅ Janji/appointment yang bisa di-cancel

**Gunakan Event untuk**:
- ✅ Jadwal tetap (kuliah, praktikum)
- ✅ Event yang sync dari Google Calendar
- ✅ Kompetisi, organisasi (dari fitur lain)
- ✅ Jadwal berulang (recurring)

### Tips Menggunakan Priority

- **High (🔴)**: Deadline besok/urgent, bimbingan penting
- **Medium (🟠)**: Deadline minggu ini, task normal
- **Low (🟢)**: Deadline masih lama, bisa dikerjakan kapanpun

## 🎯 Examples

### Contoh Task Mahasiswa

```dart
// Task 1: Urgent TA
UserTask(
  title: 'Selesaikan BAB 1 TA',
  description: 'Chapter introduction dan background',
  dueDate: DateTime(2026, 2, 25),
  dueTime: TimeOfDay(hour: 14, minute: 0),
  priority: TaskPriority.high,
  isCompleted: false,
);

// Task 2: Bimbingan
UserTask(
  title: 'Bimbingan dengan Dosen',
  description: 'Konsultasi progress TA',
  dueDate: DateTime(2026, 2, 26),
  dueTime: TimeOfDay(hour: 10, minute: 0),
  priority: TaskPriority.high,
  isCompleted: false,
);

// Task 3: Shopping (no specific time)
UserTask(
  title: 'Beli bahan presentasi',
  description: 'Kertas manila dan spidol',
  dueDate: DateTime(2026, 2, 24),
  dueTime: null, // ❌ Tidak ada waktu spesifik
  priority: TaskPriority.low,
  isCompleted: false,
);

// Task 4: Review (flexible)
UserTask(
  title: 'Review materi UTS Algoritma',
  description: 'Bab 1-5',
  dueDate: DateTime(2026, 2, 28),
  dueTime: null,
  priority: TaskPriority.medium,
  isCompleted: true, // ✅ Sudah selesai
);
```

## ⚡ Performance

### Optimizations

- **Indexes**: Query by `user_id`, `due_date`, `is_completed` sudah di-optimize
- **RLS**: Row Level Security memastikan user hanya lihat task sendiri
- **Caching**: Tasks di-load per bulan (sama seperti events)
- **Auto-update**: `updated_at` otomatis diupdate via trigger

### Database Functions

Helper functions untuk common queries:
- `get_pending_tasks_count(user_id)` - Count pending tasks
- `get_tasks_for_date(user_id, date)` - Get tasks for specific date
- `get_overdue_tasks(user_id)` - Get overdue tasks

## 🐛 Troubleshooting

### Task tidak muncul di kalender
**Solusi**:
1. Pastikan database schema sudah di-run
2. Check RLS policies di Supabase Dashboard
3. Verify user sudah login
4. Reload page (pull-to-refresh)

### Error saat create/update task
**Solusi**:
1. Check internet connection
2. Verify user_id valid
3. Check Supabase logs di Dashboard
4. Pastikan due_date tidak null

### Task tidak bisa di-delete
**Solusi**:
1. Check RLS policy "Users can delete own tasks"
2. Verify task.user_id == current_user.id
3. Check Supabase logs untuk error

## 📚 Related Features

- **Calendar Events**: Jadwal tetap dari course schedules, kompetisi, organisasi
- **Google Calendar Sync**: Sync events dari Google Calendar
- **Personal Notes**: Catatan pribadi (berbeda dari task)
- **Projects**: Project management (berbeda dari daily tasks)

## 🎉 Completion Indicators

Saat task di-complete:
- ✅ Checkbox hijau ter-centang
- ~~Text di-strikethrough~~
- 🎨 Warna berubah abu-abu
- 💾 Auto-save ke database
- 📊 Statistics updated

## 💡 Future Enhancements (Ideas)

- [ ] Notifikasi untuk reminder task
- [ ] Recurring tasks (task berulang)
- [ ] Sub-tasks (checklist dalam task)
- [ ] Task categories/tags
- [ ] Export tasks to PDF/Excel
- [ ] Statistics & analytics dashboard
- [ ] Collaboration (assign task ke user lain)

---

**Happy Task Managing! 📋✨**

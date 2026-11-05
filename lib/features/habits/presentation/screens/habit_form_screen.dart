import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:discipline/core/constants/app_constants.dart';
import 'package:discipline/core/services/notification_service.dart';
import 'package:discipline/core/utils/date_time_utils.dart';
import 'package:discipline/data/models/habit_model.dart';
import 'package:discipline/features/habits/presentation/providers/habit_provider.dart';

class HabitFormScreen extends StatefulWidget {
  final Habit? habit;

  const HabitFormScreen({super.key, this.habit});

  @override
  State<HabitFormScreen> createState() => _HabitFormScreenState();
}

class _HabitFormScreenState extends State<HabitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  late String _frequencyType;
  late List<int> _selectedDays;
  late bool _reminderEnabled;
  TimeOfDay? _reminderTime;
  String? _customDaysError;

  bool get isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final h = widget.habit;
    _nameController = TextEditingController(text: h?.name ?? '');
    _descriptionController = TextEditingController(text: h?.description ?? '');
    _frequencyType = h?.frequencyType ?? AppConstants.frequencyDaily;
    _selectedDays = List<int>.from(h?.customDays ?? []);
    _reminderEnabled = h?.reminderEnabled ?? false;

    if (h != null && h.reminderHour != null && h.reminderMinute != null) {
      _reminderTime = TimeOfDay(
        hour: h.reminderHour!,
        minute: h.reminderMinute!,
      );
    } else {
      _reminderTime = const TimeOfDay(hour: 20, minute: 0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleWeekday(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
      _selectedDays.sort();
      if (_selectedDays.isNotEmpty) {
        _customDaysError = null;
      }
    });
  }

  Future<void> _selectReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  Future<void> _saveHabit() async {
    setState(() {
      _customDaysError = null;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_frequencyType == AppConstants.frequencyCustom &&
        _selectedDays.isEmpty) {
      setState(() {
        _customDaysError = 'Vui lòng chọn ít nhất một ngày trong tuần';
      });
      return;
    }

    final provider = context.read<HabitProvider>();
    final now = DateTime.now();

    final habitToSave = Habit(
      id: widget.habit?.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      frequencyType: _frequencyType,
      customDays: _frequencyType == AppConstants.frequencyCustom
          ? _selectedDays
          : const [],
      reminderEnabled: _reminderEnabled,
      reminderHour: _reminderEnabled ? _reminderTime?.hour : null,
      reminderMinute: _reminderEnabled ? _reminderTime?.minute : null,
      isArchived: widget.habit?.isArchived ?? false,
      createdAt: widget.habit?.createdAt ?? now,
      updatedAt: now,
    );

    bool success;
    if (isEditing) {
      success = await provider.updateHabit(habitToSave);
    } else {
      success = await provider.addHabit(habitToSave);
    }

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Đã cập nhật thói quen'
                  : 'Đã tạo thói quen mới thành công',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Đã xảy ra lỗi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa thói quen' : 'Thêm thói quen mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Name Field
            TextFormField(
              key: const Key('habit_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên thói quen *',
                hintText: 'Ví dụ: Đọc sách 30 phút, Chạy bộ...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star_outline),
              ),
              maxLength: 60,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Tên thói quen không được để trống';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              key: const Key('habit_description_field'),
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả (tùy chọn)',
                hintText: 'Mục tiêu, ghi chú hoặc động lực...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Frequency Selector
            Text(
              'Tần suất thực hiện',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: AppConstants.frequencyDaily,
                  label: Text('Hằng ngày'),
                  icon: Icon(Icons.repeat),
                ),
                ButtonSegment(
                  value: AppConstants.frequencyCustom,
                  label: Text('Tùy chỉnh ngày'),
                  icon: Icon(Icons.calendar_month),
                ),
              ],
              selected: {_frequencyType},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _frequencyType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 12),

            // Custom Weekday Chips
            if (_frequencyType == AppConstants.frequencyCustom) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  final isSelected = _selectedDays.contains(day);
                  return FilterChip(
                    label: Text(DateTimeUtils.getWeekdayName(day)),
                    selected: isSelected,
                    onSelected: (_) => _toggleWeekday(day),
                    selectedColor: theme.colorScheme.primaryContainer,
                  );
                }),
              ),
              if (_customDaysError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _customDaysError!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],

            const Divider(height: 32),

            // Reminder Switch
            SwitchListTile(
              title: const Text('Nhắc nhở hằng ngày'),
              subtitle: const Text('Nhận thông báo khi đến giờ thực hiện'),
              value: _reminderEnabled,
              secondary: const Icon(Icons.notifications_active_outlined),
              onChanged: (val) async {
                if (val) {
                  final messenger = ScaffoldMessenger.of(context);
                  final notifService = context.read<NotificationService>();
                  final granted = await notifService.requestPermissions();
                  if (!granted && mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Chưa được cấp quyền thông báo. Vui lòng bật quyền thông báo trong cài đặt máy.',
                        ),
                      ),
                    );
                  }
                }
                if (mounted) {
                  setState(() {
                    _reminderEnabled = val;
                  });
                }
              },
            ),

            if (_reminderEnabled) ...[
              ListTile(
                title: const Text('Thời gian nhắc nhở'),
                subtitle: Text(
                  _reminderTime != null
                      ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
                      : 'Chưa đặt giờ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: _selectReminderTime,
              ),
            ],

            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _saveHabit,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Lưu thay đổi' : 'Lưu thói quen'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel Button
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy bỏ'),
            ),
          ],
        ),
      ),
    );
  }
}

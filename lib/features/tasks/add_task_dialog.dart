import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/constants/timer_constants.dart';
import '../../core/models/planned_task.dart';
import '../../core/models/task_tag.dart';
import '../../core/utils/dates.dart';
import '../today/daily_controller.dart';

Future<void> showAddTaskDialog({
  required BuildContext context,
  DateTimeRange? initialRange,
}) async {
  // Defer dialog until after current pointer update to avoid mouse tracker re-entrancy.
  await Future<void>.delayed(Duration.zero);
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (context) => _PlanningModal(initialRange: initialRange),
  );
}

class _PlanningModal extends ConsumerStatefulWidget {
  const _PlanningModal({this.initialRange});

  final DateTimeRange? initialRange;

  @override
  ConsumerState<_PlanningModal> createState() => _PlanningModalState();
}

class _PlanningModalState extends ConsumerState<_PlanningModal>
    with TickerProviderStateMixin {
  static const int _minCycleMinutes = 5;
  static const int _maxCycleMinutes = 60;
  static const int _cycleStep = 5;
  static const int _minTotalCycles = 1;
  static const int _maxTotalCycles = 20;

  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final AnimationController _ringController;
  late final AnimationController _pulseController;
  late final AnimationController _sweepController;

  late DateTimeRange _dateRange;
  TaskTag _tag = TaskTag.study;
  int _cycleMinutes = TimerConstants.defaultCycleMinutes;
  int _totalCycles = TimerConstants.defaultTotalCycles;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _noteController = TextEditingController();
    _ringController =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final today = dateOnly(DateTime.now());
    final initial = widget.initialRange;
    _dateRange = initial == null
        ? DateTimeRange(start: today, end: today)
        : DateTimeRange(
            start: dateOnly(initial.start),
            end: dateOnly(initial.end),
          );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _ringController.dispose();
    _pulseController.dispose();
    _sweepController.dispose();
    super.dispose();
  }

  int get _totalMinutes => _cycleMinutes * _totalCycles;

  String _formatTotalTime(int minutes) {
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    if (hours <= 0) return '${remain}m';
    if (remain == 0) return '${hours}h';
    return '${hours}h ${remain}m';
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  String _titleForRange(DateTimeRange range) {
    final start = dateOnly(range.start);
    final end = dateOnly(range.end);
    final today = dateOnly(DateTime.now());
    final tomorrow = today.add(const Duration(days: 1));

    if (_isSameDay(start, end)) {
      if (_isSameDay(start, tomorrow)) return '明天要獵什麼？';
      if (_isSameDay(start, today)) return '今天要獵什麼？';
    }

    return '獵取規劃';
  }

  String _dateLabel(DateTimeRange range) {
    final start = dateOnly(range.start);
    final end = dateOnly(range.end);
    final now = dateOnly(DateTime.now());
    final tomorrow = now.add(const Duration(days: 1));

    if (_isSameDay(start, end)) {
      final prefix = _isSameDay(start, tomorrow)
          ? '明天'
          : _isSameDay(start, now)
              ? '今天'
              : '選定日期';
      return '$prefix (${_formatDate(start)})';
    }

    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _rangeIncludesTodayOrPast(DateTimeRange range) {
    final today = dateOnly(DateTime.now());
    final start = dateOnly(range.start);
    return !today.isBefore(start);
  }

  List<DateTime> _expandRange(DateTimeRange range) {
    final start = dateOnly(range.start);
    final end = dateOnly(range.end);
    final days = end.difference(start).inDays;
    return List<DateTime>.generate(
      days + 1,
      (index) => start.add(Duration(days: index)),
    );
  }

  Future<void> _pickDateRange() async {
    final now = dateOnly(DateTime.now());
    final earliest = DateTime(now.year - 5, 1, 1);
    final latest = DateTime(now.year + 5, 12, 31);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: earliest,
      lastDate: latest,
      initialDateRange: _dateRange,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.accent,
              secondary: AppColors.accent,
              surface: AppColors.card,
            ),
            dialogTheme: theme.dialogTheme.copyWith(
              backgroundColor: AppColors.card,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) return;
    setState(() {
      _dateRange = DateTimeRange(
        start: dateOnly(picked.start),
        end: dateOnly(picked.end),
      );
    });
  }

  void _convertNoteToTitle() {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;
    final firstLine = note.split('\n').first.trim();
    if (firstLine.isEmpty) return;
    _titleController.text = firstLine;
    _titleController.selection = TextSelection.collapsed(
      offset: _titleController.text.length,
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final note = _noteController.text.trim();
    var title = _titleController.text.trim();
    if (title.isEmpty && note.isNotEmpty) {
      title = note.split('\n').first.trim();
      _titleController.text = title;
    }
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('請輸入任務名稱')));
      return;
    }

    final dateList = _expandRange(_dateRange);
    final plannedDates = <String>[];
    final plannedCycles = <int>[];
    final rawCycles =
        PlannedTask.distributeCycles(_totalCycles, dateList.length);
    final today = dateOnly(DateTime.now());
    final immediateEntries = <MapEntry<DateTime, int>>[];

    for (var i = 0; i < dateList.length; i++) {
      final cycles = rawCycles[i];
      if (cycles <= 0) continue;
      if (!dateList[i].isAfter(today)) {
        immediateEntries.add(MapEntry(dateList[i], cycles));
        continue;
      }
      plannedDates.add(ymd(dateList[i]));
      plannedCycles.add(cycles);
    }

    if (plannedDates.isEmpty && immediateEntries.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('請調整輪數或日期範圍')));
      return;
    }

    setState(() => _isSubmitting = true);

    for (final entry in immediateEntries) {
      await ref.read(dailyControllerProvider.notifier).addTaskForDate(
            date: entry.key,
            title: title,
            tag: _tag,
            totalCycles: entry.value,
            cycleMinutes: _cycleMinutes,
            note: note.isEmpty ? null : note,
          );
    }

    if (plannedDates.isNotEmpty) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final plan = PlannedTask(
        id: const Uuid().v4(),
        title: title,
        tag: _tag,
        totalCycles: plannedCycles.fold<int>(0, (sum, v) => sum + v),
        cycleMinutes: _cycleMinutes,
        plannedDates: plannedDates,
        plannedCycles: plannedCycles,
        note: note.isEmpty ? null : note,
        createdAtEpochMs: nowMs,
        updatedAtEpochMs: nowMs,
      );

      await ref.read(plannedTaskRepositoryProvider).save(plan);
    }

    await _sweepController.forward(from: 0);
    HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final totalLabel = _formatTotalTime(_totalMinutes);
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final title = _titleForRange(_dateRange);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 680,
                    maxHeight: media.size.height * 0.92,
                  ),
                  child: _PlanningCard(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        AbsorbPointer(
                          absorbing: _isSubmitting,
                          child: _buildContent(context, totalLabel, title),
                        ),
                        if (_isSubmitting)
                          _CompletionOverlay(animation: _sweepController),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String totalLabel,
    String headerTitle,
  ) {
    final totalProgress =
        (_totalMinutes / (_maxTotalCycles * _maxCycleMinutes)).clamp(0.0, 1.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    headerTitle,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RotationTransition(
                      turns: _ringController,
                      child: _AnimatedRing(
                        value: totalProgress,
                        size: 46,
                        strokeWidth: 8,
                        trackColor: const Color(0xFF0B1220),
                        progressColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: Tween<double>(begin: 0.96, end: 1.0)
                              .animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        '預計總時間：$totalLabel',
                        key: ValueKey(totalLabel),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              autofocus: true,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '寫論文、跑步、讀書...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.divider.withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _TagSelector(
              selected: _tag,
              onSelected: (tag) => setState(() => _tag = tag),
            ),
            const SizedBox(height: 18),
            _SliderRow(
              title: '每輪時長',
              valueLabel: '${_cycleMinutes}m',
              ringValue: _cycleMinutes / _maxCycleMinutes,
              child: Slider(
                value: _cycleMinutes.toDouble(),
                min: _minCycleMinutes.toDouble(),
                max: _maxCycleMinutes.toDouble(),
                divisions: (_maxCycleMinutes - _minCycleMinutes) ~/ _cycleStep,
                label: '$_cycleMinutes 分',
                onChanged: (value) {
                  setState(() => _cycleMinutes = value.round());
                },
              ),
            ),
            const SizedBox(height: 12),
            _SliderRow(
              title: '總輪數',
              valueLabel: '$_totalCycles',
              ringValue: _totalCycles / _maxTotalCycles,
              child: Slider(
                value: _totalCycles.toDouble(),
                min: _minTotalCycles.toDouble(),
                max: _maxTotalCycles.toDouble(),
                divisions: _maxTotalCycles - _minTotalCycles,
                label: '$_totalCycles 輪',
                onChanged: (value) {
                  setState(() => _totalCycles = value.round());
                },
              ),
            ),
            const SizedBox(height: 12),
            _DatePickerButton(
              label: _dateLabel(_dateRange),
              onPressed: _pickDateRange,
            ),
            if (_rangeIncludesTodayOrPast(_dateRange))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '包含今天或過去：會直接寫入對應日期',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    minLines: 3,
                    maxLines: 5,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: '今天想記得的事、靈感、提醒...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.divider.withValues(alpha: 0.6),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0B1220).withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: _convertNoteToTitle,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(
                        color: AppColors.divider.withValues(alpha: 0.7),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('轉任務'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                TextButton(
                  onPressed:
                      _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                const Spacer(),
                Text(
                  totalLabel,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _PulseButton(
                  enabled: !_isSubmitting,
                  controller: _pulseController,
                  label: '就位！',
                  onPressed: _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanningCard extends StatelessWidget {
  const _PlanningCard({
    required this.child,
    required this.borderRadius,
  });

  final Widget child;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.45),
      surfaceTintColor: Colors.transparent,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.86),
              borderRadius: borderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  blurRadius: 22,
                  spreadRadius: -12,
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TagSelector extends StatelessWidget {
  const _TagSelector({
    required this.selected,
    required this.onSelected,
  });

  final TaskTag selected;
  final ValueChanged<TaskTag> onSelected;

  Color _chipColor(TaskTag tag) {
    switch (tag) {
      case TaskTag.urgent:
        return const Color(0xFFEF4444);
      case TaskTag.study:
        return const Color(0xFF22C55E);
      case TaskTag.workout:
        return const Color(0xFF3B82F6);
      case TaskTag.life:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TaskTag.values.map((tag) {
            final color = _chipColor(tag);
            final active = tag == selected;

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(tag),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active
                        ? color.withValues(alpha: 0.18)
                        : const Color(0xFF0B1220).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: active
                          ? color
                          : AppColors.divider.withValues(alpha: 0.6),
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.45),
                              blurRadius: 16,
                              spreadRadius: -6,
                            ),
                          ]
                        : const [],
                  ),
                  child: Text(
                    tag.label,
                    style: TextStyle(
                      color: active ? color : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.title,
    required this.valueLabel,
    required this.ringValue,
    required this.child,
  });

  final String title;
  final String valueLabel;
  final double ringValue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            _AnimatedRing(
              value: ringValue,
              size: 28,
              strokeWidth: 5,
              trackColor: const Color(0xFF0B1220),
              progressColor: AppColors.accent,
            ),
            const SizedBox(width: 8),
            Text(
              valueLabel,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '日期範圍：$label',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );
  }
}

class _PulseButton extends StatelessWidget {
  const _PulseButton({
    required this.enabled,
    required this.controller,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final AnimationController controller;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );

    return ScaleTransition(
      scale: enabled ? scale : const AlwaysStoppedAnimation(1.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.accentDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0B1220),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedRing extends StatelessWidget {
  const _AnimatedRing({
    required this.value,
    required this.size,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(
            value: v,
            strokeWidth: strokeWidth,
            trackColor: trackColor,
            progressColor: progressColor,
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
  });

  final double value;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    final sweep = 2 * pi * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}

class _CompletionOverlay extends StatelessWidget {
  const _CompletionOverlay({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final progress = animation.value;
            return Stack(
              children: [
                Opacity(
                  opacity: progress,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth * 1.4;
                      final height = constraints.maxHeight * 1.2;
                      final dx = -constraints.maxWidth +
                          constraints.maxWidth * 2 * progress;

                      return Transform.translate(
                        offset: Offset(dx, -constraints.maxHeight * 0.2),
                        child: Transform.rotate(
                          angle: -0.15,
                          child: Container(
                            width: width,
                            height: height,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.accent.withValues(alpha: 0.2),
                                  AppColors.accentDark.withValues(alpha: 0.55),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Center(
                  child: Opacity(
                    opacity: progress < 0.4 ? 0 : 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.check_circle, color: AppColors.accent, size: 42),
                        SizedBox(height: 8),
                        Text(
                          '明日獵取就緒！お疲れ様',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

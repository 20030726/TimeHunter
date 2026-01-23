import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/hunt_variant.dart';
import '../../core/models/task_tag.dart';
import '../../core/utils/iterable_ext.dart';
import '../today/daily_controller.dart';
import 'fullscreen_control.dart';
import 'music_control.dart';
import 'timer_controller.dart';
import 'timer_layouts.dart';

class HuntTimerPage extends ConsumerStatefulWidget {
  const HuntTimerPage({
    super.key,
    required this.taskId,
    this.variant = HuntVariant.huntHud,
  });

  final String taskId;
  final HuntVariant variant;

  @override
  ConsumerState<HuntTimerPage> createState() => _HuntTimerPageState();
}

class _HuntTimerPageState extends ConsumerState<HuntTimerPage> with WidgetsBindingObserver {
  // UI specific state
  bool _showSuccess = false;
  bool _hasShownCompletion = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // TimerController handles restoring its own state
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // TimerController handles its own dispose logic
    // ref.read(backgroundAudioProvider).stop(); // This is now handled by audioController
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-sync timer state if app resumes (TimerController handles this internally)
      ref.read(timerStateProvider.notifier).build(); // Re-initialize state based on repository
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch relevant state from controllers
    final dailyAsync = ref.watch(dailyControllerProvider);
    final timerStateAsync = ref.watch(timerStateProvider);

    return Scaffold(
      body: SafeArea(
        child: dailyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (daily) {
            final task = daily.tasks.where((t) => t.id == widget.taskId).firstOrNull;

            // Only proceed if timerState is available and not loading/error
            return timerStateAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Timer Error: $e')),
              data: (timerState) {
                final isFinished =
                    timerState.remainingSeconds == 0 && !timerState.isRunning;

                if (!isFinished) {
                  _hasShownCompletion = false;
                }

                // Update _showSuccess based on timer completion for UI animation
                if (isFinished && !_hasShownCompletion) {
                  _hasShownCompletion = true;
                  // This means a timer has just finished, trigger success animation
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      _showSuccess = true;
                    });
                    Future.delayed(const Duration(milliseconds: 850), () {
                      if (!mounted) return;
                      setState(() {
                        _showSuccess = false;
                      });
                    });
                  });
                }

                final remaining = timerState.remainingSeconds;
                final cycleMinutes = timerState.cycleMinutes;
                final isRunning = timerState.isRunning;

                final ratio = remaining <= 0
                    ? 1.0
                    : 1.0 - (remaining / (cycleMinutes * 60));

                final taskColor = task == null
                    ? const Color(0xFF22C55E)
                    : Color(task.tag.colorValue);
                final showOverlayTools =
                    widget.variant != HuntVariant.splitCommand;

                final layoutData = TimerLayoutData(
                  variant: widget.variant,
                  title: task?.title ?? '開獵',
                  tagLabel: task?.tag.label ?? '',
                  remainingSeconds: remaining,
                  ratio: ratio,
                  completedCycles: task?.completedCycles ?? 0,
                  totalCycles: task?.totalCycles ?? 0,
                  isRunning: isRunning,
                  showSuccess: _showSuccess,
                  slackRemaining: daily.slackRemaining,
                  canSlack: daily.slackRemaining > 0,
                  cycleMinutes: cycleMinutes,
                  accent: taskColor,
                  onClose: () => Navigator.of(context).maybePop(),
                  onToggleRun: isRunning
                      ? () => ref.read(timerStateProvider.notifier).pause()
                      : () {
                          if (task != null) {
                            ref.read(timerStateProvider.notifier).start(widget.taskId, task);
                          }
                        },
                  onSlack: () => ref.read(timerStateProvider.notifier).slack15(),
                  onCycleChanged: (next) {
                    ref.read(timerStateProvider.notifier).updateCycleMinutes(next);
                    if (task != null) {
                      ref.read(dailyControllerProvider.notifier).updateCycleMinutes(task.id, next);
                    }
                  },
                );

                return Stack(
                  children: [
                    TimerLayouts.build(layoutData),
                    if (showOverlayTools)
                      Positioned.fill(
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 56, right: 18),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const MusicControl(compact: true),
                                  if (kIsWeb) ...[
                                    const SizedBox(width: 8),
                                    const FullscreenControl(compact: true),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    TimerSuccessOverlay(
                      show: _showSuccess,
                      color: const Color(0xFF22C55E),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

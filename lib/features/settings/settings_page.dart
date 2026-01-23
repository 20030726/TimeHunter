import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../showcase/variant_layouts.dart';
import 'plan_reminder_controller.dart';
import 'variant_settings_controller.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variantAsync = ref.watch(variantSettingsProvider);
    final reminderAsync = ref.watch(planReminderProvider);
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: variantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (selected) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '帳號',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline),
                      const SizedBox(width: 12),
                      Expanded(
                        child: authState.when(
                          loading: () => const Text('讀取中...'),
                          error: (e, _) => Text('錯誤：$e'),
                          data: (user) => Text(
                            user?.email ?? '未登入',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(authRepositoryProvider).signOut();
                        },
                        child: const Text('登出'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '明日規劃提醒',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              reminderAsync.when(
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('讀取提醒設定...'),
                      ],
                    ),
                  ),
                ),
                error: (e, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('提醒設定讀取失敗：$e'),
                  ),
                ),
                data: (settings) {
                  final timeLabel = settings.timeOfDay.format(context);
                  return Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: settings.enabled,
                          onChanged: (value) {
                            ref
                                .read(planReminderProvider.notifier)
                                .setEnabled(value);
                          },
                          title: const Text('啟用提醒'),
                          subtitle: const Text('晚上提醒你規劃明天任務'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          enabled: settings.enabled,
                          leading: const Icon(Icons.notifications_outlined),
                          title: const Text('提醒時間'),
                          subtitle: Text(
                            settings.enabled ? '每天提醒一次' : '已關閉',
                          ),
                          trailing: Text(timeLabel),
                          onTap: settings.enabled
                              ? () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: settings.timeOfDay,
                                  );
                                  if (picked == null) return;
                                  await ref
                                      .read(planReminderProvider.notifier)
                                      .setTime(picked);
                                }
                              : null,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                '主畫面風格',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              RadioGroup<HuntVariant>(
                groupValue: selected,
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(variantSettingsProvider.notifier).setVariant(value);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: HuntVariant.values
                      .map(
                        (variant) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: RadioListTile<HuntVariant>(
                            value: variant,
                            title: Text(variant.label),
                            subtitle: Text(variant.tagline),
                            secondary: _ColorDot(color: _accentFor(variant)),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _accentFor(HuntVariant variant) {
    switch (variant) {
      case HuntVariant.huntHud:
        return const Color(0xFF39FF88);
      case HuntVariant.timelineRail:
        return const Color(0xFFF59E0B);
      case HuntVariant.splitCommand:
        return const Color(0xFFF97316);
      case HuntVariant.monoStrike:
        return const Color(0xFF00FF7F);
      case HuntVariant.stellarHunt:
        return const Color(0xFF39FF14);
      case HuntVariant.arcadeBoard:
        return const Color(0xFF00F5FF);
      case HuntVariant.orbitCommand:
        return const Color(0xFF22D3EE);
      case HuntVariant.auroraGlass:
        return const Color(0xFF22C55E);
    }
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

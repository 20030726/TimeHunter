# TimeHunter 架構規範 (ARCH_RULES)

本文件基於目前 timehunter 專案結構整理規範與改進建議，做為之後開發與 code review 的準則。

## 現況結構對照 (Clean Architecture)
- Composition Root / DI：`lib/main.dart`
- Presentation：`lib/features/**`、`lib/widgets/**`、`lib/app/**`
- Domain：`lib/core/models/**`、`lib/core/utils/**`
- Data / Repository Impl：`lib/core/storage/**`、`lib/core/auth/**`
- 外部設定：`lib/firebase_options.dart`

### 目前觀察
- 已有 Repository 介面與 Riverpod Provider：`lib/core/storage/*`、`lib/core/auth/auth_repository.dart`、`lib/app/providers.dart`
- UI 仍含部分業務邏輯與副作用（計時、音效、排程計算）

## 核心架構：Clean Architecture 分層原則
### 分層定義
- Presentation：Widget / Page / UI state，只負責呈現與事件轉發。
- Application：Controllers / UseCases（Riverpod `AsyncNotifier`/`StateNotifier` 或 BLoC）。
- Domain：Entities/Value Objects、Repository 介面（不依賴 Flutter）。
- Data：Repository 實作（只做資料組合與轉換）。
- Services：所有外部 API/IO（Firebase、Hive、Audio、HTTP 等）集中於 `lib/services/`。

### 依賴規則（必須遵守）
- 依賴方向：Presentation → Application → Domain → Data → Services。
- 禁止在 Domain/Data 直接 import Flutter UI。
- 禁止 UI 直接呼叫 Services 或 Firebase SDK。
- `lib/main.dart` 僅負責初始化與 DI，不執行業務流程。

## 邏輯解耦規範（UI）
- UI 禁止撰寫業務邏輯；所有狀態變更、計算、IO 需透過 Provider/BLoC。
- UI 可保留「純視覺」或「短暫互動」邏輯（動畫、表單輸入狀態）。
- 需搬離的代表性邏輯：
  - 計時流程/音效/存檔：`lib/features/timer/hunt_timer_page.dart`
  - 時間排程計算：`lib/features/records/records_page.dart`
- 建議新增控制器：
  - `TimerController`（計時狀態 + 存取 `TimerRepository`）
  - `AudioController`（統一播放/停止）

## 服務抽象化規範（必須）
- 所有 API 調用（如 Firebase）只能在 `lib/services/` 內發生。
- Repository 實作只能呼叫 Services，不可直接呼叫 Firebase SDK。
- 需要調整的位置：
  - Firestore 存取：`lib/core/storage/firebase_daily_repository.dart`
  - FirebaseAuth：`lib/core/auth/auth_repository.dart`
  - Firebase 初始化：`lib/main.dart`
- 建議目錄：
  - `lib/services/firebase/`（Firestore/Auth/Init）
  - `lib/services/storage/`（Hive 封裝）
  - `lib/services/audio/`（AudioPlayer 封裝）

## 組件優化（共用元件/Mixin 提議）
- 倒數格式/顯示重複：`lib/features/showcase/variant_layouts.dart`、`lib/features/timer/timer_layouts.dart`
  → 抽成 `lib/core/utils/time_format.dart` + `lib/widgets/countdown_text.dart`
- AsyncValue loading/error/data 模式重複：`lib/features/today/today_page.dart`、`lib/features/settings/settings_page.dart`、`lib/features/records/records_page.dart`、`lib/features/showcase/variant_gallery_page.dart`
  → 抽成 `lib/widgets/async_view.dart`
- `firstOrNull` extension 只在單一檔案中定義：`lib/features/timer/hunt_timer_page.dart`
  → 抽成 `lib/core/utils/iterable_ext.dart` 或改用 `collection` 套件
- 音效播放流程與資源釋放重複：`lib/features/timer/hunt_timer_page.dart`、`lib/app/audio_service.dart`
  → 抽成 `lib/services/audio/audio_player_service.dart` 或共用 mixin
- 多處 AlertDialog 版型相似：`lib/features/tasks/add_task_dialog.dart`、`lib/features/records/records_page.dart`、`lib/features/today/today_page.dart`
  → 抽成 `lib/widgets/dialogs/*`（表單/確認對話框）

## 硬編碼清理（建議抽離到常量）
- 顏色值：`lib/features/showcase/variant_layouts.dart`、`lib/features/timer/timer_layouts.dart`、`lib/widgets/*`、`lib/features/today/today_page.dart`
  → 集中到 `lib/app/theme.dart` 或 `lib/core/constants/colors.dart`
- 時間/數值常量：
  - Slack 次數：`lib/core/models/daily_data.dart`
  - Slack 增加 15 分鐘：`lib/features/timer/hunt_timer_page.dart`
  - 週期預設/選項：`lib/features/tasks/add_task_dialog.dart`
  - Timeline 尺寸/分鐘高度：`lib/features/records/records_page.dart`
  → 集中到 `lib/core/constants/timer_constants.dart`
- 音效檔名與佔位字串：`lib/features/timer/hunt_timer_page.dart`、`lib/app/audio_service.dart`
  → 集中到 `lib/core/constants/audio_assets.dart`
- 動畫時間、尺寸、padding：`lib/features/showcase/variant_layouts.dart`、`lib/features/timer/timer_layouts.dart`、`lib/widgets/heatmap_calendar.dart`、`lib/widgets/progress_ring.dart`
  → 集中到 `lib/core/constants/ui_constants.dart`

## Code Review Checklist
- UI 不含業務邏輯、IO；只呼叫 Provider/BLoC。
- Firebase/外部 API 只在 `lib/services/`。
- 新增功能必須落在正確層級與依賴方向。
- 遇到重複 UI/邏輯，優先抽 Shared Widget/Helper。
- 新增硬編碼需同步放入常量檔。

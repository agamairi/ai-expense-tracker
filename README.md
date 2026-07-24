# BAInk

A fully on-device, privacy-first AI expense tracker for Android that automatically detects and categorizes transactions from bank and payment notifications.

## How it works

1. **Capture**: A native background notification listener captures incoming bank and payment notifications.
2. **Extract**: An on-device small language model (FunctionGemma via `flutter_gemma`, using structured function-calling) extracts the amount, merchant, category, and transaction type.
3. **Review**: The user receives an interactive notification to Approve, Reject, or Edit the captured transaction.
4. **Store**: Approved transactions are stored locally via Drift/SQLite.

Inference is 100% on-device. No notification text or financial data is ever sent to any server.

## Features

* **Notification-based auto-capture**: Seamlessly log expenses as notifications arrive.
* **On-device AI extraction**: Structured data parsing using FunctionGemma function-calling.
* **Approve/Reject/Edit workflow**: Interactive notifications for manual review before saving.
* **AI chat assistant**: Log expenses manually using natural language (e.g., "Spent 15 on coffee").
* **Dashboard analytics**: Visualize spending with Line, Area, Bar, and Pie charts, plus a period selector.
* **Account management**: Track live balances across multiple accounts.
* **Budget management**: Set and track budgets per category.
* **Auto-categorization rules**: Map specific merchants to categories automatically.
* **Audit log**: Review history with search, filtering, date-range selection, and swipe actions.
* **Export**: Export data to CSV and JSON.

## Architecture

BAInk utilizes a persistent-background-engine design. A `FlutterEngine` is created at process start in `ExpenseTrackerApplication`, completely decoupled from the Activity lifecycle. This ensures that the notification capture and AI extraction pipeline survives even when the app is backgrounded or swiped away.

The codebase follows Clean Architecture principles, separated into Presentation, Domain, and Data layers.

## Tech stack

* **Framework**: Flutter
* **Native**: Kotlin (for Android services and receiver)
* **Local Storage**: Drift (SQLite)
* **AI Inference**: `flutter_gemma` (FunctionGemma 270M model)
* **UI**: Material 3

## Getting started

```bash
flutter pub get
flutter run
```

**Note**: You will need a real Android device or a compatible emulator, as the app requires `NotificationListenerService` and supports on-device model inference. The AI model (approximately 271MB) will download on first use from the Settings screen.

---
title: System Architecture
type: architecture
author: Antigravity
tags: [architecture, flutter, android, gemma]
---

# Ai Expense Tracker Architecture

## Overview
Ai Expense Tracker is a privacy-first, on-device AI-powered financial application. It uses a local Small Language Model (SLM) via `flutter_gemma` to automatically process and categorize transactions from SMS/Push notifications. 

## Core Components

### 1. Presentation Layer (Flutter / UI)
- **MainScreen**: App shell with a custom bottom navigation bar and side-by-side Floating Action Button.
- **DashboardView**: Displays real-time financial health, net cashflow, and category budget rings. Tapping rings navigates directly to a filtered Audit Log.
- **AuditLogView**: A granular review screen for all transactions. Provides chips for filtering by category and tabs for Approved/Rejected/Pending statuses. Cards are expandable and display exact AI parsing contexts.
- **ChatView**: An AI assistant interface where users can naturally log expenses (e.g., "I spent \$12 on lunch"). This seamlessly connects to `flutter_gemma` to extract structured transactions and auto-approves them.
- **SettingsView**: Includes the actual `flutter_gemma` model download mechanism (FunctionGemma 270M) tracking byte-level progress.

### 2. Domain Layer (Business Logic)
- **Models**: Defines core data structures (`Transaction`, `AppRule`, `Account`).
- **Services**: 
  - `SlmEngineService`: Manages Gemma 3 inference, prompt formulation, and parsing of user queries or notifications.
  - `NotificationListenerService`: (Kotlin Native) intercepts device notifications and routes them to Flutter.

### 3. Data Layer (Drift SQLite)
- Uses `drift` for robust local storage.
- Repositories (`TransactionRepositoryImpl`, `AppRuleRepositoryImpl`) provide structured access and caching over raw SQL queries.

## Data Flow (AI Extraction)
1. User enters text in `ChatView` (or a background notification is received).
2. `SlmEngineService` constructs a structured prompt.
3. `flutter_gemma` processes the prompt on-device using the FunctionGemma (270M) model.
4. Response is regex-parsed into a `Transaction` object.
5. Transaction is auto-approved, saved via `TransactionRepository`, and surfaced immediately in the UI./Reject/Edit)
6. Edit -> Deep Link -> Flutter UI

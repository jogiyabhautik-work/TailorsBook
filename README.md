# TailorsBook

TailorsBook is a comprehensive Flutter and Supabase-powered application designed specifically for tailoring shop management. It streamlines order tracking, worker assignments, customer measurements, and payment flows in a single, cohesive interface.

## 🚀 Features

- **Order Management:** Track orders from creation to delivery with detailed status histories.
- **Worker Assignments:** Assign stitching tasks to external workers or track in-house ("self-stitch") tasks.
- **Fabric Tracking:** Keep track of fabric deposits, current inventory, and usage per order.
- **Advanced Measurements:** Save and manage highly customizable measurement templates for different clothing types (e.g., shirts, pants, suits).
- **Payment & Invoicing:** Track advances, calculate remaining balances, and generate printable PDF invoices for customers.
- **Realtime Sync:** Fully responsive realtime database synchronization using Supabase.
- **Offline Resiliency:** Cached local stats and offline capabilities for seamless usage in low-connectivity environments.

## 📸 Screenshots

> *Add screenshots here*
> ![Dashboard Placeholder](assets/images/dashboard_placeholder.png)

## 🛠️ Technology Stack

- **Frontend:** Flutter (Dart)
- **Backend & Database:** Supabase (PostgreSQL, Realtime, Auth, Storage)
- **Architecture:** Provider-based state management with localized services.

## 📦 Project Structure

The codebase strictly adheres to a clean, scalable production structure:

```text
lib/
 â”œâ”€â”€ core/          # Shared utilities, constants, services, and extensions
 â”œâ”€â”€ models/        # Application data models (Orders, Workers, Payments)
 â”œâ”€â”€ providers/     # State management providers
 â”œâ”€â”€ screens/       # Feature-based UI screens (Auth, Orders, Settings, etc.)
 â”œâ”€â”€ widgets/       # Reusable UI components
 â””â”€â”€ main.dart      # Application entry point
```

## ⚙️ Setup & Installation

### 1. Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (latest stable version recommended)
- A [Supabase](https://supabase.com/) project

### 2. Environment Configuration
Clone the repository, then copy the environment template to create your `.env` file:
```bash
cp .env.example .env
```
Edit `.env` and fill in your Supabase credentials:
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 3. Database Migration
Ensure all tables are properly created in your Supabase project.
Execute the SQL migrations found in `supabase/migrations/` in order via the Supabase SQL Editor:
1. `001_initial_schema.sql`
2. `002_worker_system.sql`
3. `003_payment_system.sql`
4. `004_final_stabilization.sql`

### 4. Build and Run
Fetch the dependencies and run the application:
```bash
flutter clean
flutter pub get
flutter run
```

## 🔒 Security & Release

For production builds, the repository is configured to exclude sensitive configurations, keystores, and debug logs. Ensure that `.env` is **never** checked into version control.

To create a release APK:
```bash
flutter build apk --release
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](#) if you want to contribute.

## 📝 License

Copyright © 2026 TailorsBook. All Rights Reserved.

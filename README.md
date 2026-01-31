# 🐙 Didit - Your Action Companion

**Didit** is a premium, mobile-first daily action tracking application designed to help you stay focused on your daily routines with a sleek, modern aesthetic.

---

## ✨ Key Features

-   **🎯 Action Tracking**: Easily track daily actions like Coffee, Water, Pills, Exercise, and more.
-   **📈 Visual Statistics**: Detailed insights with interactive charts showing performance over 7, 14, or 30 days.
-   **✨ Premium Design**: A beautiful, fluid interface featuring smooth gradients and micro-animations tailored for a premium feel.
-   **⚙️ Custom Goals**: Set individual daily goals for each action (Achieve or Avoid) to track your progress effectively.
-   **🔄 Smart Reset System**: Daily reset logic with a credits system to keep your tracking flexible.
-   **☁️ Cloud Sync**: Securely backup and restore your data using Google Drive (Android) or iCloud (iOS).
-   **📊 Google Analytics**: Integrated event tracking to monitor tutorial completion and key user interactions.
-   **🌍 Global Support**: Multi-lingual support for 7 languages:
    -   Korean, English, Japanese, Chinese, Spanish, French, and German.

---

## 🛠 Tech Stack

-   **Framework**: [Flutter](https://flutter.dev) (iOS & Android)
-   **Cloud Integration**: Google Drive API & iCloud Storage
-   **Analytics**: Firebase Analytics
-   **State Management**: [Provider](https://pub.dev/packages/provider)
-   **Icons**: [Lucide Icons](https://pub.dev/packages/lucide_icons)
-   **Animations**: [Flutter Animate](https://pub.dev/packages/flutter_animate)
-   **Typography**: [Google Fonts (Outfit)](https://fonts.google.com/specimen/Outfit)
-   **Persistence**: [Shared Preferences](https://pub.dev/packages/shared_preferences)

---

## 🚀 Getting Started

### Prerequisites

-   Flutter SDK (v3.0.0 or higher)
-   Android SDK / Xcode for emulators
-   Firebase project setup (for Analytics)
-   Cloud platform configuration (Google Cloud Console / Apple Developer Portal)

### Installation

1.  **Clone the project**
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the application**:
    ```bash
    flutter run
    ```

---

## 📂 Project Structure

-   `lib/main.dart`: Main entry, Firebase initialization, and app structure.
-   `lib/models/action.dart`: Data structures for Action configurations and states.
-   `lib/providers/`: Business logic and state management for actions and localization.
-   `lib/services/`: External services for Analytics, Cloud Backup, and Ads.
-   `lib/widgets/`: Core UI components (Action circles, Stats views).
-   `lib/screens/`: Feature screens (Main navigation, Goals setup, Settings).

---

## 📱 Platforms

This project is optimized specifically for:
-   **Android**
-   **iOS**

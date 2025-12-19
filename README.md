# 💬 MyChart — Professional Flutter Chat Application

A **feature-rich, real-time messaging application** built with **Flutter**, **Firebase**, and **Riverpod**. MyChart delivers seamless communication with text messages, voice notes, media sharing, video/audio calls, message reactions, and more.

---

## 📱 Features

### ✨ Core Messaging

* **Real-time Messaging** — Instant text messages with live updates
* **Voice Messages** — Record and send high-quality voice notes with duration display
* **Message Reactions** — React with emojis (❤️ 👍 😂 😮 😢 🙏 🔥 🎉)
* **Reply to Messages** — Quote and reply with message preview
* **Edit Messages** — Edit sent messages with an *edited* indicator
* **Delete Messages** — Remove messages from conversations
* **Copy Messages** — Copy message text to clipboard
* **Read Receipts** — Double checkmarks for read status
* **Typing Indicators** — See when friends are typing *(optional)*
* **Online Status** — Real-time online/offline indicators
* **Last Seen** — View users’ last active time

### 📎 Media & Calls

* Image & media sharing
* Audio calls
* Video calls (powered by **Zego Cloud**)

---

## 🚀 Getting Started

### ✅ Prerequisites

Make sure you have the following installed:

* **Flutter SDK** ≥ 3.19.0
* **Dart SDK** ≥ 3.3.0
* **Firebase Account**
* **Zego Cloud Account**
* **Cloudinary Account**

---

## 📥 Installation

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/AnishTiwari5077/new_chart.git
cd new_chart
```

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

---

## 🔥 Firebase Setup

### 3.1 Create Firebase Project

1. Go to **Firebase Console**
2. Click **Add Project**
3. Project name: `MyChart`
4. Complete the setup wizard

### 3.2 Add Android App

* Package name: `com.example.new_chart`
* Download `google-services.json`
* Place it in:

```
android/app/
```

### 3.3 Add iOS App

* Bundle ID: `com.example.newChart`
* Download `GoogleService-Info.plist`
* Place it in:

```
ios/Runner/
```

### 3.4 Enable Firebase Services

Enable the following in Firebase Console:

* **Authentication** → Email/Password
* **Cloud Messaging** *(optional)*

---

## 🔐 Firebase Security Rules

### Firestore Rules (`firestore.rules`)

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // ============================================
    // SIMPLE & WORKING RULES
    // ============================================
    
    // Users Collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Chats Collection
    match /chats/{chatId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
      
      // Messages Subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
      }
    }
    
    // Friend Requests Collection - SIMPLIFIED
    match /friendRequests/{requestId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Notifications Collection
    match /notifications/{notificationId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```



---

## ☁️ Cloudinary Setup

### 4.1 Get Credentials

* Create a Cloudinary account
* Note your **Cloud Name**
* Create an **Unsigned Upload Preset**

### 4.2 Update Configuration

```dart
StorageRepository(
  cloudName: 'YOUR_CLOUD_NAME',
  uploadPreset: 'YOUR_UPLOAD_PRESET',
)
```

---

## 📞 Zego Cloud (Video & Audio Calls)

### 5.1 Get Credentials

* Create a project in **Zego Console**
* Get **App ID** and **App Sign**

### 5.2 Update Configuration

```dart
class ZegoService {
  static const int appID = YOUR_APP_ID;
  static const String appSign = 'YOUR_APP_SIGN';
}
```

---

## ⚙️ Platform Configuration

### 🤖 Android

* **Minimum SDK**: 21

`android/app/build.gradle`

```gradle
android {
  compileSdkVersion 34
  defaultConfig {
    applicationId "com.example.new_chart"
    minSdkVersion 21
    targetSdkVersion 34
    versionCode 1
    versionName "1.0.0"
  }
}
```

**Android Permissions** (`AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

---

### 🍎 iOS

* **Minimum iOS**: 12.0

`ios/Podfile`

```ruby
platform :ios, '12.0'
```

**Permissions** (`Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access for voice messages</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo access for sharing images</string>
```

---

## ▶️ Run the App

```bash
flutter doctor
flutter run
flutter run --release
```

---

## ⭐ Support

If you find this project helpful, **give it a star** on GitHub and feel free to contribute!

---

**Made with ❤️ using Flutter**


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
*  **Push Notification**-  For sending and receving message,friend Request, Reject freind (Implemented using Nodejs)

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
## ScreenShot (Light Mood)
<img width="315" height="700" alt="Screenshot_1766143334" src="https://github.com/user-attachments/assets/d77b9e65-ad70-41b1-8839-a42bfedad5bb" />
<img width="315" height="700" alt="Screenshot_1766143266" src="https://github.com/user-attachments/assets/33be433e-8d84-464c-b887-1060c3424de5" />
<img width="315" height="700" alt="Screenshot_1766143263" src="https://github.com/user-attachments/assets/19d9e556-17ab-4874-86dd-b59f56d18c32" />
<img width="315" height="700" alt="Screenshot_1766143239" src="https://github.com/user-attachments/assets/2c26b49e-6ac7-413e-ac52-96473a156619" />
<img width="315" height="700" alt="Screenshot_1766143170" src="https://github.com/user-attachments/assets/38866a34-f3e7-46a5-ba10-b21a448d80fa" />
<img width="315" height="700" alt="Screenshot_1766143166" src="https://github.com/user-attachments/assets/722e3984-aab0-49da-8c89-f03f5819f718" />
<img width="315" height="700" alt="Screenshot_1766143166" src="https://github.com/user-attachments/assets/938df0d7-9d4b-46f7-85f2-a5fb4e3d8839" />
<img width="315" height="700" alt="Screenshot_1766143149" src="https://github.com/user-attachments/assets/a65b81aa-e28e-4a8a-84cb-636f93606e0b" />
<img width="315" height="700" alt="Screenshot_1766143146" src="https://github.com/user-attachments/assets/a5cc95fe-bde8-4a23-a17a-b94bae7f42db" />
<img width="315" height="700" alt="Screenshot_1766143140" src="https://github.com/user-attachments/assets/d050f271-a88e-430c-9d1e-aced24e6204d" />
<img width="315" height="700" alt="Screenshot_1766143136" src="https://github.com/user-attachments/assets/40a44b55-d4e8-4cc1-9ff2-36911d4ba51d" />
<img width="315" height="700" alt="Screenshot_1766143061" src="https://github.com/user-attachments/assets/91376cbf-88dd-404d-88ef-22c87cf37c64" />
<img width="315" height="700" alt="Screenshot_1766143038" src="https://github.com/user-attachments/assets/3d52a966-2964-4753-8130-b81bc7ebdb1c" />
<img width="315" height="700" alt="Screenshot_1766143034" src="https://github.com/user-attachments/assets/2c9ed619-3634-4d92-aa80-3943c606359e" />
<img width="315" height="700" alt="Screenshot_1766143030" src="https://github.com/user-attachments/assets/76fa14df-acd8-420c-acaf-d3d6e9bddede" />


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



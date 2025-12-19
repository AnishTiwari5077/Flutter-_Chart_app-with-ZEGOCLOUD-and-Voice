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
<img width="315" height="700" alt="Screenshot_1766143399" src="https://github.com/user-attachments/assets/73cf2dfa-2bdb-4976-936b-aae43708e791" />
<img width="315" height="700" alt="Screenshot_1766143384" src="https://github.com/user-attachments/assets/cb797ace-8970-4557-a51d-8988cbbfd722" />
<img width="315" height="700" alt="Screenshot_1766143379" src="https://github.com/user-attachments/assets/d3308a31-cc60-42a2-98f6-4ccfdf5daf8e" />
<img width="315" height="700" alt="Screenshot_1766143334" src="https://github.com/user-attachments/assets/85ce704c-1434-4bae-998b-ece07198e9d5" />
<img width="315" height="700" alt="Screenshot_1766143298" src="https://github.com/user-attachments/assets/dc9dc01f-e0f4-4161-adb5-778a744bc601" />
<img width="315" height="700" alt="Screenshot_1766143293" src="https://github.com/user-attachments/assets/81292e4d-fc7d-463c-b281-d441add888ef" />
<img width="315" height="700" alt="Screenshot_1766143288" src="https://github.com/user-attachments/assets/db44fc53-f5b2-453a-9b78-1644cdba4407" />
<img width="315" height="700" alt="Screenshot_1766143280" src="https://github.com/user-attachments/assets/381ff46d-b72d-4322-91b9-c82effb7f22d" />
<img width="315" height="700" alt="Screenshot_1766143271" src="https://github.com/user-attachments/assets/7139faa3-e4cb-42d6-ab4f-ff46ed26d03d" />
<img width="315" height="700" alt="Screenshot_1766143266" src="https://github.com/user-attachments/assets/d7bd1b9a-1fa4-45d3-a43f-b0d355e41248" />
<img width="315" height="700" alt="Screenshot_1766143263" src="https://github.com/user-attachments/assets/e3a0d5c6-c0f4-4ba9-a1c2-30ad9267c8cb" />
<img width="315" height="700" alt="Screenshot_1766143239" src="https://github.com/user-attachments/assets/79e9fc24-8f45-48f1-bd50-d854dd4394fa" />
<img width="315" height="700" alt="Screenshot_1766143170" src="https://github.com/user-attachments/assets/942f0cee-9a1c-4b02-90b1-af3f20da0db1" />
<img width="315" height="700" alt="Screenshot_1766143166" src="https://github.com/user-attachments/assets/75e2c687-7649-4592-93d6-bf804a39fab9" />
<img width="315" height="700" alt="Screenshot_1766143149" src="https://github.com/user-attachments/assets/6e574368-f270-4868-9f3f-570c0dec6c6e" />
<img width="315" height="700" alt="Screenshot_1766143146" src="https://github.com/user-attachments/assets/cc9b5322-3fbc-490c-bdda-ff7c3bc3d948" />
<img width="315" height="700" alt="Screenshot_1766143140" src="https://github.com/user-attachments/assets/45365f7c-39cd-49d1-bc54-4cdbcf6bddbe" />
<img width="315" height="700" alt="Screenshot_1766143136" src="https://github.com/user-attachments/assets/0dcfa5ad-3c31-4778-bf7a-5299d5e60783" />
<img width="315" height="700" alt="Screenshot_1766143066" src="https://github.com/user-attachments/assets/6b4a71e7-cf49-495f-92b3-8d0858ef1432" />
<img width="315" height="700" alt="Screenshot_1766143061" src="https://github.com/user-attachments/assets/30a1127f-1a73-4c1b-afa7-26a3d8297ccf" />
<img width="315" height="700" alt="Screenshot_1766143038" src="https://github.com/user-attachments/assets/beb0c190-5714-4448-85d2-5ec62adfce58" />
<img width="315" height="700" alt="Screenshot_1766143034" src="https://github.com/user-attachments/assets/164953ba-8c45-46af-b6c7-8954a7568b90" />
<img width="315" height="700" alt="Screenshot_1766143030" src="https://github.com/user-attachments/assets/319dcdce-af93-4528-844a-28183be6c348" />



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




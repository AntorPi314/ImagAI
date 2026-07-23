# ImagAI

<<<<<<< HEAD
## Figma Design

https://www.figma.com/design/mHx0AGdxmoBz3GMgWXyRNT/Mobile-App-Development--ImagAI-?node-id=0-1&t=92ZxLOs1LDNqvRqa-1


## App Screenshots

![screenshot](https://github.com/AntorPi314/ImagAI/blob/main/screenshot/ImagAI.png)

=======
An AI-powered image processing app built with Flutter. ImagAI lets users analyze images and PDFs using AI models such as Gemini and DeepSeek, compress images and videos, and chat with other users in a global chat room.


## Screenshots

![screenshot](https://github.com/AntorPi314/ImagAI/blob/main/screenshot/ImagAI.png)

## Features

- **Math Problem Solver** — Solve math problems step by step from an image
- **Medical Report Summarize** — Summarize medical reports into clear, structured sections
- **Skin Issue Detection** — Analyze visible skin conditions from an image
- **Image to Text** — Extract all visible text from an image
- **AI PDF Viewer** — View PDFs and generate AI-powered summaries
- **Plant and Disease Identifier** — Identify plants and detect visible diseases
- **Image Compression** — Compress images to reduce file size
- **Video Compression** — Compress videos with adjustable quality, bitrate, and format options
- **Global Chat** — Real-time chat with other users, backed by Firebase Authentication and Firestore
- **History** — Local history of previously processed results

## Tech Stack

- Flutter and Dart
- Firebase Core, Firebase Authentication, Cloud Firestore
- Google Sign-In
- Gemini and DeepSeek APIs for AI processing
- FFmpeg Kit for video compression
- pdfx and file_picker for PDF handling

## Project Structure

```
ImagAI/
├── android/
├── lib/
│   ├── core/
│   ├── database/
│   ├── features/
│   │   ├── ai_tools/
│   │   ├── compression/
│   │   ├── global_chat/
│   │   ├── home/
│   │   ├── pdf_viewer/
│   │   └── settings/
│   ├── services/
│   ├── shared/
│   ├── app.dart
│   ├── firebase_options.dart
│   └── main.dart
├── web/
└── pubspec.yaml
```

## Getting Started

### Prerequisites

- Flutter SDK (^3.11.4)
- A Firebase project with Authentication and Cloud Firestore enabled
- A Gemini and/or DeepSeek API key

### Installation

```bash
git clone https://github.com/AntorPi314/ImagAI.git
cd ImagAI
flutter pub get
```

Add your Firebase configuration file (`lib/firebase_options.dart`), then run:

```bash
flutter run
```

### API Key

Enter your Gemini or DeepSeek API key from the in-app Settings screen. The key is stored locally on the device using `shared_preferences` and is never bundled with the source code.

## Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Authentication** (Google Sign-In)
3. Enable **Cloud Firestore**
4. Generate `firebase_options.dart` using the FlutterFire CLI:

```bash
flutterfire configure
```

5. Apply the Firestore security rules below to your project

## Firestore Security Rules

The global chat feature relies on the following Firestore rules. These rules ensure users can only create messages as themselves, can only add their own UID to a message's report list, and that any message reported by two or more different users is automatically eligible for deletion.

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /messages/{messageId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null
                    && request.resource.data.uid == request.auth.uid
                    && request.resource.data.keys().hasOnly(['uid', 'name', 'initials', 'text', 'timestamp', 'reportedBy'])
                    && request.resource.data.text is string
                    && request.resource.data.text.size() > 0
                    && request.resource.data.text.size() <= 2000
                    && request.resource.data.reportedBy is list
                    && request.resource.data.reportedBy.size() == 0;
      // Only allow adding own uid to reportedBy, one at a time
      allow update: if request.auth != null
                    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['reportedBy'])
                    && request.resource.data.reportedBy.size() == resource.data.reportedBy.size() + 1
                    && request.resource.data.reportedBy.hasAll(resource.data.reportedBy)
                    && !(request.auth.uid in resource.data.reportedBy)
                    && request.auth.uid in request.resource.data.reportedBy;
      // Own message can always be deleted; any message with 2+ reports can be deleted
      allow delete: if request.auth != null
                    && (resource.data.uid == request.auth.uid
                        || resource.data.reportedBy.size() >= 2);
    }
  }
}
```

Copy these rules into the **Rules** tab of your Firestore Database in the Firebase Console.

## Design

Figma design file:
https://www.figma.com/design/mHx0AGdxmoBz3GMgWXyRNT/Mobile-App-Development--ImagAI-?node-id=0-1&t=92ZxLOs1LDNqvRqa-1


## License

This project is licensed under the MIT License. You are free to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of this software, provided the original copyright notice and this permission notice are included in all copies or substantial portions of the software.

See the [LICENSE](LICENSE) file for the full license text.
>>>>>>> 84cfff6a3ff9761f081cd05251d4df3c8386f8b2

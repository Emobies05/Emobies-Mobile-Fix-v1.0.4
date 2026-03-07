# 🔧 Emobies
### *Your Trusted Mobile Repair Partner*

> Built from Dubai 🇦🇪 · Powered by Seven Brains 🧠 · Made for Kerala 🌿

[![Flutter](https://img.shields.io/badge/Flutter-3.27.0-02569B?logo=flutter)](https://flutter.dev)
[![Version](https://img.shields.io/badge/Version-1.0.7-00E676)](https://github.com/Emobies05/Emobies-AP-135)
[![Platform](https://img.shields.io/badge/Platform-Android-brightgreen?logo=android)](https://play.google.com)
[![Backend](https://img.shields.io/badge/Backend-Railway-FF5500)](https://railway.app)
[![License](https://img.shields.io/badge/License-MIT-FF5500)](LICENSE)

---

## 📱 What is Emobies?

Emobies is a full-stack mobile repair service platform — connecting customers with trusted repair technicians, delivery boys, and service centres.

Built entirely on a phone 📱 using Termux + Acode, backend deployed on Railway.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔧 **Repair Complaints** | Submit, track, and manage repair requests |
| 💬 **Live Chat** | Chat per complaint with technician |
| 🚚 **Delivery Boy** | Pickup & delivery tracking |
| 🏪 **Service Centre** | Assign complaints to service centres |
| 🪙 **EmoCoins** | Loyalty rewards system |
| 🤖 **AI Chatbot** | Gemini-powered repair assistant |
| 👑 **Admin Panel** | Full superadmin + staff management |
| 🔐 **Secure Auth** | JWT-based login + register |

---

## 🏗️ Architecture

```
Flutter App (Android)
      ↓
Node.js + Express API (Railway)
      ↓
MongoDB (In-memory / Atlas)
      ↓
Gemini AI (Google)
```

---

## 🚀 Backend API

**Base URL:** `https://emobies-ap-135-production.up.railway.app`

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/register` | POST | Register user |
| `/api/auth/login` | POST | Login user |
| `/api/complaints` | GET/POST | Manage complaints |
| `/api/chat/:id` | GET/POST | Chat per complaint |
| `/api/emocoins/balance` | GET | EmoCoins balance |
| `/api/ai/chat` | POST | Gemini AI chat |

---

## 👑 Superadmin

```
Phone: 9847842172
Password: Emobies@2026!
```

---

## 📦 Tech Stack

```
Frontend:    Flutter 3.27.0 (Dart)
Backend:     Node.js + Express
AI:          Gemini API (Google)
Deploy:      Railway (Backend) + Vercel (Web)
Build:       GitHub Actions
Store:       Google Play Console
```

---

## 🚀 Build & Deploy

```bash
# Clone repo
git clone https://github.com/Emobies05/Emobies-AP-135.git

# Install dependencies
flutter pub get

# Build APK
flutter build apk --release
```

---

## 🌐 Links

- 🔧 **App:** Google Play Store (Publishing)
- 🌍 **Web:** [emobies-ap-135.vercel.app](https://emobies-ap-135.vercel.app)
- 📄 **Privacy Policy:** [emobies05.github.io/public-/privacy-policy.html](https://emobies05.github.io/public-/privacy-policy.html)
- 🦋 **Sister App:** [Emowall AI 2.0](https://github.com/Emobies05/Emobies-AP-135/tree/Emowall-Ai-2.0)

---

## 🧠 Powered by Seven Brains

Same multi-AI architecture as Emowall AI 2.0 — Claude, Gemini, ChatGPT, Cursor, Copilot, DeepSeek, Perplexity working together.

---

## 🦋 Vision

> *"Emobies is not just a repair app.*
> *It's the foundation of an ecosystem —*
> *Emobies + Emowall + TheWall = One Platform."*

**Emobies — Built by Dwin from Dubai 🇦🇪, Powered by Seven Brains 🧠✨**

---

*Package: `com.nxtbit.emobies_24` · Min SDK: 21 · Target SDK: 35*

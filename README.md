# 🏠 Addis Rent - Rental Property Management App

![Flutter](https://img.shields.io/badge/Flutter-3.19-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.2-blue?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Cloud-orange?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)

A full-featured mobile application for managing rental properties in Addis Ababa, Ethiopia. Built with Flutter and Firebase, this app connects landlords with tenants in a seamless rental experience.

## 📱 App Preview

| Login Screen | Property List | Property Details | Add Property |
|--------------|---------------|------------------|--------------|
| ![Login](https://via.placeholder.com/300x600/4A6572/FFFFFF?text=Login+Screen) | ![Properties](https://via.placeholder.com/300x600/344955/FFFFFF?text=Properties) | ![Details](https://via.placeholder.com/300x600/232F34/FFFFFF?text=Details) | ![Add](https://via.placeholder.com/300x600/4A6572/FFFFFF?text=Add+Property) |

## ✨ Features

### 👤 Authentication & User Roles
- **Multi-role system**: Tenant, Landlord, and Admin roles
- **Secure login**: Email/password and Google Sign-In
- **Role-based navigation**: Different interfaces for different users
- **Profile management**: Update personal information and profile picture

### 🏠 Property Management
- **Add properties**: Landlords can list properties with images, descriptions, and amenities
- **Property search**: Advanced filtering by location, price, bedrooms, and amenities
- **Property details**: Comprehensive view with images, description, and landlord contact
- **Favorites system**: Tenants can save favorite properties
- **Admin approval**: Properties require admin approval before appearing in listings

### 📸 Media & Uploads
- **Image upload**: Multiple image support with Cloudinary integration
- **Image compression**: Automatic image optimization before upload
- **Gallery view**: Swipeable image galleries for property photos

### 🔔 Real-time Features
- **Live updates**: Real-time property listing updates
- **Instant filtering**: Apply filters without page refresh
- **Notification system**: (Planned) Push notifications for new properties and messages

### 🎨 User Experience
- **Modern UI**: Clean, intuitive interface with dark/light mode support
- **Offline support**: (Planned) Basic functionality without internet
- **Multi-language**: (Planned) Support for English and Amharic

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.19** - Cross-platform framework
- **Dart 3.2** - Programming language
- **Provider** - State management
- **Go Router** - Navigation routing

### Backend & Services
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL database
- **Firebase Storage** - File storage
- **Cloudinary** - Image hosting and optimization

### Packages & Dependencies
- `firebase_core`, `firebase_auth`, `cloud_firestore` - Firebase integration
- `google_sign_in` - Google authentication
- `image_picker` - Camera/gallery access
- `http` - API calls
- `provider` - State management
- `flutter_dotenv` - Environment variables

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.19.0)
- Dart (>=3.2.0)
- Android Studio / VS Code with Flutter extension
- Firebase account
- Cloudinary account

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/helenlemessa/Addis-Rent-app.git
cd Addis-Rent-app

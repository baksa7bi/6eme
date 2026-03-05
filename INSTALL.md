# Flutter Store App - Configuration

This project is a Flutter store app with Stripe integration, dark/light mode, and a UI inspired by the provided image.

## Prerequisites
- Flutter SDK installed.
- Stripe account (Publishable Key and Secret Key).

## Stripe Configuration

### 1. Keys
Update `lib/services/stripe_service.dart` with your **Secret Key** (for testing/dev only).
Initialize the **Publishable Key** in `lib/main.dart`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = "YOUR_PUBLISHABLE_KEY";
  runApp(...);
}
```

### 2. Android Setup
Update `android/app/src/main/kotlin/.../MainActivity.kt` to inherit from `FlutterFragmentActivity` instead of `FlutterActivity`.

Update `android/app/src/main/res/values/styles.xml`:
```xml
<style name="LaunchTheme" parent="Theme.AppCompat.Light.NoActionBar">
```

### 3. iOS Setup
Update `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>Scan cards</string>
```

## Running the app
```bash
flutter pub get
flutter run
```

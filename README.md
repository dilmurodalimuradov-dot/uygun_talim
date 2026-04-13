# Uygun Ta'lim

`Uygun Ta'lim` Flutter asosida yozilgan mobil ilova bo'lib, kurslar, modullar, darslar, testlar, sertifikatlar va to'lovlar bilan ishlaydi.

## Asosiy imkoniyatlar

- login va token asosida autentifikatsiya
- kurslar ro'yxati va kurs detali
- modul va darslar bilan ishlash
- test topshirish
- sertifikatlarni ko'rish
- to'lov holatini tekshirish

## Texnologiyalar

- Flutter
- Dart
- Provider
- HTTP API
- Flutter Secure Storage
- Shared Preferences
- WebView

## Ishga tushirish

Talablar:

- Flutter SDK o'rnatilgan bo'lishi kerak
- Dart SDK (`Flutter` bilan birga keladi)
- Android Studio yoki VS Code
- emulator yoki telefon

Loyihani ishga tushirish:

```bash
git clone https://github.com/Sharof19/uygun_talim.git
cd uygun_talim
flutter pub get
flutter run
```

## Muhim eslatma

Ilova backend API bilan ishlaydi. Kod ichida ishlatilayotgan asosiy manzillar:

- `https://api.uyguntalim.tsue.uz/api`
- `https://api.uyguntalim.tsue.uz/api-v1`

Agar backend o'zgarsa, `lib/domain/services/` ichidagi servis fayllarida `baseUrl` qiymatlarini yangilash kerak bo'ladi.

## Loyiha tuzilmasi

```text
lib/
  domain/
    provider/
    services/
  ui/
    pages/
    routes/
    theme/
    ui_theme/
    widgets/
  main.dart
```

Qisqacha:

- `lib/domain/services/` - API bilan ishlash logikasi
- `lib/domain/provider/` - state management
- `lib/ui/pages/` - asosiy sahifalar
- `lib/ui/routes/` - route va navigation
- `lib/ui/widgets/` - qayta ishlatiladigan widgetlar

## O'quvchilar uchun tavsiya

Loyihani o'rganishda shu tartib foydali:

1. `lib/main.dart`
2. `lib/ui/routes/`
3. `lib/ui/pages/login_screen.dart`
4. `lib/domain/services/`
5. `provider` va qolgan sahifalar

## Foydali buyruqlar

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Ehtiyot bo'ling

- token va maxfiy ma'lumotlarni repo'ga joylamang
- production API bilan ishlayotgan bo'lsangiz, test hisoblaridan foydalaning
- `build/` va `.dart_tool/` papkalari git'ga qo'shilmaydi

## Repository

GitHub manzili:

`https://github.com/Sharof19/uygun_talim`

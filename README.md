# MiniStrava Mobile App

Mobilna aplikacja Flutter inspirowana Stravą, służąca do rejestrowania treningów, analizy aktywności i interakcji społecznościowych.

## Spis treści
- [Funkcjonalności](#funkcjonalności)
- [Stack technologiczny](#stack-technologiczny)
- [Wymagania](#wymagania)
- [Instalacja i uruchomienie](#instalacja-i-uruchomienie)
- [Konfiguracja backendu](#konfiguracja-backendu)
- [Tryb offline](#tryb-offline)
- [Struktura projektu](#struktura-projektu)
- [Testy](#testy)

## Funkcjonalności
- Rejestracja, logowanie i reset hasła.
- Rejestrowanie treningu na mapie (GPS) z pomiarem:
  - czasu,
  - dystansu,
  - prędkości,
  - tempa.
- Zapisywanie aktywności (z notatką i opcjonalnym zdjęciem).
- Historia treningów z filtrowaniem i sortowaniem.
- Szczegóły aktywności z podglądem trasy na mapie.
- Eksport aktywności do formatu GPX i udostępnianie pliku.
- Feed znajomych z kudosami i komentarzami.
- Ranking użytkowników (tydzień / miesiąc).
- Profil użytkownika z edycją danych i awatarem.
- Zarządzanie znajomymi, blokowanie i zgłaszanie użytkowników.

## Stack technologiczny
- **Flutter / Dart**
- **HTTP REST API** (`http`)
- **Lokalne, bezpieczne przechowywanie danych** (`flutter_secure_storage`)
- **Mapy** (`flutter_map`, OpenStreetMap)
- **Geolokalizacja** (`geolocator`)
- **Udostępnianie plików** (`share_plus`)
- **Obsługa zdjęć** (`image_picker`)

## Wymagania
- Flutter SDK (zgodny z `sdk: ^3.9.2`)
- Dart SDK (w pakiecie z Flutter)
- Android Studio lub Xcode (w zależności od platformy)

## Instalacja i uruchomienie
1. Sklonuj repozytorium.
2. Przejdź do katalogu projektu:
   ```bash
   cd miniStravaMobileApp
   ```
3. Zainstaluj zależności:
   ```bash
   flutter pub get
   ```
4. Uruchom aplikację:
   ```bash
   flutter run
   ```

## Konfiguracja backendu
Adres API jest obecnie wpisany na stałe w serwisach (`lib/services/*`):

- `lib/services/auth_service.dart`
- `lib/services/activity_service.dart`
- `lib/services/feed_service.dart`
- `lib/services/user_service.dart`

Domyślny adres:

```text
https://strava.host358482.xce.pl/api
```

W przypadku własnego backendu zaktualizuj wartość `_baseUrl` we wskazanych plikach.

## Tryb offline
Aplikacja wspiera tryb gościa offline:
- treningi mogą być zapisywane lokalnie,
- po ponownym zalogowaniu online następuje synchronizacja zaległych aktywności.

## Struktura projektu
```text
lib/
├── main.dart
├── models/
├── screens/
├── services/
└── widgets/
```

## Testy
Uruchom testy poleceniem:

```bash
flutter test
```

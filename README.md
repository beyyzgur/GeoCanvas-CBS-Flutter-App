# GeoCanvas - CBS App

Harita üzerinden saha envanteri toplamak için geliştirilmiş mobil CBS (Coğrafi Bilgi Sistemi) uygulaması. Kullanıcı; nokta, çizgi ve alan (polygon) geometrileri çizip her birine öznitelik bilgisi girebilir, kayıtları harita üzerinde görüntüleyip düzenleyebilir.

## Özellikler

- E-posta ile kayıt / giriş (Supabase Auth)
- Türkiye haritası üzerinde nokta / çizgi / alan çizimi
- Türe göre dinamik öznitelik formları
- Geometri kuralları ile doğrulama
- Çevrimdışı çalışma: yerel SQLite + bağlantı gelince otomatik senkron
- Harita katmanı değiştirme, konumum, köşe düzenleme (geri/ileri al)

## Teknolojiler

- Flutter (Dart)
- Riverpod — durum yönetimi
- Supabase — kimlik doğrulama + veritabanı
- SQLite (sqflite) — yerel önbellek
- flutter_map — harita

## Kurulum

1. Bağımlılıkları yükle:

```bash
   flutter pub get
```

2. Proje kök dizininde bir `.env` dosyası oluştur ve Supabase bilgilerini gir:

```bash
SUPABASE_URL=...
SUPABASE_PUBLISHABLE_KEY=...
```

3. Uygulamayı çalıştır:

```bash
   flutter run
```

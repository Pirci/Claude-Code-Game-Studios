# Context Management

**Dosya hafızadır, konuşma değil.** Konuşma sıkıştırılır/kaybolur; kararlar dosyada kalır.

- **Durum dosyası:** `production/session-state/active.md` — görev kapanınca ≤ 4 satır özet
  (ne değişti, yeni testler, test sayısı, NEXT). En fazla son 4 özet; eskisi `archive.md`'ye.
- **Açık işler:** `production/continuation.md` (yalnız açık görevler). Kapananlar
  `continuation-archive.md`'ye eklenir — okunmadan, sona ekleyerek.
- **Çok bölümlü belge:** önce iskelet, sonra bölüm bölüm yaz; onaylanan bölüm hemen dosyaya.
- **Sıkıştırma:** görev/commit sonrasında ve konu değişiminde; ilgisiz işler arasında `/clear`.
  Özet şunları korur: aktif görev + adım, değişen dosyalar, test sonucu, açık sorular, `active.md` atfı.
- **Kesinti sonrası:** önce `active.md`, sonra orada adı geçen yarım dosyalar.
- **Status bloğu (Production+):** `active.md` içinde `<!-- STATUS -->` Epic / Feature / Task `<!-- /STATUS -->`.
- **Okuma ve ajan kullanımı:** `coordination-rules.md` → "Okuma ve çıktı disiplini".

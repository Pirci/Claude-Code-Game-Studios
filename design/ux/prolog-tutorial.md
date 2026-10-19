# UX Spec: Prolog Öğreticisi (C-41)

*Oluşturulma: 2026-10-19 — Görev C-41 (M1). Kararlar kullanıcıdan alındı (2026-10-19).*
*Durum: Uygulandı (kanıt: `production/qa/evidence/c41-tutorial-*.png`).*

## 1. Amaç

Rehbersiz oyuncu Prolog'da her mekaniği **bir kez, ihtiyaç duyduğu anda** görür:
fetih → üretim → savaş/ordu gönderme → arındırma → Erlik'in yayılması → Ruh. Öğretici oyun
akışını kesmez, haritayı ve girdiyi kilitlemez.

## 2. Kararlar (kullanıcı onaylı)

| Konu | Karar |
| --- | --- |
| İpucu biçimi | **Bağlamsal ipucu balonları**: ilgili mekanik ilk kez önemli olunca küçük panel; her ipucu bir kez, [Anladım] ile kapanır |
| Kalıcılık | **Ayarlar dosyasında** (`settings.json` → `tutorial.seen_hints`); Yeni Sefer'de tekrar gösterilmez; Ayarlar'da **Öğreticiyi Sıfırla** |
| Erlik'in Gölgesi | **Üst çubukta kalıcı**; `erlik_power = eşik − 1` iken hedef satırının yerini kırmızı uyarı alır |

## 3. İpuçları ve tetikleri (`TutorialRules`)

| İpucu | Tetik | Anahtar |
| --- | --- | --- |
| Önce üret | 1. tur, altın ≥ üretim maliyeti; hedef paneli kapanınca (modal açıkken beklenir) | `HINT_RECRUIT` |
| Ordu gönder | Ordusu > 1 olan oyuncu bölgesi seçilince | `HINT_SEND_ARMY` |
| Fetih | Nötr bölge seçilince | `HINT_NEUTRAL` |
| Arındırma | Bozuk (seviye ≥ 1) bölge seçilince — öncelik en yüksek | `HINT_CORRUPTED` |
| Yayılım | İlk Erlik yayılımında | `HINT_SPREAD` |
| Ruh | Ruh ilk kez 0'dan büyük olunca | `HINT_SPIRIT` |

Kurallar: aynı anda en çok **bir** balon; modal açıkken ya da oyun bitmişken gösterilmez; meşgulken
kaçan ipucu bir sonraki tetikte yeniden denenir; "görüldü" yalnız [Anladım] ile yazılır.

## 4. Yerleşim

- **Balon:** sol üst, üst çubuğun hemen altı (alt-sol Bereket Vadisi'ni örter); metin genişliği 216px,
  `HudPanel` varyasyonu, sağ altta [Anladım].
- **Üst çubuk, 2. satır:** `Hedef: <metin>` (taşarsa `…`), `Birleşen boylar: x / y`, `Arındırılan inler: x / y`,
  `Erlik'in Gölgesi: güç / eşik` (mor; 8/9'da kırmızı). Uyarıda hedef metni ve ilerleme gizlenir, yerine
  `ERLIK_SHADOW_WARNING` gelir (çubuk büyümez, harita örtülmez).
- **Harita işareti:** çözülmemiş hedef bölgesinin etiketi üstünde 9×9 gök mavisi / beyaz / altın elmas
  (F7 `V` kümesi); arındırılınca söner, yayılım yeniden bozarsa döner. Animasyonsuz (Hareketi Azalt ile aynı).

## 5. Erişilebilirlik

Renk tek başına anlam taşımaz: uyarı hem kırmızı hem metin değişimidir. Klavye: [Anladım] odaklanabilir
düğmedir. Hareketi Azalt: balon ve işaret zaten animasyonsuzdur.

## 6. Kabul ölçütleri

- Balon yalnız tetikte, bir kez, tek tek çıkar; [Anladım] ayarlara yazar; yeni oturumda görülen çıkmaz;
  Öğreticiyi Sıfırla hepsini siler. *(Test: `tutorial_flow_test`, `tutorial_test`)*
- HUD hedef metni, ilerleme ve gölge `HudPresenter` modelinden; 8 / 9'da uyarı. *(Test)*
- İşaret Canavarın İni'nde; arındırınca söner, yayılımla döner (scene-flow AC6). *(Test)*
- en/de/ar'da taşma yok. *(Ekran görüntüsü — bilinen: Arapçada 2. satır dar, bkz. §7)*

## 7. Çözülenler (C-69)

- Arapça üst çubuk: sorun darlık değil **yön** idi ("4 / 9" → "9 / 4", "(+2)" → "(2+)"). Sayısal ifadeler
  LRI … PDI ile soldan sağa yalıtıldı (`NumberFormatter.fraction` / `ltr`; ADR-0009 eki).
- Hedef paneli alt-orta; işaret örtülürse üst-orta, ikisi de örterse en az örten (`PanelPlacement`).
  İpucu balonu sol üst → sağ üst → sol alt aynı kuralla.
- `icon_objective_marker_0/1.png` (9×9, 2 kare / 1 fps, palet renkleri;
  `tools/asset-pipeline/generate_objective_marker.gd`); Hareketi Azalt'ta sabit kare.

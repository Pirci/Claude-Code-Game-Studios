# Denge Kontrolü: Lütuf Ekonomisi ve Perde 1 Etkisi (C-44)

- **Tarih:** 2026-10-21
- **Görev:** C-44 (`production/continuation.md`); C-53 ile eklenen "lütuf dengesi" bitti kriteri, D5 eğri hedefi,
  Ruh çiftçiliği (N4/N9 devri), `spirit-system.md` §3.4–3.5, §4.4
- **Beceri:** `/balance-check` (alan: lütuf ekonomisi + Perde 1 ilerlemesi)
- **Yöntem:** basit planlayıcı oyuncu modeliyle kural simülasyonu; simülatör scratchpad'dedir (depoya
  girmedi). Kurallar `spirit-system.md`, `perde1-dogu-curcet.md` ve Prolog raporundaki gibi aynen uygulandı.
  **Gerçek doğrulama C-47 controller replay'idir.**
- **Prolog raporuyla ilişki:** [`prolog-balance-2026-10-19.md`](prolog-balance-2026-10-19.md) M1'i kapatmıştı;
  bu rapor lütufların Perde 1'e taşındığı M2 sorularını kapatır.

---

## Sağlık Özeti: **CONCERNS → kararlarla çözüldü** (kullanıcı onayı: C-44, 2026-10-21)

Lütuf maliyet eğrisi ve katalog, Perde 1'in Ruh arzıyla uyumlu olacak şekilde hedeflenmişti ama D5'teki
"6–8 lütuf, 600–800 Ruh" hedefi gerçek arzın (~40–60 Ruh/sahne) yaklaşık iki katıydı. Karar: eğri
değişmez, **hedef** düzeltilir. İki küçük risk açık kalır ve izlenir: Kurt Gücü yığını (sınır kondu) ve
Güney yolunun T20 sonucu (C-47 replay'i esas).

---

## 1. Ruh arzı

Perde 1 kaynakları (`perde1-dogu-curcet.md` §6): `curuk_koru` L3 **+30**, `kurt_ini_ormani` L1 **+10**
(isteğe bağlı), yayılımla oluşan L1 **+10** (duruma bağlı). Prolog: canavar +30, Doğu Obası +10, yayılım
arındırmaları +10 (Prolog raporu §4).

| Oyuncu | Prolog Ruh | Perde 1 Ruh | Toplam | Alınan lütuf (2 sahne sonu) | Not |
| --- | --- | --- | --- | --- | --- |
| Zayıf (yalnız zorunlu hedefler) | 30 | 30 | 60 | 1 | Perde 1'de seçim yok: 0 + 30 < 50. Ruh taşınır (kabul) |
| Orta | 50 | 40 | 90 | 2 | Prolog'da 1 (20 taşınır); Perde 1'de 20 + 40 = 60 ≥ 50 → 2. lütuf |
| İyi (titiz, tüm arındırmalar) | ~80 | ~60 | ~140 | 2 | 3. lütuf birikimli 150 ister, eşiğin hemen altı |

Sahne başına ortalama ~30–70, orta oyuncuda ~45; D5'in yeni hedefi ortalama **~58 Ruh/sahne**,
erişilebilir üst-orta aralıktır. Perde 1'de en çok **2 lütuf** erişilir.

**Prolog'da lütuf alan oyuncu için Perde 1'deki sıradaki lütuf 50 Ruh'tur.** `curuk_koru` +30 tek
başına yetmez; seçim opsiyonel arındırmalara bağlıdır (`perde1-dogu-curcet.md` §6 düzeltildi, eski
"ilk lütuf garanti" ifadesi kaldırıldı).

## 2. Maliyet eğrisi

`boon_cost(n) = 30 + 20n` (**değişmez**). Birikimli maliyet `30k + 10k(k−1)`:

| k (lütuf) | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Sıradaki maliyet | 30 | 50 | 70 | 90 | 110 | 130 | 150 | 170 |
| Birikimli Ruh | 30 | 80 | 150 | 240 | **350** | 480 | **630** | 800 |
| Ortalama / sahne (6 sahne) | 5 | 13 | 25 | 40 | **58** | 80 | **105** | 133 |

**D5 hedefi (güncel):** 5 lütuf (M2 kataloğunda tür başına 1) ≈ 350 Ruh ≈ ortalama ~58 Ruh/sahne; kilitli
lütuflar (Sürü Kutsaması, Yiğit Ruhu) açılınca 7 lütuf (≈ 630). Eski "6–8 lütuf, 600–800 Ruh" geçersiz.

## 3. Simülasyon (onaylı Perde 1 yapılandırması)

Yapılandırma: R2 kapalı, takviye yalnız başkent (`curcet_otagi`), `attack_start_turn = 5`,
`erlik_spread_interval = 3`, `erlik_loss_threshold = 9`. W = zafer turu, L = kayıp turu, R = Ruh.

| Senaryo | Sonuç |
| --- | --- |
| **Baseline** N-fast (kuzey yolu) | W12, R40 |
| S-purify-first (güney yolu) | **W20**, R40 |
| Mixed | W14, R50 |
| No-purify | L18 |
| Pasif | L15 |
| 3 boş tur | W15 |
| 6 boş tur | W18 |

Lütuf varyantları (yığın başına etki, aynı yapılandırma):

| Varyant | N-fast | S-purify | Mixed | No-purify | 3 boş | 6 boş |
| --- | --- | --- | --- | --- | --- | --- |
| KG1 (Kurt Gücü ×1) | W12 | W17 | W14 | L18 | W15 | W18 |
| KG2 (×2) | W12 | W19 | W15 | L18 | W15 | W17 |
| KG3 (×3) | **W9** | W17 | W13 | L15 | W11 | W14 |
| KG1, t0 = 8 (8. turda alınır) | W12 | W17 | W14 | L18 | W15 | W18 |
| DP1 (Demir Post ×1) | baseline | W17, R70 | baseline | baseline | baseline | baseline |
| AR1 (Arınma Ustalığı ×1) | Ruh +8 her çizgide, turlar aynı | | | | | |

Okuma:

- **Kurt Gücü mono-build riski:** 3 yığın kuzey yolunu T12 → T9'a indiriyor. Karar: `KURT_GUCU_MAX_STACKS = 3`
  (Gök Kalkanı kalıbı). Perde 1'de ≤ 2 lütuf erişildiği için M2'de pratik etki yok; sınır sonraki
  perdeler içindir. KG2 sonuçları (W12/W19/W15) beklendiği gibi KG1 ile KG3 arasındadır.
- **Demir Post** yalnızca S-purify çizgisini etkiler (W17, R70): AI oyuncunun *etkin* savunmasını okur, geri
  alma vuruşları zayıflar. Diğer çizgilerde sonucu değiştirmez.
- **Arınma Ustalığı** yalnızca Ruh ekler (+8 / %20 × 40); tur sayılarını değiştirmez.
- **RİSK, Güney yolu:** basit oyuncu modelinde T20 — başkent Cürcet Obası'nı geri alıyor (R1 geri alma),
  arkada 1 ordu bırakan oyuncu cezalanır. Değerler şimdilik değişmez; C-47 gerçek controller replay'i esas;
  gerekirse `attack_start_turn` veya başkent takviyesi ayarlanır. (Seviye belgesindeki eski "S-purify W14"
  orkestratör tablo okuma hatasıydı; doğru değer W20, Mixed W14 doğrudur.)

## 4. Varsayımlar

- Oyuncu basit planlayıcıdır (en iyi tek hamle, bekleme/ihmal yok); insan oyuncu T10–15 bandında beklenir.
- Simülatör scratchpad'dedir, depoya alınmadı; yalnız bu raporun tablolarını üretir.
- **Gerçek doğrulama: C-47 controller replay.** Fark çıkarsa replay esas alınır, belgeler güncellenir.
- Lütuf etkileri alındığı anda başlar; "t0" lütfun alındığı tur.

## 5. Kararlar (C-44, 2026-10-21, kullanıcı onaylı)

| # | Konu | Karar |
| --- | --- | --- |
| 1 | Maliyet formülü | **Değişmez** (`30 + 20n`) |
| 2 | D5 hedefi | 5 lütuf ≈ 350 Ruh ≈ ~58 Ruh/sahne; 7 lütuf (≈ 630) kilitliler açılınca. Gerekçe: Perde 1 Ruh arzı ~40–60 |
| 3 | Kurt Gücü `max_stacks` | **3** (spirit §3.5 tablo, §4, §7; registry `kurt_gucu_max_stacks`) |
| 4 | Sahne lütuf havuzu | Prolog = M1 üçlüsü (Arınma Ustalığı, Bereket, Gök Kalkanı); Demir Post Prolog'da ölü seçim. `SceneDefinition.boon_pool_ids` (boş = tüm katalog); uygulama **C-47** |
| 5 | Ruh çiftçiliği | Perde 1 için yeni kural yok. Eşik: playtestte zafer turu > T18 → yedek "aynı bölgenin tekrar arındırması ×0.5" (spirit §7, **yedek, kapalı**) |
| 6 | Zayıf oyuncu | Perde 1'i seçimsiz bitirmesi kabul (Ruh taşınır) |
| 7 | AI ve Demir Post | AI oyuncunun etkin savunmasını okur; spirit'te not, ayrıntı `enemy-layers.md`'de |
| 8 | Yeniden deneme | Sunum determinizmi `(chapter_id, n)`; spirit §4.5 + AC25. Yığılma sınırı düşürülürse eski kayıt `n = boons.size()` (AC27, M2) |
| 9 | Seviye belgesi düzeltmeleri | "İlk lütuf garanti" kaldırıldı (sıradaki lütuf 50 Ruh); S-purify W14 → **W20** + RİSK notu; test listesi (§13 #10) güncellendi |

## İzlenecek Açık Noktalar

| Konu | Sahibi | Not |
| --- | --- | --- |
| S-purify T20 | C-47 replay | Gerekirse `attack_start_turn` veya başkent takviyesi |
| Zafer turu > T18 | Playtest | Yedek çiftçilik düğmesi (×0.5) |
| `boon_pool_ids` | C-47 | `SceneDefinition` veri alanı + AC26 |
| Yığılma sınırı düşürme | M2 | AC27 |

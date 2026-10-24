# UX Spec: Kök Böri Lütuf Seçimi

> **Durum**: Approved (C-45, 2026-10-21)
> **Yazar**: ux-designer
> **Güncelleme**: 2026-10-21
> **Ekran adı**: `BoonOfferModal` (+ `BoonCard`)
> **Platform**: PC (Steam), klavye + fare; gamepad/dokunmatik yok (2026-10-08 kararı)
> **GDD**: `design/gdd/spirit-system.md` §3.4, §3.5, §4.4, §4.5, AC'ler; `design/gdd/scene-flow.md` §3.6 (`BOON_PICKS`), AC24; `design/balance/boon-balance-2026-10-21.md`
> **ADR**: ADR-0011 (pasif görünüm, `ModalQueue`), ADR-0006 (yığın / `max_stacks`), ADR-0009 (yerelleştirme, piksel font), ADR-0012
> **İlgili UX spec'leri**: `design/ux/scene-screens.md` §0 (ortak modal kuralları), HUD (C-41), Zafer kartı / Hedef paneli
> **Erişilebilirlik katmanı**: Standard (+ Hareketi Azalt)
> **Kapsam notu**: "Mevcut" = kodda var (C-39, `c39-boon-offer-*.png`). "M2" = bu spec'in tanımladığı ekleme; henüz uygulanmadı.
> **Yeni pattern işareti**: interaction-patterns.md henüz yok; bu belgede "yeni" etiketli kalıplar: *yığın göstergesi*, *ertelenebilir/zorunlu modal ikilisi*.

---

## 1. Amaç ve oyuncu ihtiyacı

| | |
|---|---|
| Oyuncu ihtiyacı | Topladığı Ruh'u kalıcı bir güce çevirirken "neyi, neye karşılık seçtiğimi" tek bakışta anlamak; seçimin geri alınamadığını bilerek güvenle karar vermek. |
| Oyuncu hedefi | 3 karttan birini ≤ 3 girdiyle (odak zaten ilk kartta: ok/Tab + Enter) seçmek ya da ertelemek. |
| Oyun hedefi | `SpiritController.pick_boon` için tek bir `boon_id` almak (Ruh düşer, etki hemen başlar). |
| Duygu hedefi | Törensel ve sakin; baskı yok (modal tur akışını keser ama zamanlayıcı yok). Güç hissi: etki kartta sayıyla okunur. |

## 2. Varış bağlamı

| Tetikleyici | Oyuncu ne yapıyordu | Bilişsel yük | Not |
|---|---|---|---|
| Şafak (tur başı) | Tur sonuna bastı, ekonomi/AI çözüldü | Orta | Kendiliğinden, tur başına en çok 1; **ertelenebilir** |
| HUD Kök Böri düğmesi | Kendi turunda, haritada planlıyor | Orta | İstediği an; bekleyen sunum varken düğme görünür |
| Zafer zinciri (`BOON_PICKS`) | Zafer kartını kapattı | Düşük | **Zorunlu**, ertelenemez, `victory_pick_cap` (8) ile sınırlı |
| "Devam Et" yüklemesi | Kayıttan döndü | Düşük | Bekleyen sunum bir kez açılır (`offer_pending_boon`), ertelenebilir |

Korku: yanlış seçim / geri dönüş yok. Yanıt: kartta etki + kalan Ruh görünür; zorunlu zincirde ek onay yok (3 seçenek, hepsi iyi).

## 3. Gezinti konumu

```
GameContext
  └── ModalQueue (CanvasLayer 10, tek modal, FIFO)
        └── BoonOfferModal  (DivinePanel)
              └── BoonCard ×3 (+ [Sonra] yalnız ertelenebilirse)
```

| Özellik | Değer |
|---|---|
| Modal türü | Overlay modal: arka plan %60 koyu, harita tıklaması kesilir (`MOUSE_FILTER_STOP`), odak modala hapsolur. Genişlik: scene-screens §0.1 ortak kuralı (iç ≤ 288, dış 304 px) |
| Kapatma | Ertelenebilir: [Sonra] veya Esc. Zorunlu: **yalnız kart seçimi** (Esc etkisiz, düğme yok) — scene-screens §0.2 Esc kuralı |
| Kuyruk | Bkz. §3.1 |
| Odak | Açılışta ilk kart (`get_focus_target`); kapanışta kuyruk boşalınca önceki odak geri verilir |

### 3.1 Kuyruk sırası (ADR-0011 K5)

- Ertelenebilir sunum başka modal açıkken sıraya **girmez** (`_push_boon_offer(false)` false döner); zorunlu zincir sıraya girer.
- Şafakta **önce özet/rapor modalları**, lütuf sunumu onlardan sonra. `_push_boon_offer(false)` **kuyruk drained olunca yeniden denenir** (bekleyen sunum varsa); oyuncu HUD düğmesine basmak zorunda kalmaz.
- Sunum yine de aynı turda tekrar tekrar zorlanmaz: tur başına en çok 1 kendiliğinden açılış (AC1).

## 4. Giriş / çıkış

| Giriş | Zorunlu? | Koşul | Veri |
|---|---|---|---|
| `_on_turn_ended` / kuyruk drained → `_push_boon_offer(false)` | Hayır | Sunum bekliyor (`ruh ≥ boon_cost(n)` ve havuz > 0), başka modal yok | `current_offer(chapter_id)`, `ruh`, `next_boon_cost()` |
| `_on_kok_bori_pressed` | Hayır | `game_result == ONGOING`, başka modal yok | aynı |
| `start_boon_picks` | Evet | Zafer sonrası; `_victory_picks < victory_pick_cap` | aynı |
| `_on_boon_picked` (zorunlu) | Evet | Seçimden sonra koşul sürüyor ve tavan dolmadı | sıradaki zorunlu sunum hemen sıraya girer |

| Çıkış | Sonuç |
|---|---|
| Kart seç (Enter / Space / tık) | `boon_picked(boon_id)` → `pick_boon`; modal kapanır; HUD yenilenir. Zorunlu: `_victory_picks++`, sıradaki sunum ya da `boon_picks_finished` |
| [Sonra] / Esc (yalnız ertelenebilir) | `deferred` → Ruh/lütuf değişmez; sunum aynı girdilerle aynı 3'lüyle bekler; HUD düğmesi açık kalır; yeni tur başında yeniden gösterilir |
| Seçim sonrası (ertelenebilir) | Kendiliğinden ikinci modal **yok**; HUD düğmesi bekleyen sunumu hemen açar |

## 5. Düzen (640×360 taban, tam kat ölçekleme)

### 5.1 Tel kafes (M2 ekleri `+`)

```
          ╔════════════════════════════════════════════╗   DivinePanel (iç ≤ 288)
          ║ [+figür]       Kök Böri                    ║   HeaderLabel 12px (altın); figür başlığın YANINDA
          ║   Bir lütuf al, Oğuz. Diğerleri göğe döner.║   OfferLine (sarmalı)
          ║      Ruh: 36     Bedel: 30 Ruh             ║   SpiritLabel / CostLabel
          ║   + Kalan: 6                               ║   + kalan Ruh (M2)
          ║  (zorunluysa: BOON_CARRIES_ON altyazısı)   ║   CarriesOnLabel
          ║ ┌────────┐ ┌────────┐ ┌────────┐           ║
          ║ │+[ik] Ad│ │+[ik] Ad│ │+[ik] Ad│           ║   + 24×24 ikon, ADIN SOLUNDA aynı satır
          ║ │ Açıkl. │ │ Açıkl. │ │ Açıkl. │           ║   sarmalı açıklama
          ║ │+ ×1/3  │ │+ ×2/3  │ │        │           ║   + yığın satırı (yalnız yığınlı lütuf)
          ║ └────────┘ └────────┘ └────────┘           ║   ● odak: ilk kart
          ║              [ Sonra ]                     ║   yalnız ertelenebilir
          ╚════════════════════════════════════════════╝
```

### 5.2 Bölgeler ve ölçüler

| Bölge | Karar |
|---|---|
| Panel | Ortada (`Placement.CENTER`). Kullanılabilir yükseklik ≈ 360 − 40 (üst çubuk) − 31 (alt çubuk 27 + 4 marj) − 8 ≈ **281 px** (scene-screens §0.6) |
| Kart | **Genişlik 92 px** (karar C-45; art bible güncellendi), `MIN_HEIGHT` 92, iç boşluk 4; 3 kart + 2×6 = 288 px. Ekler yalnız yüksekliği artırır |
| Kart yüksekliği | İçeriğe göre (`_fit_height`); dil başına en uzun kart belirler, üç kart eşit yükseklikte |
| Kök Böri figürü | 32–48 px, başlığın **yanında**. Yükseklik bütçesine sığmazsa **gizlenir** (bilgi kaybı yok); karar AC9 ölçümüne bağlı |

**Yükseklik bütçesi (karar):** en uzun yerelleştirme (RU) mevcut ≈ 250 px. 24×24 ikon kart adının soluna aynı satıra konduğu için ek ≈ +10 px (ikon yüksekliği − tek satır), yığın satırı +16 → ≈ 276 px ≤ 281. Marj ince; AC9 ölçümü zorunlu, taşarsa önce figür gizlenir.

## 6. Kart içeriği

| Öğe | Karar | Kaynak |
|---|---|---|
| Ad | `tr(name_key)`, altın HeaderLabel; solunda 24×24 ikon (M2, C-67). **Uygulama (C-46, 2026-10-22):** adın en uzun sözcüğü daralan alana (58 px) sığmazsa ikon adın üstüne geçer, ad tam genişlik (sözcük ortasından bölünme yok — DE "Himmelsschild", RU "Мастерство"); ölçüm: 6 dilde modal ≤ 280 px (RU), kanıt `production/qa/evidence/c46-boon-icons-en-de-ru-ar-zh-tr.png` | `BoonDefinition.name_key`, `BoonDefinition.icon` |
| Açıklama | `tr(description_key) % display_amount()`; yüzde key'i `%%` taşır. Askeri lütuflar aynı yolu kullanır (`BOON_KURT_GUCU_DESC`, `BOON_DEMIR_POST_DESC`) | `display_amount()` |
| Yığın göstergesi | Aşağıda | `ModifierController` yığın sayısı + `ModifierSource.max_stacks` |
| Maliyet | Başlık altında ortak `Bedel: 30 Ruh`; kart başına tekrar yok. Sonraki bedel (`+STEP`) gösterilmez | `next_boon_cost()` |
| Mevcut / kalan Ruh | `Ruh: 36` ve `Kalan: 6` **iki ayrı etiket** (`→` glifi kullanılmaz; çevirmen biçimi serbest). `Kalan = ruh − bedel` ≥ 0 | `GameState.ruh` |
| Seçili | 1 px altın kontur + `◆` ≤ 2 kare gösterilir sonra modal kapanır; Hareketi Azalt'ta anında kapanır. Odak konturu (§7.1) ile aynı 1 px altın kenarlık dili; seçim anı `◆` ile ayrışır (renk tek taşıyıcı değil) | art bible §7 |

**Yığın göstergesi kuralları (karar, yeni pattern)**

| Durum | Gösterim |
|---|---|
| Sınırlı lütuf (Gök Kalkanı, Kurt Gücü, Demir Post: ≤ 3) | `×N/MAX`, N = **bu seçimden sonraki** yığın (ilk alım `×1/3`) |
| Maksimuma ulaşan seçim | `×3/3 (son)`; `(son)` kısa çeviri key'i (`BOON_STACK_LAST`) |
| Sınırsız lütuf (Bereket, Arınma Ustalığı) | Yalnız daha önce alınmışsa `×N` (seçimden sonraki), ilk alımda satır yok |
| Maksimuma ulaşmış lütuf | Havuzdan **çıkar** (GDD §3.5); "dolu" kartı yoktur |
| Renk | Yalnız renge bağlı değil: metin `×N/MAX` |

`×` glifi: Fusion'da varlığı henüz doğrulanmadı. **Görev:** `glyph_coverage_test` kapsamına `×` ve `→` eklenir; doğrulanana kadar ASCII `x` kullanılır (`x1/3`). Kararın kendisi (`×N/MAX` + `(son)`) değişmez.

**Tekrarlı kartlar (karar):** Havuz < 3'te `BoonRules.offer` aynı lütfu 2–3 slotta döndürebilir; **görünüm katmanı tekrarları birleştirir** (1–2 benzersiz kart). `BoonRules.offer` ve test determinizmi değişmez. Tek kart kalırsa Enter yine seçer; kart satırı ortalanır.

## 7. Etkileşim

### 7.1 Gezinti

| Girdi | Eylem | Not |
|---|---|---|
| Sol/Sağ ok | Komşu karta odak (görsel komşu) | Arapçada ok yönü görsel; sağdaki kart ilk |
| Tab / Shift+Tab | Kartlar sırasıyla, ardından [Sonra] (varsa), başa sarar | Odak modaldan çıkmaz |
| Aşağı/Yukarı | Kart ↔ [Sonra] | Zorunluda [Sonra] yoktur |
| Fare üstü | Hover (odağı taşımaz) | Tema ile |
| Odak görünümü | 1 px altın kenarlık; açılışta gizlice verilir (`FocusReveal.focus_quietly`), ilk ok/Tab'da görünür | |

### 7.2 Eylem

| Girdi | Bağlam | Eylem | Not |
|---|---|---|---|
| Enter / Space / sol tık | Kart odakta/üstünde | Seç ve kapat | Geri alma yok |
| Enter / tık | [Sonra] | Ertele | Yalnız ertelenebilir |
| Esc (`ui_cancel`) | Ertelenebilir | Ertele | Ortak Esc kuralı |
| Esc | **Zorunlu** | Etkisiz (modal kalır) | Zorunlu içeriği atlatacak modal; Esc ile oyun menüsü açılmaz (harita girdisi kilitli) |
| Sağ tık / kaydırma | Her yerde | No-op | |
| Girdi koruması | **Tüm sunumlar** (zorunlu zincir, şafak, HUD, yükleme) | Açılışta tek `screen_input_guard_s` (0,4 sn); koruma içinde tık/Enter/Esc düşer (kuyruğa alınmaz) | Ertelenebilir sunum dahil: şafakta kapatılan bir önceki modalın çift basışı yanlış lütuf seçtirmez. **Mevcut kodda yok** → `ui-programmer` görevi (`VictoryCard`'ın `InputGuard`'ı) |

Zorunlu zincirde her yeni ara kart (aynı modal yeniden oluşur) koruma yeniden başlatır.

## 8. Durumlar

| Durum | Tetik | Görünüm / davranış |
|---|---|---|
| Ertelenebilir | `mandatory = false` | [Sonra] görünür; `CarriesOnLabel` gizli; Esc erteler |
| Zorunlu | `mandatory = true` | [Sonra] yok; `BOON_CARRIES_ON`; Esc etkisiz; zincir: Ruh bedelin altına inince / havuz boşalınca / 8 seçime ulaşınca biter |
| Zincirde ara kart | Seçimden sonra koşul sürüyor | Aynı modal yeniden oluşur, yeni 3'lü, odak ilk kartta; **Karar (C-45): "N/M" ilerleme göstergesi yok** (dizi uzunluğu Ruh'a bağlı, sayı kaygı yaratır); yalnız `BOON_CARRIES_ON` |
| Havuz < 3 | Sahne havuzu / yığın tavanı | Tekrarlar birleştirilir (§6) |
| Havuz = 0 | Hepsi tavanda / filtrelendi | Modal açılmaz, HUD düğmesi gizli; zorunlu zincirde `boon_picks_finished` ertelenmiş yayınlanır |
| Ruh < bedel | Yetersiz | Sunum yok, düğme gizli; "kilitli" kart yok |
| Başka modal açık | Kuyruk dolu | Ertelenebilir sunum şimdi açılmaz; **kuyruk drained olunca yeniden denenir** (§3.1) |
| Kaybedilen sahne | `game_result` ≠ ONGOING | Sunum gösterilmez, Ruh korunur; HUD düğmesi kapalı |
| Arapça (RTL) | locale `ar` | Kartlar tersten dizilir (ilk kart sağda), metin sağa hizalı, Unifont 16 (başlık 16); harita LTR. Başlık/sarmalı satırlar ortalı |
| Hareketi Azalt | `reduce_motion` | Kart belirişi (isteğe bağlı cila: kart başına 4 kare dither + 2 kare bekleme) yok; kartlar anında tam; seçim konturu anında; panel girişi düz kesme. M2 varsayılanı zaten düz kesme (dither cila, AC değil) |

## 9. M2 eklemeleri

| Ekleme | Tanım | Bağımlılık |
|---|---|---|
| Askeri lütuflar | Kurt Gücü (`army_attack` +1, tavan 3), Demir Post (`army_defense` +1, tavan 3); açıklama "güç +N", ek öğretici metin yok | `BoonCatalog.active_systems` `&"effective_power"` eklenince havuza girer |
| Yığın göstergesi | §6 | Yığın sayısı okuma API'si |
| Sahne havuzu | `SceneDefinition.boon_pool_ids` ile havuz daralır; Prolog'da yalnız M1 üçlüsü; havuz < 3 gerçekçi olur | C-47 |
| Kalan Ruh satırı | `Kalan: X` | yok |
| İkon / figür / dither | C-67 | art-director varlıkları |
| Yükseklik bütçesi | §5.2 (≈ 276 ≤ 281) | AC9 |
| Girdi koruması | §7.2 | ui-programmer (C-47) |

## 10. Veri ve olaylar

| Veri | Kaynak | Güncelleme | Boş/eksik |
|---|---|---|---|
| 3'lü teklif | `SpiritController.current_offer(chapter_id)` | Modal açıldığı anda | Boş → modal açılmaz |
| Ruh | `GameState.ruh` | Açılışta | — |
| Bedel | `SpiritController.next_boon_cost()` | Açılışta | — |
| Yığın N / MAX (M2) | `ModifierController` kaydı + `ModifierSource.max_stacks` | Açılışta | MAX yoksa `×N` ya da satır yok |

| Oyuncu eylemi | Olay (sinyal) | Alıcı |
|---|---|---|
| Kart seç | `boon_picked(boon_id)` → `closed` | `GameContext._on_boon_picked` → `SpiritController.pick_boon` |
| Ertele | `deferred` → `closed` | `ModalQueue` (durum değişmez) |

Görünüm pasiftir: veri alır, niyet sinyali yollar; durum yazmaz.

## 11. Yerelleştirme

| Öğe | Not |
|---|---|
| Sınırlar | Kart genişliği 92 px sabit; ad ve açıklama sarar. Metin ≥ %40 genişlemeye dayanmalı; en uzun tek sözcük 84 px'e sığmalı (RU "Мастерство", DE "Himmelsschild" c39'da sığıyor). İkon adın soluna girdiği için ad alanı 24+4 px daralır: AC9 bunu da ölçer |
| Format | `BOON_COST`, `PER_TURN` gibi biçim key'leri çevirmen sahipli (ADR-0009); `to_upper/lower` yok |
| Yeni key'ler (M2) | `BOON_STACK` (`×%s/%s`), `BOON_STACK_LAST` (`(son)`), `BOON_REMAINING` (`Kalan: %s`). Glif: `×`/`→` testi (§6) |
| RTL | §8; sayılar ve `×N/MAX` Arapça satırda okunur kalmalı (LTR yalıtılmış) |
| CJK | Kısa metin: kart yüksekliği `MIN_HEIGHT` tabanında, üç kart eşit |

## 12. Erişilebilirlik

| Madde | Karşılık |
|---|---|
| Yalnız klavye | Tüm eylemler ok/Tab/Enter/Esc ile |
| Renk tek başına değil | Yığın `×N/MAX` metin; seçim `◆` + kontur; zorunlu/ertelenebilir fark [Sonra] varlığı ve altyazıyla |
| Yanıp sönme | Yok |
| Ekran okuyucu (AccessKit) | **Kapsam dışı** (Standard katman). `accessibility_name` kodda kalabilir, AC değil |
| Odak sırası | Kart 1 → 2 → 3 → [Sonra] → başa |
| Okunabilirlik | Font yalnız 12/24/36 (Fusion), Arapça 16/32 (Unifont) |

## 13. Kabul kriterleri

- [ ] AC1: Sunum bekliyorken tur sonunda (özet modalları kapandıktan sonra) modal kendiliğinden açılır, tur başına en çok 1; açık modal varsa açılmaz, kuyruk drained olunca yeniden denenir.
- [ ] AC2: HUD Kök Böri düğmesi yalnız bekleyen sunumda ve `ONGOING` iken görünür ve modalı açar.
- [ ] AC3: Ertelenebilir modalda [Sonra] ve Esc ertelemeyi yapar; Ruh/lütuf değişmez; yeniden açılışta aynı 3'lü gelir.
- [ ] AC4: Zorunlu modalda [Sonra] yok, Esc etkisiz, `BOON_CARRIES_ON` görünür; zincir `victory_pick_cap` (8) ile biter.
- [ ] AC5: Açılışta odak ilk karttadır; ok/Tab ile 3 kart (+[Sonra]) dolaşılır, odak modaldan çıkmaz; kapanışta önceki odak geri gelir.
- [ ] AC6: Seçimden sonra Ruh bedel kadar düşer, etki aynı turda görünür; ertelenebilirde ikinci modal kendiliğinden açılmaz.
- [ ] AC7 (M2): Tavanlı lütufta `×N/MAX` (son yığında `(son)`), tavana ulaşmış lütuf kartta yok; havuz < 3'te tekrarlı kartlar birleşik, tek kartla Enter seçer.
- [x] AC8 (M2, C-74 — `BoonOfferModal.new(guard_s)`, `input_guard_all_modals_test.gd`): **Her** sunum türünde (zorunlu, şafak, HUD, yükleme) `screen_input_guard_s` içinde tık/Enter/Esc hiçbir kartı seçmez/ertelemez (scene-flow AC24 genişletilmiş).
- [ ] AC9: 640×360'ta RU, DE, AR, ZH, TR, EN için panel üst (40) / alt (31) çubuklara taşmaz (≤ 281 px), kart metinleri kırpılmaz (ikon + yığın satırı dahil); figür sığmazsa gizlenir; ekran görüntüsü kanıtı `production/qa/evidence/`.
- [ ] AC10: Arapçada ilk kart sağda, Unifont 16, harita LTR.
- [ ] AC11: Seçim konturu (1 px altın + `◆`) görünür ve ≤ 2 kare sonra modal kapanır; Hareketi Azalt açıkken kontur ve (varsa) kart belirişi anlıktır.
- [ ] AC12: `GameContext`/`BoonOfferModal` durum yazmaz; yalnız `boon_picked`/`deferred` yayılır.

## 14. Kararlar (C-45, 2026-10-21)

| # | Konu | Karar (C-45) | Sahip |
|---|---|---|---|
| 1 | Yığın göstergesi | Seçim **sonrası** değer `×N/MAX`; son yığında `(son)` eki | game-designer |
| 2 | Girdi koruması | Tüm sunumlara `InputGuard` + `screen_input_guard_s` (§7.2) | ui-programmer |
| 3 | Kök Böri figürü | Başlığın yanında; sığmazsa gizli | art-director |
| 4 | Zincirde "N/M" | Yok; yalnız `BOON_CARRIES_ON` | game-designer |
| 5 | Havuz < 3 tekrarı | Görünümde birleştir; `BoonRules.offer` değişmez | game-designer + ui-programmer |
| 6 | Kart genişliği | 92 px; art bible §7 güncellendi | art-director |
| 7 | Sonraki bedel | Gösterilmez; yalnız `Kalan: X` | game-designer |
| 8 | Ruh/Kalan | İki ayrı etiket; `→` kullanılmaz | ux-designer |
| 9 | Kuyruk | Şafakta özet önce; sunum drained'de yeniden denenir (ADR-0011 K5) | ui-programmer |
| 10 | Glif | `×`, `→` için glif testi görevi; doğrulanana dek ASCII `x` | ui-programmer |

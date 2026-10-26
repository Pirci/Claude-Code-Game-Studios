# UX Spec: Sahne Akışı Ekranları (`SceneFlowScreens`)

> **Durum**: Approved (C-45, 2026-10-21) · **Yazar**: ux-designer · **Güncelleme**: 2026-10-21
> **Platform**: PC (Steam), yalnız klavye + fare (gamepad/dokunmatik yok — 2026-10-08 kararı)
> **GDD**: `design/gdd/scene-flow.md` §3.5–§3.9, §8 (AC28–AC32), §9–§10 · `design/levels/perde1-dogu-curcet.md` §2 · `design/narrative/narrative-voice.md` §8
> **ADR**: ADR-0009 (font/RTL), ADR-0011 (`ModalQueue`, pasif görünüm), ADR-0012 (`NarrativeContext`, `ChapterSelectContext`)
> **Erişilebilirlik katmanı**: Standard (Hareketi Azalt var; ekran okuyucu kapsam dışı)
> **Kapsam**: tek belgede 5 ekran. "Mevcut" = kodda bugün; "M2" = bu belgenin tanımladığı ekleme.
> **Yeni pattern işareti**: interaction-patterns.md henüz yok; "yeni" etiketli kalıplar: *ortak girdi koruması (tüm modallar)*, *Esc kuralı*, *E5 durum ikonu + düğüm satırı*.
> **Kanıt**: `production/qa/evidence/c40-scene-flow-{en,de,ar}.png`, `c69-placement-and-marker-en-ar.png`, `c56-menu-continue.png`.

| # | Ekran | Durum (`SceneFlow`) | Kod | Bağlam |
| ---- | ---- | ---- | ---- | ---- |
| E1 | Anlatı ekranı (giriş / Kök Böri A / çıkış / son / Destanı Oku) | `INTRO_NARRATIVE`, `KOK_BORI_MARK` A, `OUTRO_NARRATIVE`, `CAMPAIGN_END`, `STORY_REPLAY` | `contexts/narrative_context/narrative_context.gd` | tam ekran, ayrı bağlam |
| E2 | Hedef paneli (Kök Böri işareti) | `KOK_BORI_MARK` B | `features/campaign/ui/objective_panel.gd` | harita üstü modal |
| E3 | Zafer sonuç kartı | `VICTORY_BEAT` | `features/campaign/ui/victory_card.gd` | harita üstü modal |
| E4 | Yenilgi ekranı | `DEFEAT` | `features/campaign/ui/defeat_screen.gd` | harita üstü modal |
| E5 | Bölüm seçimi (sefer haritası) | `CHAPTER_SELECT` | `contexts/chapter_select_context/chapter_select_context.gd` | tam ekran, ayrı bağlam |

---

## 0. Ortak Kurallar (tüm ekranlar; diğer UX spec'leri de bunlara başvurur)

### 0.1 Modal genişliği ve başlık

| Kural | Karar (C-45) |
| ---- | ---- |
| Genişlik | ModalQueue modallarında iç genişlik tavanı **288 px**, dış **304 px** (E2 280 → 288) |
| Başlık | M2'de tüm panel/modal başlıkları **12 px `HeaderLabel`** (Arapça 16). 24 px yalnız tam ekran başlık kartı (cila). art-bible §7 ve scene-flow §10 güncellendi |
| Açılış animasyonu | M2 varsayılanı **düz kesme**; dither cila, AC değil. Hareketi Azalt = dither yok + sabit kare |

### 0.2 Girdi

| Girdi | Anlam |
| ---- | ---- |
| Enter / Space | Odaktaki düğmeyi bas (E1'de: ilerle) — `ui_accept` |
| Sol tık | Düğme; E1'de her yerde ilerle |
| Tab / ok | Odağı taşı; çerçeve yalnız klavye kullanımında görünür (`FocusReveal.focus_quietly`) |
| Tuş tekrarı (echo) | Sayılmaz |

**Esc kuralı (yeni pattern):**

| Modal türü | Esc |
| ---- | ---- |
| Tek güvenli çıkışı olan veya ertelenebilir (E3 zafer/rapor kartı, ertelenebilir lütuf, E1 anlatı, E5) | O eylem: E3 = Devam · ertelenebilir lütuf = Ertele · E1 = Atla · E5 = Ana Menü |
| Zorunlu içeriği atlatacak (zorunlu lütuf, E2 hedef paneli, E4 yenilgi) | Etkisiz |
| HUD hedef seçimi modu | Esc = iptal |

### 0.3 Girdi koruması (`InputGuard`, `screen_input_guard_s` = 0,4 sn) — yeni pattern

| Kural | Ayrıntı |
| ---- | ---- |
| Kapsam | **Tüm ModalQueue modalları** (lütuf seçimi — ertelenebilir sunum dahil, E2, E3, E4, rapor/özet modalları) **ve E5 bölüm seçimi** açılışında; her yeni E1 sayfasında da |
| Amaç | Kazandıran tık, çift Enter veya art arda Esc bir sonraki ekranı geçemez / yanlış lütuf seçtirmez |
| Davranış | Koruma içinde Esc/Enter/tık **düşer** (kuyruğa alınmaz); düğmeler `disabled`, süre sonunda önceki durumuna döner |
| Görsel | Düğme soluk (devre dışı stili); sayaç/ipucu yok |

### 0.4 Hareketi Azalt (`AccessibilitySettings.reduce_motion`)

| Öğe | Normal | Hareketi Azalt |
| ---- | ---- | ---- |
| Anlatı metni | karakter karakter (`text_reveal_cps` = 45) | anında |
| Sayfa geçişi | düz kesme (cila: 4 kare dither) | düz kesme |
| E2 işaret ikonu / Kök Böri parçacıkları | 2 kare, 1 fps | sabit (orta kare) |
| E3 Kök Böri parıltısı (cila) | sıcak parlama | sabit kare |
| E4 dağılan gri Kök Böri (cila) | dither dağılma | sabit kare |
| E5 yeni açılma parıltısı | 4 kare altın | parlamasız, sabit "yeni" işareti |
| Alfa fade / kesirli ölçek | **hiçbir zaman yok** (art bible §7, AC27) | — |

Hiçbir öğe ≥ 3 Hz yanıp sönmez (en hızlısı 1 fps işaret) → flaş uyarısı gerekmez.

### 0.5 Yerelleştirme ve yazı

| Kural | Ayrıntı |
| ---- | ---- |
| Font | Fusion Pixel 12 (satır ≈ 18 px); Arapça Unifont 16 (≈ 18-20 px); yalnız native boyut |
| RTL | Düzen aynalanır (düğme sırası, başlık hizası); **sayfa sayacı `n/N` LTR sabit**; harita ve illüstrasyon aynalanmaz; sayısal ifadeler yalıtılmış LTR (C-69) |
| Taşma | UI etiketi `…` ile kısalır; **anlatı metni asla kısalmaz** (sığmayan çeviri içerik hatası, L6) |
| Sembol | `✓ ⚠ ✕ −` metinde yok; durumlar piksel ikon (ADR-0009). `×` ve `→` için glif testi görevi (C-47) yazılır; doğrulanana kadar ASCII `x` kullanılır |
| Büyük/küçük harf | Kodda dönüştürme yok |
| Ekran okuyucu | AccessKit kapsam dışı; `accessibility_name` kodda kalabilir, AC değil |

### 0.6 Çubuk ölçüleri ve yükseklik bütçesi

Üst çubuk **40 px** (2 satır), alt çubuk **27 px**, modal alt marjı **31** (27 + 4). Modal için kullanılabilir yükseklik ≈ 360 − 40 − 31 − 8 ≈ **281 px**. Üst-orta aday konumu üst çubuğun 4 px altı (y = 44).

### 0.7 Akış (M2: K = 2, Prolog + Perde 1)

```
Yeni Sefer ─▶ E1 giriş ─▶ E1 Kök Böri A ─▶ E2 ─[Başla]─▶ OYUN ─zafer─▶ E3 ─▶ (lütuf) ─▶ E1 çıkış ─┬─ c<K ▶ E5
Devam Et (map yok) ───────────────────────────────────────────────────────────────────────▶ E5     └─ c=K ▶ E1 son ▶ Menü
OYUN ─yenilgi─▶ E4 ─[Yeniden Dene]─▶ E2 (yalnız B) · E4 ─[Ana Menü]─▶ Menü · E5 ─[Destanı Oku]─▶ E1 replay ─▶ E5
```

M2 ilk kez `CHAPTER_SELECT`'i zaferden sonra gösterir (K=2): Prolog çıkışı → E5 (Perde 1 `AVAILABLE`, yeni açılma + `CHAPTER_1_TEASER`). Perde 1 çıkışı → `CAMPAIGN_END` (E1 biçimi) → Ana Menü.

### 0.8 Anlatı paneli geometrisi — F4 kesinleştirme

Ölçüm (c40): panel 640×92, başlık satırı ≈ 14 px, satır aralığı ≈ 18 px, düğme satırı ≈ 18-20 px. F4'ün geçici varsayımı tutmuyor.

| Sayfa türü | Metin satırı (Fusion 12 **ve** Unifont 16) | Karakter üst sınırı (en) | Kaynak |
| ---- | ---- | ---- | ---- |
| Başlıksız | ≤ 3 | 220 (`PAGE_MAX_CHARS_EN`) | narrative-voice §8 |
| Başlıklı | ≤ 2 | 150 | narrative-voice AC-V4 |

F4'teki "5/4 ve 3/2" yerine bu tablo geçerli; L6 testi bu `max_lines` ile koşar. Panel yüksekliği 92 px değişmez. Değerler ekran görüntüsünden çıkarıldı → AC-E1-7 gerçek `Font.get_multiline_string_size` ile doğrular.

### 0.9 Ses (ADR-0008; M2'de yer tutucu yeterli)

Sayfa ilerle `sfx_narrative_advance` · Kök Böri görünür (A, E2) `sfx_kok_bori_appear` · Zafer/yenilgi `sfx_victory`+`music_victory` / `sfx_defeat`+`music_defeat` · Yeni açılan bölüm / kilitli ret `sfx_chapter_unlock` / `sfx_ui_denied`.

---

## E1. Anlatı Ekranı (`NarrativeContext`)

### E1.1 Amaç

Oyuncu: sahnenin ağırlığını kısa ve resimli okumak; istemiyorsa **bedelsiz** geçmek (≤ 150 sn okuma ya da ≤ 3 basışta oyuna: Esc, Esc, [Başla]). Oyun: sahneyi destan sayfası olarak çerçevelemek, E2'ye taşımak. Duygu: törensel sakinlik; atlama her zaman serbest.

### E1.2 Giriş / Çıkış

| Giriş | Veri | Çıkış | Sonraki |
| ---- | ---- | ---- | ---- |
| `INTRO_NARRATIVE`(c) (T1/T6) | `scene.intro_pages` (1–4) | son sayfa / Esc / [Atla] | `KOK_BORI_MARK` A; A boşsa E2 |
| `KOK_BORI_MARK` A (T10) | `scene.kok_bori_pages` (0–2); Yeniden Dene'de **gösterilmez** | aynı | E2 |
| `OUTRO_NARRATIVE`(c) (T18) | `scene.outro_pages` (1–4) | aynı | c<K: E5 · c=K: `CAMPAIGN_END` |
| `CAMPAIGN_END` (T20) | `campaign.end_pages` (1–4) | aynı | Ana Menü |
| `STORY_REPLAY`(c) (T7, E5'ten) | intro + A + outro art arda, **salt-okunur** | son sayfa / Esc (tüm oynatmadan çıkar) | E5 |

Tek sinyal: `pages_finished`. Durum/kayıt/Ruh değişmez (replay).

### E1.3 Düzen (640×360)

```
y0  ┌────────────────────────────────────────────────────────┐
    │  İLLÜSTRASYON 640×360 (alt 92 px panelin altında kalır)│
    │  ► güvenli alan: üst 640×268 — özne/yüz/Kök Böri burada│
y268├────────────────────────────────────────────────────────┤
    │ {Başlık 12px, yalnız başlıklı sayfa}          {n/N LTR}│ HudPanel
    │ {Metin: ≤3 satır (başlıklıysa ≤2), sola hizalı}        │ 640×92
    │                                    [Atla]  [Devam ●]   │
y360└────────────────────────────────────────────────────────┘
```

| Bölge | İçerik | Taşma |
| ---- | ---- | ---- |
| İllüstrasyon | `NarrativePage.illustration_path`; boşsa önceki görsel; yüklenemezse `#141A33` düz zemin. `STRETCH_KEEP_CENTERED` | yok |
| Başlık | `title_key` (yalnız tekil başlıklar), 12 px `HeaderLabel` | gizlenir (başlıksız) |
| Sayaç | sağ üst, LTR `n/N` (ASCII) | — |
| Metin | 624 px × (başlıksız 3 / başlıklı 2 satır); kaydırma yok | sığmayan = içerik hatası |
| Düğmeler | alt sağ (RTL'de alt sol): [Atla] ikincil, [Devam] birincil (sessiz odak) | `…` |

**İllüstrasyon güvenli alanı (C-68'e girdi):** önemli içerik (yüz, Kök Böri, imza ışığı) üst 640×268'de olmalı.

### E1.4 İçerik tablosu

| Öğe | Anahtar | Bütçe (en) | Not |
| ---- | ---- | ---- | ---- |
| Sayfa metni | `CHAPTER_<n>_INTRO_<p>`, `_KOKBORI_<p>`, `_OUTRO_<p>` | ≤ 220 (başlıklı ≤ 150) | de/fr/ru ≈ +30% → L6 dil başına; Arapça aynı satır sınırı |
| Sayfa başlığı | `CHAPTER_1_TITLE`, `CHAPTER_2_TITLE`, `CHAPTER_1_KAGAN_TITLE`, `CHAPTER_2_KANGLI_TITLE` | ≈ 24 (tek satır) | de en uzun, sığıyor; Arapça sağa hizalı |
| [Atla] / [Devam] | `SKIP` (de 12) / `CONTINUE` (de 11) | — | — |
| Sayaç | (yok) | 3–5 | LTR sabit |

### E1.5 Etkileşim

| Girdi | Koşul | Eylem |
| ---- | ---- | ---- |
| Enter / Space / sol tık / [Devam] | metin yazılıyor | metni tamamla (sayfa geçmez) — F6 |
| aynı | metin tamam | sonraki sayfa; son sayfaysa `pages_finished` |
| Esc / [Atla] | koruma geçti | **bulunulan durumun** kalan sayfalarını atla; onay yok; E2 atlanmaz |
| herhangi | ilk 0,4 sn | yok sayılır (§0.3) |
| Esc (`STORY_REPLAY`) | — | tüm oynatmadan çık (E5) |

Her sayfada [Devam] sessiz odak; [Atla] Tab ile odaklanabilir.

### E1.6 Durumlar

| Durum | Tetik | Davranış |
| ---- | ---- | ---- |
| Yazılıyor / Tamam | sayfa açıldı / metin bitti | ilk basış tamamlar / ikinci ilerler |
| İllüstrasyon yükleniyor | asenkron | önceki kare / `#141A33`; metin okunur; ≤ 2 illüstrasyon bellekte |
| İllüstrasyon yok / zaman aşımı (3 sn) | dosya yok | düz indigo (c40 bugün bu hâlde: C-68'e kadar); uyarı log, çökme yok |
| Boş sayfa listesi | `_pages` boş | anında `pages_finished` |
| **M2: iki sahne** | Prolog 2+1+2, Perde 1 2+1+2 (G-1 `CHAPTER_2_TITLE`, G-2, G-3 Kök Böri `PROFILE`; O-1, O-2 `CHAPTER_2_KANGLI_TITLE`) | aynı şablon, yalnız veri |
| **M2: `CAMPAIGN_END`** | Perde 1 çıkışından sonra | aynı şablon (`CAMPAIGN_END_DEMO_1` + `CHAPTER_2_TEASER`); son sayfa → Ana Menü |
| **M2: Yeniden Dene** | T22 | A atlanır, doğrudan E2 |

**Karar (C-45) — Perde 1 illüstrasyonları:** 5 sayfa / **5 illüstrasyon**, adlandırma `ill_perde1_<ad>.png` (Prolog gibi); G-3 Kök Böri `PROFILE` sayfası dahil; güvenli alan §E1.3. Sahip: art-director + narrative-director.

### E1.7 Mevcut ↔ GDD farkları (kararlar)

| Fark | Karar (C-45) |
| ---- | ---- |
| Sayfa geçişi: 4 kare dither (GDD §3.8) | M2'de düz kesme; dither cila |
| Başlık kartı 24 px (GDD §3.8/§9) | 12 px `HeaderLabel` panel içinde (§0.1); GDD güncellendi; 24 px tam ekran kart cila |
| F4 geometri 5/3 satır | gerçek 3/2 (§0.8) |
| "Tıkla-ilerle ipucu" (§10) | [Devam] yeterli; ek ipucu yok |

### E1.8 Kabul kriterleri

- [ ] AC-E1-1: Metin yazılırken ilk Enter/tık tamamlar, ikinci ilerler; Esc kalan sayfaları atlar (AC28).
- [ ] AC-E1-2: İlk 0,4 sn girdi yok sayılır; art arda iki Esc: ikincisi yeni ekranın korumasına düşerse yok sayılır.
- [ ] AC-E1-3: Hareketi Azalt'ta metin anında, geçiş düz kesme.
- [ ] AC-E1-4: Esc E2'yi kapatmaz (Prolog Yeni Sefer → Esc, Esc, [Başla] = 3 basış, ≥ 0,8 sn).
- [ ] AC-E1-5: Tüm ekran yalnız klavye ile geçilebilir.
- [ ] AC-E1-6: Arapçada sayaç `n/N` LTR; düğme sırası aynalı; Unifont 16; illüstrasyon aynalanmaz (c40-ar ile eşleşir).
- [ ] AC-E1-7: Her çeviri (11 dil) başlıksız ≤ 3, başlıklı ≤ 2 satıra sığar (`glyph_coverage_test` + L6, §0.8).
- [ ] AC-E1-8: Perde 1 (5 sayfa) ve `CAMPAIGN_END` aynı ekranda render olur; `STORY_REPLAY` kayıt yazmaz.
- [ ] AC-E1-9: İllüstrasyon yoksa düz zemin + metin okunur, çökme yok.

---

## E2. Hedef Paneli — Kök Böri İşareti (`ObjectivePanel`)

### E2.1 Amaç

Oyuncu: "Ne yapmalıyım, nerede?" sorusuna tek bakışta cevap; işaretleri **görerek** başlamak (hedef cümlesini okuyup işaretli bölgeyi 10 sn içinde göstermek, AC33). Oyun: hedefi atlanamaz biçimde iletmek; S2 kaydını tetiklemek. Duygu: rehberlik, baskı değil.

### E2.2 Giriş / Çıkış

| Giriş | Çıkış | Sonuç |
| ---- | ---- | ---- |
| T11 (A'dan / A boşsa T10) · T22 Yeniden Dene | [Başla] / Enter / Space (tek basış) | `dismissed` → S2 kaydı → `PLAYING` |
| — | **Esc kapatmaz** (Esc kuralı, §0.2) | yok sayılır |

Harita 1. tur durumunda arkada görünür; yalnız zemin katmanı koyu indigoya kayar, **işaretler ve sahiplik/bozulma katmanı boyanmaz**. Harita girdisi kilitli.

### E2.3 Düzen (640×360) — örtmeme kuralı

```
y0   ┌─ üst bar 40 px (2 satır) ──────────────────────────┐
y44  │     ┌─ DivinePanel iç 288 / dış 304 × ≈130 ───┐    │  üst-orta aday: üst bar altı +4
     │     │        Kök Böri  (12px başlık)          │    │
     │     │  {Kök Böri sözü, ≤ 2 satır}             │ ◆  │  ◆ = hedef işareti 9×9
     │     │  Hedef: {metin, ≤ 3 satır}              │    │    (panelin DIŞINDA)
     │     │            [ Başla ● ]                  │    │
y~174│     └─────────────────────────────────────────┘    │
     │   (harita: işaretler ve bölgeler görünür)          │
y333 └─ alt bar 27 px (+4 marj → y329'a kadar kullanılır)─┘
```

| Bölge | İçerik | Not |
| ---- | ---- | ---- |
| Başlık | `KOK_BORI`, 12 px `HeaderLabel`, ortalı | — |
| Mitik satır | `scene.kok_bori_line_key`, 288 px sarma, ≤ 2 satır | ortalı |
| Hedef satırı | `OBJECTIVE_LABEL: ` + `WinCondition.description_key`, 288 px sarma, ≤ 3 satır | tek doğruluk kaynağı = kazanma koşulu |
| [Başla] | `START_SCENE`, min 64 px, `PrimaryButton`, sessiz odak | — |
| Haritada işaret | `icon_objective_marker` 9×9, `V` kümesi | şekil taşıyıcı (renk tek taşıyıcı değil) |

**Karar (C-45) — Kök Böri sprite'ı:** M2'de panel **sprite'sız**; söz yeterli. 48×32 profil sprite'ı `/asset-spec` ile cila (önce C-68 illüstrasyonları).

**Yerleşim (Mevcut, `PanelPlacement.choose`):** aday sırası alt-orta → üst-orta; hiçbir işareti kesmeyen ilk aday; ikisi de keserse toplam kesişimi en küçük olan (eşitlikte alt). **Perde 1:** `erlik_foci` = `curuk_koru` (335,240); `objective_region_ids` = `curcet_otagi` (562,125). Alt-orta `curuk_koru`'yu keser; üst-orta (x ≈ 170–470 → 288/304 px genişlikte bile) iki işareti de kesmemesi beklenir (AC-E2-3 gerçek verilerle doğrular). Üst-orta kuzey yolunu kısa süre örter; kabul edilen bedel.

### E2.4 İçerik tablosu

| Öğe | Anahtar | En uzun dil | Arapça |
| ---- | ---- | ---- | ---- |
| Başlık | `KOK_BORI` | `Kök Böri` (özel ad) | `كوك بوري` |
| Kök Böri sözü | `CHAPTER_1_KOKBORI_LINE` (en 55), `CHAPTER_2_KOKBORI_LINE` (bütçe 90) | de/ru 2 satır | 2 satır, Unifont 16 |
| Etiket | `OBJECTIVE_LABEL` | de `Ziel` / fr `Objectif` | `الهدف` |
| Hedef metni | `WIN_CONDITION_CH1` (en 53), `WIN_CONDITION_CH2` (C-43) | de 2 satır; > 3 satır içerik hatası | 2 satır |
| [Başla] | `START_SCENE` | de/fr 9 | `بدء` |

### E2.5 Etkileşim

Enter / Space / tık [Başla] → kapat → `PLAYING` (koruma sonrası). Esc etkisiz. Tab: tek odaklanabilir öğe; odak panelden çıkmaz. Haritaya tık kilitli.

### E2.6 Durumlar

| Durum | Davranış |
| ---- | ---- |
| Normal | §E2.3 |
| `V` boş | yalnız metin, işaret yok (hata değil) |
| Yeniden Dene (T22) | yalnız E2 (anlatı yok) |
| Sahne içi (panel sonrası) | işaret `V` boşalana kadar kalır; HUD "Hedef" satırı kalıcı (c56'da var) |
| **M2: Perde 1** | 2 işaret (odak + başkent); HUD ilerleme satırı **dört parça** (bkz. Karar K3 aşağıda) |
| **M2: sahne 2'de A boş değil** | G-3 E1'de, E2'de yalnız söz satırı; tekrar yok |

**Karar (C-45, K3) — Perde 1 hedef ilerlemesi:** `must_defeat_all_enemies` iken HUD ilerleme satırına "Cürcet bölgeleri x/3" (alınan düşman bölgesi / başlangıçtaki düşman bölgesi sayısı) eklenir; kazanma koşulunun dört parçası da izlenir. scene-flow §10 güncellendi; uygulama hud.md.

### E2.7 Kabul kriterleri

- [ ] AC-E2-1: Panel `WIN_CONDITION_*` ve `kok_bori_line_key` metnini gösterir; Esc kapatmaz; [Başla] kapatır (AC29).
- [ ] AC-E2-2: İlk 0,4 sn tık/Enter yok sayılır.
- [ ] AC-E2-3: Prolog (`sinir_bolge`) ve Perde 1 (`curuk_koru`, `curcet_otagi`) için panel hiçbir işaret ikonunu örtmez (`objective_marker_rects()` kesişim = 0); Final için en az kesişen aday seçilir (birim, `PanelPlacement`).
- [ ] AC-E2-4: Panel (iç ≤ 288 px) de/ru ve Arapçada hedef 3 satırı aşmaz, ekran dışına taşmaz; üst çubuk (40 px) altında, alt çubuk (31 px marj) üstünde kalır.
- [ ] AC-E2-5: İşaret `V` boşalınca söner, yayılımla yeniden bozulursa geri gelir.
- [ ] AC-E2-6: İşaret renk-körlüğünde şekille ayırt edilir.
- [ ] AC-E2-7: Yalnız klavye ile başlanabilir; S2 yalnızca [Başla]'dan sonra yazılır (AC18).

---

## E3. Zafer Sonuç Kartı (`VictoryCard`)

### E3.1 Amaç

Oyuncu: zaferi hissetmek, ne başardığını görmek (tur, toprak, Ruh); tek basışla lütuf seçimine/çıkışa geçmek. Oyun: sonucu bildirip `acknowledged` ile lütuf dizisini (F2) başlatmak. Duygu: kısa, sıcak, hak edilmiş.

### E3.2 Giriş / Çıkış

T13 `game_won` (`current_turn`, `regions_held / regions_total`, `ruh_gained` F3) → [Devam] / Enter / Space / **Esc** / tık → `acknowledged` → `BOON_PICKS` (k>0) ya da COMMIT → E1 çıkış.

### E3.3 Düzen

```
 (harita karartılmış; ModalQueue ortalar)
        ╔══════════════════════════════╗  ModalPanel, min 180 px, iç ≤ 288
        ║           Zafer              ║  12px HeaderLabel
        ║   Tur sayısı: {n}            ║
        ║   Elimizdeki topraklar: a / b║
        ║   Kazanılan Ruh: {r}         ║
        ║         [ Devam ● ]          ║
        ╚══════════════════════════════╝
```

| Satır | Anahtar | Not |
| ---- | ---- | ---- |
| Başlık | `VICTORY` | 12 px; de `Sieg` kısa |
| Tur | `RESULT_TURNS` | `NumberFormatter.format_int` |
| Topraklar | `RESULT_REGIONS` | `NumberFormatter.fraction(a,b)`; es en uzun (28 + kesir) → kart 288'e kadar genişler; kesir LTR-yalıtılmış |
| Ruh | `RESULT_RUH_GAINED` | int |
| [Devam] | `CONTINUE` | `PrimaryButton` |

**Karar (C-45):** E3 M2'de **yalın** (3 satır metin, düz `ModalPanel`). Altın çerçeve, Kök Böri parıltısı ve satır başına ikon + rakam Alpha cilası (art-director).

### E3.4 Etkileşim

Enter / Space / tık / **Esc** = Devam (koruma sonrası; Esc kuralı §0.2 — geri alınamaz zarar yok, lütuf modalında Esc etkisiz olması bilinçli fark). İlk 0,4 sn girdi düşer.

### E3.5 Durumlar

Koruma (ilk 0,4 sn, [Devam] pasif) · Normal · `ruh_gained = 0` satır **0** gösterilir, gizlenmez · **M2: Perde 1** aynı kart, `regions_held/8` · Lütuf var (k>0): kapanır kapanmaz zorunlu lütuf modalı (≤ 1 kare boşluk, odak sessiz; lütuf modalı kendi girdi korumasını alır).

### E3.6 Kabul kriterleri

- [ ] AC-E3-1: Değerler `current_turn`, oyuncu bölge sayısı / toplam, F3 ile eşit (AC31).
- [ ] AC-E3-2: Kazandıran tık `t0+0,1 sn`'de kartı kapatmaz; Enter/Space/Esc/tık `t0+0,4 sn` sonrası çalışır (AC24).
- [ ] AC-E3-3: Yalnız klavye ile kapanır; odak [Devam]'dadır.
- [ ] AC-E3-4: de/es/ru/ar'da satır taşması yok; Arapça kesir ve sayılar okunur sırada.
- [ ] AC-E3-5: Kapanışta k>0 ise lütuf modalı koruma süresi içinde yanlış seçilemez (boon-selection AC8).

---

## E4. Yenilgi Ekranı (`DefeatScreen`)

### E4.1 Amaç

Oyuncu: "Neden kaybettim?" ve "ilerlemem gitti mi?" sorularına anında cevap; tekrar denemeye cesaret (≤ 2 basışta yeniden başlat/menü). Oyun: `loss_reason`'ı öğrenme geri bildirimine çevirmek; kayıt yazmadan yeniden deneme sunmak. Duygu: soğuk ama cezalandırıcı değil.

### E4.2 Giriş / Çıkış

| Giriş | Çıkış | Sonuç |
| ---- | ---- | ---- |
| T14 `game_lost` (`loss_reason` durumdan) | [Bölümü Yeniden Dene] (T22) | giriş anlık görüntüsü geri yüklenir → E2 (yalnız B) |
| | [Ana Menü] (T23) | kayıt yazılmaz; Devam Et son tur sonu kaydını açar |
| | Esc | **etkisiz** (Esc kuralı §0.2; **Karar C-45**) |

**Son hamle sırası (battle-report ile uyumlu):** oyuncunun son bölgesi düşünce sıra = son hamle raporu → E4; özet atlanır.

### E4.3 Düzen

```
      ┌────────────────────────────────────┐ ModalPanel (iç ≤ 288; M2: tema Karar aşağıda)
      │              Yenilgi               │ 12px
      │ {Neden metni, ≤ 3 satır}           │
      │ Erlik'in Gölgesi: {güç} / {eşik}   │ ← yalnız ERLIK
      │ {Güvence: Ruh ve lütuflar korunur} │
      │ [ Bölümü Yeniden Dene ● ] [Ana Menü]│
      └────────────────────────────────────┘
```

### E4.4 İçerik tablosu

| Öğe | Kaynak / Anahtar | Not |
| ---- | ---- | ---- |
| Başlık | `DEFEAT` | de `Niederlage` |
| Neden | 1) `scene.defeat_text_key` 2) `DEFEAT_REASON_<loss_reason>` 3) `DEFEAT_REASON_GENERIC` | fr ERLIK (49) → 3 satır; Arapça 2 satır |
| Erlik değeri | `ERLIK_SHADOW_VALUE` = `erlik_power / erlik_loss_threshold` (yalnız `ERLIK`) | kesir LTR-yalıtılmış |
| Güvence | `DEFEAT_PROGRESS_KEPT` | en 61 → 2–3 satır; her yenilgide |
| Birincil / ikincil | `RETRY_SCENE` ("bölüm" terimi, E5 ile tutarlı) / `MAIN_MENU` | de `Kapitel wiederholen` (19) |

**Kapandı (C-76, 2026-10-25):** yeni metin "Erlik'in gölgesi bu toprakları yuttu." / "Erlik's shadow has swallowed these lands." (11 dil; yer sözcüğü yok — `narrative_voice_test`); en/tr/fr/de/ru/ar'da tek satır, taşma yok (`production/qa/evidence/c76-defeat-erlik.png`). ~~**Açık bağımlılık (C-45, Q11 → karar):** `DEFEAT_REASON_ERLIK` sahneden bağımsız yeniden yazımı ("ata yurdu/homeland" çıkar; Perde 1 doğu ormanı için de doğru) **11 dilde henüz yok**. Metin **C-47/C-43 içerik görevi** (narrative-director); **AC-E4-1 (ERLIK metni kısmı) ve AC-E4-7 bu metnin yazılmasına bağlıdır**; yazılana dek E4'te Perde 1 Erlik kaybı yanlış bağlam gösterir (c40 hâlâ "homeland").~~

### E4.5 Etkileşim

Enter / Space: odaktaki düğme (varsayılan [Yeniden Dene], sessiz odak). Tab / ← →: iki düğme arası. Tık: ilgili düğme. İlk 0,4 sn iki düğme pasif. [Ana Menü] **onaysız** (kayıt yazılmıyor, kayıp yok).

### E4.6 Durumlar

| Durum | Fark |
| ---- | ---- |
| `ERLIK` | neden + `Erlik'in Gölgesi: 9 / 9` satırı |
| `NO_REGIONS` | değer satırı yok (Perde 1 siyasi yenilgi buraya eşlenir) |
| `NONE` / eşlemesiz | `DEFEAT_REASON_GENERIC` |
| Sahneye özel | `defeat_text_key` dolu → o metin kazanır |
| Yeniden Dene tekrarı | her seferinde aynı giriş anlık görüntüsü; sınır yok |
| **M2: Perde 1** | iki kayıp yolu (Erlik / siyasi); Kök Böri sunumu gösterilmez, Ruh harcanmaz |

### E4.7 Karar (C-45) — görsel hava

`ModalPanel` türevi `DefeatPanel`: altın başlık/çerçeve yerine gri-mor süs, **metin kontrastı ≥ 4,5:1 zorunlu** ("düşük kontrast" yalnız zemin/süs için geçerli, metin için değil). Gri dağılan Kök Böri cila. Çizim art-director'ın; M2'de mevcut `ModalPanel` ile çıkılabilir ama AC-E4-6 tema onaylanana dek açık kalır.

### E4.8 Kabul kriterleri

- [ ] AC-E4-1: Neden sırası `defeat_text_key` → `DEFEAT_REASON_<loss_reason>` → genel (AC15b); `ERLIK`'te `9 / 9` biçimi. (ERLIK metin içeriği §E4.4 bağımlılığına bağlı.)
- [ ] AC-E4-2: `DEFEAT_PROGRESS_KEPT` her yenilgide görünür.
- [ ] AC-E4-3: Ekran açılırken `SaveStore.write` çağrı sayısı değişmez (AC15).
- [ ] AC-E4-4: Yeniden Dene → E2 (anlatı yok), `ruh/boons` giriş değerine döner (AC16).
- [ ] AC-E4-5: Yalnız klavye ile iki yol çalışır; varsayılan odak [Yeniden Dene]; Esc etkisiz.
- [ ] AC-E4-6: Altın renk yok (art-director onaylı tema); tüm metin ≥ 4,5:1.
- [x] AC-E4-7 (C-76, neden metni kısmı): fr/de/ru/ar'da neden metni taşmaz (yeni `DEFEAT_REASON_ERLIK` yazıldıktan sonra); düğmeler tek satırda sığar ya da panel genişler (≤ 288).
- [ ] AC-E4-8: Erlik satırı `loss_reason ≠ ERLIK` iken görünmez.

---

## E5. Bölüm Seçimi — Sefer Haritası (`ChapterSelectContext`)

### E5.1 Amaç

Oyuncu: zaferden sonra **durup nefes almak**, ilerlemesini (sahneler, Ruh, lütuflar) görmek, sıradaki tehdidi merak etmek; tek basışla sıradaki sahneyi başlatmak ya da destanı yeniden okumak. Oyun: sahne arası otomatik geçişi önlemek; Devam Et'in sahne arası iniş noktası olmak. Duygu: yolun uzadığı, kapı açıldı hissi.

### E5.2 Giriş / Çıkış

| Giriş | Çıkış | Sonraki |
| ---- | ---- | ---- |
| E1 çıkışı (T19, c<K): `chapters_completed`, `ruh`, `boons` (S3 sonrası) | [Başla] (T6) | E1 giriş(c) |
| Devam Et, `map = null` (T4) | [Destanı Oku] (T7) | E1 replay → E5 |
| | [Ana Menü] (T8) / **Esc** | Ana Menü |

**Karar (C-45):** E5'te Esc = [Ana Menü] (onaysız; durum S3'te güvende, kayıp yok). Tamamlanmış kampanya (Devam Et) salt-okunur + `CAMPAIGN_COMPLETE` rozeti; aynı Esc. K = 1'de E5 zaferden sonra gösterilmezdi; M2'de gösterilir (K = 2).

### E5.3 Düzen (640×360)

Mevcut ortalı tek `ModalPanel` (min 300 px) tek satırlık `[ad … düğme]` M2'de taşar (c40'ta ad zaten kesiliyor). M2: iki satırlı düğüm (üst: ad; alt: durum/teaser). E5 tam ekran bağlam olduğundan panel ≈ 400 px olabilir (§0.1 modal tavanı yalnız ModalQueue modalları içindir).

```
 zemin #141A33 (kilim şeridi: art-director kararı, cila)      640×360
        ┌────────────────────────────────────────────┐ ModalPanel ≈ 400 px
        │                 Kampanya                    │
        │          [Kampanya tamamlandı]  ← yalnız hepsi tamam
        │ │ [ikon✓] Prolog: Doğuş            [Destanı Oku] │
        │ │ [ikon◆] Perde 1: Doğu — Cürcet     [Başla ●]   │
        │ │         {teaser: ≤ 2 satır}                     │
        │ │ [kilit] Perde 2: …  (soluk)                     │
        │ Ruh: 12   Bereket x2   Gök Kalkanı x1  (şerit)   │
        │                [ Ana Menü ]                  │
        └────────────────────────────────────────────┘
```

| Bölge | İçerik | Taşma |
| ---- | ---- | ---- |
| Başlık | `CHAPTER_SELECT_TITLE`, 12 px | — |
| Rozet | `CAMPAIGN_COMPLETE` (yalnız `next_chapter = 0`) | — |
| Düğüm satırı | durum ikonu (piksel) + `title_key` + eylem düğmesi; ≈ 20 px, `AVAILABLE` + teaser ≈ 40 px | ad `…` ile kısalır; **tam ad odakta** |
| Teaser | `scenes[c-2].teaser_key` (c-1. sahnenin teaser'ı c'yi anlatır); yalnız `AVAILABLE`, ≤ 2 satır | bütçe ≈ 64 |
| Güç şeridi | `ruh` + lütuf başına yığın (`ad x2`, ASCII `x`); sarmalı, ortalı, ≤ 2 satır | her parça LTR yalıtılmış |
| [Ana Menü] | `MAIN_MENU` | — |

Alpha K = 6: 6 düğüm × ≈ 22 + teaser 20 + başlık/şerit/düğme ≈ 80 → ≈ 232 + dolgu ≤ 360; tek sütun, kaydırma yok.

### E5.4 İçerik tablosu

| Öğe | Anahtar | En uzun dil / not |
| ---- | ---- | ---- |
| Sahne adı | `CHAPTER_1_TITLE`, `CHAPTER_2_TITLE` | de ≈ 45 → kesilir; Arapça sağa hizalı, kesilir |
| [Başla] / [Destanı Oku] | `START_SCENE` / `READ_STORY` | ru `Читать сказание` (15) |
| Kilit ipucu | `CHAPTER_LOCKED_HINT` | de 41 karakter |
| Teaser | `CHAPTER_1_TEASER` (M2 yeni), `CHAPTER_2_TEASER` (`CAMPAIGN_END` içinde) | ≈ 64 (en) |
| Ruh / Lütuf | `SPIRIT` + `NumberFormatter.format_int` / `boon.name_key` + `x%s` | de `Kunst der Reinigung x1` |
| Rozet | `CAMPAIGN_COMPLETE` | de 22 |

### E5.5 Etkileşim

| Girdi | Hedef | Eylem |
| ---- | ---- | ---- |
| Enter / tık | [Başla] (`AVAILABLE`) | `start_requested(c)` |
| Enter / tık | [Destanı Oku] (`COMPLETED`) | `read_requested(c)` |
| Enter / tık | `LOCKED` düğüm | eylem yok; **ipucu ortak durum satırında** + `sfx_ui_denied`; satır odaklanabilir |
| Enter / Esc | [Ana Menü] | `menu_requested` |
| Tab / ↑ ↓ | düğümler + [Ana Menü] | yukarıdan aşağı (RTL'de de dikey) |

**Karar (C-45) — kilit ipucu:** `LOCKED` düğüm yalnız ikon + soluk ad; `CHAPTER_LOCKED_HINT` ortak bir durum satırında (odak/tık sırasında) gösterilir; teaser `AVAILABLE` düğümün altında; ek key gerekmez.

Başlangıç odağı (sessiz): `AVAILABLE` düğümün [Başla]'sı; yoksa [Ana Menü]. **Girdi koruması:** E5 açılışında 0,4 sn (§0.3; uygulandı C-74 — `ChapterSelectContext.bind_services(..., guard_s)`, koruma sonrası Esc = [Ana Menü]; kanıt `tests/integration/campaign/input_guard_all_modals_test.gd`).

### E5.6 Durumlar

| Durum | Görsel | Davranış |
| ---- | ---- | ---- |
| `COMPLETED` | tamamlandı **piksel ikon** + normal metin | [Destanı Oku] |
| `AVAILABLE` (en fazla 1) | Kök Böri ışığı ikonu, teaser | [Başla] birincil |
| `LOCKED` | kilit ikonu + soluk metin | eylem yok, ipucu + ret sesi |
| Yeni açılma | E1 çıkışından gelişte, ziyaret başına **bir kez** 4 kare altın parıltı | Hareketi Azalt: parlamasız sabit "yeni" işareti |
| Kampanya tamam | rozet; [Başla] yok | [Destanı Oku] + [Ana Menü] |
| **M2 ilk giriş (Prolog zaferi)** | düğüm 1 `COMPLETED`, düğüm 2 `AVAILABLE` + yeni açılma + `CHAPTER_1_TEASER` | şerit S3 sonrası değerleri gösterir |
| **M2 Devam Et** (`map = null`) | aynı, parıltı **yok** | — |
| **M2 tamam (K=2)** | iki `COMPLETED` + rozet | yalnız Devam Et ile (normal çıkış `CAMPAIGN_END`) |
| Boş `boons` | yalnız Ruh | — |
| Kayıt hatası | kalıcı `SAVE_FAILED` uyarısı | yeniden dene |

### E5.7 M2 eklemeleri (kodda eksik)

`teaser_key` satırı · tamamlandı/kilit piksel ikonu + Kök Böri ışığı ikonu (`/asset-spec`) · yeni açılma parıltısı + `sfx_chapter_unlock` · `LOCKED` odaklanabilir + ret sesi · iki satırlı düğüm (ad kesilmesi) · E5 girdi koruması · Esc = Ana Menü · kilim zemin cila.

### E5.8 Kabul kriterleri

- [ ] AC-E5-1: `LOCKED` düğümde eylem yok, ipucu görünür (AC30); `COMPLETED`'da [Destanı Oku] replay'i salt-okunur oynatır.
- [ ] AC-E5-2: Yeni açılan düğüm E1 çıkışından gelişte bir kez parlar; Hareketi Azalt'ta parlamaz.
- [ ] AC-E5-3: Ruh ve lütuf şeridi `GameState` ile eşleşir.
- [ ] AC-E5-4: Durum ikonu + metin renk-körlüğünde ayırt edilir (`COMPLETED` ikon, `LOCKED` kilit, `AVAILABLE` ışık).
- [ ] AC-E5-5: K = 2'de en uzun dilde (de/ru) ve Arapçada 640×360'a taşmadan sığar; ad kesilirse tam ad odakta görünür.
- [ ] AC-E5-6: Açılıştan sonra ilk 0,4 sn [Başla] pasif ve Esc/Enter düşer.
- [ ] AC-E5-7: Arapçada lütuf şeridi okunur sırada (her `ad xN` yalıtılmış).
- [ ] AC-E5-8: Yalnız klavye ile her eylem düğmesine ve [Ana Menü]'ye ulaşılır; Esc = [Ana Menü].
- [ ] AC-E5-9: Devam Et (`map = null`) E5'e iner, E1 giriş anlatısı gösterilmez.

---

## 6. Kararlar özeti (C-45, 2026-10-21)

| # | Karar (C-45) | Sahip |
| ---- | ---- | ---- |
| Q1 | Başlıklar 12 px (§0.1); GDD'ler güncellendi; 24 px cila | art-director |
| Q2 | E2 sprite'sız (M2); sprite cila | art-director |
| Q3 | E5 Esc = Ana Menü | game-designer |
| Q4 | K3: Perde 1 HUD'a "Cürcet bölgeleri x/3" | game-designer + ui-programmer (hud.md) |
| Q5 | E3 yalın; ikon + Kök Böri parıltısı Alpha cilası | art-director |
| Q6 | E4 Esc etkisiz | game-designer |
| Q7 | `DefeatPanel` (gri-mor süs, metin ≥ 4,5:1) | art-director |
| Q8 | `LOCKED` yalnız ikon + soluk ad; ipucu ortak durum satırında | game-designer |
| Q9 | AccessKit/ekran okuyucu kapsam dışı | ux-designer |
| Q10 | Perde 1: 5 illüstrasyon, `ill_perde1_<ad>.png` | art-director + narrative-director |
| Q11 | `DEFEAT_REASON_ERLIK` = açık bağımlılık (C-47/C-43 içerik görevi); E4 AC-E4-1/7 buna bağlı | narrative-director |

## 7. Ek: Yeni / Gerekli Çeviri Anahtarları (M2)

| Anahtar | Ekran | Durum |
| ---- | ---- | ---- |
| `CHAPTER_1_TEASER` | E5 | C-43 güncellemesi bekliyor |
| `CHAPTER_2_TITLE`, `_INTRO_1/2`, `_KOKBORI_1`, `_KOKBORI_LINE`, `_OUTRO_1/2`, `_KANGLI_TITLE`, `_TEASER`, `WIN_CONDITION_CH2` | E1, E2, E5 | C-43 anahtar listesi |
| `CAMPAIGN_END_DEMO_1` (güncel) | E1 son | C-43 |
| `DEFEAT_REASON_ERLIK` (sahneden bağımsız) | E4 | yeniden yazılacak (C-47/C-43) |
| Kilit ipucu için ek anahtar gerekmez | E5 | mevcut `CHAPTER_LOCKED_HINT` |

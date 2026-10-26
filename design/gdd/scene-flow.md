# Sistem GDD: Sahne Akışı & İlerleme

*Oyun: ULUS: Blood of the Sky Wolf*
*Oluşturulma: 2026-10-19*
*Durum: Designed (inceleme bekliyor — `/design-review` taze oturumda). Kod henüz yok: uygulama C-40, mimari karar C-62, anlatı metinleri C-54 ([`narrative-voice.md`](../narrative/narrative-voice.md)); kayıp sebebi C-63'te kodlandı (`MapState.loss_reason`). Prolog kayıp kuralı C-49 ile belirlendi (§3.7).*
*Creative Director Review (CD-GDD-ALIGN): atlandı — lean mod*
*Katman: Presentation*
*Uyguladığı sütun: Destanı Yaşa · Epik Ama Erişilebilir*
*Görev: C-35 (gece modu — kullanıcıya ait kararlar önerilen seçenekle verildi; liste §12'de)*

> **Terimler.** *Sahne* = *bölüm* = bir `chapter_id` (kodda `ChapterMapDefinition`); oyunun altı
> sahnesi Prolog, Perde 1–4 ve Final'dir. *Godot sahnesi* (`.tscn`) ayrı bir kavramdır ve metinde
> böyle anılır. *Anlatı ekranı* = tam ekran illüstrasyon + metin sayfası. *Kök Böri işareti* = sahne
> açılışında Kök Böri'nin hedefi haritada gösterdiği an (§3.5). *Sahne girişi anlık görüntüsü* =
> sahne başındaki taşınan verinin kopyası (§3.4). Zafer/yenilgi sonucunu üreten kural
> `region-map-system.md`'ye (§3.6–3.7), lütuf kuralları `spirit-system.md`'ye aittir; bu belge
> onların çıktısını tüketen **akışı** tanımlar. Sınıf adları (`CampaignRules`, `SceneDefinition` …)
> çalışma adlarıdır; kesin adlar ve dosya yolları ADR C-62'de belirlenir.

---

## 1. Overview

Sahne Akışı, oyunun ana menüsünden kampanya sonuna uzanan ekran ve durum sırasını yönetir. Kampanya
altı sahneden oluşur (Prolog, dört Perde, Final) ve doğrusal açılır: sahne N+1, ancak sahne N
kazanılınca açılır. Her sahne aynı kalıpla oynanır: bir **anlatı girişi** (destan sayfaları, ardından
Kök Böri'nin hedefi haritada işaretlediği an — Prolog'da gökten inişi olan "genesis" sahnesi),
**harita oyunu**, sonra ikiye ayrılan bir çıkış. Zaferde: sonuç kartı → Kök Böri'nin zorunlu lütuf
seçimleri → kalıcı kayıt → **anlatı çıkışı** (Prolog'da Oğuz'un Kağan ilan edilmesi) → sefer haritasında
yeni açılan sahne. Yenilgide: yenilgi ekranı → sahneyi baştan deneme ya da ana menü. Sistem ayrıca
hangi verinin sahneden sahneye taşındığını (tamamlanan sahneler, Ruh, lütuflar), hangisinin sıfırlandığını
(altın, harita, tur), kayıtların hangi anlarda yazıldığını ve "Devam Et"in neyi sürdürdüğünü belirler.
Oyuncunun doğrudan gördüğü kısım anlatı sayfaları, Kök Böri işareti, zafer/yenilgi ekranları ve sefer
haritasıdır; kural katmanı (açılma, taşıma, zorunlu seçim sayısı, durum makinesi) saf ve test edilebilirdir.

---

## 2. Player Fantasy

**Destanın sayfasını çeviren kağan; gökten inen kurdun gösterdiği yolda yürüyen Oğuz.**

Her sahne bir destan sayfasıdır. Oyuncu haritaya inmeden önce o sayfanın ağırlığını okur (kısa, resimli);
sonra Kök Böri gökten belirir ve parmağıyla tehdidi gösterir: "işte yenilecek olan". Hedef bir cümle ve
haritada yanan bir ışıktır — oyuncu ne yapacağını bilerek başlar. Zafer geldiğinde kendisini kutlayan bir
sonuç kartı, ardından Kök Böri'nin kutsaması (seçimler), en sonda sayfanın kapanışı gelir: Prolog'da
boylar bayrak altında toplanır ve Oğuz **Kağan** ilan edilir. Bölüm bitince yol uzar: sefer haritasında
bir sonraki yönün kapısı açılır ve Kök Böri bir sonraki tehdidi fısıldar. Yenilgi bir bitiş değil bir
"tekrar yaz"dır: destan sürer, önceki sahnelerden kazanılan güç yerinde durur.

| Katman | İçerik |
| ---- | ---- |
| **MDA — Estetik** | 1. Anlatı (sahne çerçevesi, Kağan ilanı, genişleme→miras yayının ilk adımı); 2. Fantazi (Kök Böri'nin rehberliği, Ülgen'in eli); 3. Duygu (destan illüstrasyonları) |
| **MDA — Dinamik** | Okuma ritüeli → net hedef → oyun → kutsama → kapanış; her 20–35 dakikalık sahne 1–2 dakikalık bir anlatı çerçevesiyle sınırlanır; sefer haritası doğal duraklama noktasıdır |
| **MDA — Mekanik** | Durum makinesi (§3.3), taşıma/sıfırlama kuralı (§3.2), kayıt noktaları (§3.4), zorunlu seçim dizisi (F2) |
| **SDT — Özerklik** | Her anlatı atlanabilir; sonraki sahnenin ne zaman başlayacağını oyuncu seçer; zafer lütufları gerçek seçimdir |
| **SDT — Yeterlik** | Hedef cümle + harita ışığı + HUD "Hedef" satırı ("ne yapmalıyım" hiç belirsiz kalmaz); sonuç kartı (tur, bölge, Ruh); taşınan Ruh ve lütuflar sefer haritasında görünür |
| **SDT — İlişki** | Kök Böri her sahnede aynı motifle (ışık, profil/iniş/cephe pozu) geri gelen rehber-yoldaştır; Oğuz'un unvanı ilerler (Genç Oğuz → Kağan) |
| **Akış (Csikszentmihalyi)** | Makro döngü: sahne sonu = doğal duraklama + dönme nedeni (bir sonraki tehdidin ipucu); 640×360'ta ilk eylem skip ile ≤ 10 sn, tam okumayla ≤ 150 sn |

**Kaçınılacak his:** metin duvarı, atlanamayan sinematik, hedefi bilmeden oynamaya başlama, zaferden
sonra ilerlemenin kaybolması (kapatma hatası), yenilgide kalıcı ceza, tamamlanmış sahneyi tekrar
oynayarak Ruh biriktirme (kuru grind).

**Sütun testleri.** *Destanı Yaşa* — "Bu sahne destanın gerçek bir anını yaşatıyor mu?" → her sahne bir
giriş + çıkış sayfasıyla çerçevelenir ve Kök Böri'nin sahne başı varlığı zorunludur. *Epik Ama
Erişilebilir* — "İlk oynayan biri 2–3 turda anlayabilir mi?" → hedef 1 cümle (`WinCondition.description_key`),
haritada işaretli, HUD'da kalıcı; anlatı en çok iki basışla geçilir.

---

## 3. Detailed Rules

### 3.1 Kampanya Yapısı ve Sahne Kataloğu

| `chapter_id` | Sahne | Slug | Harita (bölge) | Kök Böri pozu | Kapsam |
| ---- | ---- | ---- | ---- | ---- | ---- |
| 1 | Prolog: Doğuş | `prolog` | Oğuz ata yurdu (6) | `DESCENT` (genesis) | M1 |
| 2 | Perde 1: Doğu — Cürcet | `perde1_dogu` | Doğu ormanları (8) | `PROFILE` | M2 |
| 3 | Perde 2: Batı — Urum | `perde2_bati` | Batı toprakları (10) | `PROFILE` | Alpha |
| 4 | Perde 3: Kuzey — İtil/Ural | `perde3_kuzey` | Kuzey donmuş toprakları (8) | `PROFILE` | Alpha |
| 5 | Perde 4: Güney — Sındu/Şam | `perde4_guney` | Güney çölleri/vadileri (10) | `PROFILE` | Alpha |
| 6 | Final: Miras | `final_miras` | Birleşik dünya (15) | `FRONT` (altı oğulla) | Alpha |

Pozlar art bible §5 "Kök Böri": profil (varsayılan), iniş (Prolog), cephe (Final).

> **Perde 1 girişi (C-43, 2026-10-20 — [`perde1-dogu-curcet.md`](../levels/perde1-dogu-curcet.md)):** `chapter_id = 2`,
> slug `perde1_dogu` (`campaign.tres` kimliği), 8 bölge, `PROFILE` (Kök Böri G-3). Anlatı: giriş G-1 (başlıklı,
> buyruk dört yöne), G-2 ("Boyun eğmem" + doğu ormanlarından kara sis), G-3 (Kök Böri,
> `CHAPTER_2_KOKBORI_1` + `CHAPTER_2_KOKBORI_LINE`); çıkış O-1 (orman nefes alır), O-2 (başlıklı "Kanglı",
> Cürcet diz çöker; teaser: batıda Urum). Önkoşul: Prolog kazanılmış (F1). Sahne verisi `map_path` ile
> Perde 1 `ChapterMapDefinition` `.tres`'ine bağlanır; takviye listesi `enemy_reinforcement_region_ids =
> [curcet_otagi]` o haritanın verisidir (resource F6), `SceneDefinition`'da değil.
> **Perde 2 bağlantısı:** yalnız Perde 1 zaferi → O-2 → sefer haritasında sonraki sahnenin açılması (F1);
> Perde 2 yerleşimi/kimliği Perde 1 belgesinde tanımlanmaz (UNRESOLVED, `perde1-dogu-curcet.md` §14).

1. **Doğrusal ve sabit sıra.** `chapter_id` aynı zamanda oynanış sırasıdır (1…K, K ≤ 6). Ayrı bir "unlock
   order" alanı yoktur; kimlikler 1'den başlayıp boşluksuz artar (içerik değişmezi, §3.10).
2. **Kampanya uzunluğu K** = derlemedeki `CampaignDefinition` içindeki sahne sayısıdır: M1'de K=1,
   M2'de K=2, Alpha'da K=6. İçeriği yazılmamış sahneler hiç listelenmez (hayalet "yakında" düğümü yok).
3. **Açılma:** sahne c yalnızca `c == 1` ya da `c−1` tamamlanmışsa açıktır (F1). Bir sahne yalnızca
   **zaferle** tamamlanır; yenilgi ya da yarıda bırakma tamamlanma yazmaz.
4. **Tamamlanan sahne tekrar oynanmaz (v1).** Anlatısı "Destanı Oku" ile yeniden okunabilir (§3.9);
   oynanış yeniden açılmaz. Gerekçe: Ruh'un tek musluğu arındırmadır (`spirit-system.md` §3.3);
   tamamlanmış sahneyi tekrar oynayıp ödül almak Ruh çiftçiliği olurdu (Sandbox DEĞİL anti-sütunu).
5. **Kampanya tamamlandı** ⇔ `chapters_completed = {1…K}`. Son sahnenin çıkışından sonra
   `CAMPAIGN_END` gösterilir (§3.3).
6. **Yeni Sefer her zaman sahne 1'den başlar.** Sahne seçme/atlama yoktur.

### 3.2 Taşınan ve Sıfırlanan Veri

| Veri | Sahne sonunda (COMMIT) | Yeni sahne başında | Kaynak kural |
| ---- | ---- | ---- | ---- |
| `chapters_completed` | `∪ {c}` (tekrar eklenmez, F7) | taşınır | F1 |
| `current_chapter` | `min(c+1, K)` | seçilen sahne | F7 |
| `ruh` | seçimlerden sonraki bakiye taşınır | taşınır | `spirit` §3.3 |
| `boons` (seçim listesi) | taşınır (`n` = `boons.size()` artar) | taşınır | `spirit` §3.4 |
| `campaign_seed` *(C-44 inceleme, D4)* | taşınır (sefer boyunca sabit) | taşınır; Yeniden Dene'de değişmez | `spirit` §4.5, §3.4 |
| `modifiers` (türetilmiş) | — | `ModifierController.rebuild()` ile `boons`'tan kurulur | ADR-0006 |
| `gold` | 0'lanır (taşınmaz) | `starting_gold` (bölüm verisi) | `resource` §3.1 R8 |
| `map_state` (sahipler, ordular, bozulma, `current_turn`, `actions_remaining`, `last_erlik_spread_turn`, `erlik_spread_interval`, üretim sayaçları, `selected_region_id`, `game_result`, `loss_reason`; Erlik'in Gölgesi `erlik_power` bozulmalardan türetilir, ayrıca saklanmaz — `spirit` §4.7) | `null` | `ChapterMapDefinition.create_map_state()`; `current_turn = 1` | `region-map` §3.1, `spirit` §5 |
| Bekleyen lütuf sunumu | yok (türetilmiş) | `ruh`/`boons`'tan türetilir | `spirit` §3.4 |
| `AccessibilitySettings`, dil, ses | ayrı dosya, her zaman kalıcı | — | ADR-0007 |
| Sahne girişi anlık görüntüsü | korunur (yeniden denemek için) | yeni sahnenin girişinde yeniden yakalanır | §3.4 |

Yeni sahnenin 1. turunda lütuf sunumu **kendiliğinden açılmaz** (şafak kuralı `end_turn` sonrasını
kapsar, `spirit` §3.4); taşınan Ruh eşiği karşılıyorsa HUD'daki Kök Böri düğmesi hemen açar ve sunum 2.
tur başında otomatik gösterilir (§5).

### 3.3 Akış Durum Makinesi

```
                            ┌──────────────── Ana Menü (kayıt yazılmaz) ◀───────────────┐
MAIN_MENU ─Yeni Sefer─▶ INTRO_NARRATIVE ─▶ KOK_BORI_MARK ─▶ PLAYING ─game_lost─▶ DEFEAT ─┤
    │                      (A: sayfalar)      (A: Kök Böri sayfaları  │ ▲                 │
    │                                          B: hedef işareti)      │ └─Yeniden Dene────┘
    │                                                     ▲           │      (yalnız B)
    │                                                     │       game_won
    │                                                 Başla(c)        ▼
    ├─Devam Et ─ harita var ──▶ PLAYING            CHAPTER_SELECT   VICTORY_BEAT ─▶ BOON_PICKS (k ≥ 0)
    │           └ harita yok ─▶ CHAPTER_SELECT ◀─ OUTRO_NARRATIVE ◀── [COMMIT + kayıt S3] ◀──┘
    │                              │   └ Destanı Oku ▶ STORY_REPLAY ▶ CHAPTER_SELECT   (c == K: ▶ CAMPAIGN_END ▶ MAIN_MENU)
    └─Ayarlar / Çık (mevcut)
```

| Durum | Ekran | Sahibi |
| ---- | ---- | ---- |
| `MAIN_MENU` | Ana menü (mevcut `MenuContext`) | Menü |
| `CHAPTER_SELECT` | Sefer haritası (§3.9) | Sahne Akışı |
| `INTRO_NARRATIVE` | Tam ekran anlatı sayfaları (§3.5, §3.8) | Sahne Akışı |
| `KOK_BORI_MARK` | A: Kök Böri anlatı sayfaları (opsiyonel; Prolog'da genesis). B: harita üstünde hedef işareti paneli | Sahne Akışı |
| `PLAYING` | Harita oyunu (`GameContext`) | Harita/Ruh/Kaynak |
| `VICTORY_BEAT` | Sonuç kartı (§3.6) | Sahne Akışı |
| `BOON_PICKS` | Zorunlu Kök Böri lütuf seçimleri (`BoonOfferModal`, `mandatory`) | Ruh (`spirit`) |
| `OUTRO_NARRATIVE` | Tam ekran anlatı sayfaları | Sahne Akışı |
| `DEFEAT` | Yenilgi ekranı (§3.7) | Sahne Akışı |
| `CAMPAIGN_END` | Kampanya sonu sayfaları (içerik: `CampaignDefinition.end_pages`) | Sahne Akışı |
| `STORY_REPLAY` | Tamamlanmış sahnenin anlatısını salt-okunur oynatır | Sahne Akışı |

COMMIT bir durum değil, `BOON_PICKS → OUTRO_NARRATIVE` geçişinin **eylemidir** (anlıktır, girdi almaz).

**Geçiş tablosu.** Tabloda olmayan her (durum, olay) çifti yok sayılır (hata değil; log'a `scene_flow:
ignored <olay> in <durum>` yazılır).

| # | Durum | Olay [koşul] | Eylem | Sonraki durum |
| ---- | ---- | ---- | ---- | ---- |
| T1 | `MAIN_MENU` | `new_campaign_requested` [kayıt yok] | Yeni `GameState`: `current_chapter=1`, `chapters_completed=[]`, `ruh=0`, `boons=[]`, `campaign_seed` üretilir (C-44 inceleme, D4; §3.4) | `INTRO_NARRATIVE`(1) |
| T2 | `MAIN_MENU` | `new_campaign_requested` [kayıt var] | Onay modalı `CONFIRM_NEW_CAMPAIGN`; Evet → T1 eylemi, Hayır → kayda dokunulmaz | `INTRO_NARRATIVE`(1) / `MAIN_MENU` |
| T3 | `MAIN_MENU` | `continue_requested` [`LoadResult` OK, `map ≠ null`] | Durumu benimse; `ModifierController.rebuild()`; sahne tanımını `current_chapter`'dan bul | `PLAYING`(c, devam) |
| T4 | `MAIN_MENU` | `continue_requested` [OK, `map == null`] | Durumu benimse | `CHAPTER_SELECT` |
| T5 | `MAIN_MENU` | `continue_requested` [OK değil] | Hata ipucu (düğme zaten pasif olmalı) | `MAIN_MENU` |
| T6 | `CHAPTER_SELECT` | `start_requested(c)` [`state(c) = AVAILABLE`] | — | `INTRO_NARRATIVE`(c) |
| T7 | `CHAPTER_SELECT` | `read_requested(c)` [`state(c) = COMPLETED`] | Salt-okunur oynatma; durum değişmez | `STORY_REPLAY`(c) |
| T8 | `CHAPTER_SELECT` | `menu_requested` | — | `MAIN_MENU` |
| T9 | `STORY_REPLAY` | son sayfa ilerledi ya da Esc | — | `CHAPTER_SELECT` |
| T10 | `INTRO_NARRATIVE` | son sayfa ilerledi ya da `skip` | A boşsa T11 eylemi burada uygulanır (B'ye her giriş haritayı kurar) | `KOK_BORI_MARK`(c, A); A boşsa doğrudan B |
| T11 | `KOK_BORI_MARK` A | son sayfa ilerledi ya da `skip` | Haritayı kur (`create_map_state`, `gold = starting_gold`), `ModifierController.rebuild()`, sahne girişi anlık görüntüsünü yakala | `KOK_BORI_MARK`(c, B) |
| T12 | `KOK_BORI_MARK` B | `dismiss` ([Başla]) | **S2 kaydı** (§3.4) | `PLAYING`(c) |
| T13 | `PLAYING` | `game_won` | `game_result` kilidi zaten aktif (`region-map` §3.7) | `VICTORY_BEAT` |
| T14 | `PLAYING` | `game_lost` (argümansız; sebep `MapState.loss_reason`'dan okunur) | Kayıt yazılmaz | `DEFEAT` |
| T15 | `PLAYING` | `menu_pressed` | Onay `CONFIRM_LEAVE_SCENE`; Evet → kayıt yazmadan çık, Hayır → kal | `MAIN_MENU` / `PLAYING` |
| T16 | `VICTORY_BEAT` | `devam` | `k = F2`; k>0 ise lütuf dizisini başlat | `BOON_PICKS` (k>0) ya da COMMIT → `OUTRO_NARRATIVE` (k=0) |
| T17 | `BOON_PICKS` | her seçim | `SpiritController.pick_boon`; devam şartı (F2) sürüyorsa sıradaki sunum | `BOON_PICKS`, bitince COMMIT → `OUTRO_NARRATIVE` |
| T18 | COMMIT (eylem) | — | F7 durum güncellemesi + **S3 kaydı** | `OUTRO_NARRATIVE`(c) |
| T19 | `OUTRO_NARRATIVE` | son sayfa ilerledi ya da `skip` [c < K] | — | `CHAPTER_SELECT` (yeni açılan düğüm efekti) |
| T20 | `OUTRO_NARRATIVE` | aynı [c == K] | — | `CAMPAIGN_END` |
| T21 | `CAMPAIGN_END` | `devam` | — | `MAIN_MENU` |
| T22 | `DEFEAT` | `retry` | Sahne girişi anlık görüntüsünü geri yükle (§3.4); harita yeniden kurulur; `ModifierController.rebuild()` (geri alınan lütufların etkisi kalmaz) | `KOK_BORI_MARK`(c, yalnız B) |
| T23 | `DEFEAT` | `menu` | Kayıt yazılmaz | `MAIN_MENU` |

Ek kurallar:
- **Tek terminal sinyal:** bir sahne denemesinde `PLAYING`'den çıkıldıktan sonra gelen ikinci
  `game_won`/`game_lost` yok sayılır (T13/T14 yalnızca `PLAYING` durumunda geçerlidir).
- **Pencereyi işletim sisteminden kapatma** (Alt-F4, çökme) hiçbir durumda yeni kayıt yazmaz; geçerli
  kayıt noktaları yalnızca S1–S3'tür (§3.4).
- Sinyaller yukarı gider (ADR-0001): `scene_started(chapter_id, first_entry)`, `scene_completed(chapter_id)`,
  `scene_failed(chapter_id)`, `campaign_completed`. Ses ve öğretici (C-41) bunlara bağlanır.

### 3.4 Kayıt Noktaları ve "Devam Et" (ADR-0007 ile)

| Kod | An | Yuva | İçerik | Durum |
| ---- | ---- | ---- | ---- | ---- |
| **S1** | `turn_ended` (yalnızca `PLAYING` ve `ONGOING`) | `campaign` | Tam `GameState` | ADR-0007'de var |
| **S2** | T12: hedef işareti kapatılıp `PLAYING`'e geçerken | `campaign` + `scene_entry` | Tam `GameState`: 1. tur başı, `actions_remaining` sıfırlanmış | **Yeni** (ADR-0007 değişikliği) |
| **S3** | T18: son zorunlu seçimden sonra, ilk anlatı sayfasından önce | `campaign` | `chapters_completed ∪ {c}`, `current_chapter`, `map = null`, `gold = 0`, `ruh`, `boons` | ADR-0007'de var; sırası burada kesinleşir |
| yok | T14 (yenilgi), T15, T23, işletim sistemi kapatma | — | Kayıt yazılmaz; son kayıt aynen korunur | — |

- **Kampanya tohumu (C-44 inceleme (2026-10-21), D4 / H6):** Yeni Sefer'de (T1) üretilen `campaign_seed`
  kampanya kaydına (`campaign` yuvası, `GameState`) yazılır; `spirit-system.md` §4.5 lütuf sunum
  seed'ine eklenir. Sefer boyunca sabittir: S1–S3 ile korunur, Yeniden Dene'de (T22) ve Devam Et'te
  değişmez; yalnızca yeni Yeni Sefer (T1/T2) yenisini üretir. Testte enjekte edilir. Kayıt biçimi
  alanı ADR-0007 sürümüne işlenir — **uygulandı C-77 (2026-10-25):** şema v2, v1 kayıt `campaign_seed = 0` ile göç eder (ADR-0007 eki).
- **S2 gerekçesi:** (a) Yeni Sefer ve Yeniden Dene'den sonra eski sahneden kalma bir kayıt "Devam Et"i
  yanıltmasın; (b) sahne girişi anlık görüntüsü kalıcı olsun, Devam Et'ten sonra bile Yeniden Dene
  çalışsın. 1. tur başı, ADR-0007'nin "tutarlı durum tur sınırlarında vardır" ilkesine uyar; tur ortası
  kayıt eklenmiş olmaz.
- **Anlatı sırasında kapatma kaydı etkilemez:** S2 ancak hedef işareti kapatılınca yazılır; ondan önce
  kapatılırsa Devam Et önceki duruma (sefer haritası) döner ve giriş anlatısı yeniden gösterilir (atlanabilir).
- **`scene_entry` yuvası** bir `campaign` belgesiyle aynı biçimdedir (ADR-0007 `slot` kimliği zaten
  çoklu yuvaya hazır); her sahne girişinde (S2) üzerine yazılır, tamamlamada silinmez (zararsız).
  Yeniden Dene tek kod yoluyla bu yuvadan okur; yazma başarısızsa bellekteki kopya kullanılır.
- **Tur sonu otomatik kayıt (S1)** ve `game_won` ilişkisi: `turn_ended` yalnızca `ONGOING` iken yayılır
  (`region-map` §3.4); zafer tur ortasında ya da tur sonunda olsa da S3 öncesi hiçbir kayıt "kazanılmış
  harita" taşımaz.

**"Devam Et" neyi sürdürür** (ADR-0007: düğme ancak `read()` + `from_dict()` başarılıysa etkin):

| `LoadResult` | `map` | `chapters_completed` | Sonuç |
| ---- | ---- | ---- | ---- |
| OK | `≠ null` | herhangi | `PLAYING`, kayıtlı tur başı. Giriş anlatısı ve hedef paneli gösterilmez. Yükleme **tur başı sayılır:** bekleyen lütuf varsa otomatik modal açılır (en fazla 1, `spirit` §3.4); HUD "Hedef" satırı ve işaretler durumdan türetilir |
| OK | `null` | `⊊ {1…K}` | `CHAPTER_SELECT`; `current_chapter` seçili/odaklı |
| OK | `null` | `= {1…K}` | `CHAPTER_SELECT` salt-okunur ("Başla" yok, "Destanı Oku" var; üstte `CAMPAIGN_COMPLETE` rozeti) |
| `CORRUPT`, `VERSION_TOO_NEW`, `MISSING`, **içerik uyumsuz** (kayıttaki sahne kimliği K'yı aşıyor) | — | — | Devam Et pasif + ipucu (`SAVE_CORRUPT`, `SAVE_TOO_NEW`, `SAVE_CONTENT_MISSING`) |

**Yeniden Dene anlık görüntüsü (R3 kararı).** Yeniden Dene, sahnenin **girişindeki** durumu geri getirir:
`ruh`, `boons`, `chapters_completed` giriş değerlerine döner; sahnede kazanılan Ruh ve sahne içinde
(şafak sunumlarıyla) seçilen lütuflar **geri alınır**; harita ve altın sıfırdan kurulur. Gerekçe: sahne
haritası sıfırlanıyorken o haritadan kazanılan Ruh'u saklamak aynı ödülün çift sayımıdır ve kasıtlı
yenilgi ile Ruh çiftçiliğine yol açar (örn. Doğu Obası'nı arındır +10, 14 tur bekle, kaybet, yeniden dene,
tekrarla). Önceki sahnelerden taşınan her şey korunur — yenilgi **kalıcı** ilerleme silmez (`spirit` §3.4:
"Ruh korunur"un anlamı budur). Knob: `retry_restores_entry_snapshot` (§7). Yuva yoksa/uyumsuzsa
(`scene_entry.chapter_id ≠ c`) geri-düşüş: mevcut `ruh`/`boons` ile devam edilir ve uyarı loglanır.

### 3.5 Sahne Girişi: `INTRO_NARRATIVE` + `KOK_BORI_MARK`

**Sıra:** giriş sayfaları (1–4) → Kök Böri bölümü (A: 0–2 sayfa; B: hedef işareti, zorunlu) → `PLAYING`.
Anlatı sayfalarının ortak kuralları §3.8'dedir.

**A — Kök Böri sayfaları.** Sahnenin `kok_bori_pages` listesidir; Kök Böri'nin illüstrasyonda göründüğü
tam ekran sayfalar. Prolog'da bu, **genesis sahnesi**dir. Diğer sahnelerde liste boş olabilir (yalnız B
yeterli — solo kapsam kontrolü). Yeniden Dene'de A gösterilmez.

**Prolog "genesis" — yapı (metin C-54'ün, burada yalnızca vuruşlar):**

| Sayfa | Durum | Vuruş | Illüstrasyon (art bible §8 adlandırma) |
| ---- | ---- | ---- | ---- |
| G-1 | `INTRO_NARRATIVE` | Doğuş: gün doğumu altın-turuncu, doğaüstü işaretlerle gelen çocuk. Başlık kartı = sahne adı (`CHAPTER_1_TITLE`, 12px — C-45 (2026-10-21); 24px yalnız tam ekran başlık kartı, cila) | `ill_prolog_intro.png` |
| G-2 | `INTRO_NARRATIVE` | Dağınık boylar ve bozkırı kavuran ilk Erlik canavarı; çürümenin ilk lekesi | `ill_prolog_tribes.png` |
| G-3 | `KOK_BORI_MARK` A | **Kök Böri'nin ilk görünüşü:** gökten ışık çizgileriyle iner (kanat yok), Oğuz'a canavarın ininin yönünü gösterir; koyu ilahi sahne, gök mavisi/beyaz/altın | `ill_prolog_genesis.png` |
| G-4 | `KOK_BORI_MARK` B | Harita üstünde hedef işareti (aşağıda) | harita |

M1 illüstrasyon bütçesi: giriş 2 + genesis 1 + çıkış 2 = **5** (§7 içerik bütçesi).

**B — Hedef işareti paneli (tüm sahneler).** Harita 1. tur durumunda görünür; yalnız zemin/arka plan
katmanı koyu indigoya kayar (art bible §2: ton kaydırma bilgi katmanını boyamaz). Gösterilenler:

| Öğe | İçerik | Veri kaynağı |
| ---- | ---- | ---- |
| Kök Böri | 48×32 profil sprite (poz = sahnenin `kok_bori_pose`'u; harita/panel için profil), ışık parçacıklı, yarı saydam yok (alfa 0/255) | `SceneDefinition.kok_bori_pose` |
| Mitik satır | 1–2 satır Kök Böri sözü | `SceneDefinition.kok_bori_line_key` |
| Hedef etiketi + hedef metni | `OBJECTIVE_LABEL` + düz mekanik özet ("3 boyu birleştir ve Erlik'in canavarını yen") | `WinCondition.description_key` (Prolog: `WIN_CONDITION_CH1`) |
| Haritada hedef işaretleri | `V` kümesindeki bölgelerin üstünde işaret ikonu (F7) | `WinCondition.erlik_foci` ∪ `SceneDefinition.objective_region_ids` |
| Düğme | [Başla] (birincil, sessiz odak) | — |

- **Tek doğruluk kaynağı:** mekanik hedef metni ve Erlik odakları **kazanma koşulundan** okunur (metin ile
  kural ayrışamaz). `objective_region_ids` yalnızca koşulda geçmeyen ek hedefler içindir (ör. Perde 1'de
  Cürcet Kağan'ın başkenti).
- **Panel işaretlerin üstünü örtmez** (UX kuralı): panel önce alt-orta, çakışıyorsa üst-orta konumlanır;
  ikisi de çakışıyorsa en az çakışan şerit seçilir. Bölge sahiplik/bozulma katmanları panel dışında hiç
  boyanmaz.
- **Kapatma:** yalnızca [Başla] / Enter / Space (tek basış). **Esc hedef panelini kapatmaz** (Esc ile
  art arda atlayan oyuncu hedefi kaçırmasın). Girdi koruması: açılıştan `screen_input_guard_s` sonra.
- **Kalıcılık:** işaretler `V` boşalana kadar haritada kalır (örn. canavar arındırılınca söner; yayılım
  odağı yeniden bozarsa geri gelir — `region-map` §5). HUD'da kalıcı **"Hedef"** satırı gösterilir
  (metin + ilerleme: `fethedilen nötr / gerekli`, `arındırılan odak / toplam odak`); bunlar
  `region-map` §4 formüllerinin ilerleme gösterimidir (yeni kural değil). HUD gereksinimi §10'da.
- **Yeniden Dene:** yalnızca B gösterilir (anlatı sayfaları yok); hedef yeniden oryantasyon sağlar.

### 3.6 Zafer Dizisi

Sıra (TR-concept-007, ADR-0007, `spirit` §3.4, `region-map` §3.7):

1. **`game_won`** — hamlenin bütün sonuçları (sahiplik, ordu, bozulma, Ruh, aksiyon) zaten işlenmiştir;
   `game_result = WON` kilidi aktiftir; **lütuf seçimi kilitten muaftır**.
2. **`VICTORY_BEAT` — sonuç kartı.** Altın çerçeveli `ModalPanel`, "Zafer" havası (art bible §2:
   merkezde beyaz-altın parlamalı Kök Böri). Satırlar: `RESULT_TURNS` (= `current_turn`), `RESULT_REGIONS`
   (oyuncu bölgesi / toplam bölge), `RESULT_RUH_GAINED` (= F3). Tek düğme [Devam] (Enter/Space/Esc/tık).
   Girdi koruması `screen_input_guard_s`: kazandıran hamlenin fare tıkı kartı ya da sonraki seçimi
   **devre dışı bırakmaz/tetiklemez**.
3. **`BOON_PICKS` — zorunlu lütuf dizisi.** `k` = F2. Her adımda `BoonOfferModal.show_offer(ids,
   mandatory = true)` (ADR-0011): **Ertele yok, Esc etkisiz**; 3 lütuf gösterilir, oyuncu 1 seçer
   (`spirit` §4.5 deterministik sunum, `n` = o ana kadar seçilen). Altyazı `BOON_CARRIES_ON` ("Bu lütuf
   sonraki sahnelere taşınır"). Dizi, (a) Ruh bir sonraki maliyetin altına inince, (b) uygun havuz boşalınca
   ya da (c) `VICTORY_PICK_CAP` seçime ulaşınca biter; (c)'de kalan sunum **türetilmiş olarak bekler**
   (sonraki sahnede HUD düğmesi). `k = 0` ise bu durum hiç gösterilmez.
4. **COMMIT (T18) — F7 + S3.** `chapters_completed ∪= {c}`, `current_chapter = min(c+1, K)`,
   `map_state = null`, `gold = 0`; ardından `campaign` yuvasına S3 yazılır. Yazma başarısızsa
   (`save_failed`): bellek durumu geçerli sayılır, akış sürer, kalıcı uyarı (`SAVE_FAILED`) gösterilir ve
   yazım `OUTRO_NARRATIVE` bitişinde ve `CHAPTER_SELECT` girişinde (idempotent) yeniden denenir.
5. **`OUTRO_NARRATIVE`.** 1–4 sayfa (§3.8). Kaydı S3 yazdığından çıkışı atlamak/kapatmak durumu etkilemez.
6. **Çıkış:** c < K → `CHAPTER_SELECT` (yeni açılan sahne düğümü bir kez ışıldar + `teaser_key` satırı);
   c == K → `CAMPAIGN_END`.

**Prolog çıkışı — Kağan ilanı (yapı):**

| Sayfa | Vuruş | İllüstrasyon |
| ---- | ---- | ---- |
| O-1 | Canavar arındırıldı, bozkır yeşeriyor; Kök Böri'nin ışığı toprağa iner (Ülgen'in zaferi) | `ill_prolog_beast_purified.png` |
| O-2 | Boylar bayrak altında toplanır; Oğuz **Kağan** ilan edilir. Başlık kartı `CHAPTER_1_KAGAN_TITLE` (12px — C-45 (2026-10-21), ör. "Oğuz Kağan") | `ill_prolog_kagan.png` |

Kağan ilanı **anlatı ödülüdür**; ayrı bir mekanik etki taşımaz (durum `chapters_completed ∋ 1`'den
türetilir). Mekanik karşılığı bir sonraki sahnenin açılmasıdır: Perde 1'de Ruh lütuf sistemi tam devrededir
(konsept). M1 demosunda K = 1 olduğundan O-2'den sonra `CAMPAIGN_END` (demo sonu, `end_pages`) gelir.

### 3.7 Yenilgi Akışı

"Sahne `game_lost` bildirdiğinde" akış sahneden bağımsızdır; kayıp kuralını harita üretir, bu belge
yalnız sonucunu tüketir. **Kayıp kuralı (C-49 ile belirlendi; sahibi `region-map-system.md` §3.6,
`spirit-system.md` §3.7 / §4.7):** `erlik_power = Σ corruption_level ≥ erlik_loss_threshold` (Prolog **9**,
başlangıç 4, 0 = kapalı; yalnızca `end_turn` 5. adımında) **ya da** oyuncunun hiç bölgesi kalmaması. Prolog'da
siyasi düşman yoktur; tek gerçekçi kayıp yolu Erlik'tir (arındırmayan oyuncu 15. turun sonunda kaybeder —
`resource-system.md` §4). Kayıp **sebebi** `loss_reason` ile taşınır:

| `loss_reason` | Tetik | Yenilgi metni anahtarı | Örnek metin (en) |
| ---- | ---- | ---- | ---- |
| `ERLIK` | `erlik_loss_threshold > 0` ve `erlik_power ≥ eşik` | `DEFEAT_REASON_ERLIK` | "Erlik's shadow has swallowed the homeland." |
| `NO_REGIONS` | Oyuncunun hiç bölgesi kalmadı | `DEFEAT_REASON_NO_REGIONS` | "Your last land has fallen." |
| `NONE` / eşlemesiz | Sebep üretilmedi ya da metin eşlemesinde karşılığı yok (ör. gelecekteki enum değeri) | `DEFEAT_REASON_GENERIC` | "The campaign ends here." |

**Perde 1 (C-43, 2026-10-20 — [`perde1-dogu-curcet.md`](../levels/perde1-dogu-curcet.md) §2/§6):** Perde 1'de
siyasi düşman vardır ama tüm bölgelerin kaybı mevcut `NO_REGIONS`'a eşlenir (yeni enum yok); Erlik kaybı eşiği 9.
`DEFEAT_REASON_ERLIK` metni **sahneden bağımsızdır** ("Erlik'in gölgesi bozkırı yuttu" benzeri; Prolog'a özgü
"homeland" ifadesi kalmaz), 11 dilde yeniden yazılır. Aynı turda zafer + Erlik kaybı: önce kaybetme.

Sebep C-63'te kodlandı: `MapState.loss_reason` enum'u `MapState.LossReason` { `NONE`, `NO_REGIONS`, `ERLIK` }
(`LOST` değilken `NONE`); `game_lost` sinyali **argümansızdır**, yenilgi ekranı sebebi durumdan okur
(ADR-0011 pasif görünüm). Metin anahtarı yukarıdaki tablodan eşlenir (`DEFEAT_REASON_` + enum adı). İki sebep aynı kontrolde sağlanırsa gösterilen
sebep `NO_REGIONS`'tur (siyasi kayıp önce değerlendirilir; pratikte `end_turn` 1. adımındaki erken çıkış
Erlik adımını zaten atlar). Metinler yer tutucudur; son söz C-54'ündür.

1. `game_lost` → `DEFEAT` (T14). **Hiçbir kayıt yazılmaz;** son tur sonu otomatik kaydı (S1) olduğu
   gibi kalır (ADR-0007). Kök Böri sunumu gösterilmez (`spirit` §3.4); Ruh harcanmaz.
2. **Yenilgi ekranı:** art bible §2 "Yenilgi" (soğuk gri-mor, altın yok, %15–20 opak dağılan gri Kök Böri).
   İçerik: başlık `DEFEAT`; neden metni sırayla: sahnenin `defeat_text_key`'i (doluysa), yoksa
   `DEFEAT_REASON_<loss_reason>` (tabloda), o da yoksa `DEFEAT_REASON_GENERIC`; güvence satırı
   `DEFEAT_PROGRESS_KEPT` ("Önceki sahnelerden kazandığın Ruh ve lütuflar korunuyor."). `ERLIK` sebebinde ek
   olarak son görülen `erlik_power / eşik` değeri gösterilir (öğrenme geri bildirimi: "neden kaybettim"
   okunur; değer HUD'daki göstergeyle aynı kaynaktan — `spirit` §3.7). Düğmeler: **[Sahneyi Yeniden
   Dene]** (birincil, sessiz odak) ve **[Ana Menü]**.
3. **Yeniden Dene (T22):** §3.4 anlık görüntüsünü geri yükler; harita ve altın sıfırdan; doğrudan hedef
   paneline (B) gider; anlatı sayfaları yeniden gösterilmez; [Başla] ile S2 yeniden yazılır (eski sahne
   kaydının üzerine).
4. **Ana Menü (T23):** kayıt yazılmaz. "Devam Et" sonradan son tur sonu kaydını açar (ADR-0007: "yenilgi
   son otomatik kaydı bozmaz"). Kayıp kaçınılmaz bir durumdan alınmışsa oyuncu yine kaybeder ve bu ekranı
   yeniden görür; bu bilinçli bir kabuldür (§11-Q3). Prolog'da ihmal çizgisinde son kayıt 15. tur başıdır
   (`erlik_power = 8`, yayılım o turun sonunda): oyuncunun o turda (kuvveti yetiyorsa) tek bir arındırma hamlesiyle kurtulma
   şansı vardır — "Devam Et" bu yüzden çoğu zaman kaçınılmaz değil, son bir fırsattır.
5. `loss_reason` `NONE` ya da eşleme tablosunda olmayan bir değerse akış bozulmaz; `DEFEAT_REASON_GENERIC` gösterilir.

### 3.8 Anlatı Ekranı Kuralları (`NarrativeScreen`)

Kapsam: `INTRO_NARRATIVE`, `KOK_BORI_MARK` A, `OUTRO_NARRATIVE`, `CAMPAIGN_END`, `STORY_REPLAY`.

- **Sayfa:** tam ekran 640×360 illüstrasyon (üstte) + alt koyu panel (12px krem metin; art bible §7).
  İsteğe bağlı başlık 12px `HeaderLabel` (Arapça 16px; **C-45 (2026-10-21):** 24px yalnız tam ekran başlık kartı, cila) (yalnız sahne adı/Kağan ilanı gibi tekil başlıklar, art bible
  §7 tipografi). Köşede `n/N` sayfa göstergesi (ASCII rakam), sağ altta [Atla] düğmesi.
- **Girdi (yalnızca klavye + fare):** Enter/Space/sol tık = ilerle; Esc/[Atla] = **bulunulan durumun**
  kalan sayfalarını atla. Metin yazılırken ilk basış metni tamamlar, ikinci basış ilerler (F6). Tuş
  tekrarı (echo) sayılmaz. Gamepad yok.
- **Atlama kapsamı:** `INTRO_NARRATIVE` atlanırsa `KOK_BORI_MARK` A açılır; A ayrıca atlanabilir; ikisi
  `screen_input_guard_s` kadar ara ile iki basıştır. Atlama **hedef panelini (B) atlamaz.** Atlama her
  zaman serbesttir, onay istemez; çıkış anlatısı atlansa da S3 zaten yazılmıştır.
- **Girdi koruması:** her yeni ekran/sayfada ilk `screen_input_guard_s` içindeki girdi yok sayılır
  (önceki ekrandan taşan çift basış ve kazandıran fare tıkı bir sonraki ekranı geçemez).
- **Metin gösterimi:** karakter karakter ortaya çıkar (`text_reveal_cps`; 0 = anında). Otomatik ilerleme
  varsayılan **kapalı** (`auto_advance_delay_s = 0`).
- **Geçişler:** sayfalar arası ya düz kesme ya da 4 karelik dither geçişi (%100→%75→%50→%25 dama maskesi;
  art bible §7). **Alfa fade ve kesirli ölçek yasak.** Hareketi Azalt açıkken: metin anında, geçiş düz
  kesme, işaret/Kök Böri titreşimi durur (orta kare).
- **Illüstrasyon:** `SceneDefinition`/`NarrativePage` içindeki yoldan `ResourceLoader.load_threaded_request()`
  ile yüklenir (art bible §8: illüstrasyon asenkron); aynı anda en fazla **2** illüstrasyon bellekte
  (geçerli + sonraki, ≈ 1,8 MB). Sonraki sayfanın illüstrasyonu önceden istenir. `illustration_path` boşsa
  önceki sayfanın görseli korunur (aynı resim üstünde ardışık metin sayfaları — içerik tasarrufu); ilk
  sayfada boş olamaz. Yükleme `illustration_load_timeout_s` içinde bitmezse düz indigo (`#141A33`) zemin
  gösterilir, hata loglanır, oyun çökmez.
- **Metin:** yalnızca `tr(key)`; sabit metin yok; 11 dil (en geri-düşüş). Sığma kuralı F4; dil başına
  uzunluk testi (§8). Arapça: Unifont 16px, RTL yerleşim (ADR-0009); illüstrasyon aynalanmaz.
- **Odak:** [Devam]/[Atla] düğmeleri `FocusReveal.focus_quietly` ile sessiz odak alır (C-25); fare
  kullanıcısına odak çerçevesi gösterilmez.
- **STORY_REPLAY:** `intro_pages + kok_bori_pages + outro_pages` art arda, salt-okunur; durum, kayıt ve
  Ruh değişmez; Esc tüm oynatmadan çıkar.

### 3.9 Bölüm Seçimi (`CHAPTER_SELECT`) ve "Destanı Oku"

Neden var: (1) sahne sonu **doğal duraklama noktası** ve dönme nedenidir (makro döngü); (2) taşınan Ruh
ve lütuflar görünür olur (ilerleme geri bildirimi; çapraz inceleme N1); (3) anlatıyı yeniden okumanın tek
yeri; (4) Devam Et'in sahne arası iniş noktası. Sahne arası otomatik geçiş yoktur.

- **Düğüm durumları** (F1): `COMPLETED` (tamamlandı işareti), `AVAILABLE` (Kök Böri ışığı; en fazla bir
  tane), `LOCKED` (kilit işareti). Her düğüm: sahne adı (`title_key`); `AVAILABLE` düğümde ayrıca
  `teaser_key` satırı (bir sonraki tehdidin ipucu).
- **Eylemler:** `AVAILABLE` → [Başla] (birincil, sessiz odak, T6); `COMPLETED` → [Destanı Oku] (ikincil,
  T7); `LOCKED` → seçilebilir ama eylem yok, `CHAPTER_LOCKED_HINT` ipucu + ret sesi; [Ana Menü] (T8).
- **Taşınan güç şeridi:** `ruh` bakiyesi ve `boons` listesi (lütuf başına yığın sayısı) gösterilir.
- **Yeni açılma efekti:** `OUTRO_NARRATIVE`'dan gelişte yeni `AVAILABLE` düğüm bir kez 4 kare altın
  parlar (Hareketi Azalt: parlamadan sabit işaret). Aynı `CHAPTER_SELECT` ziyaretinde tekrarlanmaz.
- K = 1 (M1 demosu) iken zafer sonrası `CHAPTER_SELECT` hiç gösterilmez (T20 doğrudan `CAMPAIGN_END`);
  Devam Et ile tamamlanmış demo kaydı `CHAPTER_SELECT`'i salt-okunur açar.

### 3.10 Veri Modeli ve İçerik Doğrulama

İçerik (Resource) kaydedilmez (ADR-0007); `load()` ile yüklenir, büyük sahne zinciri `preload` edilmez
(ADR-0001). Mekanik veri `ChapterMapDefinition`'da (region-map §3.1), **sunum verisi** `SceneDefinition`'dadır:
metin yazarı haritaya dokunmadan anlatıyı düzenler (Modüler İnşa).

**`CampaignDefinition`** (tek kaynak, ör. `res://features/campaign/data/campaign.tres`):

| Alan | Tür | Kural |
| ---- | ---- | ---- |
| `scenes` | `Array[SceneDefinition]` | `chapter_id` 1'den başlayıp boşluksuz artar; sıra = oynanış sırası; `K = scenes.size()` (1–6) |
| `end_pages` | `Array[NarrativePage]` | `CAMPAIGN_END` içeriği (M1: demo sonu + Perde 1 ipucu; Alpha: son sözler). 1–4 sayfa |

**`SceneDefinition`** (sahne başına bir kaynak):

| Alan | Tür | Anlam / kural |
| ---- | ---- | ---- |
| `chapter_id` | `int` | 1–6; benzersiz; oynanış sırası |
| `title_key` | `StringName` | Sahne adı (`CHAPTER_<n>_TITLE`). `ChapterMapDefinition.chapter_name_key` ile **aynı** olmalı (test); C-40'ta HUD bu alandan okur |
| `map_path` | `String` | `ChapterMapDefinition` `.tres` yolu (bugün `res://features/grid/data/chapter_<n>_map.tres`). `load()` ile; `GameContext.CHAPTER_MAP_PATH_FORMAT` sabiti yerini buna bırakır |
| `intro_pages` | `Array[NarrativePage]` | 1–4 sayfa |
| `kok_bori_pose` | enum `PROFILE` / `DESCENT` / `FRONT` | Art bible §5 pozları |
| `kok_bori_pages` | `Array[NarrativePage]` | 0–2 sayfa (Prolog: genesis, 1 sayfa) |
| `kok_bori_line_key` | `StringName` | Hedef panelindeki 1–2 satırlık Kök Böri sözü |
| `objective_region_ids` | `Array[StringName]` | Kazanma koşulunda geçmeyen ek işaretli bölgeler (çoğu sahnede boş) |
| `outro_pages` | `Array[NarrativePage]` | 1–4 sayfa |
| `teaser_key` | `StringName` | Sefer haritasında bir sonraki sahnenin 1 satırlık ipucu (sahne **bu sahne tamamlanınca açılan** sahneyi anlatır) |
| `defeat_text_key` | `StringName` | İsteğe bağlı sahneye özel yenilgi metni (boş → neden/genel) |
| `boon_pool_ids` | `Array[StringName]` | *(C-44 inceleme (2026-10-21), W-12)* Sahne lütuf havuzu: uygun havuz bu listeyle de kesişir (`spirit-system.md` §3.5, §7). **Boş = tüm katalog.** Kimlikler katalogdaki `boon_id`'lerdir |

**`NarrativePage`:** `illustration_path: String` (boş = önceki), `text_key: StringName` (zorunlu),
`title_key: StringName` (isteğe bağlı), `sfx_id: StringName` (isteğe bağlı).

**`SceneFlowConfig`** (knob'lar, §7): `res://features/campaign/data/scene_flow_config.tres`.

**Prolog örnek veri:** `chapter_id = 1`; `title_key = CHAPTER_1_TITLE`; `map_path = …/chapter_1_map.tres`;
`intro_pages` = [`ill_prolog_intro.png` + `CHAPTER_1_INTRO_1` + başlık `CHAPTER_1_TITLE`;
`ill_prolog_tribes.png` + `CHAPTER_1_INTRO_2`]; `kok_bori_pose = DESCENT`; `kok_bori_pages` =
[`ill_prolog_genesis.png` + `CHAPTER_1_KOKBORI_1`]; `kok_bori_line_key = CHAPTER_1_KOKBORI_LINE`;
`objective_region_ids = []` (Canavarın İni `erlik_foci`'den gelir); `boon_pool_ids = [arinma_ustaligi, bereket, gok_kalkani]`
(M1 üçlüsü; C-44 inceleme, W-12); `outro_pages` =
[`ill_prolog_beast_purified.png` + `CHAPTER_1_OUTRO_1`; `ill_prolog_kagan.png` + `CHAPTER_1_OUTRO_2` +
başlık `CHAPTER_1_KAGAN_TITLE`]; `teaser_key = CHAPTER_1_TEASER`.

**Perde 1 örnek veri (C-43, [`perde1-dogu-curcet.md`](../levels/perde1-dogu-curcet.md) §2/§6):** `chapter_id = 2`;
`title_key = CHAPTER_2_TITLE`; `map_path` = Perde 1 haritası; `intro_pages` = G-1 (`CHAPTER_2_INTRO_1`, başlık
`CHAPTER_2_TITLE`), G-2 (`CHAPTER_2_INTRO_2`); `kok_bori_pose = PROFILE`; `kok_bori_pages` = G-3
(`CHAPTER_2_KOKBORI_1`); `kok_bori_line_key = CHAPTER_2_KOKBORI_LINE`; `objective_region_ids = [curcet_otagi]`;
`outro_pages` = O-1 (`CHAPTER_2_OUTRO_1`), O-2 (`CHAPTER_2_OUTRO_2`, başlık `CHAPTER_2_KANGLI_TITLE`);
`teaser_key = CHAPTER_2_TEASER`. Harita verisi: `enemy_reinforcement_region_ids = [curcet_otagi]`. (Prolog'un
`CHAPTER_1_TEASER` ve `CAMPAIGN_END_DEMO_1` içerikleri C-43'te güncellenir.)

**İçerik doğrulama (CI testi, "lint"):**

| # | Kural |
| ---- | ---- |
| L1 | Kimlikler 1…K boşluksuz ve benzersiz; her `map_path` bir `ChapterMapDefinition` yükler ve `chapter_id` eşleşir |
| L2 | `title_key == ChapterMapDefinition.chapter_name_key` |
| L3 | `erlik_foci` ve `objective_region_ids` bölge kimlikleri o haritada vardır |
| L4 | Sayfa sayısı aralıkları (§7) ve ilk sayfanın `illustration_path ≠ ""` |
| L5 | Başvurulan her anahtar `translations.csv`'de boş olmayan `en` sütununa sahip (ADR-0009: önce `en`) |
| L6 | Her anahtar 11 dilde native fontta sığar (F4) ve glif kapsamı geçer (`glyph_coverage_test`) |
| L7 | Her illüstrasyon dosyası var; 640×360; alfa yalnızca 0/255; ≤ 32 renk; palet doğrulayıcıdan geçer |
| L8 | `Σ` `en` karakter bütçeleri (F5) aşılmaz |
| L9 | `Prolog.kok_bori_pose = DESCENT`; `kok_bori_pages ≥ 1` (genesis zorunlu) |
| L10 | *(C-44 inceleme, W-12)* `boon_pool_ids` içindeki her kimlik katalogda bir `boon_id`'dir ve tekrarsızdır; liste doluysa katalogdan süzülen havuz (`requires` etkin olanlar) en az 3 lütuf içerir (aksi halde sunum slotları tekrar eder, `spirit` §5). Prolog listesi tam olarak `[arinma_ustaligi, bereket, gok_kalkani]` *(✅ C-78, `boon_offer_seed_pool_test.gd`)* |

---

## 4. Formulas

### F1 — Sahne açılma ve durum

`unlocked(c) = (c == 1) OR ((c − 1) ∈ chapters_completed)`
`state(c) = COMPLETED  eğer c ∈ chapters_completed;  AVAILABLE  eğer unlocked(c) AND c ∉ chapters_completed;  LOCKED  aksi halde`
`next_chapter = min { c ∈ [1, K] : c ∉ chapters_completed }`  (küme boşsa kampanya tamam)
`valid(chapters_completed) = ∀ c ∈ chapters_completed : 1 ≤ c ≤ K  AND  (c == 1 OR (c − 1) ∈ chapters_completed)`

| Değişken | Sembol | Tip | Aralık | Açıklama |
| ---- | ---- | ---- | ---- | ---- |
| Sahne kimliği | `c` | int | 1–K | `chapter_id` |
| Kampanya uzunluğu | `K` | int | 1–6 | `CampaignDefinition.scenes.size()` |
| Tamamlananlar | `chapters_completed` | küme (int) | boyut 0–K | `GameState.chapters_completed`; küme anlamlı: tekrar eklenmez |

**Çıktı aralığı:** her `c` için tam bir durum; aynı anda en fazla bir `AVAILABLE`. `valid` yanlışsa kayıt
`CORRUPT` sayılır (ADR-0007 doğrulaması). `GameState.is_chapter_unlocked(c)` bu `unlocked` ile aynıdır.
**Örnek (K=3):** `[]` → (AVAILABLE, LOCKED, LOCKED), next=1. `[1]` → (COMPLETED, AVAILABLE, LOCKED), next=2.
`[1,2,3]` → hepsi COMPLETED, next=yok. `[2]` ve `[1,3]` → `valid = false`.

### F2 — Zorunlu lütuf seçim sayısı (zafer anı)

`boon_cost(i) = BASE_BOON_COST + i × BOON_COST_STEP`  (`spirit-system.md` §4.4)
`cumulative(n, j) = Σ_{i=0}^{j−1} boon_cost(n + i) = j × BASE + STEP × (j × n + j × (j − 1) / 2)`
`k_cost = max { j ≥ 0 : cumulative(n, j) ≤ ruh }`
`k = min(k_cost, k_pool, VICTORY_PICK_CAP)`  ;  `ruh_sonra = ruh − cumulative(n, k)`

| Değişken | Sembol | Tip | Aralık | Açıklama |
| ---- | ---- | ---- | ---- | ---- |
| Ruh | `ruh` | int | ≥ 0 (Prolog tavanı ≈ 70; Final yüzlerce) | `GameState.ruh`, `VICTORY_BEAT`'te |
| Alınmış lütuf sayısı | `n` | int | ≥ 0 | `boons.size()` |
| Havuz sınırı | `k_pool` | int | 0–∞ | Uygun havuz boşalana kadar seçim sayısı; M1'de havuz (Arınma, Bereket sınırsız) hiç boşalmaz → ∞ |
| Güvenlik tavanı | `VICTORY_PICK_CAP` | int | 3–12 (varsayılan 8) | Hata/debug durumlarında sonsuz diziyi sınırlar |

**Uygulama notu:** gerçekte döngüyle (`while sunum_bekliyor AND seçim < cap`) yürür; kapalı form, havuz
sabitken test kâhinidir. **Çıktı aralığı:** `k ∈ [0, VICTORY_PICK_CAP]`.
**Örnekler** (BASE=30, STEP=20): `(ruh 29, n 0)` → k=0, 29 kalır. `(30, 0)` → 1, 0. `(40, 0)` → 1, 10 (Prolog:
canavar 30 + öğretici bölge 10). `(79, 0)` → 1, 49. `(80, 0)` → 2, 0. `(100, 2)` → 1 (70), 30 kalır
(`cumulative(2,2) = 160 > 100`). `(150, 0)` → 3, 0. `(10000, 0)` → 8 (tavan), `cumulative(0,8) = 800`,
9200 kalır; kalan sunum türetilmiş bekler.

### F3 — Sahnede kazanılan Ruh (sonuç kartı)

`ruh_gained = ruh_now − ruh_entry + Σ_{i=n_entry}^{n_now−1} boon_cost(i)`

| Değişken | Tip | Aralık | Açıklama |
| ---- | ---- | ---- | ---- |
| `ruh_now`, `n_now` | int | ≥ 0 | `VICTORY_BEAT` anındaki bakiye / lütuf sayısı |
| `ruh_entry`, `n_entry` | int | ≥ 0 | Sahne girişi anlık görüntüsü |

**Çıktı:** ≥ 0 (Ruh'un tek musluğu arındırmadır; harcama maliyeti geri eklenir).
**Örnek:** giriş (0, 0); sahnede toplam 50 Ruh kazanıldı, şafakta 1 lütuf (30) seçildi → `ruh_now = 20`,
`n_now = 1` → `20 − 0 + 30 = 50`. Prolog'da yalnız canavar: `(30, 0)` → 30.

### F4 — Metnin panele sığması

`max_lines(font) = floor((PANEL_INNER_H − title_h) / line_h(font))`  ;  `OK ⇔ lines_needed(text) ≤ max_lines`
`lines_needed` = `Font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, PANEL_INNER_W, font_size)` ile ölçülen sarmalı satır sayısı.

| Değişken | Değer (geçici — UX C-45 kesinleştirir) |
| ---- | ---- |
| `PANEL_INNER_W` × `PANEL_INNER_H` | 624 × 76 px (alt panel 640 × 92, 8 px dolgu) |
| `title_h` | 28 px (başlık varsa), aksi 0 |
| `line_h` | Fusion Pixel 12 px → 14; Unifont 16 px (Arapça) → 18 |

**Çıktı:** başlıksız `max_lines` = 5 (Fusion) / 4 (Unifont); başlıklı = 3 / 2. Aşan sayfa, yazar tarafından
bölünür (kaydırma yok). **Örnek:** 220 karakterlik `en` metin ≈ 3 satır → başlıklı sayfada da sığar; aynı
anlamın Arapça çevirisi başlıklı sayfada 2 satırı aşarsa L6 testi kırmızı olur.

### F5 — Anlatı okuma bütçesi

`read_time_est(page) = len_en(text) / READ_CPS`  (`READ_CPS = 17` karakter/sn, tahmin sabiti)
`bütçe_giriş: Σ len_en(intro_pages ∪ kok_bori_pages) ≤ INTRO_BUDGET_CHARS (1100) ≈ 65 sn`
`bütçe_çıkış: Σ len_en(outro_pages) ≤ OUTRO_BUDGET_CHARS (900) ≈ 53 sn`  ;  `len_en(text) ≤ PAGE_MAX_CHARS_EN (220)`

**Örnek (Prolog, örnek uzunluklar):** giriş 180 + 200, genesis 160 → 540 ≤ 1100 (≈ 32 sn); çıkış 190 + 170 =
360 ≤ 900 (≈ 21 sn). Amaç: 20–35 dk'lık sahneyi 1–2 dk'lık çerçeveyle sınırlamak.

### F6 — Girdi korumasının ve metin ortaya çıkışının zamanlaması

`accept_input_at = t_shown + screen_input_guard_s`
`reveal_done_at = t_shown + len(text) / text_reveal_cps`  (`cps = 0` → `t_shown`)
`auto_advance_at = reveal_done_at + auto_advance_delay_s`  (`delay = 0` → yok)
`presses_to_pass(page) = 2` eğer `t_now < reveal_done_at`, aksi `1`

**Örnek:** 180 karakter, `cps = 45` → ortaya çıkış 4,0 sn; koruma 0,4 sn. 1,0 sn'de basış metni tamamlar,
ikinci basış sayfayı geçer. Hızlı yol (Yeni Sefer → ilk eylem): Esc (≥ 0,4 sn) → Esc (≥ 0,4 sn) → [Başla]
= 3 basış, ≈ 1,2 sn alt sınır.

### F7 — Hedef işaret kümesi ve tamamlama durumu

`M = erlik_foci ∪ objective_region_ids`
`unresolved(r) = (r ∈ erlik_foci AND r.corruption_level > 0) OR (r ∈ objective_region_ids AND r.owner ≠ PLAYER)`
`V = { r ∈ M : unresolved(r) }`  (haritada işaretlenen bölgeler)

Tamamlama (COMMIT): `chapters_completed' = chapters_completed ∪ {c}` ; `current_chapter' = min(c + 1, K)` ;
`map_state' = null` ; `gold' = 0` ; `ruh'`, `boons'` = seçimlerden sonraki değerler.

**Örnek (Prolog):** `M = {sinir_bolge}`; başlangıçta bozulma 3 → `V = {sinir_bolge}`; arındırılınca `V = ∅`
(işaret söner); yayılım yeniden bozarsa `V` geri döner. COMMIT: `c = 1`, `K = 6` → `current_chapter' = 2`;
`c = K = 1` (demo) → `current_chapter' = 1`. COMMIT iki kez çalışırsa sonuç aynıdır (idempotent).

---

## 5. Edge Cases

**Kapatma ve çökme**
- **If oyuncu `INTRO_NARRATIVE` / `KOK_BORI_MARK` sırasında kapatırsa**: kayıt değişmez (S2 henüz yok).
  Devam Et önceki duruma (sefer haritası ya da önceki sahne kaydı) döner, giriş anlatısı yeniden gösterilir.
- **If oyuncu `PLAYING`'de kapatır ya da Ana Menü'ye basarsa**: son tur sonu kaydından sonraki hamleler
  kaybolur. Ana Menü düğmesi bunu `CONFIRM_LEAVE_SCENE` ile uyarır; Alt-F4'te uyarı yoktur. Devam Et son
  kayıttan sürer ("geri al" etkisi — oyun deterministik olduğundan kaydı sömürmenin getirisi yoktur).
- **If oyuncu `VICTORY_BEAT` ya da `BOON_PICKS` sırasında kapatırsa**: S3 henüz yazılmadığı için zafer ve
  o ana kadar yapılan seçimler kalıcı olmaz; Devam Et son tur sonu kaydından açar, oyuncu kazandıran
  hamleyi (en çok bir tur: `actions_per_turn = 1`) yeniden yapar. Bilinçli sadelik; sertleştirme seçeneği
  §11-Q7.
- **If kapatma COMMIT/S3 yazımı sırasında olursa**: atomik yazım (ADR-0007) sayesinde ya eski ya yeni kayıt
  geçerlidir; yenisi `map = null` taşır → Devam Et `CHAPTER_SELECT`.
- **If oyuncu `OUTRO_NARRATIVE` sırasında kapatırsa**: S3 yazılmıştır; Devam Et `CHAPTER_SELECT` açar,
  çıkış anlatısı yeniden gösterilmez ama "Destanı Oku" ile okunabilir (§3.9).
- **If oyuncu `CAMPAIGN_END` sırasında kapatırsa**: Devam Et `CHAPTER_SELECT`'i salt-okunur açar; sonu
  ekranı bir daha otomatik gösterilmez.

**Sonuç sinyalleri**
- **If aynı kontrol noktasında hem kazanma hem kaybetme koşulu sağlanıyorsa**: `region-map` §3.6 öncelik
  kuralı (önce kaybetme) sonucu belirler; Sahne Akışı yalnızca kilitlenmiş tek sonucu görür (`game_result`
  kilidi). Sahne Akışı sonucu yeniden yorumlamaz.
- **If `PLAYING` dışında `game_won`/`game_lost` gelirse** (örn. `VICTORY_BEAT` sırasında `game_lost`):
  yok sayılır ve loglanır (geçiş tablosunda yok).
- **If zafer tur sonunda (end_turn 5. adım) bulunursa**: `turn_ended` yayılmadığından S1 yazılmaz;
  akış yine T13'ten yürür, S3 zafer kaydıdır.

**Lütuf dizisi**
- **If zafer anında uygun lütuf yoksa ya da Ruh yetmiyorsa** (`k = 0`): `BOON_PICKS` hiç gösterilmez;
  `VICTORY_BEAT` → COMMIT → `OUTRO_NARRATIVE`. Ruh bakiyesi olduğu gibi taşınır.
- **If Ruh çok yüksekse** (hata ayarı ya da debug "sınırsız kaynak"): en çok `VICTORY_PICK_CAP` (8)
  zorunlu seçim yapılır; kalan türetilmiş sunum yeni sahnede HUD düğmesi ve şafak kuralıyla sunulur.
- **If kazandıran fare tıkı `VICTORY_BEAT` ya da lütuf kartlarının üstüne düşerse**: `screen_input_guard_s`
  içindeki girdi yok sayılır; kart yanlışlıkla seçilmez.
- **If havuzda 3'ten az uygun lütuf varsa**: `spirit` §5 kuralı (slotlar tekrar eder); Sahne Akışı farklı
  davranmaz.

**Anlatı ekranı**
- **If oyuncu atla'ya iki kez art arda basarsa**: ilk basış bulunulan durumu atlar; ikincisi yeni ekranın
  koruma süresine düşerse yok sayılır, düşmezse yeni ekranı (A) atlar. Hedef paneli (B) **hiçbir** atlama
  basışıyla kapanmaz (yalnız [Başla]).
- **If oyuncu aynı ekranı daha önce hiç görmeden zaten atlamışsa**: atlama idempotenttir; durum aynı
  sonraki ekrana gider, ekstra durum tutulmaz.
- **If metin yazılırken basılırsa**: metin tamamlanır, sayfa geçilmez (F6).
- **If illüstrasyon dosyası yok ya da süre aşımı olursa**: düz indigo zemin, hata log'u, metin yine
  gösterilir; çökme yok.
- **If bir çeviri anahtarı eksikse**: `en` geri-düşüşü gösterilir (`locale/fallback`); `en` de yoksa anahtar
  adı görünür ve debug yapıda assert verir (L5 bunu CI'da yakalar).
- **If dil Arapçaysa**: Unifont 16, `max_lines` 4/2; sığmayan çeviri L6'da kırmızıdır; çalışma anında
  satır sonu `…` ile kesilmez (okunamaz metin yerine içerik hatası olarak ele alınır).
- **If Hareketi Azalt açıksa**: metin anında, geçişler düz kesme, işaret ve Kök Böri titreşimi durağan.
- **If hedef işaret kümesi `V` boşsa** (odak/ek hedef yok): panel yalnız metin gösterir, haritada işaret
  yoktur (hata değil).
- **If odak arındırıldıktan sonra yayılımla yeniden bozulursa**: `V` yeniden dolar, işaret geri gelir
  (kazanma koşuluyla tutarlı, `region-map` §5).

**Devam Et ve kayıt**
- **If kayıt tamamlanmış kampanyaya aitse**: `CHAPTER_SELECT` salt-okunur (Başla yok).
- **If kayıt, derlemenin K'sından büyük bir sahne içeriyorsa** (ör. tam oyun kaydı demo derlemesinde):
  yükleme başarısız sayılır (`SAVE_CONTENT_MISSING`); dosya silinmez, üzerine yazılmaz.
- **If `chapters_completed` önek kuralını bozuyorsa** (`[2]`, `[1,3]`): `CORRUPT` → `.bak` denenir (F1).
- **If `map ≠ null` kaydında `current_chapter ≠ map.chapter_id` ise**: `CORRUPT` (ADR-0007).
- **If Devam Et ile yüklenen durum zaten kazanma koşulunu sağlıyorsa** (içerik yamasıyla koşul gevşemiş):
  özel işlem yok; bir sonraki hamle ya da tur sonu kontrolü `game_won`'u üretir (kendiliğinden düzelir).
- **If S3 yazımı başarısız olursa**: §3.6 madde 4 (bellek durumu geçerli, yeniden dene, kalıcı uyarı).
- **If `Yeni Sefer` onayı iptal edilirse**: kayıt baytı baytına aynı kalır.
- **If `scene_entry` yuvası yoksa/uyumsuzsa** (Yeniden Dene): mevcut `ruh`/`boons` ile devam, uyarı log'u
  (§3.4 geri-düşüş).
- **If oyuncu Yeniden Dene'yi art arda kullanırsa**: her seferinde aynı anlık görüntü; sayı sınırı yok.
- **If bellek ya da disk dolu**: `save_failed` kalıcı uyarı; oynanış sürer (ADR-0007).

**Sınır durumları**
- **If K = 1** (M1 demosu): `CHAPTER_SELECT` zafer sonrası atlanır (T20); tamamlanmış demo kaydı Devam Et'te
  salt-okunur seçim ekranını açar.
- **If c == K ve Final'e özel bir miras/bölünme aşaması gerekiyorsa** (`legacy-division.md`, yazılmadı):
  `OUTRO_NARRATIVE` ile `CAMPAIGN_END` arasına yeni bir durum eklenir; geçiş tablosu bunu taşıyacak biçimde
  yazılmıştır (§11-Q5).
- **If debug "God Mode — tüm bölümler açık" kullanılırsa**: yalnız debug yapıda, `chapters_completed`'a
  **yazmaz**, sürüm yapısında derlenmez.
- **If pencere odağı kaybedilirse**: oyun turn-based ve zamanlayıcı yoktur; yalnız metin ortaya çıkışı ve
  otomatik ilerleme (varsayılan kapalı) duraklar.

**Dejenere stratejiler (Sirlin)**
- *Kasıtlı yenilgiyle Ruh çiftçiliği* — R3 anlık görüntü geri yüklemesi etkisizleştirir (§3.4).
- *Tamamlanmış sahneyi tekrar oynayıp Ruh toplama* — v1'de oynanış yeniden açılmaz (§3.1).
- *Hedef panelini atlayıp hedefi kaçırma* — B atlanamaz; HUD "Hedef" satırı kalıcıdır.
- *Kaydı geri alma amaçlı Ana Menü → Devam Et* — "geri al" olarak serbest bırakılır; oyunda rastgelelik
  olmadığından (sunum seed'li, savaş deterministik) bu getiri sağlamaz.

---

## 6. Dependencies

### Bu sistemin dayandıkları (yukarı akış)

| Sistem | Tür | Arayüz |
| ---- | ---- | ---- |
| Harita / Tur Akışı (`region-map-system.md`) | **Sert** | `game_won` / `game_lost` (argümansız) ve **kayıp sebebi** `MapState.loss_reason` (`NONE` / `NO_REGIONS` / `ERLIK`; §3.6 kayıp koşulları, kodu C-63), `MapState.game_result` kilidi (§3.7); `ChapterMapDefinition.create_map_state()`, `starting_gold`; `WinCondition.erlik_foci`, `erlik_loss_threshold` ve `description_key`; `turn_ended` (S1 tetikleyicisi, §3.4) |
| Kök Böri / Ruh (`spirit-system.md`) | **Sert** | `ruh`, `boons`, `boon_cost(n)` (§4.4), deterministik sunum (§4.5), `pick_boon` (kilitte serbest), bekleyen sunumun türetilmesi (§3.4), şafak kuralı; sahne geçişinde bozulmanın sıfırlanması (§5) |
| Kaynak Yönetimi (`resource-system.md`) | **Sert** | `gold = starting_gold` sahne başında, sahne sonunda altın taşınmaz (§3.1 R8, AC16) |
| Kayıt / Yükleme (ADR-0007) | **Sert** | S1–S3, `campaign` + `scene_entry` yuvaları, `LoadResult`, `map: null` anlamı, `chapters_completed` doğrulaması |
| Bağlam hiyerarşisi (ADR-0001) | **Sert** | `RootContext` durum sahibi, `load()` ile geçiş, `MenuContext.continue_requested`, "call down, signal up" |
| Modifikatör hattı (ADR-0006) | Sert | Sahne başında / yüklemede `ModifierController.rebuild()` |
| Sunum katmanı (ADR-0011) | Sert | `ModalQueue` sırası, `BoonOfferModal(mandatory)`, HUD modeli, pasif görünüm sözleşmesi |
| Yerelleştirme (ADR-0009) | Sert | `tr()` anahtarları, 11 dil, piksel font zinciri, Arapça RTL, glif kapsamı |
| Ses (ADR-0008) | Yumuşak | Sahne sinyalleriyle SFX/müzik tetikleri (§9) |
| Art bible (§2, §4, §5, §7, §8) | Sert | Oyun durumu atmosferleri, Kök Böri pozları, panel ve ekran kuralları, illüstrasyon standartları |
| Erişilebilirlik ayarları (`AccessibilitySettings`) | Yumuşak | Hareketi Azalt davranışı |
| Ordu / Savaş (`army-system.md`, `combat-system.md`) | Yok | Doğrudan bağ yok; sonuçları harita üzerinden gelir |
| Katmanlı Düşman ([`enemy-layers.md`](enemy-layers.md), C-44) | Yumuşak | Siyasi düşman **yeni `loss_reason` değeri eklemez** (K4): Perde 1+ siyasi yenilgi mevcut `NO_REGIONS` ile (bölgesiz kalma) ve `ERLIK` ile ifade edilir; tabloya satır eklenmez (§3.7) |
| Konsey (`council-system.md`, yazılmadı) | Gelecek | Perde 2'de konsey ekranı sefer haritasına eklenebilir |
| Miras / Bölünme (`legacy-division.md`, yazılmadı) | Gelecek | Final çıkışı (§11-Q5) |

### Bu sisteme dayananlar (aşağı akış)

| Sistem | Tür | Arayüz |
| ---- | ---- | ---- |
| Prolog öğretici akışı (C-41) | Sert | `scene_started(chapter_id, first_entry)`; öğretici hedef panelinden sonra başlar |
| HUD / sunum (ADR-0011, C-37–C-41) | Sert | Kalıcı "Hedef" satırı ve işaretler (`V`), `chapter title_key` |
| Ses (ADR-0008) | Yumuşak | `scene_started/completed/failed`, `campaign_completed` sinyalleri |
| Menü (`MenuContext`) | Sert | Devam Et durumu/ipuçları, Yeni Sefer onayı |
| Anlatı sesi (C-54) | Sert | Sayfa / Kök Böri satırı / neden metinleri için anahtar listesi ve karakter bütçeleri (F4–F5) |

### Karşı belgelerdeki eklemeler (çift yönlü bağımlılık — C-35'te uygulandı, 2026-10-19)

`region-map-system.md` §6 (Sahne Akışı + `loss_reason`); `spirit-system.md` §3.4 (zafer dizisi tavanı,
yenilgi/Ruh), §5 (sahne geçişi, 1. tur), §6 (Sahne Akışı); `resource-system.md` §6 (aşağı akış satırı);
`game-concept.md` (Oturum Seviyesi yönlendirmesi, Sonraki Adımlar); ADR-0007 (S2 / `scene_entry` yuvası /
`current_chapter` anlamı / önek doğrulaması / `CONTENT_MISSING` — *C-56 için öneri*, durum Accepted);
ADR-0001 (`SceneDefinition.map_path` — C-62); ADR-0011 (`ModalQueue` sırası: sonuç kartı, yenilgi; HUD
"Hedef"); art bible §7 "Ekranlar" (yeni ekranlar maddesi). `systems-index.md` satırı kullanıcı tarafından
eklenir (önerilen bağımlılık sütunu: Harita, Ruh, Kaynak, Kayıt/Yükleme, Yerelleştirme).

**Mühendislik notları:** illüstrasyon `ResourceLoader.load_threaded_request()` (art bible §8; 4.7'de
kararlı API), sahne zinciri `preload` edilmez; ekran geçişi ≤ 1 sn (ADR-0001 bütçesi); anlatı ekranlarında
`modulate`/`self_modulate` alfa tween'i yoktur (CI grep'i, §8-AC27). Bağlam yerleşimi (anlatı ekranları
`GameContext` katmanı mı, ayrı bağlam mı) ADR C-62'nin kararıdır.

---

## 7. Tuning Knobs

Knob'lar `SceneFlowConfig` kaynağındadır (kodda sabit yok; `res://features/campaign/data/scene_flow_config.tres`).

| Knob | Kategori | Varsayılan | Güvenli aralık | Çok düşükse | Çok yüksekse / not |
| ---- | ---- | ---- | ---- | ---- | ---- |
| `text_reveal_cps` | Feel | 45 | 0 (anında) ya da 20–120 | < 20: oyuncu bekler, sıkılır | > 120 pratikte anında; 0 Hareketi Azalt'ta zorlanır |
| `screen_input_guard_s` | Feel | 0.4 | 0.2–1.0 | < 0.2: kazandıran tık sonraki ekranı geçer, çift basış atlama kaçar | > 1.0: ekranlar "yapışkan" hisseder |
| `auto_advance_delay_s` | Feel | 0 (kapalı) | 0 ya da 3–20 | < 3: okumaya yetmez | Kapalı varsayılan: oyuncu kontrolü; ayarlardan erişilebilirlik seçeneği olarak açılabilir |
| `VICTORY_PICK_CAP` | Curve | 8 | 3–12 | < 3: normal zaferde (k ≤ 3) kısıtlar | > 12: patolojik durumda uzun zorunlu dizi. Spirit hedefi finalde 5 lütuf (kilitliler açılınca 7) *(C-44 inceleme, W-11)* |
| `retry_restores_entry_snapshot` | Gate | true | true / false | false: yenilgide sahne içi Ruh/lütuf korunur (kasıtlı yenilgiyle Ruh çiftçiliği açılır) | R3 kararının geri alma düğmesi (§12) |
| `confirm_leave_scene` | Gate | true | true / false | false: kazara Ana Menü son kayıttan sonraki tüm hamleleri sessizce siler | — |
| `illustration_load_timeout_s` | Gate | 3 | 1–10 | < 1: yavaş diskte gereksiz düz zemin | > 10: takılı hissi |
| `intro_pages` / `kok_bori_pages` / `outro_pages` (sahne başına sayfa sayısı) | Curve (içerik bütçesi) | Prolog 2 / 1 / 2 | 1–4 / 0–2 / 1–4 | — | Fazlası illüstrasyon maliyeti ve oturum şişmesi; solo kapsam kontrolü |
| `PAGE_MAX_CHARS_EN` | Curve | 220 | 120–300 | — | Üstü F4'te sığmaz / okuma yükü |
| `INTRO_BUDGET_CHARS` / `OUTRO_BUDGET_CHARS` | Curve | 1100 / 900 | 600–1500 / 400–1200 | — | Üstü 1–2 dk'lık çerçeveyi aşar; Epik Ama Erişilebilir ihlali |
| `READ_CPS` | Curve (tahmin) | 17 | 12–25 | — | Yalnız bütçeleri saniyeye çevirir, oyunu etkilemez |
| Panel geometrisi (`PANEL_INNER_W/H`, `title_h`, `line_h`) | Feel | 624×76, 28, 14/18 | UX C-45 | — | F4 `max_lines`'ı belirler; değişirse L6 yeniden koşulur |

**Etkileşimler:** `text_reveal_cps` ↔ `screen_input_guard_s` (düşük hız + uzun koruma = uzun bekleme);
`VICTORY_PICK_CAP` ↔ spirit `BASE_BOON_COST` / `BOON_COST_STEP` (maliyet eğrisi değişirse tipik `k`
değişir; tavan yalnız patolojik duruma kalmalı); `retry_restores_entry_snapshot` ↔ spirit Ruh ekonomisi
(false iken C-49 kayıp süresi, çiftçilik maliyetini belirler).

---

## 8. Acceptance Criteria

Test türü her maddede; birim ve entegrasyon testleri **BLOCKING**. `T#` = §3.3 geçiş numarası.

### Birim — kural katmanı (BLOCKING)

- **AC1 (F1):** **GIVEN** K=3, **WHEN** `chapters_completed` = `[]`, `[1]`, `[1,2,3]`, **THEN** durum vektörleri
  sırasıyla (AVAILABLE, LOCKED, LOCKED), (COMPLETED, AVAILABLE, LOCKED), (COMPLETED×3) ve `next_chapter`
  1, 2, yok; `GameState.is_chapter_unlocked` her `c` için `unlocked(c)` ile eşittir.
- **AC2 (F1 geçerlilik):** **GIVEN** `[2]`, `[1,3]`, `[1,4]` (K=3), **THEN** `valid = false`; `[1,2]` için true.
- **AC3 (F7 COMMIT):** **GIVEN** c=1, K=6, **WHEN** COMMIT iki kez çalışır, **THEN** `chapters_completed = [1]`,
  `current_chapter = 2`, `map_state = null`, `gold = 0`; **GIVEN** c=K=1, **THEN** `current_chapter = 1`.
- **AC4 (F2):** **GIVEN** BASE=30, STEP=20, **WHEN** `(ruh, n)` = (29,0), (30,0), (40,0), (79,0), (80,0),
  (100,2), (150,0), (10000,0), **THEN** `(k, ruh_sonra)` = (0,29), (1,0), (1,10), (1,49), (2,0), (1,30), (3,0),
  (8, 9200).
- **AC5 (F3):** **GIVEN** giriş (0,0) ve şafakta 30 harcanmış, **WHEN** `ruh_now = 20`, `n_now = 1`, **THEN**
  `ruh_gained = 50`; Prolog yalnız canavar `(30,0)` → 30.
- **AC6 (F7 küme):** **GIVEN** Prolog verisi, **THEN** `M = {sinir_bolge}`; bozulma 3 iken `V = {sinir_bolge}`,
  0 iken `V = ∅`, yayılımla 1'e dönünce `V = {sinir_bolge}`.
- **AC7 (durum makinesi):** **GIVEN** T1–T23, **WHEN** her (durum, olay, koşul) çifti verilir, **THEN** sonraki
  durum ve eylem tabloyla birebir aynıdır; tabloda olmayan her çift durumu değiştirmez ve log üretir.
- **AC8 (tek terminal sinyal):** **GIVEN** `PLAYING`, **WHEN** `game_won` ve ardından aynı karede `game_lost`
  (ve tersi) gelir, **THEN** yalnız ilki işlenir (`VICTORY_BEAT` ya da `DEFEAT`), ikincisi yok sayılır.
- **AC9 (taşıma/sıfırlama):** **GIVEN** sahne 1 tamamlandı (Ruh 10, `boons = [bereket]`), **WHEN** sahne 2
  başlar, **THEN** `ruh = 10`, `boons` aynı, `gold = starting_gold(2)`, `current_turn = 1`,
  `last_erlik_spread_turn = 0`, `game_result = ONGOING` ve `modifiers` `boons`'tan yeniden kurulmuştur.

### Entegrasyon — akış ve kayıt (BLOCKING)

- **AC10 (zafer sırası, TR-concept-007):** **GIVEN** `k = 2`, **WHEN** `game_won`, **THEN** sıra:
  `VICTORY_BEAT` → seçim 1 → seçim 2 → S3 yazımı → ilk anlatı sayfası; S3, ilk çıkış sayfasından **önce**
  ve son `pick_boon`'dan **sonra** olur; `k = 0` iken `BOON_PICKS` hiç gösterilmez.
- **AC11 (kilitte seçim):** **GIVEN** `game_result = WON`, **THEN** `SpiritController.pick_boon` çalışır ve
  `attempt_move`/`end_turn`/üretim reddedilir.
- **AC12 (S3 içeriği):** **GIVEN** S3 yazıldı, **WHEN** kayıt yüklenir, **THEN** `map == null`,
  `chapters_completed ∋ c`, `current_chapter = min(c+1, K)`, `ruh`/`boons` zafer sonrası değerlerdir ve
  Devam Et `CHAPTER_SELECT` açar (T4).
- **AC13 (çıkışta kapatma):** **GIVEN** `OUTRO_NARRATIVE` ortasında süreç kapatıldı, **WHEN** Devam Et,
  **THEN** `CHAPTER_SELECT`; sahne `COMPLETED`; çıkış anlatısı otomatik gösterilmez.
- **AC14 (lütuf sırasında kapatma):** **GIVEN** `k = 2`, ilk seçimden sonra kapatıldı, **WHEN** Devam Et,
  **THEN** son tur sonu kaydı yüklenir (T3), `chapters_completed ∌ c` ve `ruh`/`boons` o kaydın değerleridir.
- **AC15 (yenilgi):** **GIVEN** `PLAYING`, **WHEN** `game_lost`, **THEN** `DEFEAT`; `SaveStore.write` çağrı
  sayısı değişmez; hiçbir lütuf sunumu gösterilmez; Devam Et son tur sonu kaydını açar.
- **AC15b (yenilgi sebebi → metin):** **GIVEN** `defeat_text_key` boş, **WHEN** `loss_reason` = `ERLIK`,
  `NO_REGIONS`, `NONE`, eşleme tablosunda olmayan bir değer, **THEN** gösterilen anahtar sırasıyla `DEFEAT_REASON_ERLIK`,
  `DEFEAT_REASON_NO_REGIONS`, `DEFEAT_REASON_GENERIC`, `DEFEAT_REASON_GENERIC`; `defeat_text_key` doluysa
  her durumda o anahtar kazanır; `ERLIK`'te `erlik_power / eşik` değeri (örn. `9 / 9`) gösterilir.
  *(Birim — kod C-40; `loss_reason` üretimi C-63)*
- **AC16 (Yeniden Dene, R3):** **GIVEN** giriş (Ruh 0, `boons = []`), sahnede +10 Ruh ve 1 lütuf (şafak) alındı
  ve `game_lost`, **WHEN** Yeniden Dene, **THEN** `ruh = 0`, `boons = []`, `current_turn = 1`, gold
  `starting_gold`, harita yeniden kurulu, `modifiers` `boons`'tan yeniden kurulmuş (şafak lütfunun etkisi
  yok); anlatı sayfaları gösterilmez, hedef paneli gösterilir; [Başla] ile
  S2 yazılır.
- **AC17 (Devam sonrası Yeniden Dene):** **GIVEN** mid-scene kayıttan Devam Et ile yüklenmiş yeni süreç ve
  `scene_entry` yuvası mevcut, **WHEN** `game_lost` + Yeniden Dene, **THEN** AC16 ile aynı sonuç;
  **GIVEN** yuva yok, **THEN** mevcut `ruh`/`boons` ile devam edilir ve uyarı loglanır.
- **AC18 (S2):** **GIVEN** yeni sahne, **WHEN** hedef paneli kapatılır, **THEN** `campaign` ve `scene_entry`
  yuvaları 1. tur başı durumuyla yazılır; giriş anlatısı ya da hedef paneli sırasında kapatılırsa **hiçbir
  yazım olmaz**.
- **AC19 (Devam Et yönlendirmesi):** **GIVEN** kayıt `map ≠ null`, `map == null` ve eksik, `map == null` ve
  tamam, bozuk, K'yı aşan sahne içeren, **THEN** sırasıyla `PLAYING`, `CHAPTER_SELECT`, `CHAPTER_SELECT`
  salt-okunur, Devam Et pasif (`SAVE_CORRUPT`), Devam Et pasif (`SAVE_CONTENT_MISSING`).
- **AC20 (mid-scene devam):** **GIVEN** `ruh ≥ boon_cost(n)` olan kayıt, **WHEN** Devam Et, **THEN** giriş
  anlatısı/hedef paneli yok; otomatik lütuf modalı **bir** kez açılır; HUD "Hedef" satırı ve `V` işaretleri
  yüklenen durumdan türetilmiştir.
- **AC21 (Yeni Sefer onayı):** **GIVEN** kayıt var, **WHEN** Yeni Sefer ve iptal, **THEN** kayıt dosyası baytı
  baytına aynıdır; onay → T1.
- **AC22 (Ana Menü onayı):** **GIVEN** `PLAYING`, **WHEN** Ana Menü, **THEN** `CONFIRM_LEAVE_SCENE`; Evet →
  `MAIN_MENU` ve kayıt yazımı yok; Hayır → `PLAYING`. `confirm_leave_scene = false` iken onaysız çıkar.
- **AC23 (S1 değişmedi):** **GIVEN** `PLAYING` ve `ONGOING`, **WHEN** `turn_ended`, **THEN** yalnızca
  `campaign` yuvası yazılır (S1); `DEFEAT`/`VICTORY_BEAT` durumlarında S1 hiç yazılmaz.
- **AC24 (girdi koruması):** **GIVEN** kazandıran fare tıkı `t0`'da, **WHEN** `t0 + 0.1 s`'de tık/Enter,
  **THEN** `VICTORY_BEAT` kapanmaz ve hiçbir lütuf kartı seçilmez; `t0 + screen_input_guard_s` sonrası çalışır.

### İçerik / veri (BLOCKING, CI)

- **AC25:** L1–L9 testleri `campaign.tres` üzerinde yeşildir (kimlikler, harita eşleşmesi, başlık eşleşmesi,
  bölge kimlikleri, sayfa aralıkları, anahtarların `en` değeri, 11 dilde `max_lines`, illüstrasyon 640×360 /
  ≤ 32 renk / palet, karakter bütçeleri, Prolog genesis).
- **AC26 (Prolog verisi):** **THEN** `intro_pages = 2`, `kok_bori_pages = 1`, `outro_pages = 2`,
  `kok_bori_pose = DESCENT`, son çıkış sayfasında `title_key = CHAPTER_1_KAGAN_TITLE`, K=1 derlemesinde
  `CampaignDefinition.end_pages ≥ 1`.
- **AC25b (sahne havuzu verisi, C-44 inceleme, W-12):** L10 yeşildir; Prolog `boon_pool_ids` tam olarak
  `[arinma_ustaligi, bereket, gok_kalkani]`; var olmayan `boon_id` ya da 3'ten küçük süzülmüş havuz CI'ı kırar.
- **AC25c (kampanya tohumu, C-44 inceleme, D4; ✅ C-77 — `save_serializer_campaign_seed_test.gd`):** Yeni Sefer `campaign_seed` üretir ve kayda yazar; S1–S3,
  Devam Et ve Yeniden Dene sonrası aynı değer okunur; yeni Yeni Sefer değeri yeniden üretir. Testte tohum enjekte edilir.
- **AC27 (alfa/fade yasağı):** `features/campaign/` içinde ve anlatı ekranı betiklerinde `modulate` /
  `self_modulate` alfa tween'i bulunmaz (`run-tests.sh` grep denetimi; ihlalde CI kırmızı).

### UI — rehberli kullanım (ADVISORY, walkthrough + ekran görüntüsü)

- **AC28 (anlatı ekranı):** Metin yazılırken ilk Enter metni tamamlar, ikincisi sayfayı geçer; Esc kalan
  sayfaları atlar; ilk 0.4 sn girdi yok sayılır; Hareketi Azalt açıkken metin anında, geçişler düz kesmedir.
- **AC29 (hedef paneli):** Panel `WIN_CONDITION_CH1` metnini ve `kok_bori_line_key` satırını gösterir;
  `sinir_bolge` üstünde işaret vardır; panel işaretin üstünü örtmez; Esc paneli kapatmaz, [Başla] kapatır;
  canavar arındırılınca işaret söner.
- **AC30 (sefer haritası):** `LOCKED` düğmede eylem yok ve ipucu görünür; `COMPLETED` düğmede [Destanı Oku]
  salt-okunur oynatır ve durum değişmez; yeni açılan düğüm bir kez ışıldar; `ruh` ve lütuf şeridi
  `GameState` ile eşleşir.
- **AC31 (sonuç kartı / yenilgi):** Kart değerleri `current_turn`, bölge sayısı ve F3 ile eşit; yenilgi
  ekranı neden metnini (`defeat_text_key` → `DEFEAT_REASON_<loss_reason>` → genel; AC15b) ve
  `DEFEAT_PROGRESS_KEPT` satırını gösterir.
- **AC32 (11 dil):** en/tr/de/fr/es/zh/ja/ko/ru/pt/ar için her anlatı sayfası sığar; Arapçada Unifont 16 ve
  RTL doğru; en/de/ar ekran görüntüsü kanıtı `production/qa/evidence/` altında.

### Deneyim ölçütleri (playtest — `/playtest-report`)

- **AC33 (hedef netliği):** 5 ilk kez oynayan kişiden en az 4'ü hedef panelinden hemen sonra Prolog hedefini
  kendi sözleriyle doğru söyler ("3 boyu birleştir + canavarı yen") ve en az 4'ü canavarın ininin yerini
  10 sn içinde gösterir.
- **AC34 (tempo):** Yeni Sefer → ilk eylem: atlayarak ≤ 10 sn, tam okuyarak ≤ 150 sn (ortalama); hiçbir
  oyuncu "atlayamadım" ya da "hedefi kaçırdım" demez; zafer sonrası ilerleme kaybı bildirilmez.
- **AC35 (performans):** Durum geçişi ≤ 1 sn; anlatı sırasında bellekte ≤ 2 illüstrasyon (≈ 1,8 MB).

---

## 9. Visual/Audio Requirements

| Olay / ekran | Görsel (art bible) | Ses | Öncelik |
| ---- | ---- | ---- | ---- |
| Anlatı sayfası | Tam ekran 640×360 illüstrasyon (≤ 32 renk, alfa 0/255), alt koyu panelde 12px krem metin, kilim / koçboynuzu / tündük kenar, filigran Kök Böri; geçiş = düz kesme ya da 4 kare dither | `sfx_narrative_advance` (yumuşak tık) | M1 yer tutucu |
| Kök Böri ilk görünüşü (genesis) | `ill_prolog_genesis.png`: iniş pozu — gökten ışık çizgileri, kanat yok, gök mavisi `#47A3E8` → beyaz `#D4EDFF` dither + altın `#EDC76B` hale, koyu ilahi zemin | `sfx_kok_bori_appear` (uzun çan) | M1 |
| Hedef paneli (B) | "İlahi" panel (`#0A0D1C`, 2px `#EDC76B`, 7×7 tündük köşe), 48×32 Kök Böri profil sprite, zemin katmanı koyu indigo | `sfx_kok_bori_appear` | M1 |
| Hedef işareti (haritada) | 9×9 ikon `icon_objective_marker` (gök mavisi/beyaz/altın ışık pikselleri, 2 kare / 1 fps, alfa 0/255; sahiplik ve bozulma katmanını örtmez; renk körlüğünde şekil yeterli); Hareketi Azalt: sabit | — | M1 (`/asset-spec`) |
| Zafer sonuç kartı | "Zafer" havası: sıcak altın, merkezde beyaz-altın parlamalı Kök Böri, altın çerçeveli `ModalPanel`; üç satır ikon + rakam | `sfx_victory` + `music_victory` | M1 yer tutucu |
| Lütuf dizisi | Mevcut lütuf ekranı (art bible §2, §7; kartlar 4 kare dither ile sırayla) | Ruh / spirit GDD'si | M1 |
| Çıkış anlatısı / Kağan ilanı | Prolog gün doğumu altın-turuncu; son sayfada başlık kartı (12px — C-45 (2026-10-21); 24px cila) | `sfx_narrative_advance` | M1 |
| Yenilgi ekranı | Soğuk gri-mor, düşük kontrast, altın yok; %15–20 opak, kenarları dither ile dağılan gri Kök Böri | `sfx_defeat` + `music_defeat` | M1 yer tutucu |
| Sefer haritası | Kilim zemin; `COMPLETED` / `AVAILABLE` (Kök Böri ışığı) / `LOCKED` düğümler; tamamlandı ve kilit **piksel ikon** (ADR-0009: ✓ metin glifi değil); yeni açılma 4 kare altın parıltı | `sfx_chapter_unlock`, ret: `sfx_ui_denied` | M1 (K=1'de görünmez) → M2 |
| Müzik | Sahne başına parça ve anlatı müziği ADR-0008 takibi; MVP'de yer tutucu yeterli (konsept) | — | M2 |

Illüstrasyon dosyaları `game/assets/art/illustrations/` altında `ill_<sahne>_<ad>.png`; Prolog listesi:
`ill_prolog_intro`, `ill_prolog_tribes`, `ill_prolog_genesis`, `ill_prolog_beast_purified`, `ill_prolog_kagan`.
Art bible §7'deki "yavaş tam piksel kaydırma", illüstrasyon 640×360 olduğundan (kaydırılacak alan yok)
M1'de uygulanmaz; katmanlı illüstrasyon varlığı sağlanırsa cila olarak değerlendirilir.

---

## 10. UI Requirements

- **Anlatı ekranı:** §3.8. Köşe göstergesi `n/N`; [Atla] ikincil düğme (Esc); [Devam] / tıkla-ilerle ipucu.
- **Hedef paneli:** §3.5. **HUD gereksinimi (ADR-0011 `HudModel`):** kalıcı "Hedef" satırı: `objective_key`
  (= `WinCondition.description_key`) + `neutral_progress` (`fethedilen nötr / gerekli`) + `foci_progress`
  (`arındırılan odak / toplam`); sayılar `NumberFormatter` ile. **C-45 (2026-10-21) K3:** `must_defeat_all_enemies`
  iken (Perde 1) ilerleme satırına dördüncü parça "Cürcet bölgeleri x/3" (alınan düşman bölgesi / başlangıçtaki
  düşman bölgesi sayısı) eklenir; kazanma koşulunun dört parçası da izlenir. Kök Böri düğmesi (spirit) bekleyen sunum
  yokken pasif kalır.
- **Sonuç kartı, lütuf dizisi, yenilgi:** `ModalQueue` üzerinden tek modal; harita girdisi kilitli; odak
  `FocusReveal.focus_quietly` ile, kapanışta önceki odak geri verilir (ADR-0011).
- **Sefer haritası:** §3.9; klavye gezinmesi (ok/Tab) düğümler ve düğmeler arasında; sessiz başlangıç odağı
  `AVAILABLE` düğümün [Başla]'sı (yoksa [Ana Menü]). Fare ile düğüm seçimi.
- **Onay modalleri:** `CONFIRM_NEW_CAMPAIGN`, `CONFIRM_LEAVE_SCENE` (Evet / Hayır, varsayılan odak Hayır).
- **Yerleşim:** 640×360; de/ru uzun dillerde taşma yok; sığmayan UI etiketi `…` ile kısalır (anlatı metni
  kısalmaz — F4/L6 içerik hatasıdır).
- **Yeni çeviri anahtarları (11 dil; önce `en`, ADR-0009):** `SKIP`, `START_SCENE`, `OBJECTIVE_LABEL`,
  `RESULT_TURNS`, `RESULT_REGIONS`, `RESULT_RUH_GAINED`, `BOON_CARRIES_ON`, `RETRY_SCENE`,
  `DEFEAT_PROGRESS_KEPT`, `DEFEAT_REASON_ERLIK`, `DEFEAT_REASON_NO_REGIONS`, `DEFEAT_REASON_GENERIC`, `CHAPTER_SELECT_TITLE`,
  `CHAPTER_LOCKED_HINT`, `READ_STORY`, `CAMPAIGN_COMPLETE`, `CONFIRM_NEW_CAMPAIGN`, `CONFIRM_LEAVE_SCENE`,
  `YES`, `NO`, `SAVE_FAILED`, `SAVE_CORRUPT`, `SAVE_TOO_NEW`, `SAVE_CONTENT_MISSING`; mevcut: `CONTINUE`,
  `MAIN_MENU`, `VICTORY`, `DEFEAT`, `BACK`, `CHAPTER_1_TITLE`, `WIN_CONDITION_CH1`. Sahne anahtarları
  (`CHAPTER_<n>_INTRO_<p>`, `_KOKBORI_<p>`, `_KOKBORI_LINE`, `_OUTRO_<p>`, `_TEASER`, `CHAPTER_1_KAGAN_TITLE`)
  metin C-54'ten gelir. Harf dönüşümü kodda yapılmaz; `−` `⚠` `✓` metinde kullanılmaz (ADR-0009).

> **UX bayrağı.** Bu sistemin gerçek UI gereksinimleri vardır: C-41/C-45'te `/ux-design` ile
> `design/ux/` altında sefer haritası, sonuç kartı, yenilgi ve hedef paneli spec'leri yazılmalıdır.

---

## 11. Open Questions

| # | Soru | Sahibi | Hedef |
| ---- | ---- | ---- | ---- |
| Q1 | ~~Prolog'un kayıp kuralı ve `loss_reason`~~ **Çözüldü (C-49):** Erlik'in Gölgesi (`erlik_power ≥ 9`) ya da bölgesiz kalma; sebepler `ERLIK` / `NO_REGIONS` (§3.7). Sebep C-63'te kodlandı (`MapState.loss_reason`, `game_lost` argümansız) | C-63 (tamam) | — |
| Q2 | Perde 1–4 sırası sabit mi (varsayılan, duygusal yay tablosu), yoksa oyuncu seçimli mi? Seçimli olursa F1 önek kuralı bir "önkoşul listesi"ne dönüşür | Kullanıcı | M2 (C-43) |
| Q3 | Yenilgi sonrası Devam Et son tur sonu kaydını açar (kaçınılmaz kayıpta aynı yenilgi tekrarlanır). Alternatif: yenilgide `campaign` yuvasını sahne girişi anlık görüntüsüyle değiştirmek | Kullanıcı | İlk playtest |
| Q4 | Tamamlanmış sahnenin tekrar oynanabilir olması (Ruh ödülsüz "pratik modu") v1 dışında bırakıldı | Kullanıcı | Alpha sonrası |
| Q5 | Final çıkışındaki miras/bölünme aşaması (`legacy-division.md`) durum makinesine nasıl eklenir (OUTRO ile CAMPAIGN_END arası yeni durum öngörülür) | game-designer / narrative | Final tasarımı |
| Q6 | ADR C-62 kararları: anlatı ekranlarının bağlamı, `scene_entry` yuvası mı şema alanı mı, S2 kaydı, `CONTENT_MISSING`, `SceneDefinition` yükleme yolu | technical-director | C-62 |
| Q7 | Lütuf seçimi sırasında kapatma zaferi kaybettirir (en çok 1 hamle). Sertleştirme: `game_won` anında "zafer-bekliyor" kaydı yazıp yüklemede `WinCondition.is_met` ile zafer akışını sürdürmek | Kullanıcı | Playtest geri bildirimine göre |
| Q8 | ~~Anlatı metinleri, Kök Böri sözü ve neden metinleri (D7/N10)~~ **Çözüldü (C-54, 2026-10-19):** [`narrative-voice.md`](../narrative/narrative-voice.md) — Prolog sayfaları (`CHAPTER_1_INTRO_*`, `CHAPTER_1_KOKBORI_1`, `CHAPTER_1_OUTRO_*`), `OBJECTIVE_LABEL` + `CHAPTER_1_KOKBORI_LINE`, `DEFEAT_REASON_*`, `DEFEAT_PROGRESS_KEPT` 11 dilde; `CHAPTER_1_TEASER` / `end_pages` C-43'e | narrative-director (C-54) | M1 ✅ |
| Q9 | Sahne başına müzik/ambiyans (ADR-0008 takibi) ve anlatı ekranı cilası (katmanlı illüstrasyonla kaydırma) | audio / art | M2 |

---

## 12. Karar Günlüğü (C-35, gece modu — önerilen seçenek uygulandı)

| Karar | Seçilen | Reddedilen alternatifler | Geri alma maliyeti |
| ---- | ---- | ---- | ---- |
| Yenilgide sahne içi Ruh/lütuf | Yeniden Dene sahne girişi anlık görüntüsüne döner (önceki sahnelerden taşınanlar korunur) | Yenilgide her şey korunur (kasıtlı yenilgiyle Ruh çiftçiliği); yenilgide kampanya kaybı | Düşük — knob `retry_restores_entry_snapshot` |
| Kayıt noktaları | S1 + yeni S2 (sahne girişi, iki yuva) + S3 (lütuflardan sonra, çıkıştan önce) | Yalnız S1 + S3 (Devam Et eski sahneyi gösterir, Yeniden Dene Devam Et sonrası çalışmaz) | Orta — ADR-0007 değişikliği (C-56 öncesi) |
| Sahne sonrası | `CHAPTER_SELECT` duraklama noktası | Otomatik sonraki sahne (taşınan güç görünmez, duraklama yok) | Düşük |
| Tamamlanan sahne | Tekrar oynanmaz; yalnız "Destanı Oku" | Tekrar oynanabilir (Ruh çiftçiliği); hiç yeniden okuma yok (çıkışta kapatma anlatıyı kaybettirir) | Düşük |
| Sıra | Doğrusal, `chapter_id` = sıra, ayrı `unlock_order` yok | Seçimli Perde sırası (M2'ye ertelendi, Q2); ayrı sıra alanı | Orta — F1 önkoşul listesine dönüşür |
| Hedef işareti | Kazanma koşulundan okunan tek kaynak + ek `objective_region_ids`; Esc ile kapanmaz | Sahne verisinde elle hedef listesi (koşulla ayrışır); atlanabilir panel | Düşük |
| Atlama kapsamı | Bulunulan durum; hedef paneli atlanamaz; 0,4 sn girdi koruması | Tek Esc tüm girişi atlar; korumasız | Düşük |
| Lütuf dizisi tavanı | `VICTORY_PICK_CAP = 8` | Tavansız (spirit §3.4 metni) | Düşük |
| Veri modeli | `SceneDefinition` (sunum) ≠ `ChapterMapDefinition` (mekanik) + `CampaignDefinition` | Alanları `ChapterMapDefinition`'a eklemek | Orta — kaynak şeması |
| M1 illüstrasyon bütçesi | 5 (2 giriş, 1 genesis, 2 çıkış) | 7+ sayfa (kapsam şişmesi) | Düşük |

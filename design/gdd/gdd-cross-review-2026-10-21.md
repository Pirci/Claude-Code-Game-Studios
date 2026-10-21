# Cross-GDD Review Report — 2026-10-21 (C-44)

- **GDDs reviewed:** 9 (army, combat, enemy-layers *(yeni)*, region-map, resource, scene-flow, spirit, game-concept, systems-index) + `design/levels/perde1-dogu-curcet.md`, `design/registry/entities.yaml`, `design/balance/boon-balance-2026-10-21.md`, ADR-0005, ADR-0011
- **Odak:** C-43 / C-44 değişiklikleri (Katmanlı Düşman, AI R1 + `P_eff`, takviye bölge listesi, lütuf M2: Kurt Gücü ≤ 3, Prolog havuzu, D5 hedefi, Perde 1). 2026-10-19 raporunda çözülmüş maddeler yeniden açılmadı.
- **Yöntem:** Phase 2 (tutarlılık, game-designer) ve Phase 3 + 4 (tasarım bütünlüğü + çoklu sistem senaryoları, creative-director) paralel.
- **Verdict: CONCERNS** — 1 engelleyici (metin), 16 tutarlılık uyarısı, 8 tasarım uyarısı, bilgi notları. Kullanıcı kararları ve düzeltmeler aşağıda (§6); hepsi bu raporla aynı gün uygulandı.

---

## 1. Tutarlılık — Engelleyici

**R-1 (2f). Aynı BLOCKING denge testi iki sonuç bekliyor.** `enemy-layers.md` AC15 "S-purify **W14**"; `perde1-dogu-curcet.md` §13 #10 ve `boon-balance-2026-10-21.md` "**W20**" (C-44 düzeltmesi). → AC15 W20 yapılır. Alt konu (T20 hedef penceresi dışında) → §5 D1.

## 2. Tutarlılık — Uyarılar

| ID | Kontrol | Bulgu | Düzeltme |
| --- | --- | --- | --- |
| W-1 | 2a | `army-system.md` §6 ve `combat-system.md` §6 Katmanlı Düşman'ı listelemiyor; `enemy-layers.md` §6 ikisini "Sert" yukarı akış sayıyor | İki §6'ya "Katmanlı Düşman — AI hamleleri bu kuralları kullanır / `D_eff` okur" satırı |
| W-2 | 2a | `systems-index.md` Katmanlı Düşman bağımlılıklarında "Sahne Akışı" — yön ters (scene-flow, enemy-layers'a bağlı) | Katmanlı Düşman satırından çıkar; Sahne Akışı satırına "Katmanlı Düşman (yumuşak)" |
| W-3 | 2b | `enemy-layers.md` §5 "lütuf yığın tavanı zaten sınırlar" diyor; `spirit-system.md` §3.5 Demir Post tavanı "—" — sınırsız yığın "AI hiç vurmaz" hattı açar | **Karar D2:** `DEMIR_POST_MAX_STACKS = 3` |
| W-4 | 2b | `enemy-layers.md` F-E1 `P.army = 0` dalı PLAYER hedef için ulaşılamaz (sahipli bölge 0 orduyla kalmaz — army §3.3, region-map §5); F-E1 örneği "kurt_ini yalnız P=0'a saldırabilir" yanıltıcı | Dal "ulaşılamaz (savunmacı)" işaretlenir; örnek "kurt_ini_ormani (A=1) hiçbir koşulda vuramaz" |
| W-5 | 2b | K10 sonrası R1 hep kazanır; `BATTLE_HELD_DEFENSE` hâlâ R1 çıktısı sayılıyor: region-map §3.5, seviye §2 tetik tablosu + playtest #8, ADR-0005 2026-10-20 eki, narrative-voice (HELD satırı) | "HELD yalnız `A ≤ P_eff` saldırılar için ayrılmıştır; Perde 1 R1'i üretmez" — anahtar korunur |
| W-6 | 2b | AI `P_eff` okuyor, oyuncu yalnız ham ordu görüyor (K8 + §2 "cezalandırıcı sürpriz yok" ile çelişki) | **Karar D3** |
| W-7 | 2b | Önceki raporun C-44'e devrettiği N4/N5/N6/N8/N9 C-44'te karara bağlanmadı | **Karar D5:** C-47 ölçüm maddesi; işaretçiler "C-47 replay sonrası"na taşınır |
| W-8 | 2c | `region-map-system.md` §3.5 Perde 1 notu C-44 öncesi (ham `P.ordu`, eski savunma tutma); §4 / AC6 "varsayılan profil" demeden R1'le çelişen kural; §3.1'de `enemy_ai_profile` alanı yok | §3.5 notu → "kural sahibi enemy-layers §3.3, `P_eff`" işaretçisi; §4/AC6 "(varsayılan profil)"; §3.1 alan |
| W-9 | 2c | `enemy-layers.md` §6 karşı güncellemeler #3/#7/#8 ve §12 C1/C6 "açık" — fiilen yapıldı | ✅ işaretlenir |
| W-10 | 2c | `entities.yaml` C-44 öncesi: ratio ham `P`; `EnemyAIProfile` alanları eksik; `source` yanlış; `referenced_by`'da enemy-layers yok; `last_updated` eski | Registry güncellenir |
| W-11 | 2c | `scene-flow.md` §7 `VICTORY_PICK_CAP` "finalde 6–8 lütuf" (eski D5) | "5 lütuf (kilitliler açılınca 7)" |
| W-12 | 2c | `SceneDefinition.boon_pool_ids` yalnız spirit'te; scene-flow §3.10 tablosu, örnek verisi, lint'i yok; spirit AC26 yalnız Demir Post'u dışlıyor | scene-flow §3.10 alan + lint + Prolog örneği `[arinma_ustaligi, bereket, gok_kalkani]`; AC26 "M1 üçlüsü dışındaki hiçbir lütuf" |
| W-13 | 2d | AI/takviye değerlerinin sahibi dört yerde (enemy-layers K2 ↔ kendi başlığı, resource §7, registry) | "Değerler: bölüm verisi (seviye belgesi → `.tres`); kural: enemy-layers; yürütme: resource F6" — enemy-layers §7, resource §7, registry |
| W-14 | 2d | `objective_region_ids` region-map §3.6 ve enemy-layers §3.7'de `WinCondition` alanı gibi; scene-flow'da `SceneDefinition` alanı | İki yerde "`SceneDefinition` (scene-flow §3.10)" |
| W-15 | 2e | `decide()` girdi sözleşmesi eksik (profil + savunma modifikatörleri nereden?) | **Karar D6:** profil `bind_config` ile bölüm başına enjekte; `decide(map_state, acted, defense_modifiers)` — ADR-0005 + enemy-layers §3.1; "kalıbın tersi değil" ifadesi kalkar |
| W-16 | 2f | `resource-system.md` AC10/AC11/§5/§10 takviyeyi tüm düşman bölgelerine bağlıyor (liste öncesi) | "(boş liste = tüm düşman bölgeleri)" / "listedeyse" kaydı |

**Bilgi (küçük bayatlıklar):** F-E1 notu "koşul_2 ⇒ koşul_1" `1/1` oranı için yanlış · F-E3 `t` aralığı 1–18 (T20 gerçekleşiyor) · seviye §13 #9 "AI (10)" test sayısı → 13 · `game-concept.md` "Sonraki Adımlar" Katmanlı Düşman kutusu işaretsiz · `systems-index.md` son güncelleme tarihi · scene-flow başlığı "inceleme bekliyor" ↔ index "APPROVED" · registry `erlik_power` aralığı Prolog'a özgü (Perde 1: 0–24).

**Doğrulanan:** Kurt Gücü ≤ 3 her yerde aynı; D5 aritmetiği (5 → 350, 7 → 630); Prolog havuzu sunum hesabı; `end_turn` sırası (AI → yayılım → ekonomi/takviye → tur → kontrol) tüm belgelerde aynı; F-E3 / AC12; takviye listesi; K4 (yeni `loss_reason` yok); pasif Erlik kaybı T15; kazanma koşulu nötr kümesi; F-E4 ↔ combat Dal 1/2.

---

## 3. Tasarım Bütünlüğü (Phase 3)

| ID | Seviye | Bulgu | Karar / sahibi |
| --- | --- | --- | --- |
| H1 | WARNING (C-47 T20 doğrularsa BLOCKER) | Kök Böri'nin sözü ("Önce ışığı oraya taşı") güney / önce-arındır yolunu gösteriyor; o yol W20 (hedef T10–18). Odak nötr sayımına girmediği için güney yolu kuzeyin önüne eklenen bir parça; başkent Obası'nı geri alıyor. Ludonarrative uyumsuzluk | **D1** |
| H2 | WARNING | F-E2 savunma tutma: oyuncu `kurt_ini` + `oba`'yı tutunca başkent kalıcı felç; `enemy-layers.md` §5 "ikisi aynı anda tutulamaz" cümlesi yanlış (ikisi de zafer için zorunlu) | §5 cümlesi düzeltilir; **D5** metriği "T5 sonrası uygun AI adayı olan tur oranı"; düşükse başkent F-E2'den muaf (kullanıcıya sorulur) |
| H3 | WARNING | Felç + "Perde 1'de yeni kural yok" → risksiz Ruh çiftçiliği (odağı L3 bırak, komşu yayılımları yeniden arındır); yedek düğme tetiği (zafer > T18) bunu yakalamaz | **D5** "felç + yeniden arındırma" çizgisi; ×0.5 yedeğinin tetiği bu çizgiye bağlanır |
| H4 | WARNING | Prolog'dan taşınan Gök Kalkanı ×1 Perde 1'de pasif kaybı T15 → T20'ye iter (pasif oyuncu AI'ya komşu değil); seviye kabul #3 yalnız lütufsuz girişte geçer | **D5** GK1 / Bereket1 giriş varyantları; pasif + GK1 > T18 ise Perde 1 `erlik_loss_threshold` 9 → 8 |
| H5 | WARNING | Dikkat bütçesi: T5–9'da 5 aktif sistem (eşik 4); kral tehdidi telegraf edilmiyor; oyuncu `2(E−1) ≥ 3·P_eff` ve F-E2'yi kafadan hesaplıyor | **D3** |
| H6 | WARNING | Deterministik sunum: (chapter 2, n=1) seed → herkes Kurt Gücü / Arınma / Bereket; Demir Post Perde 1'de pratikte erişilemez; "kişisel build" fantezisi zayıf | **D4** |
| H7 | INFO | Ekonomi: altın biriktirme anlamsız (N5); başkent ordusu sınırsız (bilinçli, K3); Ruh kapalı döngü (H3); `erlik_power` testere dişi (H4) | **D5** |
| H8 | INFO | Konsept "krallar ihmal edilirse saldırır" ↔ mekanik "kral zayıf sınırı vurur; ihmal edilirse başkenti büyür" | `game-concept.md` cümlesi güncellenir |

**Sütun uyumu:** Katmanlı Düşman ✓ Destanı Yaşa · ◑ Erişilebilir (H5) · ◑ İki Katmanlı Tehdit (H2, H8) · ✓ Modüler. Perde 1 ◑ Destanı Yaşa (H1). Ruh/lütuf ✓ tüm sütunlar, ◑ build fantezisi (H6). Anti-pillar ihlali yok.

## 4. Çoklu Sistem Senaryoları (Phase 4)

| Senaryo | Sonuç |
| --- | --- |
| S1 Tur sonu T5–7 (AI vuruşu → yayılım → takviye → şafak raporu → lütuf sunumu) | S1-a WARNING: region-map §3.5 + seviye §2 eski kural / HELD (W-5, W-8 ile düzelir) · S1-b INFO: AI vuruşu ve yayılım aynı zayıf hatta biner (N6, D5) · S1-c geçti: rapor sunumdan önce; öneri: `BATTLE_LOST_DEFENSE` ADR-0011'e göre `TurnSummaryReport` satırı olarak tanımlanır |
| S2 Çürük Koru arındırma + Cürcet geri alma | S2-a WARNING: tek hamleden üç ceza (geri alma, odağın yeniden bozulması, odağın düşmana geçmesi) — kural tutarlı, okunabilirlik sorunu → yayılım hedefi bir `erlik_foci` ise HUD "Odak tehlikede" uyarısı (spirit §3.6; spec C-45) |
| S3 Erlik eşiği ile aynı turda zafer | Geçti: Perde 1'de `end_turn` zafer üretemiyor; "önce kaybetme" çatışması doğmuyor |
| S4 Sahne geçişi + lütuf/Ruh taşıma + yeniden deneme | S4-a = H4 · S4-b = H6 (yeniden deneme + deterministik AI → çözülmüş bulmaca; D4 yumuşatır) · S4-c INFO: Final'de `BOON_CARRIES_ON` yanlış olur → `legacy-division.md` yazılırken ele alınır |

---

## 5. Kararlar (kullanıcı onayı 2026-10-21)

- **D1 (H1):** C-47 denge replay'ine **BLOCKING** kabul kriteri: "S-purify (önce arındır) ≤ T16". Sağlanmazsa seviye verisi ayarlanır (ör. `attack_start_turn`, başkent takviyesi, garnizon); Kök Böri'nin sözü değişmez.
- **D2 (W-3):** `DEMIR_POST_MAX_STACKS = 3` (Gök Kalkanı / Kurt Gücü kalıbı).
- **D3 (W-6, H5):** Oyuncu bölgesinin bilgi panelinde kural bilgisi satırı: "Kağan bu bölgeyi en az N orduyla vurabilir (lütuflar dahil)" — `P_eff` ve F-E1'den türetilir; niyet önizlemesi değildir (K8 korunur). M2 HUD gereksinimi; spec C-45. **Uygulama (C-45):** `design/ux/hud.md` — satır 1. turdan itibaren her tur, key `ENEMY_STRIKE_THRESHOLD`; "lütuflar dahil" açıklaması `HINT_ENEMY_KING`'de.
- **D4 (H6):** Yeni Sefer'de üretilip kampanya kaydına yazılan **kampanya tohumu** lütuf sunum seed'ine eklenir; yeniden denemede sabit kalır (C-44 #8 determinizmi korunur), testte enjekte edilir.
- **D5 (W-7, H2, H3, H4, H7):** C-47 replay ölçüm maddeleri: T5 sonrası AI adayı tur oranı (H2); "felç + yeniden arındırma" çizgisi Ruh/tur (H3 → ×0.5 yedeğinin tetiği); GK1 / Bereket1 giriş varyantları (H4 → pasif + GK1 > T18 ise Perde 1 eşiği 9 → 8); N4/N5/N6/N8/N9 Perde 1 için ölçülür ve kabul / erteleme kaydı yazılır.
- **D6 (W-15):** `EnemyAIProfile` bölüm başına `bind_config` ile enjekte; imza `decide(map_state, acted, defense_modifiers)`.

## 6. Revizyon için işaretlenen GDD'ler

| GDD | Neden | Tür | Öncelik |
| --- | --- | --- | --- |
| enemy-layers.md | R-1, W-4, W-5, W-9, W-13, W-14, W-15, H2 §5 cümlesi, D3 | Tutarlılık | Engelleyici (R-1) → bu raporla düzeltildi |
| region-map-system.md | W-5, W-8, W-14 | Tutarlılık | Uyarı → düzeltildi |
| spirit-system.md | D2, D4, W-12 (AC26), S2-a | Tutarlılık + tasarım | Uyarı → düzeltildi |
| scene-flow.md | W-11, W-12 | Tutarlılık | Uyarı → düzeltildi |
| resource-system.md | W-13, W-16 | Tutarlılık | Uyarı → düzeltildi |
| army-system.md, combat-system.md | W-1 | Tutarlılık | Uyarı → düzeltildi |

Uygulama tarafı (kod, testler, replay ölçümleri) → C-47; UX (D3, S2-a) → C-45.

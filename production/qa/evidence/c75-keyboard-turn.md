# C-75 — Klavyeyle bir tur (K4 / A5) — yürüyüş kanıtı

**Tarih:** 2026-10-25 · **Yapı:** `main` (C-75 commit'i) · **Godot:** 4.7.1 headless + Xvfb (opengl3) · **Diller:** en, tr, ar, de
**Görsel:** [`c75-keyboard-turn.png`](c75-keyboard-turn.png) — satırlar en / tr / ar / de; sütunlar (1) bölge odağı, (2) hedef seçim modu, (3) savaş raporu.
**Otomatik test:** `game/tests/unit/grid/region_focus_neighbors_test.gd` (7 test).

## Yöntem

Gerçek `RootContext` akışı; haritaya gelindikten sonra **yalnız klavye eylemleri** (`Viewport.push_input`, `InputEventAction`) —
fare olayı ve doğrudan metot çağrısı yok. Her adımdan sonra odak sahibi kaydedildi.

| # | Tuş | Beklenen | Gözlenen odak |
|---|---|---|---|
| 1 | Enter | Gizli odak (Tur Bitir) görünür olur, tur **bitmez** (FocusReveal) | `EndTurnButton` |
| 2 | Tab ×3 | Tur Bitir → harita, okuma sırası: Kutlu Dağ → Batı Obası → Oğuz Otağı | bölge odakları |
| 3 | — | Odaktaki bölgede 1px altın kontur (görsel 1) | ✓ |
| 4 | Enter | Bölge seçilir, bilgi paneli açılır, odak panelin ilk etkin düğmesine (Ordu Gönder) | `SendArmyButton` |
| 5 | Enter | Hedef seçim modu: Ordu Gönder **basılı**, altında "Hedef bölgeyi seç", odak kaynak bölgeye | Oğuz Otağı odağı |
| 6 | ↑ | Komşuluğa göre yukarıdaki komşu: Kutlu Dağ (altın kontur, görsel 2) | Kutlu Dağ odağı |
| 7 | Enter | Hamle uygulanır, savaş raporu açılır, odak [Devam] (görsel 3) | `ContinueButton` |
| 8 | Enter ×2 | İlk basış odağı görünür yapar, ikincisi raporu kapatır; Kutlu Dağ oyuncunun | ✓ (`altai owner = PLAYER`) |

Ayrıca otomatik testte: Esc hedef modunu iptal eder (düğme normal, satır gizli, odak Ordu Gönder'e); panel odaktayken Esc
seçili bölgeye döndürür; komşusu olmayan yönde ok odağı yerinde tutar (HUD'a atlamaz); haritanın sonundan Tab HUD'a çıkar.

## Sonuç

- **A-7 (K4): GEÇTİ** — fare kullanılmadan bölge seçildi, ordu gönderildi, hedef seçildi, rapor kapatıldı; Tur Bitir aynı zincirde.
- **B6 / §5.6 (A5): GEÇTİ** — basılı düğme + `PICK_TARGET_HINT` (11 dil), Esc iptal.
- **RTL (UD kapandı):** harita her dilde LTR çizildiği için (ADR-0009) oklar ekran geometrisini izler; Arapçada sol ok yine
  soldaki bölgeye gider. Bölge odak kontrolleri `LAYOUT_DIRECTION_LTR`.
- **Bulgu (düzeltildi):** Godot, `Node2D` altındaki kontrolleri Tab gezinmesine katmıyor — Tab yalnız Ana Menü ↔ Tur Bitir
  arasında dönüyordu. Zincir açıkça kuruldu (`CampaignMap.focus_order`, `GameContext._link_map_tab_order`) ve testle korundu.
- **Bilinen sınır:** Shift+Tab haritadan çıkışta HUD'daki önceki kontrole kendiliğinden döner; haritanın sonundaki bölgeye
  geri dönüş bağı yalnız Tur Bitir yönünde kuruludur.

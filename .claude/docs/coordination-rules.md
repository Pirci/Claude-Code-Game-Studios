# Coordination Rules & Token Budget

Amaç: **aynı kalite, daha az token.** Kalite kapıları (testler, ADR uyumu, kullanıcı kararı)
aynen kalır; kısılan şey tekrar okuma, gereksiz ajan ve uzun çıktıdır.

## Orkestrasyon

1. **Önce kendin yap.** Hedefi bilinen iş (≤ ~5 dosya, tek alan) ana oturumda yapılır. Ajan
   yalnız şunlar için açılır: (a) geniş arama/keşif, (b) birbirinden bağımsız paralel işler,
   (c) ana bağlamı şişirecek uzun okuma, (d) bağımsız göz gerektiren inceleme.
2. **Tek uzman, zincir değil.** Bir iş için doğru uzmanı doğrudan çağır
   (dosya uzantısı → uzman tablosu `technical-preferences.md`'de). Yönetici → lead → uzman
   zinciri yalnız çok alanlı bir **karar** için kurulur; uygulama için kurulmaz.
3. **Paralel.** Girdileri bağımsız ajanlar tek mesajda birlikte açılır; biri BLOCKED ise
   hemen bildirilir, diğerlerinin sonucuyla kısmi rapor verilir.
4. **İnceleme kapıya göre.** Bağımsız inceleme (`/code-review`, director gate) yalnız BLOCKING
   işlerde (formül, durum makinesi, kayıt, mimari) ve kilometre taşı kapılarında. Metin, veri,
   tek satırlık düzeltme için inceleme ajanı açılmaz — test + diff yeterlidir.
5. **Alan sınırı.** Ajan kendi alanı dışındaki dosyayı açık görevlendirme olmadan değiştirmez.
   Anlaşmazlık: tasarımda `creative-director`, teknikte `technical-director`; çok alanlı
   değişikliğin yayılımını `producer` izler.

## Ajan brifi (her çağrıda)

Ajan konuşma geçmişini görmez; brif kısa ama eksiksiz olur:

- **Hedef** (tek cümle) + görev ID'si · **Okunacaklar** (`yol` + bölüm/satır — "hepsini oku" değil)
- **Bilinenler / elenenler** (yeniden keşfetmesin) · **Kapsam dışı**
- **Bitti kriteri** + çalıştırılacak test yolu
- **Dönüş biçimi:** ≤ 200 kelime — değişen dosyalar (`yol:satır`), test özeti, açık sorular.
  Kod veya dosya içeriği geri yapıştırılmaz.

## Model kademesi

Kademe takma adla yazılır (`haiku` / `sonnet` / `opus`) — sürüm kimliği yazılmaz.

| Kademe | Ne için | Ajanlar |
|--------|---------|---------|
| `haiku` | Arama, durum kontrolü, şablon doldurma, biçimlendirme | Explore (varsayılan), devops-engineer, community-manager, qa-tester, tools-programmer, sound-designer, localization-lead, release-manager |
| `sonnet` | Uygulama, tek sistem tasarımı/analizi — **varsayılan** | diğer tüm uzmanlar ve lead'ler |
| `opus` | 5+ belge sentezi, faz kapısı, mimari karar, geri dönüşü zor çıktı | creative-director, technical-director, producer, narrative-director, lead-programmer |

- Alt görev daha basitse çağrıda düşür: `Agent(subagent_type="Explore", model="haiku", …)`.
- Yükseltme (`model="opus"`) yalnız kapı kararı veya çapraz sistem sentezi için.
- Skill kademeleri SKILL.md `model:` alanındadır; `opus` skill'ler: `/review-all-gdds`,
  `/architecture-review`, `/gate-check`, `/create-architecture`, `/milestone-review`,
  `/design-review`, `/team-combat`, `/content-audit`, `/balance-check`.

## Okuma ve çıktı disiplini

- **Arşiv okunmaz:** `production/continuation-archive.md`, `production/session-state/archive.md`,
  tarihli raporlar (`*-2026-*.md`) — yalnız `Grep` ile hedefli satır.
- **Büyük dosya:** önce `Grep` ile yer bul, sonra `Read` `offset/limit`. `translations.csv`,
  `.tres`, GDD'ler bütün olarak okunmaz.
- **Testler:** `QUIET=1 tools/ci/run-tests.sh [res://tests/…yol]` — yalnız özet + başarısızlar.
  Çalışırken yalnız ilgili test klasörü; görev kapanışında bir kez tam paket.
- **Aynı dosya iki kez okunmaz**; düzenlemeden sonra doğrulama okuması yapılmaz.
- **Team-* skill'leri** yalnız kullanıcı açıkça isterse veya iş gerçekten 3+ alanı kapsıyorsa;
  aksi halde tek uzman yeterlidir.

## Agent Teams (deneysel)

Ayrı oturumlar (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) varsayılan olarak **kullanılmaz** —
her üye bağımsız token harcar. Yalnız kullanıcı isterse.

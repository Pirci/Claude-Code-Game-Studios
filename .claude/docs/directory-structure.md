# Directory Structure

```text
/
├── CLAUDE.md                    # Master configuration
├── .claude/                     # Agent definitions, skills, hooks, rules, docs
├── game/                        # 🎮 GODOT PROJESİ (project.godot burada)
│   ├── project.godot            # Godot proje dosyası
│   ├── contexts/                # Bağlam hiyerarşisi (context architecture)
│   │   ├── root_context/        # Ana sahne, bağlam geçişleri
│   │   ├── game_context/        # Oyun içi (harita, savaş, tur döngüsü)
│   │   └── menu_context/        # Ana menü, ayarlar ekranları
│   ├── features/                # Özellik bazlı kapsülleme (feature encapsulation)
│   │   ├── grid/                # Harita grid sistemi
│   │   ├── army/                # Ordu üretimi + yönetimi
│   │   ├── combat/              # Savaş çözümleme + raporlama
│   │   ├── resources/           # Kaynak toplama (altın)
│   │   ├── diplomacy/           # İttifak / fetih sistemi
│   │   ├── bozkurt/             # Bozkurt ruhu bonus sistemi
│   │   ├── campaign/            # Bölüm ilerlemesi + unlock
│   │   └── audio/               # Ses yönetimi
│   ├── state/                   # Oyun durumu (sadece veri, mantık yok)
│   ├── ui/                      # UI sahneleri + scriptler
│   │   ├── hud/                 # Oyun içi HUD
│   │   └── screens/             # Menü ekranları, raporlar
│   ├── assets/                  # Godot içi asset'ler
│   │   ├── art/                 # Görseller (maps, units, ui, illustrations)
│   │   ├── audio/               # Ses dosyaları (music, sfx)
│   │   ├── shaders/             # Shader dosyaları
│   │   └── fonts/               # Font dosyaları (MSDF aktif)
│   ├── tests/                   # GDUnit4 testleri
│   │   ├── unit/                # Birim testleri
│   │   └── integration/         # Entegrasyon testleri
│   └── debug/                   # Debug araçları (god mode, vs.)
├── design/                      # Game design documents (gdd, narrative, levels, balance)
├── docs/                        # Technical documentation (architecture, api, postmortems)
│   └── engine-reference/        # Curated engine API snapshots (version-pinned)
├── tools/                       # Build and pipeline tools (ci, build, asset-pipeline)
├── prototypes/                  # Throwaway prototypes (isolated from game/)
└── production/                  # Production management (sprints, milestones, releases)
    ├── session-state/           # Ephemeral session state (active.md — gitignored)
    └── session-logs/            # Session audit trail (gitignored)
```

## Mimari İlkeler

- **Feature encapsulation**: Her feature klasörü kendi sahneleri, scriptleri ve
  asset referanslarını içerir. Feature'lar arası bağımlılık minimumda tutulur.
- **Context hierarchy**: `root_context` → `game_context` / `menu_context`.
  Context'ler servisleri oluşturur, bağlar ve çocuklarına inject eder.
- **State segregation**: `state/` klasöründeki objeler sadece veri tutar,
  hiçbir iş mantığı içermez. Mantık controller'larda yaşar.
- **Call down, signal up**: Çocuk node'lar parent'larını bilmez. Parent çocuğa
  doğrudan çağrı yapar, çocuk parent'a sinyal gönderir.

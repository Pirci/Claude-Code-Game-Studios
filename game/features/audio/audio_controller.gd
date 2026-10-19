class_name AudioController
extends Node
## Ses çalma servisi (ADR-0008). [RootContext]'in kalıcı çocuğudur; bağlamlara
## [code]bind_services[/code] ile verilir (autoload yok). Kısa SFX'ler küçük bir
## [AudioStreamPlayer] havuzundan "SFX" bus'ına çalınır; ses seviyeleri bus'larda
## ayarlanır (ayarlar ekranı → [AudioServer]).


const SFX_BUS: StringName = &"SFX"
const MUSIC_BUS: StringName = &"Music"
## Aynı anda çalabilecek kısa SFX sayısı; dolunca en eski oyuncu yeniden kullanılır.
const SFX_POOL_SIZE: int = 4

## Bölge seçimi "tık"ı — seçimin renk körlüğü yedeği (art bible §4).
const SFX_REGION_SELECT: StringName = &"region_select"

var _library: SfxLibrary = null
var _pool: Array[AudioStreamPlayer] = []
var _next_player: int = 0


func bind_services(library: SfxLibrary) -> void:
	_library = library


## [param id] kimlikli SFX'i çalar. Kütüphane yoksa ya da kimlik tanımsızsa çalmaz,
## [code]false[/code] döner (oyun akışı sesten bağımsızdır).
func play_sfx(id: StringName) -> bool:
	if _library == null:
		return false
	var stream: AudioStream = _library.get_stream(id)
	if stream == null:
		push_warning("AudioController: tanımsız SFX kimliği '%s'" % id)
		return false
	_ensure_pool()
	var player: AudioStreamPlayer = _pool[_next_player]
	_next_player = (_next_player + 1) % _pool.size()
	player.stream = stream
	player.play()
	return true


## Test ve hata ayıklama için: havuzdaki oyuncular (salt okunur kullanım).
func get_sfx_players() -> Array[AudioStreamPlayer]:
	return _pool


func _ensure_pool() -> void:
	if not _pool.is_empty():
		return
	for i: int in SFX_POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		player.bus = SFX_BUS
		add_child(player)
		_pool.append(player)

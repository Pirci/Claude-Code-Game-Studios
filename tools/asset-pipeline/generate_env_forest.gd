extends SceneTree
## Perde 1 orman dekoru ve orman körmösünü üretir (C-46; seviye belgesi §7.7, art bible "Boyut Tablosu").
##   → game/assets/art/maps/env/env_tree_healthy_01.png, env_tree_healthy_02.png,
##     env_tree_rotten_01.png, env_tree_rotten_02.png, env_bridge_wood_01.png, env_otag_curcet_01.png
##   → game/assets/art/units/unit_kormos_forest_idle_<0|1>.png
##
## Kullanım (repo kökünden):
##   godot --headless --path game --script ../tools/asset-pipeline/generate_env_forest.gd
##
## Kurallar: tuval = görünür + her kenarda 2px; pivot = ayak (görünür alt-orta piksel); alfa 0/255;
## yalnız küresel palet (validate_palette.gd). Işık doğudan (sağ yüz açık). Çürük ağaç anlamı biçimde
## (taçsız, kırık); #A86BC4 yalnız kırık taç uçlarında (Erlik anlamı, 4.74:1 — erişilebilirlik #1).
## Körmös: 2 kare (kare 1 = 1px yukarı), zemine değmez, altında gölge; %50 dama dither alt gövdede.
const ENV_OUT: String = "res://assets/art/maps/env/"
const UNIT_OUT: String = "res://assets/art/units/"
const PAD: int = 2
const T := Color(0, 0, 0, 0)

const COLORS: Dictionary = {
	".": T,
	# Orman rampası (seviye §7.1)
	"k": Color("#070D05"), "d": Color("#1A2E17"), "m": Color("#294726"), "g": Color("#3D6B3D"),
	"l": Color("#5C8F5C"), "h": Color("#87B85C"), "w": Color("#B8D49E"),
	# Deri Kahve (gövde, köprü)
	"o": Color("#0D0A06"), "e": Color("#1C150D"), "t": Color("#3A2817"), "u": Color("#5C4229"),
	"v": Color("#8A6D4F"), "y": Color("#B8945D"),
	# Keçe Grisi (huş kabuğu)
	"q": Color("#2E2A24"), "n": Color("#4A453C"), "b": Color("#D9D4C8"),
	# Keçe Krem (otağ keçesi)
	"D": Color("#3D3426"), "R": Color("#5C4F3A"), "S": Color("#8A7A5E"), "B": Color("#B8A689"),
	"C": Color("#D4C4A3"),
	# Pas Turuncusu (Cürcet sahiplik bandı ve bayrağı — ışık değil)
	"x": Color("#C45A2A"), "X": Color("#9A4220"),
	# Erlik (çürük ağaç, körmös)
	"c": Color("#1A1719"), "z": Color("#1F0F26"), "p": Color("#33173D"), "r": Color("#522961"),
	"a": Color("#A86BC4"),
}

## Çam: sivri katmanlı taç, sol yüz koyu, sağ yüz ışıklı. 12×20.
const TREE_HEALTHY_01: Array = [
	".....kk.....",
	"....kdgk....",
	"....kdlk....",
	"...kddgwk...",
	"...kdmglk...",
	"..kddmglhk..",
	"...kdmglk...",
	"..kddmgglk..",
	".kddmmgglhk.",
	"..kdmmgglk..",
	".kddmmggllk.",
	"kddmmmgggllk",
	".kddmmgglhk.",
	"kddmmmggglhk",
	"kkddmmmggllk",
	".kkkkkkkkkk.",
	"....otuo....",
	"....otuo....",
	"....otuo....",
	"...oottuoo..",
]

## Huş: yuvarlak taç, açık kabuk. 12×18.
const TREE_HEALTHY_02: Array = [
	"....kkkk....",
	"..kkdgglkk..",
	".kddmgglhwk.",
	".kdmmggllhk.",
	"kddmmgggllhk",
	"kddmmmgglllk",
	"kdmmmggglllk",
	"kddmmmggllhk",
	".kddmmggllk.",
	".kkddmmgglk.",
	"..kkkddmkk..",
	"....qbbq....",
	"....qnbq....",
	"....qbbq....",
	"....qbnq....",
	"....qbbq....",
	"....qnbq....",
	"...qqbbqq...",
]

## Çürük ağaç: taçsız, kırık dallar; uçlarda Erlik vurgusu. 10×16.
const TREE_ROTTEN_01: Array = [
	"..a.......",
	"..pa...a..",
	"a..p..ap..",
	"pa..p.p..a",
	".pp.prp.ap",
	"...pprpp..",
	"....rp....",
	"...cpr...a",
	"..ppcr.pp.",
	"....cr.p..",
	"....cpp...",
	"....cr....",
	"....cr....",
	"...ccrp...",
	"..cccrpp..",
	".cc.c.r.c.",
]

## Çürük ağaç (kırık gövde varyantı). 10×16.
const TREE_ROTTEN_02: Array = [
	"..........",
	"..........",
	"....a.a...",
	"....pap...",
	"a...rp....",
	"pa..rp....",
	".pp.rpa...",
	"...prp.ap.",
	"....cr.p..",
	"....crpp..",
	"....cr....",
	"...pcr....",
	"..p.cr....",
	"....crp...",
	"...ccrpp..",
	"..cc.c.rc.",
]

## Tahta köprü (yandan): korkuluk + tahtalar. 16×10.
const BRIDGE_WOOD_01: Array = [
	".oo..........oo.",
	".oyooooooooooyo.",
	".ovyyyyyyyyyyvo.",
	".ovoooooooooovo.",
	"oooooooooooooooo",
	"oyvyvyvyvyvyvyvo",
	"ovuvuvuvuvuvuvuo",
	"outututututututo",
	"oooooooooooooooo",
	".ot..........to.",
]

## Cürcet otağı: yuvarlak keçe gövde, konik çatı, tepede direk + pas turuncusu sancak, sahiplik bandı. 28×24.
const OTAG_CURCET_01: Array = [
	".............txxxx..........",
	".............txxXx..........",
	".............tXxx...........",
	".............t..............",
	"............ete.............",
	"...........eRRRe............",
	"..........eRRSRRe...........",
	".........eRRSRSRRe..........",
	"........eRRSRSRSRRe.........",
	".......eRRSRSRSRSRRe........",
	"......eRRSRSRSRSRSRRe.......",
	".....eRRSRSRSRSRSRSRRe......",
	"....eeeeeeeeeeeeeeeeeee.....",
	"....eSSBBBBBBBBBBBBBCCe.....",
	"....exxxxxxxxxxxxxxxxxe.....",
	"....eXxXxXxXxXxXxXxXxXe.....",
	"....eSSBBBBBBBBBBBBBCCe.....",
	"....eSSBBBBBeeeBBBBBCCe.....",
	"....eSSBBBBeDDDeBBBBCCe.....",
	"....eSSBBBBeDDDeBBBBCCe.....",
	"....eSSBBBBeDDDeBBBBCCe.....",
	"....eSSBBBBeDDDeBBBBCCe.....",
	"....eeeeeeeeeeeeeeeeeee.....",
	"....kkkkkkkkkkkkkkkkkkk.....",
]

## Orman körmösü gövdesi: asimetrik dal-uzuvlar, tek 2×2 göz, alt gövdede dama dither. 12×11.
const KORMOS_BODY: Array = [
	"z.......z...",
	".p..zz..p.z.",
	".rp.prpz.pr.",
	"..rpprrpzp..",
	"...prrrrp...",
	"..zpaarrpz..",
	".p.paarmpp..",
	"p..prrmrp.p.",
	"...p.rpr.p..",
	"....p.r.p...",
	".....p.p....",
]
const KORMOS_SHADOW: String = "....kkkk...."
const KORMOS_W: int = 12
const KORMOS_H: int = 14


func _init() -> void:
	for dir: String in [ENV_OUT, UNIT_OUT]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var env: Dictionary = {
		"env_tree_healthy_01": TREE_HEALTHY_01,
		"env_tree_healthy_02": TREE_HEALTHY_02,
		"env_tree_rotten_01": TREE_ROTTEN_01,
		"env_tree_rotten_02": TREE_ROTTEN_02,
		"env_bridge_wood_01": BRIDGE_WOOD_01,
		"env_otag_curcet_01": OTAG_CURCET_01,
	}
	for asset_name: String in env:
		_save(build_padded(env[asset_name] as Array), ENV_OUT + asset_name + ".png")
	for frame: int in 2:
		_save(build_padded(kormos_frame(frame)), UNIT_OUT + "unit_kormos_forest_idle_%d.png" % frame)
	quit()


## Körmös karesi: gövde kare 0'da 1. satırdan, kare 1'de 0. satırdan başlar (1px yukarı); gölge son satırda.
static func kormos_frame(frame: int) -> Array:
	var empty: String = ".".repeat(KORMOS_W)
	var rows: Array = []
	var top: int = 1 - frame
	for y: int in KORMOS_H - 1:
		var body_row: int = y - top
		rows.append(KORMOS_BODY[body_row] if body_row >= 0 and body_row < KORMOS_BODY.size() else empty)
	rows.append(KORMOS_SHADOW)
	return rows


## Izgarayı her kenarda PAD boşlukla tuvale çizer; satır uzunluğu ve renk anahtarı denetlenir.
static func build_padded(rows: Array) -> Image:
	var w: int = (rows[0] as String).length()
	var h: int = rows.size()
	var img: Image = Image.create_empty(w + PAD * 2, h + PAD * 2, false, Image.FORMAT_RGBA8)
	img.fill(T)
	for y: int in h:
		var row: String = rows[y] as String
		assert(row.length() == w, "satır %d uzunluğu %d ≠ %d" % [y, row.length(), w])
		for x: int in w:
			var key: String = row[x]
			assert(COLORS.has(key), "bilinmeyen renk anahtarı '%s'" % key)
			img.set_pixel(x + PAD, y + PAD, COLORS[key] as Color)
	return img


static func _save(img: Image, path: String) -> void:
	var err: Error = img.save_png(ProjectSettings.globalize_path(path))
	print(path, " ", img.get_size(), " err=", err)

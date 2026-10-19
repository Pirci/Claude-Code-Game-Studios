class_name LoadResult
extends RefCounted
## Kayıt yükleme sonucu (ADR-0007): ya geçerli bir [GameState] ya da hata kodu — asla kısmi durum.


## CONTENT_MISSING: kayıt bu sürümde olmayan bir bölüme işaret ediyor (scene-flow C-35 eki).
enum Code { OK, CORRUPT, VERSION_TOO_NEW, MISSING, CONTENT_MISSING }

var code: Code = Code.OK
## Yalnızca `code == OK` iken dolu.
var state: GameState = null
## Günlükler için okunur açıklama.
var detail: String = ""


static func ok(game_state: GameState) -> LoadResult:
	var result: LoadResult = LoadResult.new()
	result.state = game_state
	return result


static func error(error_code: Code, message: String) -> LoadResult:
	var result: LoadResult = LoadResult.new()
	result.code = error_code
	result.detail = message
	return result

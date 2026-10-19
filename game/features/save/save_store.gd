@abstract class_name SaveStore
extends RefCounted
## Kayıt metni deposu (ADR-0007). Gerçek dosya: [FileSaveStore]; testler bellek içi
## [MemorySaveStore] kullanır (birim testlerinde dosya G/Ç yok).


## Metni [param slot]'a yazar; başarısızlıkta önceki kayıt bozulmaz. Başarıda true.
@abstract func write(slot: StringName, text: String) -> bool


## Yükleme adayları, denenme sırasıyla (dosyada: asıl → .bak → .tmp). Yoksa boş.
@abstract func read_candidates(slot: StringName) -> PackedStringArray

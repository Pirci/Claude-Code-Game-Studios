@tool
class_name SfxLibrary
extends Resource
## SFX kimliği → ses akışı eşlemesi — içerik, data-driven (ADR-0008).
## Kimlikler kodda sabit olarak durur (ör. [constant AudioController.SFX_REGION_SELECT]);
## ses dosyası değiştirmek yalnızca bu kaynağı düzenlemektir.


@export var streams: Dictionary[StringName, AudioStream] = {}


## Kimliğin ses akışı; tanımsızsa [code]null[/code].
func get_stream(id: StringName) -> AudioStream:
	return streams.get(id) as AudioStream

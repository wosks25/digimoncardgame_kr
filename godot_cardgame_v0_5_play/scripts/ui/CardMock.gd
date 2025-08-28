extends Node
class_name CardMock

var name: String
var dp: int = 0
var keywords: Array = []
var suspended: bool = false
var alive: bool = true
var owner
var _sources: Array = []        # 진화원 스택(아래→위)
var _meta := {}                 # 임의 메타 정보 저장소 (overflow_value/material_save/delay_effect 등)
var stayed_on_board:bool = false
var delay_ready_on_turn:int = -999

func set_meta(key:String, value) -> void:
	_meta[key] = value

func has_meta(key:String) -> bool:
	return _meta.has(key)

func get_meta(key:String):
	return _meta.get(key, null)

func has_sources() -> bool:
	return _sources.size() > 0

func trash_top_source() -> void:
	if has_sources():
		var top = _sources.pop_back()
		if owner:
			owner.trash.append(top)

func get_all_sources()->Array:
	return _sources.duplicate()

func get_sources_filtered(tag=null)->Array:
	if tag == null:
		return get_all_sources()
	var out := []
	for s in _sources:
		if s.has_meta("xros_tag") and s.get_meta("xros_tag") == tag:
			out.append(s)
	return out

func can_attack()->bool:
	return alive and not suspended

# Delay 발동 스텁
func execute_delay()->void:
	if has_meta("delay_effect"):
		# 예: {"type":"Memory","value":2}
		var eff = get_meta("delay_effect")
		print("Delay fired:", name, eff)

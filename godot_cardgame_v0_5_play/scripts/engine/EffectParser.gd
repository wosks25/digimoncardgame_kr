extends Node
class_name EffectParser
# 아주 간단한 효과 DSL 파서 스텁
# 예: "[진화시] 메모리 +1." → {"trigger":"WhenDigivolving","effects":[{"type":"Memory","value":1}]}

func parse_effect(text:String)->Dictionary:
	var out := {"trigger":"","effects":[]}
	if text.find("메모리 +") != -1:
		var v = _extract_number(text)
		out.effects.append({"type":"Memory","value":v})
	if text.find("시큐리티 +1") != -1:
		out.effects.append({"type":"SecurityAttack","value":1})
	return out

func _extract_number(s:String)->int:
	var re = RegEx.new()
	re.compile("([+-]?\\d+)")
	var m = re.search(s)
	if m: return int(m.get_string(1))
	return 0

extends Node
class_name DigiXrosEngine
# 디지크로스: 재료를 밑에 넣으며 비용 감소

# cond 예: {"reduce_per":2, "tags":["Shoutmon","Ballistamon"]}
func choose_xros_sources(hand:Array, field:Array, cond:Dictionary)->Array:
	var out:= []
	var tags = cond.get("tags", [])
	# 간이: 손/필드에서 이름 또는 xros_tag가 일치하는 1장씩 선택
	for t in tags:
		var found = false
		for c in hand:
			if c.name == t or (c.has_meta("xros_tag") and c.get_meta("xros_tag")==t):
				out.append(c); found=true; break
		if not found:
			for c in field:
				if c.name == t or (c.has_meta("xros_tag") and c.get_meta("xros_tag")==t):
					out.append(c); break
	return out

# 결과 카드에 소스 합치고 비용 감산치 반환
func apply_xros(result_card, sources:Array, cond:Dictionary)->int:
	var reduce := 0
	var per := int(cond.get("reduce_per", 2))
	for s in sources:
		result_card._sources.append(s)
		# 소스는 원래 위치에서 제거(손/필드 관리 외부에서 수행)
		reduce += per
	return reduce

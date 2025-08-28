extends Node
class_name DNAEngine
# 조그레스(DNA Digivolution) 간이 구현

# 요구조건 포맷 예:
# req = {"colors":["Blue","Green"], "levels":[4,4], "result_card":<CardMock>}
func can_dna(d1, d2, req:Dictionary)->bool:
	if not d1.alive or not d2.alive: return false
	if req.has("levels"):
		var lv = req["levels"]
		# Mock엔 level 없으니 meta로 가정
		if int(d1.get_meta("level")) != int(lv[0]): return false
		if int(d2.get_meta("level")) != int(lv[1]): return false
	if req.has("colors"):
		var cs = req["colors"]
		if d1.get_meta("color") != cs[0]: return false
		if d2.get_meta("color") != cs[1]: return false
	return true

# 실행: 두 재료를 제거하고 result_card로 치환(언스스펜드, 소환후대기 해제)
func perform_dna(d1, d2, req:Dictionary, owner)->Node:
	if not can_dna(d1, d2, req): return null
	var result = req.get("result_card", null)
	if result == null: return null
	# 재료 제거
	owner.field.erase(d1); owner.field.erase(d2)
	# 결과 카드 세팅
	result.owner = owner
	result.alive = true
	result.suspended = false
	result.set_meta("level", req.get("result_level", 6))
	result.set_meta("color", req.get("result_color", "Blue"))
	# 재료를 진화원으로 쌓기(아래→위 순서 가정)
	result._sources.append(d1)
	result._sources.append(d2)
	owner.field.append(result)
	print("DNA Digivolve ->", result.name)
	return result

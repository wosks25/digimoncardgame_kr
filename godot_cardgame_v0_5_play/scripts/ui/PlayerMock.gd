extends Node
class_name PlayerMock

var field: Array = []    # 필드 디지몬
var trash: Array = []    # 트래쉬
var tamers: Array = []   # 테이머 {under:Array} 가정
var security: Array = [] # 보안 스택(front pop)
var board: Array = []    # 옵션/테이머 등 보드 잔존물
var turn_index:int = 0   # 간이 턴 카운터 (자기 턴 감지용)
var id:int = 1           # 1 or 2

func has_tamer() -> bool:
	return tamers.size() > 0

# save_under_tamer(card, is_source):
# is_source=true면 진화원 보존, false면 본체 세이브
func save_under_tamer(card, is_source:bool=false) -> void:
	if not has_tamer():
		return
	if not tamers[0].has("under"):
		tamers[0].under = []
	tamers[0].under.append(card)
	if not is_source:
		field.erase(card)

func security_check(attacker, n: int) -> void:
	for i in n:
		if security.size() == 0:
			return
		var card = security.pop_front()
		# 간단 처리: dp 있으면 보안 디지몬 취급
		if card.has("dp"):
			if attacker.dp < card.dp:
				attacker.alive = false
		else:
			# 옵션/테이머 보안 효과 스텁(필요시 확대)
			pass

func security_size() -> int:
	return security.size()

# Delay용 헬퍼
func next_turn_index()->int:
	return turn_index + 1

func is_turn_now()->bool:
	return true  # PhaseManager에서 자신의 턴일 때만 호출된다고 가정(간이)

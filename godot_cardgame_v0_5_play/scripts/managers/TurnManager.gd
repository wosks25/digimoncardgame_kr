extends Node
class_name TurnManager

signal phase_changed(new_phase: String)
signal turn_changed(active_player: int)
signal memory_changed(value:int)

var active_player: int = 1
var memory: int = 0              # 음수=내 쪽, 양수=상대 쪽
var phase: String = "READY"      # READY→DRAW→BREED→MAIN→END
var turn_end_pending: bool = false
const MAX_MEM := 10

func start_game(first: int = 1) -> void:
	active_player = first
	memory = 0
	phase = "READY"
	turn_end_pending = false
	emit_signal("turn_changed", active_player)
	emit_signal("phase_changed", phase)
	emit_signal("memory_changed", memory)

# 내부용: ±10 클램프 + 신호
func _set_memory(v:int)->void:
	memory = clamp(v, -MAX_MEM, MAX_MEM)
	emit_signal("memory_changed", memory)

# 비용 지불(코스트는 양수): 상대 방향(+)
func pay(cost: int) -> void:
	_set_memory(memory + cost)
	if memory > 0:
		# “액션/효과 resolve 완료 후” 턴 종료 판정하도록 예약
		turn_end_pending = true

# 액션/효과 resolve 마지막에 반드시 호출
func resolve_action_end() -> void:
	if turn_end_pending:
		if memory >= 0:
			# 효과로 메모리 복구되었으면 턴 유지
			turn_end_pending = false
		else:
			end_turn()
	# 아무 예약 없었어도 메모리 ±10 경계 보호
	_set_memory(memory)

func add_memory(amount:int)->void:
	_set_memory(memory + amount)

func next_phase() -> void:
	match phase:
		"READY":
			phase = "DRAW"
		"DRAW":
			phase = "BREED"
		"BREED":
			phase = "MAIN"
		"MAIN":
			phase = "END"
		"END":
			end_turn()
			return
	emit_signal("phase_changed", phase)

# 턴 종료/교대
# - passed=true: PASS 규칙(상대 3 보장)
# - memory<=0에서 끝나도 상대 3 보장
func end_turn(passed: bool = false) -> void:
	if passed or memory <= 0:
		_set_memory(3)
	# 턴 교대
	active_player = 2 if active_player == 1 else 1
	# 새 턴에서 자신의 관점(음수)로 표현
	_set_memory(-abs(memory))
	phase = "READY"
	turn_end_pending = false
	emit_signal("turn_changed", active_player)
	emit_signal("phase_changed", phase)

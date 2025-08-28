extends Node
class_name PhaseManager

@export var turn: TurnManager
@export var keyword: Node = null       # KeywordEngine
@export var p1_field: Array = []       # 간이 테스트용
@export var p2_field: Array = []

var first_turn_draw_skipped: bool = false

func _ready() -> void:
	if not turn:
		turn = get_node_or_null("../TurnManager")
	if not keyword:
		keyword = get_node_or_null("../KeywordEngine")
	if turn:
		turn.connect("phase_changed", Callable(self, "_on_phase_changed"))
		turn.connect("turn_changed", Callable(self, "_on_turn_changed"))
		turn.start_game(1)

func _on_phase_changed(p: String) -> void:
	match p:
		"READY":
			_on_ready()
		"DRAW":
			_on_draw()
		"BREED":
			_on_breed()
		"MAIN":
			_on_main()
		"END":
			_on_end()

func _on_turn_changed(active: int) -> void:
	print(">> Turn -> Player %d (memory=%d)" % [active, turn.memory])

# === 페이즈 진입 ===

func _on_ready() -> void:
	# 재기동: 상대 턴 시작에 내 필드의 재기동 카드 언스스펜드
	if keyword and keyword.has_method("apply_reboot"):
		if turn.active_player == 1:
			keyword.apply_reboot(p1_field)
		else:
			keyword.apply_reboot(p2_field)

func _on_draw() -> void:
	# 선공 첫 드로우 스킵 예시
	if not first_turn_draw_skipped and turn.active_player == 1:
		first_turn_draw_skipped = true
		print("DRAW: first turn P1 skip")
	else:
		print("DRAW: +1 (샘플)")

func _on_breed() -> void:
	print("BREED: (샘플) 부화/이동 선택 지점")

func _on_main() -> void:
	print("MAIN: 카드 플레이/진화/공격 선언 등")

func _on_end() -> void:
	print("END: 종료 트리거 처리 후 턴 종료")
	# 종료 트리거 처리… (여기서 메모리 변동 가능)
	turn.resolve_action_end()  # 종료 시점 메모리 복구로 턴 유지되는 케이스 반영
	if turn.phase == "END":    # resolve로 턴이 안 끝났으면 명시적 종료
		turn.end_turn()

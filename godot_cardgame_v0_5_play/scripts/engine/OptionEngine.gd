extends Node
class_name OptionEngine
# 옵션 카드의 메인/보안/딜레이 처리(간이)

# play_option: 메인 효과 실행, Delay면 보드에 남김
func play_option(card, owner, turn)->void:
	if card.has_meta("delay_effect"):
		card.stayed_on_board = true
		card.delay_ready_on_turn = owner.next_turn_index()
		owner.board.append(card)
		print("Option on board (Delay armed):", card.name)
	else:
		_apply_main_effect(card, owner, turn)
		owner.trash.append(card)

# 보안으로 오픈 시
func security_open(card, owner, turn)->void:
	if card.has_meta("security_effect"):
		_apply_security_effect(card, owner, turn)
	# 옵션은 기본 트래쉬
	owner.trash.append(card)

# 다음 내 턴 메인에서 발동 체크
func try_fire_delay(card, owner, is_my_main_phase:bool, turn)->bool:
	if not is_my_main_phase: return false
	if not card.stayed_on_board: return false
	if owner.is_turn_now() and owner.turn_index >= card.delay_ready_on_turn:
		if card.has_meta("delay_effect"):
			_apply_delay_effect(card, owner, turn)
			owner.board.erase(card)
			owner.trash.append(card)
			print("Delay fired:", card.name)
			return true
	return false

# === 내부 간이 효과들 ===
func _apply_main_effect(card, owner, turn)->void:
	# 필요시 effect parser와 연동
	if card.has_meta("gain_memory"):
		turn.add_memory(-int(card.get_meta("gain_memory"))) # 내쪽으로 당김

func _apply_security_effect(card, owner, turn)->void:
	if card.has_meta("security_gain_memory"):
		turn.add_memory(-int(card.get_meta("security_gain_memory")))

func _apply_delay_effect(card, owner, turn)->void:
	if card.has_meta("delay_gain_memory"):
		turn.add_memory(-int(card.get_meta("delay_gain_memory")))

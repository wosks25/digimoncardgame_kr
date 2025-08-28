extends Node
class_name KeywordEngine

signal blocked(attacker, blocker)

# 블로커: 상대가 공격 선언 → 블로커 레스트, 수비자 교체
func try_block(attacker, opponent_field:Array):
	for c in opponent_field:
		if "Blocker" in c.keywords and not c.suspended:
			c.suspended = true
			emit_signal("blocked", attacker, c)
			return c
	return null

# 재기동: 상대 턴 시작에 언스스펜드
func apply_reboot(owner_field:Array)->void:
	for c in owner_field:
		if "Reboot" in c.keywords and c.suspended:
			c.suspended = false

# 관통: 상대 디지몬 삭제 & 공격자 생존 → 보안 1장 체크
func apply_piercing(attacker, opponent_state)->void:
	if "Piercing" in attacker.keywords and attacker.alive:
		opponent_state.security_check(attacker, 1)

# Blitz(진격): 메모리가 상대쪽으로 넘어가도 "진화 직후" 1회 공격 가능
# - 진화 로직에서 진화 성공→메모리>0 판단→필요시 이 함수 호출하여 즉시 공격 선언
func try_blitz_attack(attacker, battle_mgr, opponent_state)->bool:
	if "Blitz" in attacker.keywords and attacker.can_attack():
		# 외부에서 공격 대상을 지정하도록 UI/로직 연동 필요
		# 여기선 샘플로 "플레이어 공격" 1회 실행
		battle_mgr.attack_player(attacker, opponent_state)
		return true
	return false

# Delay(딜레이): 보드에 남겨두었다가 "다음 내 턴 메인"에 발동
func arm_delay(option_card)->void:
	option_card.stayed_on_board = true
	option_card.delay_ready_on_turn = option_card.owner.next_turn_index()

func can_fire_delay(option_card, is_my_main_phase:bool)->bool:
	return is_my_main_phase and option_card.stayed_on_board and option_card.owner.is_turn_now()

func fire_delay(option_card)->void:
	if option_card.has_meta("delay_effect"):
		option_card.execute_delay()  # 카드 측에서 구현
	option_card.owner.trash.append(option_card)
	option_card.owner.board.erase(option_card)

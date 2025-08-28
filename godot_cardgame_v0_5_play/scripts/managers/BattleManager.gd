extends Node
class_name BattleManager

@export var keywords: Node         # KeywordEngine
@export var delete_mgr: Node       # DeletionManager
@export var turn: Node             # TurnManager

# 외부: 공격 선언 시 호출
func declare_attack(attacker, target, opponent_state)->void:
	# 1) 대상이 플레이어면 블로커 개입 기회 부여
	if typeof(target) == TYPE_DICTIONARY and target.get("is_player", false):
		# 상대 필드에서 블로커 탐색
		if keywords and keywords.has_method("try_block"):
			if keywords.try_block(attacker, opponent_state.field):
				# 블로커 개입 → 그 블로커와 배틀
				var blk = _last_blocker(opponent_state.field)
				if blk:
					digimon_vs_digimon(attacker, blk, opponent_state)
					return
		# 블로커 없으면 보안 공격
		attack_player(attacker, opponent_state)
		return
	# 2) 대상이 디지몬이면 일반 배틀
	digimon_vs_digimon(attacker, target, opponent_state)

func _last_blocker(field:Array):
	for i in range(field.size()-1, -1, -1):
		if "Blocker" in field[i].keywords and field[i].suspended:
			return field[i]
	return null

# 디지몬 대 디지몬
func digimon_vs_digimon(attacker, defender, opponent_state) -> void:
	if attacker.dp > defender.dp:
		if not delete_mgr.try_prevent_deletion(defender, {"type":"battle","opponent":true}):
			_delete(defender)
		if attacker.alive and keywords:
			keywords.apply_piercing(attacker, opponent_state)
	elif attacker.dp < defender.dp:
		if not delete_mgr.try_prevent_deletion(attacker, {"type":"battle","opponent":true}):
			_delete(attacker)
	else:
		if not delete_mgr.try_prevent_deletion(attacker, {"type":"battle","opponent":true}):
			_delete(attacker)
		if not delete_mgr.try_prevent_deletion(defender, {"type":"battle","opponent":true}):
			_delete(defender)

# 보안 체크
func attack_player(attacker, opponent_state) -> void:
	var checks: int = int(attacker.security_attack_bonus) + 1
	while checks > 0 and attacker.alive and opponent_state.security_size() > 0:
		opponent_state.security_check(attacker, 1)  # 카드 효과 내부에서 공격자 소멸 가능
		checks -= 1

func _delete(card) -> void:
	if not card.owner:
		return
	card.owner.trash.append(card)
	card.owner.field.erase(card)
	card.alive = false

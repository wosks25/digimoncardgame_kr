extends Node
class_name DeletionManager

# 외부에서 연결해 줄 것
@export var turn: Node = null  # TurnManager (메모리 조정용)

# 삭제 방지: Evade / Armor Purge / Decoy / Save / Material Save
# cause 예시: {"type":"battle"|"effect","opponent":true|false}
func try_prevent_deletion(card, cause:Dictionary) -> bool:
	# 1) Evade: 액티브에서 자신을 서스펜드하여 삭제 취소 (턴당 1회는 상위에서 관리 가능)
	if "Evade" in card.keywords and not card.suspended:
		card.suspended = true
		return true

	# 2) Armor Purge: 진화원이 있어야. 최상위 카드만 트래쉬 → 본체 생존
	if "Armor Purge" in card.keywords and card.has_sources():
		card.trash_top_source()
		return true

	# 3) Decoy: 상대 "효과"로 아군이 삭제될 때 자신이 대신 삭제
	if cause.get("type") == "effect" and cause.get("opponent", false):
		var decoy = _find_decoy_for(card)
		if decoy:
			_delete_immediately(decoy, {"type":"decoy"})
			return true

	# 4) Material Save X: 지정된 조건/장수의 "진화원"을 테이머 밑에 보존 (본체는 삭제)
	# - card.material_save = {"count":2,"filter":"XrosTag" or null}
	if card.has_meta("material_save"):
		var ms = card.get_meta("material_save")
		var cnt:int = int(ms.get("count", 0))
		if cnt > 0 and card.owner and card.owner.has_tamer():
			var sources := card.get_sources_filtered(ms.get("filter", null))  # 조건에 맞는 진화원
			var pick := min(cnt, sources.size())
			for i in range(pick):
				card.owner.save_under_tamer(sources[i], true) # true=진화원 저장
			# 본체는 계속 삭제 진행(이 함수에서는 방지 X)
			# → 상위 _delete_immediately에서 실제 이동
			# 주: OnDeletion은 본체에만 적용. Material Save는 본체 삭제 방지 아님

	# 5) Save: 본체를 테이머 밑으로 이동(진화원은 트래쉬)
	if "Save" in card.keywords and card.owner and card.owner.has_tamer():
		card.owner.save_under_tamer(card, false)  # false=본체 저장
		# 주: Save 적용 시 본체의 OnDeletion은 무효 취급(트래쉬에 없으므로)
		return true

	return false

func _find_decoy_for(card):
	if not card.owner:
		return null
	for ally in card.owner.field:
		if ally != card and "Decoy" in ally.keywords:
			return ally
	return null

# 실제 삭제 수행(트래쉬 이동 등)
func _delete_immediately(card, cause:Dictionary) -> void:
	# Overflow(ACE) 처리: 카드가 "필드/밑"에서 "다른 영역"으로 이동할 때 메모리 패널티
	if "Overflow" in card.keywords and card.has_meta("overflow_value") and turn and turn.has_method("add_memory"):
		var ov := int(card.get_meta("overflow_value"))
		# 규칙: 내가 가진 카드가 떠나면 "내 턴 기준" 메모리를 -ov (상대쪽으로 밀림)
		turn.add_memory(ov)  # add_memory는 +면 상대쪽(+): 이 엔진은 cost=+ 의미로 구현됨

	# 본체/진화원 이동
	if card.has_sources():
		for s in card.get_all_sources():
			card.owner.trash.append(s)
	card.owner.trash.append(card)
	card.owner.field.erase(card)
	card.alive = false

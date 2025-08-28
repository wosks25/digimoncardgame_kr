extends Node
class_name SecurityManager

# 간이 보안 스택 유틸 (본 예제에선 PlayerMock의 메서드가 있어 선택)
func add_to_security_top(player, card)->void:
	player.security.push_front(card)

func take_security_top(player)->Dictionary:
	if player.security.size()==0: return {}
	return player.security.pop_front()

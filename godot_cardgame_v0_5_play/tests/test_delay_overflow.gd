extends "res://addons/gut/test.gd"

var OptionEngine := preload("res://scripts/engine/OptionEngine.gd")
var Deletion := preload("res://scripts/engine/DeletionManager.gd")
var Turn := preload("res://scripts/managers/TurnManager.gd")
var Card := preload("res://scripts/ui/CardMock.gd")
var Player := preload("res://scripts/ui/PlayerMock.gd")

func test_delay_memory_gain():
	var opt = OptionEngine.new()
	var t = Turn.new(); t.start_game(1)
	var p = Player.new()
	var c = Card.new(); c.name="Booster"; c.owner=p; c.set_meta("delay_gain_memory", 2); c.set_meta("delay_effect", {"type":"Memory","value":2})
	opt.play_option(c, p, t)  # 보드에 남음
	p.turn_index = 1
	var fired = opt.try_fire_delay(c, p, true, t)
	assert_true(fired, "Delay 발동")
	assert_eq(t.memory, -2, "메모리 2 회복(내쪽)")

func test_overflow_penalty():
	var dm = Deletion.new()
	var t = Turn.new(); t.start_game(1); dm.turn = t
	var p = Player.new()
	var ace = Card.new(); ace.owner=p; ace.keywords=["Overflow"]; ace.set_meta("overflow_value", 4)
	p.field.append(ace)
	dm._delete_immediately(ace, {"type":"effect"})
	assert_true(t.memory > 0, "오버플로로 상대쪽으로 밀림(+4)")

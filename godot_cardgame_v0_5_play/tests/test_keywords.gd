extends "res://addons/gut/test.gd"

var DM := preload("res://scripts/engine/DeletionManager.gd")
var Card := preload("res://scripts/ui/CardMock.gd")
var Player := preload("res://scripts/ui/PlayerMock.gd")

func before_each():
	pass

func test_evade_prevents_deletion():
	var p = Player.new()
	var c = Card.new(); c.owner = p; c.keywords = ["Evade"]; c.suspended = false
	var dm = DM.new()
	var prevented = dm.try_prevent_deletion(c, {"type":"battle","opponent":true})
	assert_true(prevented, "Evade는 삭제를 막아야 함")
	assert_true(c.suspended, "Evade 사용 후 서스펜드")

func test_armor_purge():
	var p = Player.new()
	var c = Card.new(); c.owner=p; c.keywords=["Armor Purge"]
	var src = Card.new(); src.name="Under"; p.trash=[]
	c._sources=[src]
	var dm = DM.new()
	var prevented = dm.try_prevent_deletion(c,{"type":"battle","opponent":true})
	assert_true(prevented, "Armor Purge는 삭제 방지")
	assert_false(c.has_sources(), "최상위 진화원 제거")

extends "res://addons/gut/test.gd"

var Battle := preload("res://scripts/managers/BattleManager.gd")
var Keyword := preload("res://scripts/engine/KeywordEngine.gd")
var Deletion := preload("res://scripts/engine/DeletionManager.gd")
var Card := preload("res://scripts/ui/CardMock.gd")
var Player := preload("res://scripts/ui/PlayerMock.gd")

func test_last_unsuspended_blocker_used():
	var bm = Battle.new()
	bm.keywords = Keyword.new()
	bm.delete_mgr = Deletion.new()
	var atk_owner = Player.new()
	var p = Player.new()
	var blocker_active = Card.new(); blocker_active.keywords=["Blocker"]; blocker_active.owner=p
	var blocker_suspended = Card.new(); blocker_suspended.keywords=["Blocker"]; blocker_suspended.owner=p; blocker_suspended.suspended=true
	p.field = [blocker_suspended, blocker_active]
	var attacker = Card.new(); attacker.dp = 5000; attacker.owner = atk_owner
	bm.declare_attack(attacker, {"is_player":true}, p)
	assert_true(blocker_active in p.trash, "활성 블로커가 배틀 후 트래쉬로 이동")
	assert_true(blocker_suspended in p.field, "기존 서스펜드 블로커는 남아야 함")

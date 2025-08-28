extends Node
class_name GameManager

@export var turn: Node
@export var battle: Node
@export var keyword: Node
@export var deletion: Node

var data_loader := preload("res://scripts/data/DataLoader.gd").new()
var effect_parser := preload("res://scripts/engine/EffectParser.gd").new()

var p1
var p2

func _ready():
	# 플레이어 생성
	p1 = preload("res://scripts/ui/PlayerMock.gd").new(); p1.id=1
	p2 = preload("res://scripts/ui/PlayerMock.gd").new(); p2.id=2
	# 카드 로드(샘플)
	var arr = data_loader.load_cards("res://scripts/data/cards.json")
	if arr.size()>0:
		var c1 = data_loader.create_card_from_dict(arr[0]); c1.owner=p1; p1.field.append(c1)
		var c2 = data_loader.create_card_from_dict(arr[1]); c2.owner=p2; p2.field.append(c2)
		# 보안 2장 세팅
		p2.security.append({"name":"Sec1","dp":3000})
		p2.security.append({"name":"Sec2","dp":4000})
	print("GameManager ready: P1 field=%d, P2 field=%d" % [p1.field.size(), p2.field.size()])

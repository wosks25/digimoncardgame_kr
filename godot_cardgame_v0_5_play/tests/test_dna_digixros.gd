extends "res://addons/gut/test.gd"

var DNA := preload("res://scripts/engine/DNAEngine.gd")
var XROS := preload("res://scripts/engine/DigiXrosEngine.gd")
var Card := preload("res://scripts/ui/CardMock.gd")
var Player := preload("res://scripts/ui/PlayerMock.gd")

func test_dna_basic():
	var dna = DNA.new()
	var p = Player.new()
	var a = Card.new(); a.set_meta("level",4); a.set_meta("color","Blue"); a.owner=p; p.field.append(a)
	var b = Card.new(); b.set_meta("level",4); b.set_meta("color","Green"); b.owner=p; p.field.append(b)
	var res = Card.new(); res.name="Paildramon"
	var out = dna.perform_dna(a, b, {"levels":[4,4],"colors":["Blue","Green"],"result_card":res,"result_level":5}, p)
	assert_true(out!=null and out.name=="Paildramon", "DNA 결과 카드 생성")

func test_xros_reduce():
	var x = XROS.new()
	var hand = []; var field=[]
	var r = Card.new(); r.name="ShoutmonX4"
	var s1 = Card.new(); s1.name="Shoutmon"; hand.append(s1)
	var s2 = Card.new(); s2.name="Ballistamon"; field.append(s2)
	var picked = x.choose_xros_sources(hand, field, {"tags":["Shoutmon","Ballistamon"]})
	var reduce = x.apply_xros(r, picked, {"reduce_per":2})
	assert_eq(reduce, 4, "Xros 총 감소치 4")
	assert_eq(r.get_all_sources().size(), 2, "결과 카드 진화원 2장")

extends Control
class_name GameController

@onready var lbl_turn:Label = $UI/TopBar/LblTurn
@onready var lbl_mem:Label = $UI/TopBar/LblMem
@onready var mem_bar:HSlider = $UI/HBox/Board/Memory/MemBar
@onready var op_raising = $UI/HBox/Board/RowOpRaising/OpRaising
@onready var op_sec = $UI/HBox/Board/RowOpSec/OpSec
@onready var op_battle = $UI/HBox/Board/RowOpBattle/OpBattle
@onready var my_battle = $UI/HBox/Board/RowMyBattle/MyBattle
@onready var my_hand = $UI/HBox/Board/RowMyHand/MyHand
@onready var my_raising = $UI/HBox/Board/RowMyRaising/MyRaising
@onready var stack_list:ItemList = $UI/HBox/Sidebar/StackList
@onready var zoom_text:RichTextLabel = $UI/HBox/Sidebar/ZoomText
@onready var btn_end:Button = $UI/HBox/Sidebar/BtnEnd

var CardViewScene := preload("res://scenes/CardView.tscn")

var db:Dictionary = {}
var p1:Dictionary = {"hand":[], "battle":[], "security":[], "deck":[], "raising":[], "tamers":[], "name":"P1"}
var p2:Dictionary = {"hand":[], "battle":[], "security":[], "deck":[], "raising":[], "tamers":[], "name":"P2"}
var active:Dictionary
var nonactive:Dictionary

var engine := RuleEngine.new()

func _ready():
	add_to_group("game_controller")
	active = p1
	nonactive = p2
	_load_db()
	_setup_demo_decks()
	_deal_start_state()
	_deploy_level3(p1)
	_deploy_level3(p2)
	var tamer = _card_by_id("ST1-16")
	tamer["cost_mod"] = {"evo_reduce":1, "play_reduce":1}
	var arr := active.get("tamers", [])
	arr.append(tamer)
	active["tamers"] = arr
	engine.start_turn(true)
	btn_end.pressed.connect(_end_turn)
	_refresh_all()

func _load_db():
	var f = FileAccess.open("res://data/cards_kr.sample.json", FileAccess.READ)
	if f:
		db = JSON.parse_string(f.get_as_text())
	else:
		db = {"cards":[]}

func _card_by_id(cid:String) -> Dictionary:
	for c in db.get("cards", []):
		if str(c.get("id","")) == cid:
			return c.duplicate(true)
	return {}

func _setup_demo_decks():
	var d := {"BT1-010":4, "BT1-015":3, "BT1-020":2, "BT1-025":1, "ST1-16":2, "BT1-099":1}
	var egg := {"EGG-001":1}
	p1["deck"] = _build_deck(d)
	p2["deck"] = _build_deck(d)
	p1["egg"] = _build_deck(egg)
	p2["egg"] = _build_deck(egg)

func _build_deck(map:Dictionary) -> Array:
	var arr:Array = []
	for cid in map.keys():
		var n := int(map.get(cid,0))
		var c := _card_by_id(cid)
		for i in range(n):
			arr.append(c.duplicate(true))
	arr.shuffle()
	return arr

func _deal_start_state():
	for P in [p1,p2]:
		var egg_arr := P.get("egg", [])
		if egg_arr.size() > 0:
			var raising := P.get("raising", [])
			raising.append(egg_arr.pop_back())
			P["raising"] = raising
			P["egg"] = egg_arr
		var deck := P.get("deck", [])
		var sec := []
		for i in range(5):
			if deck.size()>0:
				sec.append(deck.pop_back())
		P["security"] = sec
		var hand := []
		for i in range(5):
			if deck.size()>0:
				hand.append(deck.pop_back())
		P["hand"] = hand
		P["battle"] = []
		P["tamers"] = []
		P["trash"] = []
		P["deck"] = deck

func _deploy_level3(P:Dictionary):
	var hand := P.get("hand", [])
	var battle := P.get("battle", [])
	for i in range(hand.size()):
		var c = hand[i]
		if str(c.get("type","")) == "Digimon" and int(c.get("level",0))==3 and battle.size()<1:
			battle.append(hand.pop_at(i))
			P["hand"] = hand
			P["battle"] = battle
			return

func _make_card(c:Dictionary, z:String, i:int) -> Node:
	var cv = CardViewScene.instantiate()
	cv.setup(c, z, i)
	cv.pressed.connect(func():
		_update_zoom(c)
	)
	return cv

func _refresh_all():
	lbl_turn.text = "턴: %s" % ("P1" if active==p1 else "P2")
	lbl_mem.text = "메모리: %d | 페이즈: %s" % [engine.memory, engine.phase]
	mem_bar.value = engine.memory
	for cont in [op_raising, op_sec, op_battle, my_battle, my_hand, my_raising]:
		for n in cont.get_children():
			n.queue_free()

	var r_op := nonactive.get("raising", [])
	for i in range(r_op.size()):
		var v = _make_card(r_op[i], "raising_op", i)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		op_raising.add_child(v)
	var s_op := nonactive.get("security", [])
	for i in range(s_op.size()):
		var v2 = _make_card(s_op[i], "security", i)
		v2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		op_sec.add_child(v2)
	var b_op := nonactive.get("battle", [])
	for i in range(b_op.size()):
		var co = b_op[i]
		var v3 = _make_card(co, "battle_op", i)
		# allow being a drop target for attack
		v3.set_drag_forwarding(this)
		v3.drop_data = func(at_pos, data):
			try_attack_drag(int(data.get("attacker_index",-1)), "digimon", i)
		v3.can_drop_data = func(at_pos, data):
			return data is Dictionary and data.get("type","")=="attack_from_battle"
		op_battle.add_child(v3)

	var b_me := active.get("battle", [])
	for i in range(b_me.size()):
		var c = b_me[i]
		var vm = _make_card(c, "battle_me", i)
		my_battle.add_child(vm)

	var h_me := active.get("hand", [])
	for i in range(h_me.size()):
		var ch = h_me[i]
		var vh = _make_card(ch, "hand", i)
		my_hand.add_child(vh)

	var r_me := active.get("raising", [])
	for i in range(r_me.size()):
		var cr = r_me[i]
		var vr = _make_card(cr, "raising_me", i)
		my_raising.add_child(vr)

	_refresh_stack()

func _refresh_stack():
	stack_list.clear()
	for e in engine.stack:
		var eff = e.get("eff",{})
		stack_list.add_item("%s : %s %s" % [e.get("source","?"), str(eff.get("op","?")), str(eff.get("value",""))])

func _update_zoom(c:Dictionary):
	var txt = "[b]%s[/b] [%s]\nL%d %s\n\n%s" % [c.get("name_ko",""), c.get("id",""), int(c.get("level",0)), str(c.get("dp","")), c.get("text_ko","")]
	var kws := c.get("keywords", [])
	if kws.size()>0:
		txt += "\n키워드: " + ", ".join(kws)
	for e in c.get("evolve", []):
		txt += "\n진화비용(L%d→): %d%s" % [int(e.get("from_level",0)), int(e.get("cost",0)), " (감소불가)" if bool(e.get("no_cost_reduce",false)) else ""]
	if c.has("play_cost"):
		txt += "\n등장비용: %d%s" % [int(c.get("play_cost",0)), " (감소불가)" if bool(c.get("no_cost_reduce_play",false)) else ""]
	zoom_text.text = txt

# ----- Drag handlers -----
func _container_can_drop_play(data):
	return data is Dictionary and data.get("type","") == "card_from_hand"

func _container_drop_play(data):
	try_play_drag(data.get("card", {}))

func _ready_make_containers_draggable():
	# Forward drops for play/evolve/attack via containers themselves
	my_battle.can_drop_data = func(at_pos, data):
		return _container_can_drop_play(data)
	my_battle.drop_data = func(at_pos, data):
		_container_drop_play(data)
	op_sec.can_drop_data = func(at_pos, data):
		return data is Dictionary and data.get("type","") == "attack_from_battle"
	op_sec.drop_data = func(at_pos, data):
		try_attack_drag(int(data.get("attacker_index",-1)), "security", -1)

func _notification(what):
	if what == NOTIFICATION_READY:
		_ready_make_containers_draggable()

# ----- Rules glue -----
func try_play_drag(hand_card:Dictionary):
	var hand := active.get("hand", [])
	if not hand.has(hand_card):
		return
	hand.erase(hand_card)
	active["hand"] = hand
	var res = engine.play_card(active, hand_card, active==p1)
	var ctx = res.get("ctx", {})
	ctx["_draw_cb"] = func(n:int):
		_draw(n)
	engine.resolve_triggers(ctx, res.get("ordered", []))
	_refresh_all()

func try_evolve_drag(hand_card:Dictionary, base_idx:int):
	var b := active.get("battle", [])
	if base_idx < 0 or base_idx >= b.size():
		return
	var base := b[base_idx]
	if int(base.get("level",0)) + 1 != int(hand_card.get("level",0)):
		return
	var res = engine.evolve(active, base_idx, hand_card, active==p1)
	var hand := active.get("hand", [])
	hand.erase(hand_card)
	active["hand"] = hand
	var ctx = res.get("ctx", {})
	ctx["_draw_cb"] = func(n:int):
		_draw(n)
	engine.resolve_triggers(ctx, res.get("ordered", []))
	_refresh_all()

func try_attack_drag(attacker_index:int, target_type:String, target_index:int):
	var b := active.get("battle", [])
	if attacker_index < 0 or attacker_index >= b.size():
		return
	var attacker := b[attacker_index]
	engine.phase = "Attack"
	var ctx := {"checks":1, "dp_bonus":0, "attacker_idx": attacker_index}
	var kws := attacker.get("keywords", [])
	if "보안 공격 +1" in kws:
		ctx["checks"] = int(ctx["checks"]) + 1
	ctx["_draw_cb"] = func(n:int):
		_draw(n)
	var ordered = engine.collect_when_attacking("battle", attacker, active)
	engine.resolve_triggers(ctx, ordered)
	if target_type == "security":
		_resolve_security(ctx)
	elif target_type == "digimon":
		_resolve_digimon_battle(ctx, target_index)
	_refresh_all()

func _resolve_security(ctx:Dictionary):
	var checks := max(1, int(ctx.get("checks",1)))
	var sec := nonactive.get("security", [])
	for i in range(checks):
		if sec.size() == 0:
			break
		sec.pop_back()
	nonactive["security"] = sec

func _resolve_digimon_battle(ctx:Dictionary, op_index:int):
	var b_me := active.get("battle", [])
	var b_op := nonactive.get("battle", [])
	if op_index < 0 or op_index >= b_op.size():
		return
	var atk := b_me[ctx.get("attacker_idx",0)]
	var def := b_op[op_index]
	var adp := int(atk.get("dp",0)) + int(ctx.get("dp_bonus",0))
	var ddp := int(def.get("dp",0))
	if adp > ddp:
		var tr := nonactive.get("trash", [])
		tr.append(def)
		b_op.remove_at(op_index)
		nonactive["trash"] = tr
	elif adp < ddp:
		var tr2 := active.get("trash", [])
		tr2.append(atk)
		b_me.remove_at(int(ctx.get("attacker_idx",0)))
		active["trash"] = tr2
	else:
		var tr3 := nonactive.get("trash", [])
		tr3.append(def)
		b_op.remove_at(op_index)
		nonactive["trash"] = tr3
		var tr4 := active.get("trash", [])
		tr4.append(atk)
		b_me.remove_at(int(ctx.get("attacker_idx",0)))
		active["trash"] = tr4
	active["battle"] = b_me
	nonactive["battle"] = b_op

func _draw(n:int):
	var deck := active.get("deck", [])
	var hand := active.get("hand", [])
	for i in range(n):
		if deck.size()>0:
			hand.append(deck.pop_back())
	active["deck"] = deck
	active["hand"] = hand

func _end_turn():
	var tmp := active
	active = nonactive
	nonactive = tmp
	engine.start_turn(active == p1)
	_refresh_all()

extends Node

@onready var turn = $TurnManager
@onready var battle = $BattleManager
@onready var keyword = $KeywordEngine
@onready var log_label:Label = $UI/Log

# 플레이어/카드 더미(샘플)
var p1
var p2
var agumon
var magnamon

func _ready():
	print("Digimon Rule Engine – Main Loaded")
	# 버튼 연결
	$UI/PassBtn.pressed.connect(_on_pass)
	$UI/MemPlusBtn.pressed.connect(_on_mem_plus)
	$UI/MemMinusBtn.pressed.connect(_on_mem_minus)
	$UI/BattleBtn.pressed.connect(_on_battle)
	# 샘플 더미 세팅
	_setup_dummy()

func _setup_dummy():
	p1 = preload("res://scripts/ui/PlayerMock.gd").new()
	p2 = preload("res://scripts/ui/PlayerMock.gd").new()
	agumon = preload("res://scripts/ui/CardMock.gd").new()
	agumon.name = "Agumon"
	agumon.dp = 2000
	agumon.keywords = ["Reboot"]
	agumon.owner = p1
	p1.field.append(agumon)

	magnamon = preload("res://scripts/ui/CardMock.gd").new()
	magnamon.name = "Magnamon X"
	magnamon.dp = 11000
	magnamon.keywords = ["Armor Purge","Blocker","Piercing"]
	magnamon.owner = p2
	p2.field.append(magnamon)

	# 보안에 간단 카드 1장
	var sec = {"name":"SecMon","dp":3000} # 디지몬 취급
	p2.security.append(sec)

	log_label.text = "P1:Agumon(2k) | P2:MagnamonX(11k, Blocker,Piercing)\n"

func _on_pass():
	turn.end_turn(true)
	_log("PASS → P%d turn" % turn.active_player)

func _on_mem_plus():
	turn.add_memory(1)
	_log("MEM %+d = %d" % [1, turn.memory])

func _on_mem_minus():
	turn.add_memory(-1)
	_log("MEM %+d = %d" % [-1, turn.memory])

func _on_battle():
	# 공격 선언: P1 Agumon → P2(플레이어)
	_log("Declare attack: Agumon -> Player2 (Blocker check)")
	battle.declare_attack(agumon, {"is_player":true}, p2)
	turn.resolve_action_end()
	if not agumon.alive:
		_log("Agumon deleted.")
	if p2.security_size() == 0:
		_log("Security exhausted!")

func _log(t:String)->void:
	log_label.text += t + "\n"
	print(t)

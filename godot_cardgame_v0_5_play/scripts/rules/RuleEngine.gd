class_name RuleEngine
extends Node

var memory:int = 3
var phase:String = "Main"
var stack:Array = []

func start_turn(p1_turn:bool) -> void:
    phase = "Main"
    if p1_turn:
        memory = 3
    else:
        memory = -3
    stack.clear()

func get_cost_modifiers(active_state:Dictionary) -> Dictionary:
    var mod := {"play_reduce":0, "evo_reduce":0}
    for t in active_state.get("tamers", []):
        var cm := t.get("cost_mod", {})
        mod["evo_reduce"] += int(cm.get("evo_reduce", 0))
        mod["play_reduce"] += int(cm.get("play_reduce", 0))
    return mod

func _apply_cost(cost:int, reducible:bool, reduce_amount:int, no_cost_reduce:bool, actor_is_p1:bool) -> int:
    var final_cost := cost
    if reducible and not no_cost_reduce:
        final_cost = max(0, cost - reduce_amount)
    if actor_is_p1:
        memory -= final_cost
    else:
        memory += final_cost
    return final_cost

func effect_allowed(zone:String, card:Dictionary) -> bool:
    if zone == "raising":
        var kws := card.get("keywords", [])
        return "육성" in kws
    return true

func collect_on_play(zone:String, card:Dictionary, active_state:Dictionary) -> Array:
    var trigs:Array = []
    if not effect_allowed(zone, card):
        return trigs
    var timings := card.get("timings", {})
    if "onPlay" in timings:
        for eff in timings["onPlay"]:
            trigs.append({"source": card.get("name_ko",""), "eff": eff})
    return trigs

func collect_when_attacking(zone:String, card:Dictionary, active_state:Dictionary) -> Array:
    var trigs:Array = []
    if not effect_allowed(zone, card):
        return trigs
    var timings := card.get("timings", {})
    if "whenAttacking" in timings:
        for eff in timings["whenAttacking"]:
            trigs.append({"source": card.get("name_ko",""), "eff": eff})
    for t in active_state.get("tamers", []):
        var tt := t.get("timings", {})
        if "whenAttacking" in tt and tt["whenAttacking"].size() > 0:
            trigs.append({"source": t.get("name_ko",""), "eff": tt["whenAttacking"][0]})
    return trigs

func collect_when_digivolving(zone:String, card:Dictionary, active_state:Dictionary) -> Array:
    var trigs:Array = []
    if not effect_allowed(zone, card):
        return trigs
    var timings := card.get("timings", {})
    if "whenDigivolving" in timings:
        for eff in timings["whenDigivolving"]:
            trigs.append({"source": card.get("name_ko",""), "eff": eff})
    return trigs

func resolve_triggers(ctx:Dictionary, ordered:Array) -> void:
    stack.clear()
    for e in ordered:
        stack.append(e)
    while stack.size() > 0:
        var ent = stack.pop_front()
        _apply_effect(ctx, ent.get("eff", {}))

func _apply_effect(ctx:Dictionary, eff:Dictionary) -> void:
    var op := str(eff.get("op",""))
    match op:
        "draw":
            if ctx.has("_draw_cb"):
                ctx["_draw_cb"].call(int(eff.get("value",1)))
        "gain_memory":
            memory += int(eff.get("value",0))
        _:
            pass

func play_card(active_state:Dictionary, hand_card:Dictionary, actor_is_p1:bool) -> Dictionary:
    var cost := int(hand_card.get("play_cost", 0))
    var reducible := true
    var no_reduce_flag := bool(hand_card.get("no_cost_reduce_play", false))
    var free_play := bool(hand_card.get("free_play", false))
    var mod := get_cost_modifiers(active_state)
    var paid:int = 0
    if not free_play:
        paid = _apply_cost(cost, reducible, int(mod.get("play_reduce",0)), no_reduce_flag, actor_is_p1)
    var tp := str(hand_card.get("type",""))
    if tp == "Tamer":
        var arr := active_state.get("tamers", [])
        arr.append(hand_card)
        active_state["tamers"] = arr
        var ctx_t := {}
        var ord_t := collect_on_play("battle", hand_card, active_state)
        return {"ctx":ctx_t, "ordered":ord_t, "paid":paid}
    elif tp == "Digimon":
        var arr2 := active_state.get("battle", [])
        arr2.append(hand_card)
        active_state["battle"] = arr2
        var ctx := {}
        var ord := collect_on_play("battle", hand_card, active_state)
        return {"ctx":ctx, "ordered":ord, "paid":paid}
    return {"ctx":{}, "ordered":[], "paid":paid}

func evolve(active_state:Dictionary, base_idx:int, evo_card:Dictionary, actor_is_p1:bool) -> Dictionary:
    var battle := active_state.get("battle", [])
    if base_idx < 0 or base_idx >= battle.size():
        return {"ctx":{}, "ordered":[], "paid":0}
    var base := battle[base_idx]
    var evo_cost := 0
    var reducible := true
    var no_reduce_flag := bool(evo_card.get("no_cost_reduce", false))
    for e in evo_card.get("evolve", []):
        if int(e.get("from_level",-1)) == int(base.get("level",0)):
            evo_cost = int(e.get("cost",0))
            reducible = not bool(e.get("no_cost_reduce", false))
            break
    var mod := get_cost_modifiers(active_state)
    var paid := _apply_cost(evo_cost, reducible, int(mod.get("evo_reduce",0)), no_reduce_flag, actor_is_p1)
    battle[base_idx] = evo_card
    active_state["battle"] = battle
    var ctx := {"idx":base_idx}
    var ordered := collect_when_digivolving("battle", evo_card, active_state)
    return {"ctx":ctx, "ordered":ordered, "paid":paid}

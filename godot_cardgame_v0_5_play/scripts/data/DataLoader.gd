extends Node
class_name DataLoader

func load_cards(path:String)->Array:
	var f = FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("cards.json not found: " + path)
		return []
	var txt = f.get_as_text()
	var arr = JSON.parse_string(txt)
	if typeof(arr) != TYPE_ARRAY:
		push_error("cards.json parse error")
		return []
	return arr

func create_card_from_dict(d:Dictionary)->Node:
	var c = preload("res://scripts/ui/CardMock.gd").new()
	c.name = d.get("name","Card")
	c.dp = int(d.get("dp", 0))
	c.keywords = d.get("keywords", [])
	if d.has("level"): c.set_meta("level", d["level"])
	if d.has("color"): c.set_meta("color", d["color"])
	# Overflow 표기 예: {"overflow":4}
	if d.has("overflow"):
		c.keywords.append("Overflow")
		c.set_meta("overflow_value", int(d["overflow"]))
	# Delay/Option 예시 메타
	if d.has("delay_gain_memory"):
		c.set_meta("delay_effect", {"type":"Memory","value": int(d["delay_gain_memory"])})
		c.set_meta("delay_gain_memory", int(d["delay_gain_memory"]))
	return c

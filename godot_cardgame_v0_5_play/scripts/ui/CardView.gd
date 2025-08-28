extends PanelContainer
class_name CardView

var card:Dictionary = {}
var zone:String = ""
var index:int = -1

@onready var art:TextureRect = $VBox/Art
@onready var name_lbl:Label = $VBox/Name
@onready var stats_lbl:Label = $VBox/Stats

func setup(c:Dictionary, z:String, i:int) -> void:
    card = c
    zone = z
    index = i
    name_lbl.text = str(c.get("name_ko",""))
    var lvl:int = int(c.get("level",0))
    var dp:String = str(c.get("dp",""))
    stats_lbl.text = "L%d %s" % [lvl, dp]
    var cid = str(c.get("id",""))
    var path = "res://assets/cards/%s.png" % cid
    if not ResourceLoader.exists(path):
        path = "res://assets/cards/_placeholder.png"
    art.texture = load(path)

func _gui_input(e):
    if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
        # help zoom by emitting pressed; controller connects to it when needed
        emit_signal("pressed")

signal pressed

func get_drag_data(at_position):
    if zone == "hand":
        var data = {"type":"card_from_hand", "card":card}
        set_drag_preview(duplicate())
        return data
    if zone == "battle_me":
        var data2 = {"type":"attack_from_battle", "attacker_index": index, "card":card}
        set_drag_preview(duplicate())
        return data2
    return null

func can_drop_data(at_position, data):
    if zone == "battle_me" and data is Dictionary and data.get("type","") == "card_from_hand":
        return true
    return false

func drop_data(at_position, data):
    if can_drop_data(at_position, data):
        var ctrl = get_tree().get_first_node_in_group("game_controller")
        if ctrl:
            ctrl.call("try_evolve_drag", data.get("card", {}), self.index)

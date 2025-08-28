extends Control
@onready var btn_play:Button = $Margin/VBox/Buttons/BtnPlay
@onready var btn_exit:Button = $Margin/VBox/Buttons/BtnExit
func _ready():
    btn_play.pressed.connect(_on_play)
    btn_exit.pressed.connect(get_tree().quit)
func _on_play():
    get_tree().change_scene_to_file("res://scenes/GameBoard.tscn")

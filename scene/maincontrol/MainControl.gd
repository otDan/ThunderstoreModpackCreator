extends Control

func _ready():
	get_tree().root.connect("size_changed", self, "_resizeHandler")

func _resizeHandler():
	rect_size = get_viewport_rect().size

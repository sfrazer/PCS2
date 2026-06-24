extends CanvasLayer


@onready var _label: Label = $Label


func _process(_delta: float) -> void:
	var fps: int = Engine.get_frames_per_second()
	var version: String = str(ProjectSettings.get_setting("application/config/version"))
	_label.text = "FPS: %d  v%s" % [fps, version]

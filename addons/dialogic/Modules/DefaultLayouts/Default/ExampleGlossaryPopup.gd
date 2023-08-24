extends Control

func _ready() -> void:
	hide()
	Dialogic.Text.animation_textbox_hide.connect(hide)

func _process(delta) -> void:
	if visible:
		global_position = get_global_mouse_position()

func _on_dialogic_display_dialog_text_meta_hover_started(meta:String) -> void:
	var info :Dictionary = Dialogic.Glossary.get_entry(meta)
	if info:
		show()
		$Panel/VBox/Title.text = info.get('title', '')
		$Panel/VBox/Text.text = info.get('text', '')
		$Panel/VBox/Extra.text = '[right]'+info.get('extra', '')
		modulate = info.get('color', Color.WHITE)#.darkened(0.5)
		global_position = get_global_mouse_position()

func _on_dialogic_display_dialog_text_meta_hover_ended(meta:String) -> void:
	hide()

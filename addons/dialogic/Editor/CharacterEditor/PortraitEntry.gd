@tool
extends HBoxContainer

var editor_reference
var character_editor_reference

var portrait_data = {}

func load_data(name: String, data:Dictionary, char_edi_reference:Control) -> void:
	$NameEdit.text = name
	$PathEdit.text = data.get('path', '')
	portrait_data = data
	character_editor_reference = char_edi_reference

func get_portrait_name() -> String:
	return $NameEdit.text

func _ready() -> void:
	$ButtonDelete.icon = get_theme_icon("Remove", "EditorIcons")
	$ButtonSelect.icon = get_theme_icon("ListSelect", "EditorIcons")

func _on_ButtonDelete_pressed() -> void:
	character_editor_reference.update_portrait_preview()
	queue_free()

func _on_ButtonSelect_pressed() -> void:
	find_parent('EditorView').godot_file_dialog(self,'_on_file_selected', "*.png, *.svg, *.tscn")

func _on_file_selected(path:String) -> void:
	$PathEdit.text = path
	portrait_data.path = path
	if $NameEdit.text == '':
		$NameEdit.text = path.get_file().trim_suffix("."+path.get_extension())
	update_preview()

func _on_focus_entered() -> void:
	update_preview()

func update_preview() -> void:
	character_editor_reference.update_portrait_preview(self)

func visual_focus():
	modulate = get_theme_color("warning_color", "Editor")

func visual_defocus():
	modulate = Color(1,1,1,1)

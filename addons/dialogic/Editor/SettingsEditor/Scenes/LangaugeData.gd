tool
extends VBoxContainer

const SECTION_NAME := "multilang"
const IS_ENABLED_NAME := "enabled"
const LIST_NAME := "list"
const DEFAULT_NAME := "default"

export(bool) var is_default:bool
var data:Dictionary setget _setdata
var _pending:bool = false

var nodes:Dictionary

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	nodes = {
		"label" : $label,
		"dname" : $settings1/display_name,
		"delete": $settings1/btn_delete,
		"icon"  : $settings1/btn_icon,

	}
	if is_default:
		#hide settings not applicable to default language
		nodes["delete"].disabled = true
		
func _setdata(value:Dictionary):
	data = value
	nodes["dname"].text = data["display"]
	pass

### Since data may change rapidly, we don't want to load alter and save the
### configuration several times per secund. 
### This function tells Godot to wait 2 secunds before saving data.
func _data_changed():
	if _pending:
		return
	_pending = true
	yield(get_tree().create_timer(2), "_save")

func _save():
	if is_default:
		DialogicResources.set_settings_value(SECTION_NAME, DEFAULT_NAME, data)
	else:
		var list:Dictionary = DialogicResources.get_settings_value(SECTION_NAME, LIST_NAME, {})
		list[data["internal"]] = data
		DialogicResources.set_settings_value(SECTION_NAME, LIST_NAME, list)
	_pending = false

func _on_display_name_text_changed(new_text:String):
	data["display"] = new_text
	_data_changed()

func _on_btn_delete_pressed():
	#TODO: add warning
	if is_default:
		return #illegal to remove default data
	var list:Dictionary = DialogicResources.get_settings_value(SECTION_NAME, LIST_NAME, {})
	list.erase(data["internal"])
	DialogicResources.set_settings_value(SECTION_NAME, LIST_NAME, list)
	get_parent().remove_child(self)
	queue_free()

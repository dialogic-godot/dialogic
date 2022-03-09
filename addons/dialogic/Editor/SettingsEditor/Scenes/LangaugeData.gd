tool
extends VBoxContainer

const SECTION_NAME := "multilang"
const IS_ENABLED_NAME := "enabled"
const LIST_NAME := "list"
const DEFAULT_NAME := "default"

export(bool) var is_default:bool
var data:Dictionary setget _setdata
var _pending:bool = false
var _ptime:float = 0

var nodes:Dictionary

func _enter_tree():
	nodes = {
		"label" : $Label,
		"dname" : $settings1/display_name,
		"delete": $settings1/btn_delete,
		"icon"  : $settings1/btn_icon,
		"voice" : $settings2/btn_voice,

	}
	if is_default:
		#hide settings not applicable to default language
		nodes["delete"].disabled = true
		#note to maintainers: self keyword allows the (otherwise bypassed) use of the data property's setter function.
		self.data = DialogicResources.get_settings_value(SECTION_NAME, DEFAULT_NAME, {
			#default data for default language
			"internal" : "DEFAULT", #this internal name is not acually used anywhere, just kept for consitancy.
			"display" : "english", #fair presumtion
			"use_default_voice" : true, #this setting would not matter any way for default.
		})
		nodes["dname"].hint_tooltip = "Set the display-name of the default lanaguge.\nThis is only used in the editor itself."
	else:
		nodes["dname"].hint_tooltip = "Set the display-name of the "+data.get("internal", "[MISSING]")+" lanaguge.\nThis is only used in the editor itself."
	var voice_enabled = DialogicResources.get_settings_value("dialog", "text_event_audio_enable", false)
	nodes["voice"].visible = voice_enabled && not is_default

		
func _setdata(value:Dictionary):
	data = value
	$settings1/display_name.text = data["display"]
	$Label.text = data["internal"]
	$settings2/btn_voice.pressed = data["use_default_voice"]

### Since data may change rapidly, we don't want to load alter and save the
### configuration several times per secund. 
### This function tells Godot to wait 2 secunds before saving data.
func _data_changed():
	if _pending:
		return
	_pending = true
	_ptime = 2

func _process(delta:float):
	if(_pending):
		_ptime -= delta
		if _ptime <= 0:
			save()

func save():
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

func _on_btn_voice_toggled(value:bool):
	data["use_default_voice"] = value
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

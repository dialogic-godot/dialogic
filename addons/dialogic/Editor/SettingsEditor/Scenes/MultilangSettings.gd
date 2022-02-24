tool
extends VBoxContainer

const SECTION_NAME := "multilang"
const IS_ENABLED_NAME := "enabled"
const LIST_NAME := "list"
const DEFAULT_NAME := "default"

var nodes := {}
var new_lang_name := ""

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	nodes = {
		"enable" : $MultilangBox/EnableMultilangSupport,
		"settings" : $settings,
		"lang_sec": $settings/languages,
		"lang_list": $settings/languages/list,
		"newname" : $settings/newlang/NewName,
		"btnAddnew":$settings/newlang/btnAddnew,
		"default" : $settings/DefaultNameBox,
		"template": $settings/languages/template
	}
	#DialogicResources.get_settings_value(section_name, list_name, [])
	refresh()
func refresh():
	var is_enabled:bool = DialogicResources.get_settings_value(SECTION_NAME, IS_ENABLED_NAME, false)
	(nodes["enable"] as CheckBox).pressed = is_enabled
	nodes["settings"].visible = is_enabled
	for n in nodes["lang_list"].get_children():
		nodes["lang_list"].remove_child(n)
		n.queue_free()
	var list:Dictionary = DialogicResources.get_settings_value(SECTION_NAME, LIST_NAME, {})
	for l in list:
		addLanguageBox(l)
func addLanguageBox(data):
	var n = nodes["template"].duplicate()
	nodes["lang_list"].add_child(n)
	#TODO: set data



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_EnableMultilangSupport_toggled(value):
	var is_enabled:bool = value
	nodes["settings"].visible = is_enabled
	DialogicResources.set_settings_value(SECTION_NAME, IS_ENABLED_NAME, is_enabled)

func _on_NewName_text_changed(new_text):
	new_lang_name = new_text
	_correct_newlang_name()

func _correct_newlang_name():
	var caret:int = nodes["newname"].caret_position
	new_lang_name = new_lang_name.replace(" ", "_")
	nodes["newname"].text = new_lang_name
	nodes["newname"].caret_position = caret

func _on_NewName_text_entered(new_text):
	_on_NewName_text_changed(new_text)
	_on_btnAddnew_pressed()


func _on_btnAddnew_pressed():
	new_lang_name = new_lang_name.replace(" ", "_")
	var list:Dictionary = DialogicResources.get_settings_value(SECTION_NAME, LIST_NAME, {})
	if list.has(new_lang_name):
		return
	nodes["newname"].text = ""
	#NOTE: much data could be included here.
	var langdata = {
		"internal" : new_lang_name,
		"display" : new_lang_name,
		"icon" : null,
		"use_default_voice" : true,
	}
	list[new_lang_name] = langdata
	DialogicResources.set_settings_value(SECTION_NAME, LIST_NAME, langdata)


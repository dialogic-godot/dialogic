tool
extends Control

const SECTION_NAME := "multilang"
const IS_ENABLED_NAME := "enabled"
const LIST_NAME := "list"
const DEFAULT_NAME := "default"

signal language_changed(value)

var languages:Array
var list:OptionButton

func _ready():
	#if not DialogicResources.get_settings_value(SECTION_NAME, IS_ENABLED_NAME, false):
	# 	hide?
	list = $OptionButton
	list.clear()
	languages = ["INTERNAL"]
	var langdata:Dictionary = DialogicResources.get_settings_value(SECTION_NAME, LIST_NAME, {})
	var defaultdata:Dictionary = DialogicResources.get_settings_value(SECTION_NAME, DEFAULT_NAME, {"display" : "english"})
	list.add_item(defaultdata.get("display", "[missing]"))
	for d in langdata:
		list.add_item(langdata[d].get("display", "[missing]"))
		languages.append(langdata[d].get("internal", "INTERNAL"))


func _on_OptionButton_item_selected(index:int):
	emit_signal("language_changed", languages[index])

#sets selected language if set from another menu above this.
func on_language_changed(language):
	var i:int = language.find(language)
	if i < 0:
		i = 0
	list.select(i)

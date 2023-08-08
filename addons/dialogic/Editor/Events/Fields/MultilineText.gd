@tool
extends CodeEdit

## Event block field that allows entering multiline text (mainly text event).

var property_name : String
signal value_changed

func _ready() -> void:
	text_changed.connect(_on_text_changed)
	syntax_highlighter = load('res://addons/dialogic/Editor/TimelineEditor/TextEditor/syntax_highlighter.gd').new()
	syntax_highlighter.mode = syntax_highlighter.Modes.TEXT_EVENT_ONLY


func _on_text_changed(value := "") -> void:
	emit_signal("value_changed", property_name, text)
	request_code_completion(true)


func set_value(value:Variant) -> void:
	text = str(value)


func take_autofocus() -> void:
	grab_focus()


################################################################################
## 					AUTO COMPLETION
################################################################################

# Called if something was typed
func _request_code_completion(force:bool):
	$CodeCompletionHelper.request_code_completion(force, self)


# Filters the list of all possible options, depending on what was typed
# Purpose of the different Kinds is explained in [_request_code_completion]
func _filter_code_completion_candidates(candidates:Array) -> Array:
	return $CodeCompletionHelper.filter_code_completion_candidates(candidates, self)


# Called when code completion was activated
# Inserts the selected item
func _confirm_code_completion(replace:bool) -> void:
	$CodeCompletionHelper.confirm_code_completion(replace, self)


################################################################################
##					SYMBOL CLICKING
################################################################################

# Performs an action (like opening a link) when a valid symbol was clicked
func _on_symbol_lookup(symbol, line, column):
	$CodeCompletionHelper.symbol_lookup(symbol, line, column)


# Called to test if a symbol can be clicked
func _on_symbol_validate(symbol:String) -> void:
	$CodeCompletionHelper.symbol_validate(symbol, self)

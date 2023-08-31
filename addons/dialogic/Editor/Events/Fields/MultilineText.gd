@tool
extends CodeEdit

## Event block field that allows entering multiline text (mainly text event).

var property_name : String
signal value_changed

@onready var code_completion_helper :Node= find_parent('EditorsManager').get_node('CodeCompletionHelper') 

func _ready() -> void:
	text_changed.connect(_on_text_changed)
	syntax_highlighter = code_completion_helper.syntax_highlighter


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
	code_completion_helper.request_code_completion(force, self, 0)


# Filters the list of all possible options, depending on what was typed
# Purpose of the different Kinds is explained in [_request_code_completion]
func _filter_code_completion_candidates(candidates:Array) -> Array:
	return code_completion_helper.filter_code_completion_candidates(candidates, self)


# Called when code completion was activated
# Inserts the selected item
func _confirm_code_completion(replace:bool) -> void:
	code_completion_helper.confirm_code_completion(replace, self)


################################################################################
##					SYMBOL CLICKING
################################################################################

# Performs an action (like opening a link) when a valid symbol was clicked
func _on_symbol_lookup(symbol, line, column):
	code_completion_helper.symbol_lookup(symbol, line, column)


# Called to test if a symbol can be clicked
func _on_symbol_validate(symbol:String) -> void:
	code_completion_helper.symbol_validate(symbol, self)

@tool
extends DialogicVisualEditorField

## Event block field that allows entering multiline text (mainly text event).

@onready var code_completion_helper: Node = find_parent('EditorsManager').get_node('CodeCompletionHelper')


#region MAIN METHODS
################################################################################

func _ready() -> void:
	self.text_changed.connect(_on_text_changed)
	self.syntax_highlighter = code_completion_helper.text_syntax_highlighter


func _load_display_info(info:Dictionary) -> void:
	pass


func _set_value(value:Variant) -> void:
	self.text = str(value)


func _autofocus() -> void:
	grab_focus()

#endregion


#region SIGNAL METHODS
################################################################################

func _on_text_changed(_value := "") -> void:
	value_changed.emit(property_name, self.text)

#endregion


#region AUTO COMPLETION
################################################################################

## Called if something was typed
func _request_code_completion(force:bool):
	code_completion_helper.request_code_completion(force, self, 0)


## Filters the list of all possible options, depending on what was typed
## Purpose of the different Kinds is explained in [_request_code_completion]
func _filter_code_completion_candidates(candidates:Array) -> Array:
	return code_completion_helper.filter_code_completion_candidates(candidates, self)


## Called when code completion was activated
## Inserts the selected item
func _confirm_code_completion(replace:bool) -> void:
	code_completion_helper.confirm_code_completion(replace, self)

#endregion


#region SYMBOL CLICKING
################################################################################

## Performs an action (like opening a link) when a valid symbol was clicked
func _on_symbol_lookup(symbol, line, column):
	code_completion_helper.symbol_lookup(symbol, line, column)


## Called to test if a symbol can be clicked
func _on_symbol_validate(symbol:String) -> void:
	code_completion_helper.symbol_validate(symbol, self)

#endregion

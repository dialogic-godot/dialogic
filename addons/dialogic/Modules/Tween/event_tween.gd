@tool
extends DialogicEvent
class_name DialogicTweenEvent

enum TweenTarget {
	PORTRAIT,
	BACKGROUND,
}

const TIME_DEFAULT := 0.0
const IS_RELATIVE_DEFAULT := false
const AWAIT_DEFAULT := false
const PARALLEL_DEFAULT := false
const EASE_DEFAULT := Tween.EASE_IN
const TRANSITION_DEFAULT := Tween.TRANS_LINEAR


var _property := "" :
	set(value):

		if value.contains(":"):
			var split_property := value.split(":")
			_property = split_property[0]
			_sub_property = split_property[1]
		else:
			_property = value
			_sub_property = ""

		var variable_value: Variant  = ColorRect.new().get(_property)
		var variant_type: Variant.Type = typeof(variable_value) as Variant.Type

		var new_value_type := variant_to_value_type(variant_type)
		_value_type = new_value_type

var _sub_property := ""
var _target := TweenTarget.BACKGROUND
var _time: float = TIME_DEFAULT
var _is_relative: bool = IS_RELATIVE_DEFAULT
var _await: bool = AWAIT_DEFAULT
var _parallel := PARALLEL_DEFAULT
var _ease := EASE_DEFAULT
var _transition := TRANSITION_DEFAULT
var _value_type: ValueType = ValueType.NUMBER
var _value: Variant = null :
	set(value):
		_value = value
		print(value)

func _execute() -> void:
	var target_node: Node = null

	match _target:
		TweenTarget.PORTRAIT:
			target_node = null

		TweenTarget.BACKGROUND:
			target_node = dialogic.Backgrounds.get_current_background_node()

	var tween := dialogic.create_tween()
	tween.set_ease(_ease)
	tween.set_trans(_transition)

	if _parallel:
		tween.set_parallel(true)

	var full_property_path := _property

	if not _sub_property.is_empty():
		full_property_path += ":" + _sub_property


	var tweener := tween.tween_property(target_node, full_property_path, _value, _time)

	if _is_relative:
		tweener.as_relative()

	if _await:
		await tweener.finished

	finish()


#region INITIALIZE
################################################################################
# Set fixed settings of this event
func _init() -> void:
	event_name = "Tween"
	set_default_color("Color2")
	event_category = "Visuals"
	event_sorting_index = 3



#endregion

#region SAVING/LOADING
################################################################################

func to_text() -> String:
	var result_string := "[tween "

	match _target:
		TweenTarget.PORTRAIT: result_string += "portrait "
		TweenTarget.BACKGROUND: result_string += "background "


	if not _property.is_empty():
		result_string += " property=\"" + _property

		if not _sub_property.is_empty():
			result_string += ":" + _sub_property

		result_string += "\""

	if not _value == null:
		result_string += " value=\"" + str(_value) + "\""


	if not _time == TIME_DEFAULT:
		result_string += " time=\"" + str(_time) + "\""

	if not _is_relative == IS_RELATIVE_DEFAULT:
		result_string += " is_relative=\"" + str(_is_relative) + "\""

	if not _await == AWAIT_DEFAULT:
		result_string += " await=\"" + str(_await) + "\""

	if not _ease == EASE_DEFAULT:
		result_string += " ease=\"" + _tween_ease_to_text(_ease) + "\""

	if not _transition == TRANSITION_DEFAULT:
		result_string += " transition=\"" + _transition_to_text(_transition) + "\""



	return result_string + "]"


func _transition_to_text(transition_kind: int) -> String:
	match transition_kind:
		Tween.TRANS_LINEAR:
			return "Linear"

		Tween.TRANS_SINE:
			return "Sine"

		Tween.TRANS_QUINT:
			return "Quint"

		Tween.TRANS_QUART:
			return "Quart"

		Tween.TRANS_QUAD:
			return "Quad"

		Tween.TRANS_EXPO:
			return "Expo"

		Tween.TRANS_ELASTIC:
			return "Elastic"

		Tween.TRANS_CUBIC:
			return "Cubic"

		Tween.TRANS_CIRC:
			return "Circ"

		Tween.TRANS_BOUNCE:
			return "Bounce"

		Tween.TRANS_BACK:
			return "Back"

		Tween.TRANS_SPRING:
			return "Spring"

	return "Linear"


func _text_to_transition(transition_text: String) -> int:
	var transition_lowercase := transition_text.to_lower().trim_prefix("trans").strip_edges()

	match transition_lowercase:
		"linear":
			return Tween.TRANS_LINEAR

		"sine":
			return Tween.TRANS_SINE

		"quint":
			return Tween.TRANS_QUINT

		"quart":
			return Tween.TRANS_QUART

		"quad":
			return Tween.TRANS_QUAD

		"expo":
			return Tween.TRANS_EXPO

		"elastic":
			return Tween.TRANS_ELASTIC

		"cubic":
			return Tween.TRANS_CUBIC

		"circ":
			return Tween.TRANS_CIRC

		"bounce":
			return Tween.TRANS_BOUNCE

		"back":
			return Tween.TRANS_BACK

		"spring":
			return Tween.TRANS_SPRING

	return Tween.TRANS_LINEAR


## The [param ease_kind] is an integer representing the ease approach
## the [class Tween] will use.
func _tween_ease_to_text(ease_kind: int) -> String:
	match ease_kind:
		Tween.EASE_IN:
			return "Ease In"

		Tween.EASE_OUT:
			return "Ease Out"

		Tween.EASE_IN_OUT:
			return "Ease In Out"

		Tween.EASE_OUT_IN:
			return "Ease Out In"

	return "Ease In"


func _text_to_tween_ease(ease_text: String) -> int:
	var ease_lowercase := ease_text.to_lower()

	match ease_lowercase:
		"ease in":
			return Tween.EASE_IN

		"ease out":
			return Tween.EASE_OUT

		"ease in out":
			return Tween.EASE_IN_OUT

		"ease out in":
			return Tween.EASE_OUT_IN

	return Tween.EASE_IN


func from_text(string: String) -> void:
	var regex_str := r'(\w+)\s*=\s*"([^"]*)"|(\w+)'
	var regex := RegEx.new()
	regex.compile(regex_str)

	for regex_match in regex.search_all(string):

		var key := regex_match.get_string(1)

		if key.is_empty():
			key = regex_match.get_string(0)

		var value := regex_match.get_string(2)

		match key:
			"portrait":
				_target = TweenTarget.PORTRAIT

			"background":
				_target = TweenTarget.BACKGROUND

			"property":
				_property = value

			"time":
				_time = float(value)

			"is_relative":
				_is_relative = true

			"await":
				_await = true

			"value":
				_value = string_to_value_type(value)

			"ease":
				_ease = _text_to_tween_ease(value) as Tween.EaseType

			"transition":
				_transition = _text_to_transition(value) as Tween.TransitionType



func string_to_value_type(value: String) -> Variant:
	if value.is_valid_int():
		return value.to_int()

	if value.is_valid_float():
		return value.to_float()

	if value.begins_with("("):
		var values := value.replace("(", "").replace(")", "").split(",")
		var x_value := values[0].strip_edges().to_float()
		var y_value := values[1].strip_edges().to_float()
		return Vector2(x_value, y_value)

	return null



func get_shortcode() -> String:
	return "tween"


func get_shortcode_parameters() -> Dictionary:
	return {
		#param_name 	: property_info
		"property" 		: {"property": "_property", "default": _property},
		"value"			: {"property": "_value", "default": _value},
		"target"		: {"property": "_target", "default": _target},
		"time"			: {"property": "_time", "default": _time},
		"is_relative"	: {"property": "_is_relative", "default": _is_relative},
		"await"			: {"property": "_await", "default": _await},
		"sub_property"	: {"property": "_sub_property", "default": _sub_property},
		"ease"			: {"property": "_ease", "default": _ease},
	}


# You can alternatively overwrite these 3 functions: to_text(), from_text(), is_valid_event()
#endregion


func get_all_properties(search_string: String) -> Dictionary:
	const VALID_TYPE := [TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_VECTOR2, TYPE_VECTOR2I, TYPE_RECT2, TYPE_RECT2I]
	const IGNORE_WORDS := ["process_"]

	var color_rect := ColorRect.new()
	var suggestions := {}
	var fallback_icon := ["Variant", "EditorIcons"]

	for property_info: Dictionary in color_rect.get_property_list():
		var property_name: String = property_info.get("name")

		if not search_string.is_empty() and not property_name.contains(search_string):
			continue

		var ignore_property: bool = false
		for ignore_term: String in IGNORE_WORDS:

			if property_name.begins_with(ignore_term):
				ignore_property = true
				break

		if ignore_property:
			continue

		var property_type: Variant.Type = property_info.get("type")

		if not VALID_TYPE.has(property_type):
			continue

		var icon: Variant = fallback_icon

		match property_type:
			Variant.Type.TYPE_INT:
				icon = ["Number", "EditorIcons"]
			Variant.Type.TYPE_FLOAT:
				icon = ["Float", "EditorIcons"]
			Variant.Type.TYPE_STRING:
				icon = ["String", "EditorIcons"]
			_:
				icon = ["Variant", "EditorIcons"]


		suggestions[property_name] = {
			"label": "[b]"+ property_name + "[/b]",
			"value": property_name,
			"icon": load("res://addons/dialogic/Editor/Images/Pieces/variable.svg")
		}


	return suggestions


#region EDITOR REPRESENTATION
################################################################################

func build_event_editor() -> void:
	#var background_node := DialogicUtil.autoload().get_tree().get_first_node_in_group("dialogic_background_holders").get_child(0)

	add_header_edit("_target", ValueType.FIXED_OPTIONS, {
		"left_text":	"Tween ",
		"options": [
			{
				"label": "Portrait",
				"value": TweenTarget.PORTRAIT,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Background",
				"value": TweenTarget.BACKGROUND,
				"icon": load("res://addons/dialogic/Modules/DefaultLayoutParts/Layer_FullBackground/background_layer_icon.svg")
			},
		]
	})


	add_header_edit("_property", ValueType.DYNAMIC_OPTIONS,
		{"placeholder"		: "",
		"mode"				: 1,
		"suggestions_func" 	: get_all_properties,
		#"icon" 				: load("res://addons/dialogic/Editor/Images/Resources/character.svg"),
		"autofocus"			: false,
		"left_text":		" property "
	})


	add_header_edit("_sub_property", ValueType.FIXED_OPTIONS, {
		#"left_text":	"Point:",
		"autofocus"			: false,
		"placeholder"		: "All",
		"mode"				: 1,
		"options": [
			{
				"label": "All",
				"value": "",
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "x",
				"value": "x",
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "y",
				"value": "y",
				"icon": load("res://addons/dialogic/Modules/DefaultLayoutParts/Layer_FullBackground/background_layer_icon.svg")
			},
		]
	},
	"_value_type == ValueType.VECTOR2"
	)



	#region VALUE FIELDS
	add_header_edit("_value", ValueType.NUMBER,
		{
			"left_text": " to ",
			"mode": 1,
		},
		"not _property.is_empty() and _value_type == ValueType.NUMBER"
	)

	add_header_edit("_value", ValueType.VECTOR2,
		{
			"left_text": " to ",
			"mode": 1,
		},
		"not _property.is_empty() && _value_type == ValueType.VECTOR2 && _sub_property.is_empty()"
	)

	add_header_edit("_value", ValueType.NUMBER,
		{
			"left_text": " to ",
			"mode": 1,
		},
		"not _property.is_empty() && _value_type == ValueType.VECTOR2 && not _sub_property.is_empty()"
	)
	#endregion



	add_header_edit("_time", ValueType.NUMBER,
		{
			"left_text":" over ",
			"right_text": " seconds. ",
			"only_positive": true,
		}
	 )


	add_header_edit("_is_relative", ValueType.BOOL,
		{"left_text":"Relative:"}, "_time > 0.0"
	)

	add_header_edit("_await", ValueType.BOOL,
		{"left_text": "Await:"}, "_time > 0.0"
	)

	# Body Optioms
	add_body_edit("_ease", ValueType.FIXED_OPTIONS, {
		"left_text":	"Ease:",
		"autofocus"			: false,
		"mode"				: 2,
		"placeholder": "Ease In",
		"options": [
			{
				"label": "Ease In",
				"value": Tween.EASE_IN,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Ease Out",
				"value": Tween.EASE_OUT,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Ease In Out",
				"value": Tween.EASE_IN_OUT,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Ease Out In",
				"value": Tween.EASE_OUT_IN,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
		]
	},
	"_time > 0.0"
	)


	add_body_edit("_transition", ValueType.FIXED_OPTIONS, {
	"left_text":	"Transition:",
	"autofocus"			: false,
	"mode"				: 1,
	"placeholder": "Linear",
	"options": [
			{
				"label": "Linear",
				"value": Tween.TRANS_LINEAR,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Sine",
				"value": Tween.TRANS_SINE,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Quint",
				"value": Tween.TRANS_QUINT,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Quart",
				"value": Tween.TRANS_QUART,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Quad",
				"value": Tween.TRANS_QUAD,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Expo",
				"value": Tween.TRANS_EXPO,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Elastic",
				"value": Tween.TRANS_ELASTIC,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Ease Out In",
				"value": Tween.TRANS_CUBIC,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Circ",
				"value": Tween.TRANS_CIRC,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Bounce",
				"value": Tween.TRANS_BOUNCE,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Back",
				"value": Tween.TRANS_BACK,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
			{
				"label": "Spring",
				"value": Tween.TRANS_SPRING,
				"icon": load("res://addons/dialogic/Editor/Images/Resources/character.svg")
			},
		]
	},
	"_time > 0.0"
	)

func variant_to_value_type(value: Variant.Type) -> ValueType:
	match value:
		Variant.Type.TYPE_STRING:
			return ValueType.SINGLELINE_TEXT

		Variant.Type.TYPE_INT:
			return ValueType.NUMBER

		Variant.Type.TYPE_FLOAT:
			return ValueType.NUMBER

		Variant.Type.TYPE_VECTOR2:
			return ValueType.VECTOR2

		Variant.Type.TYPE_VECTOR2I:
			return ValueType.VECTOR2

		Variant.Type.TYPE_RECT2:
			return ValueType.VECTOR2

		Variant.Type.TYPE_RECT2I:
			return ValueType.VECTOR2

		_:
			return ValueType.CUSTOM

#endregion

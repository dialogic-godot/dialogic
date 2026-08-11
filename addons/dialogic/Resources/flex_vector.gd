@tool
class_name DialogicFlexVector
extends Resource
## Represents a position or size in either absolute pixels or relative to a given parent size.[br][br]
## Allows mixing sizes, e.g. x could be absolute and y be relative.
## Make sure that whenever you are editing this value or retrieving it via [method as_pixels]
## or [method as_percent] the [member container_size] is up to date.
## Percentage is a float between 0.0 and 1.0, with 1.0 being 100% of the container_size dimension.
## Mainly used by PortraitContainer.

## The FlexVectors x_value.
@export var x_value := 0.0:
	set(x):
		x_value = x
		emit_changed()

## The FlexVectors y_value.
@export var y_value := 0.0:
	set(y):
		y_value = y
		emit_changed()

## If true, the [param x_value] is in percent (ranging from 0 to 1 as a multiplier of the parents x dimension).
@export var x_percent := true
## If true, the [param y_value] is in percent (ranging from 0 to 1 as a multiplier of the parents y dimension).
@export var y_percent := true

var container_size := Vector2()


## Returns the value in pixels. Make sure container_size is up to date.
func as_pixels() -> Vector2:
	return Vector2(
		x_value if not x_percent else x_value * container_size.x,
		y_value if not y_percent else y_value * container_size.y
		)


## Returns the value in percent. Make sure container_size is up to date.
func as_percent() -> Vector2:
	return Vector2(
		0 if container_size.x == 0 else x_value / container_size.x if not x_percent else x_value,
		0 if container_size.y == 0 else y_value / container_size.y if not y_percent else y_value
		)


## Adds the given vector, while keeping the current x_percent and y_percent states and converting the incoming values if necessary.
func add(flex_vector:DialogicFlexVector) -> void:
	if x_percent == flex_vector.x_percent:
		x_value += flex_vector.x_value
	else:
		if x_percent:
			x_value += flex_vector.as_percent().x
		else:
			x_value += flex_vector.as_pixels().x

	if y_percent == flex_vector.y_percent:
		y_value += flex_vector.y_value
	else:
		if y_percent:
			y_value += flex_vector.as_percent().y
		else:
			y_value += flex_vector.as_pixels().y


## Creates a new FlexVector from the given string. See [method overwrite_from_string]
static func from_string(input: String) -> DialogicFlexVector:
	var vec := DialogicFlexVector.new()
	vec.overwrite_from_string(input)
	return vec


## Extracts information from an input string and applies it to this FlexVector.
## The string can be of format "x10 y20" or "x10px y0.2%".
## Just a single dimension can be supplied, leaving the other where it's at.
## If type isn't specified, percentag is assumed.
func overwrite_from_string(input:String) -> void:
	var vector_regex := RegEx.create_from_string(r"(?<part>x|y)\s*(?<number>(-|\+)?(\d|\.|)*)(\s*(?<type>%|px))?")
	for i in vector_regex.search_all(input):
		var value := float(i.get_string(&'number'))
		match i.get_string(&'part').to_lower().strip_edges():
			"x":
				x_value = value
				match i.get_string(&'type'):
					"px":
						x_percent = false
					"%", _:
						x_percent = true
			"y":
				y_value = value
				match i.get_string(&'type'):
					"px":
						y_percent = false
					"%", _:
						y_percent = true



## Creates a new FlexVector with the given parent_size and values from the [param vector] assumed to be in pixels.
static func from_vector(vector:Vector2, parent_size:=Vector2()) -> DialogicFlexVector:
	var vec := DialogicFlexVector.new()
	vec.container_size = parent_size
	vec.x_value = vector.x
	vec.x_percent = false
	vec.y_value = vector.y
	vec.y_percent = false
	return vec


## Replaces the given values with the values from the [param vector] assumed to be in pixels, but keeping x_percent and y_percent state and converting if necessary.
func overwrite_from_vector(vector:Vector2) -> void:
	zero()
	add(from_vector(vector, container_size))



func copy() -> DialogicFlexVector:
	var vec := DialogicFlexVector.new()
	vec.x_value = x_value
	vec.y_value = y_value
	vec.x_percent = x_percent
	vec.y_percent = y_percent
	vec.container_size = container_size
	return vec


## Sets both values to 0.
func zero() -> void:
	x_value = 0
	y_value = 0


## Converts a string representation of the FlexVector.
func _to_string() -> String:
	return "x" + str(self.x_value) + ["px", "%"][int(self.x_percent)] + " y" + str(self.y_value) + ["px", "%"][int(self.y_percent)] + " "+str(get_instance_id())


## Applies x_percent and y_percent from the given [param flex_vec] to this one and converts the values.
## Make sure container_size is up to date before.
func make_similar(flex_vec: DialogicFlexVector) -> void:
	if flex_vec.x_percent != x_percent:
		if flex_vec.x_percent:
			x_value = as_percent().x
			x_percent = true
		else:
			x_value = as_pixels().x
			x_percent = false
	if flex_vec.y_percent != y_percent:
		if flex_vec.y_percent:
			y_value = as_percent().y
			y_percent = true
		else:
			y_value = as_pixels().y
			y_percent = false

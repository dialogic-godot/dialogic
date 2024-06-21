extends GdUnitTestSuite

## Check if transition animations can be accessed with "in", "out, "in out"
## as space-delimited prefix.
func test_fade_in_animation_paths() -> void:
	const TYPE := "PortraitAnimation"
	var fade_in_1: String = DialogicResourceUtil.guess_special_resource(TYPE, "fade in").get('path', "")
	var fade_in_2: String = DialogicResourceUtil.guess_special_resource(TYPE, "fade cross").get('path', "")
	var fade_in_3: String = DialogicResourceUtil.guess_special_resource(TYPE, "fade out").get('path', "")

	var is_any_fade_in_empty := fade_in_1.is_empty() or fade_in_2.is_empty() or fade_in_3.is_empty()
	assert(is_any_fade_in_empty == false, "Fade In/Out animations are empty.")

	var are_all_fade_in_equal := fade_in_1 == fade_in_2 and fade_in_2 == fade_in_3
	assert(are_all_fade_in_equal == true, "Fade In/Out animations returned different paths.")


## Test if invalid animation paths will return empty strings.
func test_invalid_animation_path() -> void:
	const TYPE := "PortraitAnimation"
	var invalid_animation_1: String = DialogicResourceUtil.guess_special_resource(TYPE, "fade i").get('path', "")
	assert(invalid_animation_1.is_empty() == true, "Invalid animation 1's path is not empty.")


	var invalid_animation_2: String = DialogicResourceUtil.guess_special_resource(TYPE, "fade").get('path', "")
	assert(invalid_animation_2.is_empty() == true, "Invalid animation 2's path is not empty.")


## Test if invalid types will return empty strings.
func test_invalid_type_path() -> void:
	const INVALID_TYPE := "Portait Animation"
	var invalid_animation: String = DialogicResourceUtil.guess_special_resource(INVALID_TYPE, "fade in").get('path', "")
	assert(invalid_animation.is_empty() == true, "Invalid animation 1's path is not empty.")

	const VALID_TYPE := "PortraitAnimation"
	var valid_animation_path: String = DialogicResourceUtil.guess_special_resource(VALID_TYPE, "fade in").get('path', "")
	assert(valid_animation_path.is_empty() == false, "Valids animation's path is empty.")

	assert(not invalid_animation == valid_animation_path, "Valid and invalid animation paths are equal.")


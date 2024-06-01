@tool
extends DialogicSettingsPage


const POSITION_SUGGESTION_KEY := 'dialogic/portraits/position_suggestion_names'

const DEFAULT_PORTRAIT_SCENE_KEY := 'dialogic/portraits/default_portrait'

const ANIMATION_JOIN_DEFAULT_KEY 			:= 'dialogic/animations/join_default'
const ANIMATION_JOIN_DEFAULT_LENGTH_KEY 	:= 'dialogic/animations/join_default_length'
const ANIMATION_JOIN_DEFAULT_WAIT_KEY 		:= 'dialogic/animations/join_default_wait'
const ANIMATION_LEAVE_DEFAULT_KEY 			:= 'dialogic/animations/leave_default'
const ANIMATION_LEAVE_DEFAULT_LENGTH_KEY 	:= 'dialogic/animations/leave_default_length'
const ANIMATION_LEAVE_DEFAULT_WAIT_KEY 		:= 'dialogic/animations/leave_default_wait'
const ANIMATION_CROSSFADE_DEFAULT_KEY 		:= 'dialogic/animations/cross_fade_default'
const ANIMATION_CROSSFADE_DEFAULT_LENGTH_KEY:= 'dialogic/animations/cross_fade_default_length'


func _ready():
	%JoinDefault.get_suggestions_func = get_join_animation_suggestions
	%JoinDefault.mode = 1
	%LeaveDefault.get_suggestions_func = get_leave_animation_suggestions
	%LeaveDefault.mode = 1
	%CrossFadeDefault.get_suggestions_func = get_join_animation_suggestions
	%CrossFadeDefault.mode = 1

	%PositionSuggestions.text_submitted.connect(save_setting.bind(POSITION_SUGGESTION_KEY))
	%CustomPortraitScene.value_changed.connect(save_setting_with_name.bind(DEFAULT_PORTRAIT_SCENE_KEY))

	%JoinDefault.value_changed.connect(
		save_setting_with_name.bind(ANIMATION_JOIN_DEFAULT_KEY))
	%JoinDefaultLength.value_changed.connect(
		save_setting.bind(ANIMATION_JOIN_DEFAULT_LENGTH_KEY))
	%JoinDefaultWait.toggled.connect(
		save_setting.bind(ANIMATION_JOIN_DEFAULT_WAIT_KEY))

	%LeaveDefault.value_changed.connect(
		save_setting_with_name.bind(ANIMATION_LEAVE_DEFAULT_KEY))
	%LeaveDefaultLength.value_changed.connect(
		save_setting.bind(ANIMATION_LEAVE_DEFAULT_LENGTH_KEY))
	%LeaveDefaultWait.toggled.connect(
		save_setting.bind(ANIMATION_LEAVE_DEFAULT_WAIT_KEY))

	%CrossFadeDefault.value_changed.connect(
		save_setting_with_name.bind(ANIMATION_CROSSFADE_DEFAULT_KEY))
	%CrossFadeDefaultLength.value_changed.connect(
		save_setting.bind(ANIMATION_CROSSFADE_DEFAULT_LENGTH_KEY))


func _refresh():
	%PositionSuggestions.text = ProjectSettings.get_setting(POSITION_SUGGESTION_KEY, 'leftmost, left, center, right, rightmost')

	%CustomPortraitScene.resource_icon = get_theme_icon(&"PackedScene", &"EditorIcons")
	%CustomPortraitScene.set_value(ProjectSettings.get_setting(DEFAULT_PORTRAIT_SCENE_KEY, ''))

	# JOIN
	%JoinDefault.resource_icon = get_theme_icon(&"Animation", &"EditorIcons")
	%JoinDefault.set_value(DialogicUtil.pretty_name(
		ProjectSettings.get_setting(ANIMATION_JOIN_DEFAULT_KEY,
		get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_in_up.gd'))))
	%JoinDefaultLength.set_value(ProjectSettings.get_setting(ANIMATION_JOIN_DEFAULT_LENGTH_KEY, 0.5))
	%JoinDefaultWait.button_pressed = ProjectSettings.get_setting(ANIMATION_JOIN_DEFAULT_WAIT_KEY, true)

	# LEAVE
	%LeaveDefault.resource_icon = get_theme_icon(&"Animation", &"EditorIcons")
	%LeaveDefault.set_value(
		ProjectSettings.get_setting(ANIMATION_LEAVE_DEFAULT_KEY,
		get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_out_down.gd')))
	%LeaveDefaultLength.set_value(ProjectSettings.get_setting(ANIMATION_LEAVE_DEFAULT_LENGTH_KEY, 0.5))
	%LeaveDefaultWait.button_pressed = ProjectSettings.get_setting(ANIMATION_LEAVE_DEFAULT_WAIT_KEY, true)

	# CROSS FADE
	%CrossFadeDefault.resource_icon = get_theme_icon(&"Animation", &"EditorIcons")
	%CrossFadeDefault.set_value(
		ProjectSettings.get_setting(ANIMATION_CROSSFADE_DEFAULT_KEY,
		get_script().resource_path.get_base_dir().path_join('DefaultAnimations/fade_in.gd')))
	%CrossFadeDefaultLength.set_value(ProjectSettings.get_setting(ANIMATION_CROSSFADE_DEFAULT_LENGTH_KEY, 0.5))


func save_setting_with_name(property_name:String, value:Variant, settings_key:String) -> void:
	save_setting(value, settings_key)


func save_setting(value:Variant, settings_key:String) -> void:
	ProjectSettings.set_setting(settings_key, value)
	ProjectSettings.save()


func get_join_animation_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}
	for anim in list_animations():
		if '_in' in anim.get_file():
			suggestions[DialogicUtil.pretty_name(anim)] = {'value':anim, 'icon':get_theme_icon('Animation', 'EditorIcons')}
	return suggestions


func get_leave_animation_suggestions(search_text:String) -> Dictionary:
	var suggestions := {}
	for anim in list_animations():
		if '_out' in anim.get_file():
			suggestions[DialogicUtil.pretty_name(anim)] = {'value':anim, 'icon':get_theme_icon('Animation', 'EditorIcons')}
	return suggestions


func list_animations() -> Array:
	var list := DialogicUtil.listdir(get_script().resource_path.get_base_dir().path_join('DefaultAnimations'), true, false, true)
	list.append_array(DialogicUtil.listdir(ProjectSettings.get_setting('dialogic/animations/custom_folder', 'res://addons/dialogic_additions/Animations'), true, false, true))

	return list

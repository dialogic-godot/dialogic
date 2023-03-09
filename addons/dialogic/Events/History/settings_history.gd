@tool
extends HBoxContainer

func _ready() -> void:
	%SimpleHistoryEnabled.toggled.connect(setting_toggled.bind('dialogic/history/simple_history_enabled'))
	%FullHistoryEnabled.toggled.connect(setting_toggled.bind('dialogic/history/full_history_enabled'))
	%AlreadyReadHistoryEnabled.toggled.connect(setting_toggled.bind('dialogic/history/already_read_history_enabled'))


func refresh() -> void:
	%SimpleHistoryEnabled.button_pressed = DialogicUtil.get_project_setting('dialogic/history/simple_history_enabled', false)
	%FullHistoryEnabled.button_pressed = DialogicUtil.get_project_setting('dialogic/history/full_history_enabled', false)
	%AlreadyReadHistoryEnabled.button_pressed = DialogicUtil.get_project_setting('dialogic/history/already_read_history_enabled', false)


func setting_toggled(button_pressed:bool, setting:String) -> void:
	ProjectSettings.set_setting(setting, button_pressed)
	ProjectSettings.save()

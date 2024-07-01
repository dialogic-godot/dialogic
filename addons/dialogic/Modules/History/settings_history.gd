@tool
extends DialogicSettingsPage


func _get_priority() -> int:
	return -10


func _ready() -> void:
	%SimpleHistoryEnabled.toggled.connect(setting_toggled.bind('dialogic/history/simple_history_enabled'))
	%SimpleHistorySave.toggled.connect(setting_toggled.bind('dialogic/history/simple_history_save'))
	%FullHistoryEnabled.toggled.connect(setting_toggled.bind('dialogic/history/full_history_enabled'))
	%FullHistorySave.toggled.connect(setting_toggled.bind('dialogic/history/full_history_save'))
	%AlreadyReadHistoryEnabled.toggled.connect(setting_toggled.bind('dialogic/history/visited_event_history_enabled'))
	%SaveOnAutoSaveToggle.toggled.connect(setting_toggled.bind('dialogic/history/save_on_autosave'))
	%SaveOnSaveToggle.toggled.connect(setting_toggled.bind('dialogic/history/save_on_save'))


func _refresh() -> void:
	%SimpleHistoryEnabled.button_pressed = ProjectSettings.get_setting('dialogic/history/simple_history_enabled', false)
	%SimpleHistorySave.button_pressed = ProjectSettings.get_setting('dialogic/history/simple_history_save', false)
	%FullHistoryEnabled.button_pressed = ProjectSettings.get_setting('dialogic/history/full_history_enabled', false)
	%FullHistorySave.button_pressed = ProjectSettings.get_setting('dialogic/history/full_history_save', false)
	%AlreadyReadHistoryEnabled.button_pressed = ProjectSettings.get_setting('dialogic/history/visited_event_history_enabled', false)


func setting_toggled(button_pressed: bool, setting: String) -> void:
	ProjectSettings.set_setting(setting, button_pressed)
	ProjectSettings.save()

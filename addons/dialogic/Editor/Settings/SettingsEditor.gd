@tool
extends Window

func _ready():
	hide()
	about_to_popup.connect(refresh)
	
	if not Engine.is_editor_hint():
		popup()

	# Subsystems
	for script in DialogicUtil.get_event_scripts():
		for subsystem in load(script).new().get_required_subsystems():
			if subsystem.has('settings'):
				$Panel/Tabs.add_child(load(subsystem.settings).instantiate())
	refresh()


func refresh():
	for child in $Panel/Tabs.get_children():
		if child.has_method('refresh'):
			child.refresh()

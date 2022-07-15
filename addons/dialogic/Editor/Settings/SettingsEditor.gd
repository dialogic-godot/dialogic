tool
extends WindowDialog

func _ready():
	connect("about_to_show", self, 'refresh')
	
	if not Engine.editor_hint:
		popup()

	# Subsystems
	for script in DialogicUtil.get_event_scripts():
		for subsystem in load(script).new().get_required_subsystems():
			if subsystem.has('settings'):
				$Panel/Tabs.add_child(load(subsystem.settings).instance())
	refresh()


func refresh():
	for child in $Panel/Tabs.get_children():
		if child.has_method('refresh'):
			child.refresh()

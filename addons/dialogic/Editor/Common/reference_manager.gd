@tool
extends PanelContainer


func _ready() -> void:
	if get_parent() is SubViewport:
		return

	add_theme_stylebox_override("panel", get_theme_stylebox("Background", "EditorStyles"))

	for tab in $Tabs/Tabs.get_children():
		tab.add_theme_color_override("font_selected_color", get_theme_color("accent_color", "Editor"))
		tab.add_theme_font_override("font", get_theme_font("main", "EditorFonts"))
		tab.toggled.connect(tab_changed.bind(tab.get_index()+1))


func tab_changed(enabled:bool, index:int) -> void:
	for child in $Tabs.get_children():
		if child.get_index() == 0 or child.get_index() == index:
			child.show()
			if child.get_index() == index:
				child.open()
		else:
			if child.visible:
				child.close()
			child.hide()
	for child in $Tabs/Tabs.get_children():
		child.set_pressed_no_signal(index-1 == child.get_index())


func open():
	show()
	$Tabs/BrokenReferences.update_indicator()

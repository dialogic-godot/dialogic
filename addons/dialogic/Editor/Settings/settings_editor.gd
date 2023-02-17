@tool
extends DialogicEditor

## Editor that contains all settings 

func _register():
	editors_manager.register_simple_editor(self)
	self.alternative_text = "Customize dialogic and it's behaviour" 


func _ready():
	get_parent().set_tab_icon(get_index(), get_theme_icon("PluginScript", "EditorIcons"))
	
	
	for indexer in DialogicUtil.get_indexers():
		for settings_page in indexer._get_settings_pages():
			$Tabs.add_child(load(settings_page).instantiate())


func _open(extra_information:Variant = null) -> void:
	refresh()
	if typeof(extra_information) == TYPE_STRING and has_node('Tabs/'+extra_information):
		$Tabs.current_tab = get_node('Tabs/'+extra_information).get_index()


func _close():
	for child in $Tabs.get_children():
		if child.has_method('_about_to_close'):
			child._about_to_close()


func refresh():
	for child in $Tabs.get_children():
		if child.has_method('refresh'):
			child.refresh()


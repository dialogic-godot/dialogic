@tool
extends Control

var current_info : Dictionary = {}
@onready var editor_view := find_parent('EditorView')


func _ready():
	await editor_view.ready
	theme = editor_view.theme

	%Install.icon = editor_view.get_theme_icon("AssetLib", "EditorIcons")
	%LoadingIcon.texture = editor_view.get_theme_icon("KeyTrackScale", "EditorIcons")
	%InstallWarning.modulate = editor_view.get_theme_color("warning_color", "Editor")

	DialogicUtil.get_dialogic_plugin().get_editor_interface().get_resource_filesystem().resources_reimported.connect(_on_resources_reimported)


func open():
	get_parent().popup_centered_ratio(0.5)
	get_parent().mode = Window.MODE_WINDOWED
	get_parent().move_to_foreground()
	get_parent().grab_focus()


func load_info(info:Dictionary, update_type:int) -> void:
	current_info = info
	if update_type == 2:
		%State.text = "No Information Available"
		%UpdateName.text = "Unable to access versions."
		%UpdateName.add_theme_color_override("font_color", editor_view.get_theme_color("readonly_color", "Editor"))
		%Content.text = "You are probably not connected to the internet. Fair enough."
		%ShortInfo.text = "Huh, what happened here?"
		%ReadFull.hide()
		%Install.disabled = true
	else:
		%UpdateName.text = info.name
		%Content.text = markdown_to_bbcode('#'+info.body.get_slice('#', 1)).strip_edges()
		%ShortInfo.text = "Published on "+info.published_at.substr(0, info.published_at.find('T'))+" by "+info.author.login
		%ReadFull.uri = info.html_url
		%ReadFull.show()
		if update_type == 0:
			%State.text = "Update Available!"
			%UpdateName.add_theme_color_override("font_color", editor_view.get_theme_color("warning_color", "Editor"))
			%Install.disabled = false
		else:
			%State.text = "You are up to date:"
			%UpdateName.add_theme_color_override("font_color", editor_view.get_theme_color("success_color", "Editor"))
			%Install.disabled = true
		var reactions := {"laugh":"😂", "hooray":"🎉", "confused":"😕", "heart":"❤️", "rocket":"🚀", "eyes":"👀"}
		for i in reactions:
			%Reactions.get_node(i.capitalize()).visible = info.reactions[i] > 0
			%Reactions.get_node(i.capitalize()).text = reactions[i]+" "+str(info.reactions[i]) if info.reactions[i] > 0 else reactions[i]
		if info.reactions['+1']+info.reactions['-1'] > 0:
			%Reactions.get_node("Likes").visible = true
			%Reactions.get_node("Likes").text = "👍 "+str(info.reactions['+1']+info.reactions['-1'])
		else:
			%Reactions.get_node("Likes").visible = false


func _on_window_close_requested():
	get_parent().visible = false


func _on_install_pressed():
	find_parent('UpdateManager').request_update_download()

	%InfoLabel.text = "Downloading. This can take a moment."
	%Loading.show()
	%LoadingIcon.create_tween().set_loops().tween_property(%LoadingIcon, 'rotation', 2*PI, 1).from(0)


func _on_refresh_pressed():
	find_parent('UpdateManager').request_update_check()


func _on_update_manager_downdload_completed(result:int):
	%Loading.hide()
	match result:
		0: # success
			%InfoLabel.text = "Installed successfully. Restart needed!"
			%InfoLabel.modulate = editor_view.get_theme_color("success_color", "Editor")
			%Restart.show()
			%Restart.grab_focus()
		1: # failure
			%InfoLabel.text = "Download failed."
			%InfoLabel.modulate = editor_view.get_theme_color("readonly_color", "Editor")


func _on_resources_reimported(resources:Array) -> void:
	await get_tree().process_frame
	get_parent().move_to_foreground()


func markdown_to_bbcode(text:String) -> String:
	var font_sizes := {1:16, 2:16, 3:16,4:14, 5:14}
	var title_regex := RegEx.create_from_string('(^|\n)((?<level>#+)(?<title>.*))\\n')
	var res := title_regex.search(text)
	while res:
		text = text.replace(res.get_string(2), '[font_size='+str(font_sizes[len(res.get_string('level'))])+']'+res.get_string('title').strip_edges()+'[/font_size]')
		res = title_regex.search(text)

	var link_regex := RegEx.create_from_string('(?<!\\!)\\[(?<text>[^\\]]*)]\\((?<link>[^)]*)\\)')
	res = link_regex.search(text)
	while res:
		text = text.replace(res.get_string(), '[url='+res.get_string('link')+']'+res.get_string('text').strip_edges()+'[/url]')
		res = link_regex.search(text)

	var image_regex := RegEx.create_from_string('\\!\\[(?<text>[^\\]]*)]\\((?<link>[^)]*)\\)\n*')
	res = image_regex.search(text)
	while res:
		text = text.replace(res.get_string(), '[url='+res.get_string('link')+']'+res.get_string('text').strip_edges()+'[/url]')
		res = image_regex.search(text)

	var italics_regex := RegEx.create_from_string('\\*(?<text>[^\\*\\n]*)\\*')
	res = italics_regex.search(text)
	while res:
		text = text.replace(res.get_string(), '[i]'+res.get_string('text').strip_edges()+'[/i]')
		res = italics_regex.search(text)

	var bullets_regex := RegEx.create_from_string('(?<=\\n)(\\*|-)(?<text>[^\\*\\n]*)\\n')
	res = bullets_regex.search(text)
	while res:
		text = text.replace(res.get_string(), '[ul]'+res.get_string('text').strip_edges()+'[/ul]\n')
		res = bullets_regex.search(text)

	var small_code_regex := RegEx.create_from_string('(?<!`)`(?<text>[^`]+)`')
	res = small_code_regex.search(text)
	while res:
		text = text.replace(res.get_string(), '[code][color='+get_theme_color("accent_color", "Editor").to_html()+']'+res.get_string('text').strip_edges()+'[/color][/code]')
		res = small_code_regex.search(text)

	var big_code_regex := RegEx.create_from_string('(?<!`)```(?<text>[^`]+)```')
	res = big_code_regex.search(text)
	while res:
		text = text.replace(res.get_string(), '[code][bgcolor='+get_theme_color("box_selection_fill_color", "Editor").to_html()+']'+res.get_string('text').strip_edges()+'[/bgcolor][/code]')
		res = big_code_regex.search(text)

	return text



func _on_content_meta_clicked(meta:Variant) -> void:
	OS.shell_open(str(meta))


func _on_install_mouse_entered():
	if not %Install.disabled:
		%InstallWarning.show()


func _on_install_mouse_exited():
	%InstallWarning.hide()


func _on_restart_pressed():
	DialogicUtil.get_dialogic_plugin().get_editor_interface().restart_editor(true)

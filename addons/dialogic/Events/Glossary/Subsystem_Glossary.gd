extends DialogicSubsystem

var glossaries := []
var enabled := true

####################################################################################################
##					STATE
####################################################################################################

func clear_game_state() -> void:
	glossaries = []
	for path in DialogicUtil.get_project_setting('dialogic/glossary/glossary_files', []):
		add_glossary(path)

func load_game_state() -> void:
	pass

####################################################################################################
##					MAIN METHODS
####################################################################################################

func parse_glossary(text:String) -> String:
	if !enabled: return text
	var def_case_sensitive :bool = DialogicUtil.get_project_setting('dialogic/glossary/default_case_sensitive', true)
	var def_color : Color= DialogicUtil.get_project_setting('dialogic/glossary/default_color', Color.POWDER_BLUE)
	var regex := RegEx.new()
	for glossary in glossaries:
		if !glossary.enabled:
			continue
		for entry in glossary.entries.keys():
			if !glossary.entries[entry].get('enabled', true):
				continue
			var pattern :String = '(?<=\\W|^)(?<word>'+glossary.entries[entry].get('regopts', entry)+')(?!])(?=\\W|$)'
			if glossary.entries[entry].get('case_sensitive', def_case_sensitive):
				regex.compile(pattern)
			else:
				regex.compile('(?i)'+pattern)
			text = regex.sub(text,
				'[url=' + entry + ']' +
				'[color=' + glossary.entries[entry].get('color', def_color).to_html() + ']${word}[/color]' +
				'[/url]', true
				)
	return text

func add_glossary(path:String):
	if FileAccess.file_exists(path):
		var x = load(path)
		if x is DialogicGlossary:
			glossaries.append(x)
			for entry in x.entries.keys():
				var regopts :String = entry
				for i in x.entries[entry].get('alternatives', []):
					regopts += '|'+i
				x.entries[entry]['regopts'] = regopts
	else:
		printerr('[Dialogic] The glossary file "' + path + '" is missing. Make sure it exists.')
	

func get_entry(name:String, parse_variables:bool = true) -> Dictionary:
	for glossary in glossaries:
		if name in glossary.entries:
			var info:Dictionary = glossary.entries[name].duplicate()
			if parse_variables and Dialogic.has_subsystem('VAR'):
				for key in info.keys():
					if typeof(info[key]) == TYPE_STRING:
						info[key] = Dialogic.VAR.parse_variables(info[key])
			return info
	return {}

func set_entry(name: String, value: Dictionary) -> bool:
	return false

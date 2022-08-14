extends DialogicSubsystem

var glossaries = []
var enabled = true

####################################################################################################
##					STATE
####################################################################################################

func clear_game_state():
	glossaries = []
	for path in DialogicUtil.get_project_setting('dialogic/glossary/glossary_files', []):
		add_glossary(path)

func load_game_state():
	pass

####################################################################################################
##					MAIN METHODS
####################################################################################################

func parse_glossary(text:String) -> String:
	if !enabled: return text
	var def_case_sensitive = DialogicUtil.get_project_setting('dialogic/glossary/default_case_sensitive', true)
	var def_color = DialogicUtil.get_project_setting('dialogic/glossary/default_color', Color.POWDER_BLUE)
	var regex = RegEx.new()
	for glossary in glossaries:
		if !glossary.enabled:
			continue
		for entry in glossary.entries.keys():
			if !glossary.entries[entry].get('enabled', true):
				continue
			
			var pattern = '(?<word>'+glossary.entries[entry].get('regopts', entry)+')(?!])(?=\\W|$)'
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
	var x = load(path)
	if x is DialogicGlossary:
		glossaries.append(x)
		for entry in x.entries.keys():
			var regopts = entry
			for i in x.entries[entry].get('alternatives', []):
				regopts += '|'+i
			x.entries[entry]['regopts'] = regopts

func get_entry(name:String) -> Dictionary:
	for glossary in glossaries:
		if name in glossary.entries:
			return glossary.entries[name]
	return {}

func set_entry(name: String, value: Dictionary) -> bool:
	return false

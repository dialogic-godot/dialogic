tool
extends ScrollContainer

var editor_reference 
onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
var doucmentation_path :String = "res://addons/dialogic/Documentation/"
var current_page : String = "Start"


onready var nodes = {
	'title':$VBoxContainer/Title,
	'content':$VBoxContainer/Content,
}

func _ready():
	nodes['content'].set('custom_fonts/bold_font', get_font("doc_title", "EditorFonts"))
	update_data()

func update_data():
	var f = File.new()
	f.open(doucmentation_path+current_page+".md",File.READ)
	nodes['content'].bbcode_text = ""
	nodes['content'].append_bbcode(markdown_parser(f.get_as_text()))
	nodes['content'].bbcode_enabled = true
	f.close()

func parse_text(text:String):
	var reg = RegEx.new()
	
	### HEADINGS ---------------------------------------------------------------
	reg.compile('[^#]# .*\\n')
	var headings = reg.search_all(text)
	
	var idx_adder = 0
	for x in headings:

		var length = x.get_end()-x.get_start()
		var content = text.substr(x.get_start() + idx_adder, length).replace('#', '')
		content = content.strip_edges()
		
		# text that will replace the found thing
		var adding = "[font="+"res://addons/dialogic/Documentation/Theme/DocumentationHeading.tres"+"]"+content+"[/font]\n"
		
		# replacing the old text
		text.erase(x.get_start()+idx_adder, length)
		text = text.insert(x.get_start()+idx_adder, adding)
		idx_adder -= length
		idx_adder += adding.length()
	
	### LINKS ------------------------------------------------------------------
	reg.compile("\\[.*\\]\\(.*\\)")
	var links = reg.search_all(text)
	idx_adder = 0
	for x in links:
		var length = x.get_end()-x.get_start()
		var content = text.substr(x.get_start() + idx_adder, length)
		content = content.strip_edges()
		var link = content.substr(content.find("("), content.find(")"))
		content = content.replace(link, "")
		link = link.trim_suffix(")").trim_prefix("(")
		content = content.trim_suffix("]").trim_prefix("[")
		if link.is_valid_filename():
			link.get_file()
			link.trim_suffix(".md")
		# text that will replace the found thing
		var adding = "[url="+link+"]"+content+"[/url]\n"
		
		# replacing the old text
		text.erase(x.get_start()+idx_adder, length)
		text = text.insert(x.get_start()+idx_adder, adding)
		idx_adder -= length
		idx_adder += adding.length()
	

	return text

func markdown_parser(content : String):
	var result = ""
	var bolded = []
	var italics = []
	var striked = []
	var coded = []
	var linknames = []
	var images = []
	var links = []
	var lists = []
	var underlined = []
	
	var regex = RegEx.new()
	regex.compile('\\*\\*(?<boldtext>.*)\\*\\*')
	result = regex.search_all(content)
	if result:
		for res in result:
			bolded.append(res.get_string("boldtext"))
	
	regex.compile('\\_\\_(?<underlinetext>.*)\\_\\_')
	result = regex.search_all(content)
	if result:
		for res in result:
			underlined.append(res.get_string("underlinetext"))
	
	regex.compile("\\*(?<italictext>.*)\\*")
	result = regex.search_all(content)
	if result:
		for res in result:
			italics.append(res.get_string("italictext"))
	
	regex.compile("~~(?<strikedtext>.*)~~")
	result = regex.search_all(content)
	if result:
		for res in result:
			striked.append(res.get_string("strikedtext"))
	
	regex.compile("`(?<coded>.*)`")
	result = regex.search_all(content)
	if result:
		for res in result:
			coded.append(res.get_string("coded"))
	
	regex.compile("[+-*](?<element>\\s.*)")
	result = regex.search_all(content)
	if result:
		for res in result:
			lists.append(res.get_string("element"))
	
	regex.compile("(?<img>!\\[.*?\\))")
	result = regex.search_all(content)
	if result:
		for res in result:
			images.append(res.get_string("img"))
	
	regex.compile("\\[(?<linkname>.*?)\\]|\\((?<link>[h\\.]\\S*?)\\)")
	result = regex.search_all(content)
	if result:
		for res in result:
			if res.get_string("link")!="":
				links.append(res.get_string("link"))
			if res.get_string("linkname")!="":
				linknames.append(res.get_string("linkname"))
	
	for bold in bolded:
		content = content.replace("**"+bold+"**","[b]"+bold+"[/b]")
	for italic in italics:
		content = content.replace("*"+italic+"*","[i]"+italic+"[/i]")
	for strik in striked:
		content = content.replace("~~"+strik+"~~","[s]"+strik+"[/s]")
	for underline in underlined:
		content = content.replace("__"+underline+"__","[u]"+underline+"[/u]")
	for code in coded:
		content = content.replace("`"+code+"`","[code]"+code+"[/code]")
	for image in images:
		var substr = image.split("(")
		var imglink = substr[1].rstrip(")")
		content = content.replace(image,"[img]"+imglink+"[/img]")
	for i in links.size():
		content = content.replace("["+linknames[i]+"]("+links[i]+")","[url="+links[i]+"]"+linknames[i]+"[/url]")
	for element in lists:
		if content.find("- "+element):
			content = content.replace("-"+element,"[indent]-"+element+"[/indent]")
		if content.find("+ "+element):
			content = content.replace("+"+element,"[indent]-"+element+"[/indent]")
		if content.find("* "+element):
			content = content.replace("+"+element,"[indent]-"+element+"[/indent]")
	
	return content

func load_page(page):
	current_page = page
	update_data()


func _on_Content_meta_clicked(meta):
	print("clicked ",meta)
	master_tree.select_documentation_item(meta)

tool
extends ScrollContainer

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
	nodes['content'].append_bbcode(parse_text(f.get_as_text()))
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

func load_page(page):
	current_page = page
	update_data()


func _on_Content_meta_clicked(meta):
	print("clicked ",meta)
	master_tree.select_documentation_item(meta)

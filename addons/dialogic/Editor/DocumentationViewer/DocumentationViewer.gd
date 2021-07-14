tool
extends ScrollContainer

var editor_reference 
onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
var current_page : String = "Start"

signal open_link(link)

onready var nodes = {
	'DocsViewer': $DocsViewer
}

func _ready():
	
	set("custom_styles/bg", get_stylebox("Background", "EditorStyles"))
	get('custom_styles/bg').content_margin_left = 0
	pass

func load_page(page):
	current_page = page
	nodes['DocsViewer'].load_page(current_page)

func toggle_editing():
	nodes['DocsViewer'].toggle_editing()

func _on_DocsViewer_open_non_html_link(link, section):
	#print(link, " ", section)
	master_tree.select_documentation_item(link)

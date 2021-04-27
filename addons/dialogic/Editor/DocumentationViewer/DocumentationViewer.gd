tool
extends ScrollContainer

var editor_reference 
onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
var current_page : String = "Start"

signal open_link(link)

onready var nodes = {
	'DocsViewer': $VBoxContainer/DocsViewer
}

func _ready():
	pass

func load_page(page):
	current_page = page
	$VBoxContainer/DocsViewer.load_page(current_page)

func _on_DocsViewer_open_non_html_link(link, section):
	#print(link, " ", section)
	master_tree.select_documentation_item(link)

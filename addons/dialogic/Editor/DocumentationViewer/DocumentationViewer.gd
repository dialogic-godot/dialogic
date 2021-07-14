tool
extends Control

var editor_reference 
onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
var current_page : String = ""

var previous_pages = []
var next_pages = []

signal open_link(link)

onready var nodes = {
	'DocsViewer': $DocsViewer
}

func _ready():
	$HBoxContainer/Previous.icon = get_icon("Back", "EditorIcons")
	$HBoxContainer/Next.icon = get_icon("Forward", "EditorIcons")
	
	set("custom_styles/panel", get_stylebox("Background", "EditorStyles"))
	#get('custom_styles/panel').content_margin_left = 0

func load_page(page):
	if current_page: 
		previous_pages.push_back(current_page)
		$HBoxContainer/Previous.disabled = false
	next_pages = []
	current_page = page
	nodes['DocsViewer'].load_page(current_page)
	$HBoxContainer/Next.disabled = true

func open_previous_page():
	if len(previous_pages):
		next_pages.push_front(current_page)
		current_page = previous_pages.pop_back()
		nodes['DocsViewer'].load_page(current_page)
		$HBoxContainer/Previous.disabled = len(previous_pages) == 0
		$HBoxContainer/Next.disabled = false
	
func open_next_page():
	if len(next_pages):
		previous_pages.push_back(current_page)
		current_page = next_pages.pop_front()
		nodes['DocsViewer'].load_page(current_page)
		$HBoxContainer/Next.disabled = len(next_pages) == 0
		$HBoxContainer/Previous.disabled = false
	
func toggle_editing():
	nodes['DocsViewer'].toggle_editing()

func _on_DocsViewer_open_non_html_link(link, section):
	#print(link, " ", section)
	master_tree.select_documentation_item(link)

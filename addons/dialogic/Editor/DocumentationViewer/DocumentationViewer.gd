tool
extends Control

onready var master_tree = get_node('../MasterTreeContainer/MasterTree')
var current_page : String = ""

var previous_pages = []
var next_pages = []

signal open_link(link)

onready var nodes = {
	'DocsViewer': $DocsViewer,
	'Next': null,
	'Previous':null,
}

func _ready():
	set("custom_styles/panel", get_stylebox("Background", "EditorStyles"))
	
	var _scale = get_constant("inspector_margin", "Editor")
	_scale = _scale * 0.125
	nodes['DocsViewer'].MarkdownParser.editor_scale = _scale
	nodes['Next'] = find_parent("EditorView").get_node("ToolBar/DocumentationNavigation/Next")
	nodes['Next'].connect('pressed',self, 'open_next_page')
	nodes['Previous'] = find_parent("EditorView").get_node("ToolBar/DocumentationNavigation/Previous")
	nodes['Previous'].connect('pressed',self, 'open_previous_page')
	


func load_page(page):
	if current_page: 
		previous_pages.push_back(current_page)
		nodes['Previous'].disabled = false
	next_pages = []
	current_page = page
	nodes['DocsViewer'].load_page(current_page)
	nodes['Next'].disabled = true


func open_previous_page():
	if len(previous_pages):
		next_pages.push_front(current_page)
		current_page = previous_pages.pop_back()
		nodes['DocsViewer'].load_page(current_page)
		nodes['Previous'].disabled = len(previous_pages) == 0
		nodes['Next'].disabled = false


func open_next_page():
	if len(next_pages):
		previous_pages.push_back(current_page)
		current_page = next_pages.pop_front()
		nodes['DocsViewer'].load_page(current_page)
		nodes['Next'].disabled = len(next_pages) == 0
		nodes['Previous'].disabled = false


func toggle_editing():
	nodes['DocsViewer'].toggle_editing()


func _on_DocsViewer_open_non_html_link(link, section):
	#print(link, " ", section)
	master_tree.select_documentation_item(link)

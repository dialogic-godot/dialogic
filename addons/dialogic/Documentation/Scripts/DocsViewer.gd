tool
extends RichTextLabel

var documentation_path: String = ""
var current_page: String = ""
var MarkdownParser = load("res://addons/dialogic/Documentation/Scripts/DocsMarkdownParser.gd").new()

signal open_non_html_link(link)

func _ready():
	documentation_path = DocsHelper.documentation_path
	get_path()

func load_page(page_path, section = null):
	if not page_path.begins_with("res://"):
		page_path = documentation_path+"/Content/"+page_path
	if not page_path.ends_with('.md'):
		page_path += ".md"
	print("load page ", page_path)
	var f = File.new()
	f.open(page_path,File.READ)
	bbcode_text = MarkdownParser.parse(f.get_as_text())
	f.close()
	## implement sections here!
	
	

func _on_meta_clicked(meta):
	if meta.begins_with("http"):
		OS.shell_open(meta)
	else:
		emit_signal("open_non_html_link", meta)

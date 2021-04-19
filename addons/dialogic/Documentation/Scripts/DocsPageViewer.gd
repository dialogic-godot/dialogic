tool
extends RichTextLabel

export (bool) var enable_editing = false
var documentation_path: String = ""
var MarkdownParser = load("res://addons/dialogic/Documentation/Scripts/DocsMarkdownParser.gd").new()

var current_page: String = ""
var current_headings = []

signal open_non_html_link(link, section)

################################################################################
##							PUBLIC FUNCTIONS 								  ##
################################################################################

## Opens a page at path PAGE_PATH
## The PAGE_PATH can be a full godot path or a path from Documentation/Content
## E.g.: 
## "res://addons/thing/Documentation/Content/Tuts/welcome.md" == "Tuts/welcome"
## 
## The section can either be passed as a second argument or in the PAGE_PATH with #
## E.g.: "Tuts/welcome#how-to-use-the-plugin" == "Tuts/welcome", "#how-to-use-the-plugin"
func load_page(page_path: String, section : String=''):
	# return if no path is given
	if page_path == '' and not section:
		return
	
	show()
	
	#print("load page ", page_path)
	# find a section specifier at the end of the path
	if page_path.count("#") > 0:
		var result = page_path.split('#')
		page_path = result[0]
		section = result[1]
	
	# add necessary parts to the path
	if not page_path.begins_with("res://"):
		page_path = documentation_path+"/Content/"+page_path
	if not page_path.ends_with('.md'):
		page_path += ".md"
	
	# opening the file
	var f = File.new()
	f.open(page_path,File.READ)
	current_page = page_path
	
	# parsing the file
	bbcode_text = MarkdownParser.parse(f.get_as_text())
	f.close()
	
	# saving the headings for going to sections
	current_headings = MarkdownParser.heading1s + MarkdownParser.heading2s + MarkdownParser.heading3s + MarkdownParser.heading4s + MarkdownParser.heading5s
	
	# scroll to the given section
	scroll_to_section(section)

# looks if there is a heading similar to the given TITLE and then scrolls there
func scroll_to_section(title):
	#print("load section ", title)
	if not title:
		return
	# this is not really nicely done...
	for heading in current_headings:
		if heading.to_lower().strip_edges().replace(' ', '-') == title.replace('#', ''):
			var x = bbcode_text.find(heading.replace('#', '').strip_edges()+"[/font]")
			x = bbcode_text.count("\n", 0, x)
			scroll_to_line(x)
			return

################################################################################
##							PRIVATE FUNCTIONS 								  ##
################################################################################

func _ready():
	documentation_path = DocsHelper.documentation_path
	$Editing.visible = enable_editing

## When one of the links is clicked
func _on_meta_clicked(meta):
	## Check wether this is a real LINK
	if meta.begins_with("http"):
		
		# test if we can interpret this as a normal link to a docs file
		if meta.count("Documentation/Content") > 0:
			meta = meta.split("Documentation/Content")[1]
		
		# else open it with the browser
		else:
			OS.shell_open(meta)
			return
	
	## Check wether it is a section
	if meta.begins_with("#"):
		# try to open it in this document
		scroll_to_section(meta)
	
	## Else send a signal that the pluginmaker has to interpret
	else:
		# if the link contains a section
		var link = meta
		var section = null
		if meta.count("#") > 0:
			var split = meta.split('#')
			link = split[0]
			section = split[1]
		if not link.begins_with("res://"):
			link = DocsHelper.documentation_path.plus_file('Content').plus_file(link)
		if not link.ends_with(".md"):
			link += '.md'
		emit_signal("open_non_html_link", link, section)


func _on_EditPage_pressed():
	var x = File.new()
	x.open(current_page, File.READ)
	OS.shell_open(x.get_path_absolute())


func _on_RefreshPage_pressed():
	load_page(current_page)

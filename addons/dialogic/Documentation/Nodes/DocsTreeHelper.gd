tool
extends Control

# Don't change this if possible
export (String) var documentation_path : String = "res://addons/dialogic/Documentation"

# This enables/disables the use of folder files
# If enabled, the docs will expect a file named 
# exactly like a folder for each folder in the docs:
## E.g.: If you have a Tutorials folder somewhere put a Tutorials.md file next to it.
## This way the folder will be clickable and you can see the page, 
## but it won't be shown as a separate page
var use_folder_files = true

# These files will not be listed. Just use the filename! No paths in here
var file_ignore_list = ['Welcome.md']


################################################################################
##							PUBLIC FUNCTIONS 								  ##
################################################################################

## Returns a dictionary that contains the important parts of the 
##   documentations Content folder.
##
## This is mainly used if you want to somehow display a list of the docs content,
##   for example to create a file-tree or a list of documents
##
## Only files ending on .md are noticed. 
## Folders that contain no such files are ignored
func get_documentation_content():
	return get_dir_contents(documentation_path+"/Content")

## Will create a hirarchy of TreeItems on the given 'trees' root_item
## If not root_item is given a new root_item will be created
## The root item does not have to be the actual root item of the whole tree, 
##   but the root of the documentation branch.
## 
## With def_folder_info and def_page_info special information can be 
##   added to the meta of the Items
##
## If a filter_term is given, only items with that filter will be created.
## Right now there will always be all folders.
func build_documentation_tree(tree : Tree, root_item:TreeItem = null, def_folder_info:Dictionary = {}, def_page_info:Dictionary = {}, filter_term:String = ''):
	return _build_documentation_tree(tree, root_item, def_folder_info, def_page_info, filter_term)


################################################################################
##							PRIVATE FUNCTIONS 								  ##
################################################################################


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### LOOKING THROUGH THE DOCS FOLDERS:

func get_dir_contents(rootPath: String) -> Dictionary:
	var directory_structure = {}
	var dir := Directory.new()

	if dir.open(rootPath) == OK:
		dir.list_dir_begin(true, false)
		directory_structure = _add_dir_contents(dir)
	else:
		push_error("Docs: An error occurred when trying to access the path.")
	return directory_structure

func _add_dir_contents(dir: Directory) -> Dictionary:
	var file_name = dir.get_next()

	var structure = {}
	while (file_name != ""):
		var path = dir.get_current_dir() + "/" + file_name
		if dir.current_is_dir():
			#print("Found directory: %s" % path)
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin(true, false)
			var dir_content = _add_dir_contents(subDir)
			if dir_content.has('_files_'):
				structure[path] = dir_content
		else:
			#print("Found file: %s" % path)
			if not file_name.ends_with(".md"):
				file_name = dir.get_next()
				continue
			if file_name in file_ignore_list:
				file_name = dir.get_next()
				continue
			if not structure.has("_files_"):
				structure["_files_"] = []
			
			structure["_files_"].append(path)

		file_name = dir.get_next()
	dir.list_dir_end()
	return structure

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### For bouilding the tree

func _build_documentation_tree(tree : Tree, root_item:TreeItem = null, def_folder_info:Dictionary = {}, def_page_info:Dictionary = {}, filter_term:String =''):

	var documentation_tree 
	if root_item == null:
		documentation_tree = tree.create_item()
		documentation_tree.set_text(0, "Documentation")
		
	else:
		documentation_tree = root_item
	
	# if no search is performed, collapse the tree by default
	if not filter_term:
		documentation_tree.collapsed = true
	else:
		documentation_tree.collapsed = false
	
	# create the rest of the tree based on the dict we get from the DocsHelper
	var doc_structure = get_documentation_content()
	#print(doc_structure)
	create_doc_tree(tree, documentation_tree, def_folder_info, def_page_info, doc_structure, filter_term)
	return documentation_tree

# this calls itself recursivly to create the tree, based on the given dict
func create_doc_tree(tree, parent_item, def_folder_info, def_page_info, doc_structure, filter_term):
	for key in doc_structure.keys():
		# if this is a folder
		if typeof(doc_structure[key]) == TYPE_DICTIONARY:
			var folder_item = _add_documentation_folder(tree, parent_item, {'name':key.get_file(), 'path':key}, def_folder_info)
			create_doc_tree(tree, folder_item, def_folder_info, def_page_info, doc_structure[key], filter_term)
			if not filter_term:
				folder_item.collapsed = true
		# if this is a page
		elif typeof(doc_structure[key]) == TYPE_ARRAY:
			for file in doc_structure[key]:
				if use_folder_files and file.trim_suffix('.md') in doc_structure.keys():
					pass
				else:
					if not filter_term or (filter_term and filter_term.to_lower() in get_title(file, '').to_lower()):
						_add_documentation_page(tree, parent_item, {'name':file.get_file().trim_suffix(".md"), 'path': file}, def_page_info)

func merge_dir(target: Dictionary, patch: Dictionary):
	var copy = target.duplicate()
	for key in patch:
		copy[key] = patch[key]
	return copy

# this adds a folder item to the tree
func _add_documentation_folder(tree, parent_item, folder_info, default_info):
	var item = tree.create_item(parent_item)
	item.set_text(0, folder_info['name'])
	item.set_icon(0, tree.get_icon("HelpSearch", "EditorIcons"))
	item.set_editable(0, false)
	if use_folder_files:
		var x = File.new()
		if x.file_exists(folder_info['path']+'.md'):
			folder_info['path'] += '.md'
		else:
			folder_info['path'] = ''
	else:
		folder_info['path'] = ''
	item.set_metadata(0, merge_dir(default_info, folder_info))
	if not tree.get_constant("dark_theme", "Editor"):
		item.set_icon_modulate(0, get_color("property_color", "Editor"))
	return item

# this adds a page item to the tree
func _add_documentation_page(tree, parent, page_info, default_info):
	var item = tree.create_item(parent)
	item.set_text(0, get_title(page_info['path'], page_info['name']))
	item.set_tooltip(0,page_info['path'])
	item.set_editable(0, false)
	item.set_icon(0, tree.get_icon("Help", "EditorIcons"))
	var new_dir =  merge_dir(default_info, page_info)
	#print(new_dir)
	item.set_metadata(0,new_dir)
	if not tree.get_constant("dark_theme", "Editor"):
		item.set_icon_modulate(0, get_color("property_color", "Editor"))
	return item

# returns the first line of a text_file, a bit cleaned up
func get_title(path, default_name):
	# opening the file
	var f = File.new()
	f.open(path, File.READ)
	var arr = f.get_as_text().split('\n', false, 1)
	if not arr.empty():
		return arr[0].trim_prefix('#').strip_edges()
	else:
		return default_name
## ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## For searching the tree
## used to search and select an item of the tree based on a info saved in the metadata
## in most cases you just want to search for the item that has a certain path
##
## the paren_item parameter is only used so this can call itself recursivly 
func search_and_select_docs(docs_tree_item:TreeItem, info:String, key:String = 'path'):
	if info == "": return
	if info == "/":
		docs_tree_item.select(0)
		return true
	#print("Asearch ", key, " ", info)
	#print("Asearchin on item: ", docs_tree_item.get_text(0))
	var item = docs_tree_item.get_children()
	while item:
		#print("A ",item.get_text(0))
		if not item.has_method('get_metadata'):
			item = item.get_next()
		
		var meta = item.get_metadata(0)
		#print(meta)
		if meta.has(key):
			if meta[key] == info:
				item.select(0)
				return true
		if search_and_select_docs(item, info, key):
			return true
		item = item.get_next()
	return false

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#### For bouilding the tree
#func create_reference():
#	var RefColl = ReferenceCollector.new()
#	RefColl._run()

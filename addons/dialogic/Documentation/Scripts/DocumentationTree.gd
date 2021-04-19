tool
extends Tree

var documentation_tree 

# emited when an item is selceted
signal _page_selected(path)

################################################################################
##							PUBLIC FUNCTIONS 								  ##
################################################################################

func select_item(path):
	DocsHelper.search_and_select_docs(documentation_tree, path)


################################################################################
##							PRIVATE FUNCTIONS 								  ##
################################################################################

func _ready():
	connect('item_selected', self, '_on_item_selected')
	documentation_tree = DocsHelper.build_documentation_tree(self)

func _on_item_selected():
	var item = get_selected()
	var metadata = item.get_metadata(0)
	print(item.get_text(0))
	print(metadata['path'])
	if metadata.has('path'):
		emit_signal("_page_selected", metadata['path'])
	

### For searching the tree -----------------------------------------------------


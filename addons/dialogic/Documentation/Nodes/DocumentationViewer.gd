tool
extends Control

onready var DocTree = $HSplit/VBoxContainer/DocumentationTree
onready var DocPageViewer = $HSplit/DocsPageViewer


func _on_DocsPageViewer_open_non_html_link(link, section):
	DocTree.select_item(link)
	DocPageViewer.scroll_to_section(section)

func _on_DocumentationTree_page_selected(path):
	DocPageViewer.load_page(path)

func _on_FilterEntry_text_changed(new_text):
	var child = DocTree.documentation_tree.get_children()
	while child:
		child.call_recursive("call_deferred", "free")
		child = child.get_next()
	#DocsHelper.build_documentation_tree(DocTree, DocTree.documentation_tree,{},{}, new_text)
	DocTree.call_deferred("update")

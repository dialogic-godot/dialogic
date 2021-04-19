tool
extends Control

func _on_DocsPageViewer_open_non_html_link(link, section):
	$HSplit/DocumentationTree.select_item(link)
	$HSplit/DocsPageViewer.scroll_to_section(section)

func _on_DocumentationTree_page_selected(path):
	print("load page ", path)
	$HSplit/DocsPageViewer.load_page(path)

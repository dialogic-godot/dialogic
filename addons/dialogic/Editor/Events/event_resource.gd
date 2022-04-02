tool
extends Resource
class_name DialogicEvent

export (String) var id
export (String) var name
export (Texture) var icon
export (Color) var color
export (Dictionary) var properties
export (int, 'Main', 'Logic', 'Timeline', 'Audio/Visual', 'Godot', 'Other') var category

export (String) var help_page_path

export (bool) var expand_by_default = true
export (bool) var needs_indentation = false
export (bool) var display_name = true

export (int) var sorting_index

# Hopefully we can replace this with a cleaner system
# maybe even generate them based on some markup? who knows, it is free to dream
export(PackedScene) var header_scene : PackedScene
export(PackedScene) var body_scene : PackedScene

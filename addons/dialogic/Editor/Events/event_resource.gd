tool
extends Resource
class_name DialogicEvent

export (String) var id
export (String) var name
export (Texture) var icon
export (Color) var color

# Hopefully we can replace this with a cleaner system
# maybe even generate them based on some markup? who knows, it is free to dream
export(Array, Resource) var header : Array
export(Array, Resource) var body : Array


export (int, 'Main', 'Logic', 'Timeline', 'Audio/Visual', 'Godot', 'Other') var category

export (String) var help_page_path

export (bool) var expand_by_default : bool = true
export (bool) var needs_indentation : bool = false
export (bool) var display_name : bool = true

export (int) var sorting_index : int



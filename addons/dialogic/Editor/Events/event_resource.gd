tool
extends Resource
class_name DialogicEvent

export (String) var id
export (String) var name
export (Texture) var icon
export (Color) var color
export (Array) var properties
export (int, 'Main', 'Logic', 'Timeline', 'Audio/Visual', 'Godot', 'Other') var category

# This one should not be here, ideally we wouldn't have the scenes saved as 
# they are right now. They should be generated only based on this resource
export (PackedScene) var event_scene
export (String) var help_page_path

export (bool) var expand_by_default = true
export (bool) var needs_indentation = false
export (bool) var display_name = true

export (int) var sorting_index

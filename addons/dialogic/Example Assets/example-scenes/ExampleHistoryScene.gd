extends VBoxContainer

#Example scene for viewing the History
#Implements all of the visual options from 1.x History mode

@export var show_open_button: bool = true
@export var show_close_button: bool = true
@export var show_all_choices: bool = true
@export var show_selected_choice: bool = true
@export var show_character_joins: bool = true
@export var show_character_leaves: bool = true
@export var scroll_to_bottom: bool = true
@export var show_name_colors: bool = true
@export var oldest_items_first: bool = true
@export var line_break_after_names: bool
@export var name_delimeter: String = ": "

@export var history_font_size: int
@export var history_font_normal: Font
@export var history_font_bold: Font
@export var history_font_italics: Font

var text_node: MarginContainer

var last_history_index: int
var last_history_count: int

var scroll_to_bottom_flag: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	if Dialogic.has_subsystem('History'):
		text_node = load('res://addons/dialogic/Example Assets/example-scenes/ExampleHistoryItem.tscn').instantiate()
		$ShowHistory.visible = show_open_button
	else: 
		self.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if scroll_to_bottom_flag:
		await get_tree().process_frame
		%HistoryBox.ensure_control_visible(%HistoryLog.get_children()[-1])
		scroll_to_bottom_flag = false


func _on_show_history_pressed():
	show_history()

		
func show_history() -> void:
	#Start with a quick check so it doesn't rebuild if history's not been changed
	if (last_history_index != Dialogic.History.full_history[0]['index']) || (last_history_count != Dialogic.History.full_history.size()):
		last_history_index = Dialogic.History.full_history[0]['index']
		last_history_count =  Dialogic.History.full_history.size()
		
		for index in Dialogic.History.full_history.size():
			var item = Dialogic.History.full_history[index]	
			if item['event_type'] == "Text":
				var history_item_string:String = ""
				var new_node = text_node.duplicate()
				new_node.prepare_texbox(self)
				
				if item['event_object'].character != null:
					var character_name = ""
					
					if Dialogic.has_subsystem('VAR'):
						character_name += Dialogic.VAR.parse_variables(item['event_object'].character.display_name)
					else:
						character_name += item['event_object'].character.display_name
					
					if show_name_colors:
						character_name = "[color=#" + item['event_object'].character.color.to_html(false) + "]" + character_name + "[/color]"
					
					history_item_string += character_name
					
					history_item_string += name_delimeter
				
					if line_break_after_names:
						history_item_string += "\n"
				
				var final_text :String = item['event_object'].get_property_translated('text')
				if Dialogic.has_subsystem('VAR'):
					final_text = Dialogic.VAR.parse_variables(final_text)
				if Dialogic.has_subsystem('Glossary'):
					final_text = Dialogic.Glossary.parse_glossary(final_text)
				
				history_item_string += Dialogic.Text.color_names(final_text)
				
				if show_name_colors:
					history_item_string = Dialogic.Text.color_names(history_item_string)
					
				new_node.set_text(history_item_string)
				%HistoryLog.add_child(new_node)
				if oldest_items_first:
					%HistoryLog.move_child(new_node,0)
				
			if item['event_type'] == "Character" && (show_character_joins || show_character_leaves): 
				var history_item_string:String = "[i]"
				var new_node = text_node.duplicate()
				new_node.prepare_texbox(self)
				
				if !item['event_object'].leave_all:
					var character_name = ""
					
					if Dialogic.has_subsystem('VAR'):
						character_name += Dialogic.VAR.parse_variables(item['event_object'].character.display_name)
					else:
						character_name += item['event_object'].character.display_name
						
					if show_name_colors:
						history_item_string += "[color=#" + item['event_object'].character.color.to_html(false) + "]" + character_name + "[/color]"
					else: 
						history_item_string += character_name
				else: 
					history_item_string += "Everyone"
				
				if item['event_object'].action_type == DialogicCharacterEvent.ActionTypes.Join && show_character_joins:
					history_item_string += " has arrived[/i]" 
				
				if item['event_object'].action_type == DialogicCharacterEvent.ActionTypes.Leave && show_character_leaves:
					history_item_string += " has left[/i]" 
				
				new_node.set_text(history_item_string)
				%HistoryLog.add_child(new_node)
				if oldest_items_first:
					%HistoryLog.move_child(new_node,0)

			if Dialogic.has_subsystem('Choices') && item['event_type'] == "Choice" && (show_all_choices || show_selected_choice): 
				var history_item_string:String = ""
				var new_node = text_node.duplicate()
				new_node.prepare_texbox(self)
				
				if show_selected_choice && !show_all_choices:
					history_item_string += "[ul][b]" + item['event_object'].get_property_translated('text') + "[/b][/ul]"
				else:
					if index + 1 < Dialogic.History.full_history.size():
						
						#Here be shenanigans
						
						var choice_starting_event = Dialogic.History.full_history[index + 1]
						
						
						var working_timeline: DialogicTimeline = null
						
						if choice_starting_event['timeline'] == Dialogic.current_timeline.resource_path:
							working_timeline = Dialogic.current_timeline
						else:
							working_timeline = Dialogic.preload_timeline(choice_starting_event['timeline'])
						
						var search_line = choice_starting_event['index'] + 1
						var search_depth = 0
						
						while search_depth > -1:
							if working_timeline.events[search_line].event_name == "Choice":
								search_depth += 1
								
								if search_depth == 1:
									if show_selected_choice && search_line == item['index']:
										history_item_string += "•[b]" + working_timeline.events[search_line].get_property_translated('text') + "[/b]\n"
									else:
										history_item_string += "•" + working_timeline.events[search_line].get_property_translated('text') + "\n"
								
							else:
								if search_depth > 0: 
									if working_timeline.events[search_line].event_name == "End Branch":
										search_depth -= 1
								else:
									search_depth -= 1
							search_line += 1
						
						
					else:
						history_item_string += "•" + item['event_object'].get_property_translated('text') 
					
					
				new_node.set_text(history_item_string)
				%HistoryLog.add_child(new_node)
				if oldest_items_first:
					%HistoryLog.move_child(new_node,0)
					
					
					
					
				
				new_node.set_text(history_item_string)
				%HistoryLog.add_child(new_node)
				if oldest_items_first:
					%HistoryLog.move_child(new_node,0)
				
			
		

		
		if scroll_to_bottom:
			scroll_to_bottom_flag = true

	$ShowHistory.visible = false
	$HideHistory.visible = show_close_button
	%HistoryBox.visible = true

func _on_hide_history_pressed():
	%HistoryBox.visible = false
	$HideHistory.visible = false
	$ShowHistory.visible = show_open_button

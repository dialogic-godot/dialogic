tool
extends Node
class_name DialogicCustomEvents

# references to the nodes with the handler script
# to be used later by the "event_handler" 
# keys: event_id
# values: reference to handler node.
var handlers : = {}


## -----------------------------------------------------------------------------
## Loops through the custom events folder and creates a handler node 
## for every custom event.
## 
## To handle a custom event simply check if the event_id is in the handlers dicionary keys,
## then get the value (which is the handler node) to call its hadler function
func update() -> void:
	var path : String = DialogicResources.get_working_directories()["CUSTOM_EVENTS_DIR"]
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		# goes through all the folders in the custom events folder
		while file_name != "":
			# if it found a folder
			if dir.current_is_dir() and not file_name in ['.', '..']:
				
				# look through that folder
				#print("Found custom event folder: " + file_name)
				var event = load(path.plus_file(file_name).plus_file('EventBlock.tscn')).instance()
				
				if event:
					var handler_script_path = path.plus_file(file_name).plus_file('event_'+event.event_data['event_id']+'.gd')
					var event_id = event.event_data['event_id']
					var event_name = event.event_name
					
					# not necesary, we now have the data in the handlers dict
					#custom_events[event.event_data['event_id']] = {
					#	'event_script' : handler_script_path,
					#	'event_name' : event.event_name,
					#}
					
					# Check if we already have a handler node for this event.
					if handlers.has(event_id):
						#print("Custom event ",event_id," already loaded")
						#print("Continuing...")
						file_name = dir.get_next()
						continue
					else:
						#print("No handler node for event ",event_id," found.")
						#print("Creating...")
						# create a node for the custom event an attach the script
						var handler = Node.new()
						handler.set_script(load(handler_script_path))
						handler.set_name(event_name)
						
						# not really necessary, but just in case
						handler.set_meta("event_id",event_id)
						
						#add data to dictionary
						handlers[event_id] = handler
						#add node as a child of this
						self.add_child(handler)
					
					event.queue_free()
				else:
					print("[D] An error occurred when trying to access a custom event.")
			
			
			else:
				pass # files in the directory are ignored
			file_name = dir.get_next()
	else:
		print("[D] An error occurred when trying to access the custom event folder.")

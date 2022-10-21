@tool
extends HBoxContainer

var folderStructure

var timelineFolderBreakdown:Dictionary = {}
var characterFolderBreakdown:Dictionary = {}
var definitionFolderBreakdown:Dictionary = {}
var themeFolderBreakdown:Dictionary = {}
var definitionsFile = {}
var flatDefinitionsFile = {}

var conversionRootFolder = "res://converted-dialogic"

var contents

var conversionReady = false

var varSubsystemInstalled = false
var anchorNames = {}
var prefixCharacters = false

func refresh():
	pass

func _on_verify_pressed():
	
	%OutputLog.text = ""
	
	if FileAccess.file_exists("res://dialogic/settings.cfg"):
		%OutputLog.text += "[√] Dialogic 1.x data [color=green]found![/color]\r\n"
		
		if FileAccess.file_exists("res://dialogic/definitions.json"):
			%OutputLog.text += "[√] Dialogic 1.x definitions [color=green]found![/color]\r\n"
		else:
			%OutputLog.text += "[X] Dialogic 1.x definitions [color=red]not found![/color]\r\n"
			%OutputLog.text += "Please copy the res://dialogic folder from your Dialogic 1.x project into this project and try again.\r\n"
			return
			
		if FileAccess.file_exists("res://dialogic/settings.cfg"):
			%OutputLog.text += "[√] Dialogic 1.x settings [color=green]found![/color]\r\n"
		else:
			%OutputLog.text += "[X] Dialogic 1.x settings [color=red]not found![/color]\r\n"
			%OutputLog.text += "Please copy the res://dialogic folder from your Dialogic 1.x project into this project and try again.\r\n"
			return
		
		%OutputLog.text += "\r\n"
		
		%OutputLog.text += "Verifying data:\r\n"
		var file := FileAccess.open("res://dialogic/folder_structure.json", FileAccess.READ)
		var fileContent = file.get_as_text()
		var json_object = JSON.new()
		
		var error = json_object.parse(fileContent)
		
		if error == OK:
			folderStructure = json_object.get_data()
			#print(folderStructure)
		else:
			print("JSON Parse Error: ", json_object.get_error_message(), " in ", error, " at line ", json_object.get_error_line())
			%OutputLog.text += "Dialogic 1.x folder structure [color=red]could not[/color] be read!\r\n"
			%OutputLog.text += "Please check the output log for the error the JSON parser encountered.\r\n"
			return
		#folderStructure = json_object.get_data()
		
		%OutputLog.text += "Dialogic 1.x folder structure read successfully!\r\n"
		
		#I'm going to build a new, simpler tree here, as the folder structure is too complicated
			
		
		recursive_search("Timeline", folderStructure["folders"]["Timelines"], "/")
		recursive_search("Character", folderStructure["folders"]["Characters"], "/")
		recursive_search("Definition", folderStructure["folders"]["Definitions"], "/")
		recursive_search("Theme", folderStructure["folders"]["Themes"], "/")
		
		
		%OutputLog.text += "Timelines found: " + str(timelineFolderBreakdown.size()) + "\r\n"
		%OutputLog.text += "Characters found: " + str(characterFolderBreakdown.size()) + "\r\n"
		%OutputLog.text += "Definitions found: " + str(definitionFolderBreakdown.size()) + "\r\n"
		%OutputLog.text += "Themes found: " + str(themeFolderBreakdown.size()) + "\r\n"
		
		%OutputLog.text += "\r\n"
		%OutputLog.text += "Verifying count of JSON files for match with folder structure:\r\n"
		
		var timelinesDirectory = list_files_in_directory("res://dialogic/timelines")
		if timelinesDirectory.size() ==  timelineFolderBreakdown.size():
			%OutputLog.text += "Timeline files found: [color=green]" + str(timelinesDirectory.size()) + "[/color]\r\n"
		else:
			%OutputLog.text += "Timeline files found: [color=red]" + str(timelinesDirectory.size()) + "[/color]\r\n"
			%OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
		
		var characterDirectory = list_files_in_directory("res://dialogic/characters")
		if characterDirectory.size() ==  characterFolderBreakdown.size():
			%OutputLog.text += "Character files found: [color=green]" + str(characterDirectory.size()) + "[/color]\r\n"
		else:
			%OutputLog.text += "Character files found: [color=red]" + str(characterDirectory.size()) + "[/color]\r\n"
			%OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
			
		
		file = FileAccess.open("res://dialogic/definitions.json",FileAccess.READ)
		fileContent = file.get_as_text()
		json_object = JSON.new()
		
		error = json_object.parse(fileContent)
		
		if error == OK:
			definitionsFile = json_object.get_data()
			#print(folderStructure)
		else:
			print("JSON Parse Error: ", json_object.get_error_message(), " in ", error, " at line ", json_object.get_error_line())
			%OutputLog.text += "Dialogic 1.x definitions file [color=red]could not[/color] be read!\r\n"
			%OutputLog.text += "Please check the output log for the error the JSON parser encountered.\r\n"
			return
		
		
		
		for variable in definitionsFile["variables"]:
			var varPath = definitionFolderBreakdown[variable["id"]]
			var variableInfo = {}
			variableInfo["type"] = "variable"
			variableInfo["path"] = varPath
			variableInfo["name"] = variable["name"]
			variableInfo["value"] = variable["value"]
			definitionFolderBreakdown[variable["id"]] = variableInfo
		
		for variable in definitionsFile["glossary"]:
			var varPath = definitionFolderBreakdown[variable["id"]]
			var variableInfo = {}
			variableInfo["type"] = "glossary"
			variableInfo["path"] = varPath
			variableInfo["name"] = variable["name"]
			variableInfo["text"] = variable["text"]
			variableInfo["title"] = variable["title"]
			variableInfo["extra"] = variable["extra"]
			variableInfo["glossary_type"] = variable["type"]
			definitionFolderBreakdown[variable["id"]] = variableInfo
			
		if (definitionsFile["glossary"].size() + definitionsFile["variables"].size())  ==  definitionFolderBreakdown.size():
			%OutputLog.text += "Definitions found: [color=green]" + str((definitionsFile["glossary"].size() + definitionsFile["variables"].size())) + "[/color]\r\n"
			%OutputLog.text += " • Glossaries found: " + str(definitionsFile["glossary"].size()) + "\r\n"
			%OutputLog.text += " • Variables found: " + str(definitionsFile["variables"].size()) + "\r\n"
		else:
			%OutputLog.text += "Definition files found: [color=red]" + str(definitionsFile.size()) + "[/color]\r\n"
			%OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
			
		var themeDirectory = list_files_in_directory("res://dialogic/themes")
		if themeDirectory.size() ==  themeFolderBreakdown.size():
			%OutputLog.text += "Theme files found: [color=green]" + str(themeDirectory.size()) + "[/color]\r\n"
		else:
			%OutputLog.text += "Theme files found: [color=red]" + str(themeDirectory.size()) + "[/color]\r\n"
			%OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
			
		# dirty check for the variable subsystem, as properly calling has subsystem is complicated currently
		varSubsystemInstalled = file.file_exists("res://addons/dialogic/Events/Variable/event.gd")
		
		if !varSubsystemInstalled:
			%OutputLog.text += "[color=yellow]Variable subsystem is not present in this Dialogic! Variables will not be converted![/color]"
			
		%OutputLog.text += "\r\n"
		
		%OutputLog.text += "Initial integrity check completed!\r\n"
		
		
		
		if DirAccess.dir_exists_absolute(conversionRootFolder): 
			%OutputLog.text += "[color=yellow]Conversion folder already exists, coverting will overwrite existing files.[/color]\r\n"
		else:
			%OutputLog.text += conversionRootFolder
			%OutputLog.text += "Folders are being created in " + conversionRootFolder + ". Converted files will be located there.\r\n"
			var directory = DirAccess.open("res://")
			directory.make_dir(conversionRootFolder)
			directory.open(conversionRootFolder)	
			directory.make_dir("characters")
			directory.make_dir("timelines")
			directory.make_dir("themes")
		
		conversionReady = true
		$RightPanel/Begin.disabled = false
		
	else:
		%OutputLog.text += "[X] Dialogic 1.x data [color=red]not found![/color]\r\n"
		%OutputLog.text += "Please copy the res://dialogic folder from your Dialogic 1.x project into this project and try again.\r\n"


func list_files_in_directory(path):
	var files = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			if file.ends_with(".json") || file.ends_with(".cfg"):
				files.append(file)

	dir.list_dir_end()
	return files

func recursive_search(currentCheck, currentDictionary, currentFolder):
	for structureFile in currentDictionary["files"]:
		match currentCheck:
			"Timeline": timelineFolderBreakdown[structureFile] = characterNameConversion(currentFolder, false)
			"Character": characterFolderBreakdown[structureFile] = characterNameConversion(currentFolder,false)
			"Definition": definitionFolderBreakdown[structureFile] = characterNameConversion(currentFolder, false)
			"Theme": themeFolderBreakdown[structureFile] = characterNameConversion(currentFolder, false)
	
	for structureFolder in currentDictionary["folders"]:
		recursive_search(currentCheck, currentDictionary["folders"][structureFolder], currentFolder + structureFolder + "/")






func _on_begin_pressed():
	%OutputLog.text += "-----------------------------------------\r\n"
	%OutputLog.text += "Beginning file conversion:\r\n"
	%OutputLog.text += "\r\n"
	
	#Variable conversion needs to be first, to build the lookup table for new style
	#Character conversion needs to be before timelines, so the character names are available
	convertVariables()
	convertCharacters()
	convertTimelines()
	convertGlossaries()
	convertThemes()
	convertSettings()
	
	%OutputLog.text += "All conversions complete!\r\n"
	%OutputLog.text += "\r\nPlease check to make sure your timelines all look good. After that, you can remove the /addons/dialogic/Events/Converter folder, as it is no longer needed.\r\n\r\n"
	%OutputLog.text += "Please be aware, Godot may take some time on the next project load to reload all of the Characters and Timelines. This is normal, and should only happen the one time."
	

func convertTimelines():
	%OutputLog.text += "Converting timelines: \r\n"
	for item in timelineFolderBreakdown:
		var folderPath = timelineFolderBreakdown[item]
		%OutputLog.text += "Timeline " + folderPath + item +": "
		var jsonData = {}
		var file := FileAccess.open("res://dialogic/timelines/" + item, FileAccess.READ)
		var fileContent = file.get_as_text()
		var json_object = JSON.new()
		
		var error = json_object.parse(fileContent)
		
		if error == OK:
			contents = json_object.get_data()
			var fileName = contents["metadata"]["name"]
			%OutputLog.text += "Name: " + fileName + ", " + str(contents["events"].size()) + " timeline events"
			
			
			if not DirAccess.dir_exists_absolute(conversionRootFolder + "/timelines" + folderPath): 
				var directory = DirAccess.open(conversionRootFolder + "/timelines")
				
				var progresiveDirectory = ""
				for pathItem in folderPath.split('/'):
					directory.open(conversionRootFolder + "/timelines" + progresiveDirectory)
					if pathItem!= "":
						progresiveDirectory += "/" + pathItem
					if !directory.dir_exists(conversionRootFolder + "/timelines" + progresiveDirectory):
						directory.make_dir(conversionRootFolder + "/timelines" + progresiveDirectory)
				
			#just double check because sometimes its making double slashes at the final filename
			if folderPath.right(1) == "/":
				folderPath = folderPath.left(-1)
			# we will save it as an intermediary file first, then on second pass cleanup make it the .dtl	
			var newFilePath = conversionRootFolder + "/timelines" + folderPath + "/" + fileName + ".cnv"	
			
			file = FileAccess.open(newFilePath, FileAccess.WRITE)
			
			# update the new location so we know where second pass items are

			timelineFolderBreakdown[item] = newFilePath
			
			
			var processedEvents = 0

			
			var depth = []
			for event in contents["events"]:
				processedEvents += 1
				var eventLine = ""
				
				for i in depth:
					eventLine += "	"
				
				if "dialogic_" in event["event_id"]:
					match event["event_id"]:
						"dialogic_001":
							#Text Event
							var has_character:bool = false
							if event['character'] != "" && event['character']:
								has_character = true
								eventLine += characterFolderBreakdown[event['character']]['searchable_name']

								if event['portrait'] != "":
									eventLine += "(" +  event['portrait'] + ")"
								
								eventLine += ": "
							if '\n' in event['text']:
								var splitCount = 0
								var split = event['text'].split('\n')
								for splitItem in split:
									if has_character == false && splitItem.find(' ') > 0 && splitItem.find(':') > 0 && (splitItem.find(' ') > splitItem.find(':')):
										splitItem = splitItem.insert("\\", splitItem.find(':'))
									if splitCount == 0:
										file.store_line(eventLine + splitItem + "\\")
									else:
										file.store_line(splitItem + "\\")
									splitCount += 1
							else: 
								var text_line  = variableNameConversion(event['text'])
								if has_character == false && text_line.find(' ') > 0 && text_line.find(':') > 0 && (text_line.find(' ') > text_line.find(':')):
										text_line = text_line.insert("\\", text_line.find(':'))
								file.store_string(eventLine + text_line)
						"dialogic_002":
							# Character event
							
							#For some reason this is loading as a float, and the match is failing. so hard casting as string
							var eventType:String = str(event['type'])
							
							match eventType:
								"0":
									if event['character'] != "":
										eventLine += "Join "
										eventLine += characterFolderBreakdown[event['character']]['searchable_name']
										if (event['portrait'] != ""):
											eventLine += " (" + event['portrait'] + ") "
										
										for i in event['position']:
											if event['position'][i] == true:
												#1.x uses positions 0-4, while the default 2.0 scene uses positions 1-5
												eventLine += str(i.to_int() + 1)
										
										if (event['animation'] != "[Default]" && event['animation'] != "") || ('z_index' in event) || ('mirror_portrait' in event):
											# Note: due to Anima changes, animations will be converted into a default. Times and wait will be perserved
											eventLine += " ["
											if (event['animation'] != "[Default]" && event['animation'] != ""):
												eventLine += " [animation=\"Instant In Or Out\" "
												eventLine += "length=\"" +  str(event['animation_length']) + "\""
												if "animation_wait" in event:
													eventLine += " wait=\"true\""
											
											if 'z_index' in event:
												if event['z_index'] != 0:
													eventLine += ' z-index="' + str(event['z_index']) + '"'
											if 'mirror_portrait' in event:
												if event['mirror_portrait']:
													eventLine += ' mirrored="true"'
											
											eventLine += "]"
											
										file.store_string(eventLine)	
									else:
										eventLine += "# Character join event that did not have a selected character"
										file.store_string(eventLine)	
								"2":
									if event['character'] != "":
										if event['character'] != "[All]":
												
											eventLine += "Update "
											eventLine += characterFolderBreakdown[event['character']]['searchable_name']
											if 'portrait' in event:
												if (event['portrait'] != "") && (event['portrait'] != "(Don't change)"):
													eventLine += " (" + event['portrait'] + ") "

											var positionCheck = false
											if 'position' in event:
												for i in event['position']:
													
													if event['position'][i] == true:
														positionCheck = true
														eventLine += str(i.to_int() + 1)
													
											if !positionCheck:
												eventLine += " 0"
												
											if (event['animation'] != "[Default]" && event['animation'] != "") || ('z_index' in event) || ('mirror_portrait' in event):
												# Note: due to Anima changes, animations will be converted into a default. Times and wait will be perserved
												eventLine += " ["
												if (event['animation'] != "[Default]" && event['animation'] != ""):
													eventLine += "animation=\"Heartbeat\" "
													eventLine += "length=\"" +  str(event['animation_length']) + "\""
													if "animation_wait" in event:
														eventLine += " wait=\"true\""
													if "animation_repeat" in event:
														eventLine += " repeat=\"" + str(event['animation_repeat']) + "\""
												if 'z_index' in event:																							if 'z_index' in event:
													if event['z_index'] != 0:
														eventLine += ' z-index="' + str(event['z_index']) + '"'
												if 'mirror_portrait' in event:
													if event['mirror_portrait']:
														eventLine += ' mirrored="true"'
												eventLine += "]"
												
											file.store_string(eventLine)	
										else:
											file.store_string(eventLine + "# Update and Leave All not currently implemented")		
									else:
										eventLine += "# Character Update event that did not have a selected character"
										file.store_string(eventLine)	
								"1":
									if event['character'] != "":
										
										eventLine += "Leave "
										if event['character'] == "[All]":
											eventLine += "--All--"
										else:
											eventLine += characterFolderBreakdown[event['character']]['searchable_name']
										
										if event['animation'] != "[Default]" && event['animation'] != "":
											# Note: due to Anima changes, animations will be converted into a default. Times and wait will be perserved
											eventLine += " [animation=\"Instant In Or Out\" "
											eventLine += "length=\"" +  str(event['animation_length']) + "\""
											if "animation_wait" in event:
												eventLine += " wait=\"true\""
											eventLine += "]"
											file.store_string(eventLine)	
									else:
										eventLine += " # Character Update event that did not have a selected character"
										file.store_string(eventLine)	
								_:
									file.store_string("# failed" + str(event['type']))
								
							
						"dialogic_010":
							# Question event
							# With the change in 2.0, the root of the Question block is simply text event
							if event['character'] != "" && event['character']:
								eventLine += characterFolderBreakdown[event['character']]['name']
								if event['portrait'] != "":
									eventLine += "(" +  event['portrait'] + ")"
								
								eventLine += ": "
							if '\n' in event['question']:
								var splitCount = 0
								var split = event['text'].split('\n')
								for splitItem in split:
									if splitCount == 0:
										file.store_line(eventLine + splitItem + "\\")
									else:
										file.store_line(splitItem + "\\")
									splitCount += 1
							else: 
								file.store_string(eventLine + event['question'])
								
							#depth.push_front("question")

						"dialogic_011":
							#Choice event
							
							#Choice's in 1.x have depth, but they do not have matching End Nodes as Questions and Conditionals do
							if depth.size() > 0:
								if depth[0] == "choice":								
									#reset the tabs for this choice to be one tree up 
									
									if depth.size() == 1:
										eventLine = ""
									else:
										for i in (depth.size() - 1):
											eventLine = "	"

							else:
								#for the next line we want to add a depth								

								depth.push_front("choice")
								
								
							eventLine += "- "
							eventLine += event['choice']
							
							if 'value' in event:
								if event['value'] != "":
									var valueLookup = variableNameConversion("[" + definitionFolderBreakdown[event['definition']]['path'] + definitionFolderBreakdown[event['definition']]['name'] + "]" )
							
									eventLine += " [if "
									eventLine += valueLookup
									if event['condition'] != "":
										eventLine += " " + event['condition']
									else:
										#default is true, so it may not store it
										eventLine += " =="
									
									# weird line due to missing type casts on String in current Godot 4 alpha
									if event['value'] == str(event['value'].to_int()):
										eventLine += " " + event['value']
									else:
										eventLine += " \"" + event['value'] + "\""
									
									eventLine += "]"
									
							
							file.store_string(eventLine)
							#print("choice node")
							#print ("bracnh depth now" + str(depth))
						"dialogic_012":
							#If event
							var valueLookup = variableNameConversion("[" + definitionFolderBreakdown[event['definition']]['path'] + definitionFolderBreakdown[event['definition']]['name'] + "]" )
							
							eventLine += "if "
							eventLine += valueLookup
							if event['condition'] != "":
								eventLine += " " + event['condition']
							else:
								#default is true, so it may not store it
								eventLine += " =="
							
							# weird line due to missing type casts on String in current Godot 4 alpha
							if event['value'] == str(event['value'].to_int()):
								eventLine += " " + event['value']
							else:
								eventLine += " \"" + event['value'] + "\""
							
							eventLine += ":"
							file.store_string(eventLine)
							#print("if branch node")
							depth.push_front("condition")

							#print ("bracnh depth now" + str(depth))
						"dialogic_013": 
							#End Branch event
							# doesnt actually make any lines, just adjusts the tab depth
							#print("end branch node")


							var _popped = depth.pop_front()
							#print ("bracnh depth now" + str(depth))
						"dialogic_014":
							#Set Value event
							if varSubsystemInstalled:
								
								
								eventLine += "VAR "
								eventLine += variableNameConversion("[" + definitionFolderBreakdown[event['definition']]['path'] + definitionFolderBreakdown[event['definition']]['name'] + "]" )
								eventLine += " = "
								
								if "set_random" in event:
									if event['set_random'] == true:
										eventLine += "[random=\"True\""
										if "random_lower_limit" in event:
											eventLine += " min=\"" + str(event['random_lower_limit']) + "\""
										if "random_upper_limit" in event:
											eventLine += " max=\"" + str(event['random_upper_limit']) + "\""
											
										eventLine += "]"
									else:
										eventLine += event['set_value'] 
								else:
									eventLine +=  event['set_value'] 
								
								file.store_string(eventLine)
							else:
								file.store_string(eventLine + "# Set variable function. Variables subsystem is disabled")
						"dialogic_015":
							#Label event
							file.store_string(eventLine + "[label name=\"" + event['name'] +"\"]")
							anchorNames[event['id']] = event['name']
						"dialogic_016":
							#Goto event
							# Dialogic 1.x only allowed jumping to labels in the same timeline
							# But since it is stored as a ID reference, we will have to get it on the second pass
							
							file.store_string(eventLine + "[jump label=<" + event['anchor_id'] +">]")
							#file.store_string(eventLine + "# jump label, just a comment for testing")
						"dialogic_020":
							#Change Timeline event
							# we will need to come back to this one on second pass, since we may not know the new path yet
							
							file.store_string(eventLine + "[jump timeline=<" + event['change_timeline'] +">]")
							#file.store_string(eventLine + "# jump timeline, just a comment for testing")
						"dialogic_021":
							#Change Background event
							#in Dialogic 1.x, fade default value was 1. its now 0, so we need to always write one here
							var time: float = 1.0
							if "fade_duration" in event:
								time = event['fade_duration']
							file.store_string(eventLine + "[background arg=\"" + event['background'] +"\" fade=\"" + str(time) + "\"]")
						"dialogic_022":
							#Close Dialog event
							file.store_string(eventLine + "[end_timeline]")
						"dialogic_023":
							#Wait event
							
							eventLine += "[wait time=\"" + str(event['wait_seconds']) + "\""
							if !("hide_dialogbox" in event) || (event['hide_dialogbox'] == true):
								eventLine += ' hide_text="true"'
							else:
								eventLine += ' hide_text="false"'
							eventLine += "]"
							file.store_string(eventLine)
						"dialogic_024":
							#Change Theme event
							file.store_string(eventLine + '[style name="<' + event['set_theme'] + '>"]')
						"dialogic_025": 
							#Set Glossary event
							file.store_string(eventLine + "# Set Glossary event, not currently implemented")
						"dialogic_026":
							#Save event 
							if event['use_default_slot']:
								file.store_string(eventLine + "[save slot=\"Default\"]")
							else:
								file.store_string(eventLine + "[save slot=\"" + event['custom_slot'] + "\"]")
							
						"dialogic_030":
							#Audio event
							eventLine += "[sound"
							eventLine += " path=\"" + event['file'] + "\""
							eventLine += " volume=\"" + str(event['volume']) + "\""
							eventLine += " bus=\"" + event['audio_bus'] + "\"]"
							file.store_string(eventLine)
						"dialogic_031":
							#Background Music event
							eventLine += "[music"
							eventLine += " path=\"" + event['file'] + "\""
							eventLine += " volume=\"" + str(event['volume']) + "\""
							eventLine += " fade=\"" + str(event['fade_length']) + "\""
							eventLine += " bus=\"" + event['audio_bus'] + "\""
							eventLine += " loop=\"true\"]"
							file.store_string(eventLine)
						"dialogic_040":
							#Emit Signal event
							file.store_string(eventLine + "[signal arg=\"" + event['emit_signal'] +"\"]")
						"dialogic_041":
							#Change Scene event
							file.store_string(eventLine + "# Change scene event is deprecated. Scene called was: " + event['change_scene'])
						"dialogic_042":
							#Call Node event
							eventLine += "[call_node path=\"" + event['call_node']['target_node_path'] + "\" "
							eventLine += "method=\"" + event['call_node']['method_name'] + "\" "
							eventLine += "args=\"["
							for arg in event['call_node']['arguments']:
								eventLine += "\"" + arg + "\", "
							
							#remove the last comma and space
							eventLine = eventLine.left(-2)
							
							eventLine += "]\"]"
							file.store_string(eventLine)
						_: 
							file.store_string(eventLine + "# unimplemented Dialogic control with unknown number")
						
						
					
					
				else: 
					var returnString = CustomEventConverter.convertCustomEvent(event)
					if returnString != "":
						file.store_string(eventLine + returnString)
					else:
						eventLine += "# Custom event: "
						eventLine += str(event)
						eventLine = eventLine.replace("{", "*")
						eventLine = eventLine.replace("}", "*")
					
						file.store_string(eventLine)
				
				file.store_string("\r\n\r\n")
			
			
			
			%OutputLog.text += "Processed events: " + str(processedEvents) + "\r\n"
		else:
			%OutputLog.text += "[color=red]There was a problem parsing this file![/color]\r\n"
		
	%OutputLog.text += "\r\n"
	
	#second pass
	for item in timelineFolderBreakdown:
		%OutputLog.text += "Verifying file: " + timelineFolderBreakdown[item] + "\r\n"
		
		var oldFile = FileAccess.open(timelineFolderBreakdown[item], FileAccess.READ)
		var newFile = FileAccess.open(timelineFolderBreakdown[item].replace(".cnv", ".dtl"), FileAccess.WRITE)
		
		var regex = RegEx.new()
		regex.compile('(<.*?>)')
		#var result = regex.search_all(oldText)
		
		
		var whitespaceCount = 0
		while oldFile.get_position() < oldFile.get_length():
			var line = oldFile.get_line()
			
			if line.length() == 0:
				#clean up any extra whitespace so theres only one line betwen each command
				whitespaceCount += 1
				if whitespaceCount < 2:
					newFile.store_string("\r\n\r\n")
			else:
				whitespaceCount = 0
				
				var result = regex.search_all(line)
				if result:
					for res in result:
						var r_string = res.get_string()
						var newString = r_string.substr(1,r_string.length()-2)

						if "timeline" in line:
							newString = "\"" + timelineFolderBreakdown[newString].replace(".cnv", ".dtl") + "\""
						if "label" in line:
							newString = "\"" + anchorNames[newString] + "\""
						if "style" in line:
							var prev = newString
							var config = ConfigFile.new()
							var error = config.load("res://dialogic/themes/" + newString)
							if error == OK:
								if config.has_section_key("settings", "name"):
									newString = config.get_value("settings", "name")
								
							if newString == prev:
								newString = "DefaultTheme"
						
						line = line.replace(r_string,newString)
						newFile.store_string(line)
				else:
					newFile.store_string(line)
		
		oldFile = null
		
		var fileDirectory = timelineFolderBreakdown[item].replace(timelineFolderBreakdown[item].split("/")[-1], "")
		var dir = DirAccess.open(fileDirectory)
		dir.remove(timelineFolderBreakdown[item])
		
		%OutputLog.text += "Completed conversion of file: " + timelineFolderBreakdown[item].replace(".cnv", ".dtl") + "\r\n"
		
		#print(item)
	


func convertCharacters(): 
	%OutputLog.text += "Converting characters: \r\n"
	for item in characterFolderBreakdown:
		var original_file = item
		var folderPath = characterFolderBreakdown[item]
		%OutputLog.text += "Character " + folderPath + item +": "
		var jsonData = {}
		var file := FileAccess.open("res://dialogic/characters/" + item, FileAccess.READ)
		var fileContent = file.get_as_text()
		var json_object = JSON.new()
		
		var error = json_object.parse(fileContent)
		
		if error == OK:
			contents = json_object.get_data()
			var fileName = contents["name"]
			%OutputLog.text += "Name: " + fileName + "\r\n"
			
			if ("[" in fileName) || ("]" in fileName) || ("?" in fileName):
				%OutputLog.text += " [color=yellow]Stripping invalid characters from file name![/color]\r\n"
				fileName = characterNameConversion(fileName)

				
			
			
			if not DirAccess.dir_exists_absolute(conversionRootFolder + "/characters" + folderPath): 
				var directory = DirAccess.open(conversionRootFolder + "/characters")
				
				var progresiveDirectory = ""
				for pathItem in folderPath.split('/'):
					directory.open(conversionRootFolder + "/characters" + progresiveDirectory)
					if pathItem!= "":
						progresiveDirectory += "/" + pathItem
					if !directory.dir_exists(conversionRootFolder + "/characters" + progresiveDirectory):
						directory.make_dir(conversionRootFolder + "/characters" + progresiveDirectory)
			
			#add the prefix if the prefix option is enabled
			if prefixCharacters:
				var prefix = ""
				for level in folderPath.split('/'):
					if level != "":
						prefix += level.left(2) + "-"
				fileName = prefix + fileName
			# using the resource constructor for this one
			
			var current_character = DialogicCharacter.new()
			current_character.resource_path = conversionRootFolder + "/characters" + folderPath + "/" + fileName + ".dch"
			# Everything needs to be in exact order

			current_character.color = Color(contents["color"].right(6))
			var customInfoDict = {}
			customInfoDict["sound_moods"] = {}
			customInfoDict["theme"] = ""
			current_character.custom_info = customInfoDict
			current_character.description = varNameStripSpecial(contents["description"])
			if contents["display_name"] == "":
				current_character.display_name = varNameStripSpecial(contents["name"])
			else:
				current_character.display_name = varNameStripSpecial(contents["display_name"])
			current_character.mirror = contents["mirror_portraits"]
			#current_character.name = varNameStripSpecial(contents["name"])
			current_character.nicknames = []
			current_character.offset = Vector2(0,0)
			
			var portraitsList = {}
			var firstPortrait = ""
			for portrait in contents['portraits']:			
				var portraitData = {}
				if portrait['path'] != "":
					if ".tscn" in portrait['path']:
						portraitData['scene'] = portrait['path']
					else:
						portraitData['image'] = portrait['path']

				#use the global offset, scale, and mirror setting from the origianl character file
				portraitData['offset'] = Vector2(contents['offset_x'], contents['offset_y'])
				portraitData['scale'] = contents['scale'] / 100
				portraitData['mirror'] = contents['mirror_portraits']
				
				#discard it if there's an empty Default, so it doesn't throw an error
				if !((portrait['name'] == "Default") && (portrait['path'] == "")) && !((portrait['name'] == "") && (portrait['path'] == "")):
					portraitsList[portrait['name']] = portraitData
					if firstPortrait == "":
						firstPortrait = portrait['name']
				
			
			
			current_character.portraits = portraitsList
			if firstPortrait != "":
				current_character.default_portrait = firstPortrait 
			current_character.scale = 1.0
			
			ResourceSaver.save(current_character, current_character.resource_path)	

			# Before we're finished here, update the folder breakdown so it has the proper character name
			var infoDict = {}
			infoDict["original_file"] = original_file
			infoDict["path"] = characterFolderBreakdown[item]
			infoDict["name"] = fileName
			var name_breakdown:Array = ( folderPath + fileName).split("/")
			name_breakdown.reverse()
			infoDict["name_breakdown"] = name_breakdown	
			
			infoDict["searchable_name"] = infoDict["name_breakdown"][0] 
			
			characterFolderBreakdown[item] = infoDict
			
			%OutputLog.text += "\r\n"
		else:
			%OutputLog.text += "[color=red]There was a problem parsing this file![/color]\r\n"
			
	# Second pass, shorten all of the paths, so they match the character dictionary in Dialogic itself
	
	# Temporarily need an array to be able to sort
	var sorting_array:Array = []
	
	for item in characterFolderBreakdown:
		sorting_array.append(characterFolderBreakdown[item])
	
	sorting_array.sort_custom(func(a, b):return a['name_breakdown'].count("/") < b['name_breakdown'].count("/"))
	
	var clean_search_path:bool = false
	var depth = 1
	
	while !clean_search_path:
		var interim_array:Array = []
		clean_search_path = true
		
		for i in sorting_array.size():
			if sorting_array.filter(func(val): return val['searchable_name'] == sorting_array[i]['searchable_name']).size() > 1:
				clean_search_path = false
				var replace_dict:Dictionary = sorting_array[i]
				replace_dict["searchable_name"] = replace_dict["name_breakdown"][depth] + "/" + replace_dict["searchable_name"]
				interim_array.append(replace_dict)
			else: 
				interim_array.append(sorting_array[i])
		depth += 1
		sorting_array = interim_array	
		
	characterFolderBreakdown.clear()
	
	for item in sorting_array:
		if item["searchable_name"].count(" ") > 0:
			item["searchable_name"] = '"' + item["searchable_name"] + '"'
		characterFolderBreakdown[item['original_file']] = item
		%OutputLog.text += "Final character name for " + item['original_file'] + ": " + item['searchable_name'] + "\r\n"
	
	%OutputLog.text += "\r\n"

func convertVariables():
	%OutputLog.text += "Converting variables: \r\n"
	
	var convertedVariables = 0
	# Creating a file with a format identical to how the variables are stored in project settings
	if varSubsystemInstalled:
		var newVariableDictionary = {}
		for varItem in definitionFolderBreakdown:
			if "type" in definitionFolderBreakdown[varItem]:
				if definitionFolderBreakdown[varItem]["type"] == "variable":
					if definitionFolderBreakdown[varItem]["path"] == "/":
						newVariableDictionary[varNameStripSpecial(definitionFolderBreakdown[varItem]["name"])] = definitionFolderBreakdown[varItem]["value"]
						flatDefinitionsFile[varNameStripSpecial(definitionFolderBreakdown[varItem]["name"])] = varItem
						convertedVariables += 1
					else:
						# I will fill this one in later, need to figure out the recursion for it
						var dictRef = newVariableDictionary
						var flatNameBuilder = ""
						
						for pathItem in varNameStripSpecial(definitionFolderBreakdown[varItem]["path"]).split("/"):
							
							if pathItem != "":
								if pathItem in dictRef:
									dictRef = dictRef[pathItem]
									flatNameBuilder += pathItem + "."
								else:
									dictRef[pathItem] = {}
									dictRef = dictRef[pathItem]
									flatNameBuilder += pathItem + "."
								
						dictRef[varNameStripSpecial(definitionFolderBreakdown[varItem]["name"])] = definitionFolderBreakdown[varItem]["value"]
						convertedVariables +=1
						var flatName = flatNameBuilder + varNameStripSpecial(definitionFolderBreakdown[varItem]["name"])
						flatDefinitionsFile[flatName] = varItem
						

		ProjectSettings.set_setting('dialogic/variables', null)
		ProjectSettings.set_setting('dialogic/variables', newVariableDictionary)
		ProjectSettings.save()
		
		#rebuild the data in the other tabs, so it doesnt override it
		find_parent('SettingsEditor').refresh()
		%OutputLog.text += str(convertedVariables) + " variables converted, and saved to project!\r\n"
	else:
		%OutputLog.text += "[color=yellow]Variable subsystem is not present! Variables were not converted![/color]\r\n"
	
	
	%OutputLog.text += "\r\n"
	

func convertGlossaries():
	%OutputLog.text += "Converting glossaries: [color=red]not currently implemented[/color] \r\n"
	
	%OutputLog.text += "\r\n"

func convertThemes():
	%OutputLog.text += "Converting themes: [color=red]not currently implemented[/color] \r\n"
	
	%OutputLog.text += "\r\n"
	
func varNameStripSpecial(oldVariable):
	# This is to remove special characters from variable names
	# Since in code variables are accessed by Dialogic.VAR.path.to.variable, characters not usable in Godot paths have to be removed
	var newVariable = oldVariable
	newVariable = newVariable.replace(" ", "_")
	newVariable = newVariable.replace(".", "_")
	newVariable = newVariable.replace("-", "_")
	
	
	return(newVariable)
	
func variableNameConversion(oldText):
	var newText = oldText
	var regex = RegEx.new()
	regex.compile('(\\[.*?\\])')
	var result = regex.search_all(oldText)
	if result:
		for res in result:
			var r_string = res.get_string()
			var newString = res.get_string()
			newString = newString.replace("[", "")
			newString = newString.replace("]", "")
			if newString[0] == '/':
				newString = newString.right(-1)
			
			newString = varNameStripSpecial(newString)
			newString = newString.replace("/", ".")
			
			
			
			if newString in flatDefinitionsFile:
				newString = "{" + newString + "}"
				newText = newText.replace(r_string, newString)
			
			
	
	return(newText)
	
func characterNameConversion(oldText:String, filter_forward_slash:bool = true):
	#as some characters aren't supported in filenames, we need to convert both the filenames, and references to them
	#Most character name restrictions are only restrictions of Windows, but we are going to enforce it for Dialogic due to node and regex complexities for platform uniformity
	#We're also restricting the special characters used for other designations 
	var newText = oldText
	newText = newText.replace("<","[")
	newText = newText.replace(">","]")
	newText = newText.replace(":","-")
	newText = newText.replace("\\","/")
	if filter_forward_slash:
		newText = newText.replace("/","-")
	newText = newText.replace("|","-")
	newText = newText.replace("*","@")
	newText = newText.replace("?","0")
	newText = newText.replace('"',"'")
	
	#These ones as they are the delimiter for portraits
	newText = newText.replace("(","[")
	newText = newText.replace(")","]")
	
	
	return newText

func convertSettings():
	%OutputLog.text += "Converting other settings: \r\n"
	%OutputLog.text += "[color=yellow]Note! Most original settings can't be converted.[/color] \r\n"
	
	
	var config = ConfigFile.new()
	
	var err = config.load("res://dialogic/settings.cfg")
	if err != OK:
		%OutputLog.text += "[color=red]Dialogic 1.x Settings file could not be loaded![/color] \r\n"
		return
	
	ProjectSettings.set_setting('dialogic/text/autocolor_names', config.get_value("dialog", "auto_color_names", true))
	ProjectSettings.set_setting('dialogic/choices/autofocus_first', config.get_value("input", "autofocus_choices", false))
	ProjectSettings.set_setting('dialogic/choices/delay', config.get_value("input", "delay_after_options", 0.2))
	ProjectSettings.save()
	


func _on_check_box_toggled(button_pressed):
	print("box checked")
	prefixCharacters = button_pressed
	%OutputLog.text += "\r\n\r\nToggling this will add a prefix to all character filenames, which will have letters from each folder depth they are in. Characters in the root folder will have no prefix. \r\n"

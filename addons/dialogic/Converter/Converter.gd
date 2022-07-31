extends Node2D

var folderStructure

var timelineFolderBreakdown:Dictionary = {}
var characterFolderBreakdown:Dictionary = {}
var definitionFolderBreakdown:Dictionary = {}
var themeFolderBreakdown:Dictionary = {}
var definitionsFile = {}

var conversionRootFolder = "res://converted-dialogic"

var contents

# Called when the node enters the scene tree for the first time.
func _ready():
	var file = File.new()
	
	if file.file_exists("res://dialogic/settings.cfg"):
		$Panel/OutputLog.text += "[√] Dialogic 1.x data [color=green]found![/color]\r\n"
		
		if file.file_exists("res://dialogic/definitions.json"):
			$Panel/OutputLog.text += "[√] Dialogic 1.x definitions [color=green]found![/color]\r\n"
		else:
			$Panel/OutputLog.text += "[X] Dialogic 1.x definitions [color=red]not found![/color]\r\n"
			$Panel/OutputLog.text += "Please copy the res://dialogic folder from your Dialogic 1.x project into this project and try again.\r\n"
			return
			
		if file.file_exists("res://dialogic/settings.cfg"):
			$Panel/OutputLog.text += "[√] Dialogic 1.x settings [color=green]found![/color]\r\n"
		else:
			$Panel/OutputLog.text += "[X] Dialogic 1.x settings [color=red]not found![/color]\r\n"
			$Panel/OutputLog.text += "Please copy the res://dialogic folder from your Dialogic 1.x project into this project and try again.\r\n"
			return
		
		$Panel/OutputLog.text += "\r\n"
		
		$Panel/OutputLog.text += "Verifying data:\r\n"
		file.open("res://dialogic/folder_structure.json",File.READ)
		var fileContent = file.get_as_text()
		var json_object = JSON.new()
		
		var error = json_object.parse(fileContent)
		
		if error == OK:
			folderStructure = json_object.get_data()
			#print(folderStructure)
		else:
			print("JSON Parse Error: ", json_object.get_error_message(), " in ", error, " at line ", json_object.get_error_line())
			$Panel/OutputLog.text += "Dialogic 1.x folder structure [color=red]could not[/color] be read!\r\n"
			$Panel/OutputLog.text += "Please check the output log for the error the JSON parser encountered.\r\n"
			return
		#folderStructure = json_object.get_data()
		
		$Panel/OutputLog.text += "Dialogic 1.x folder structure read successfully!\r\n"
		
		#I'm going to build a new, simpler tree here, as the folder structure is too complicated
			
		
		recursive_search("Timeline", folderStructure["folders"]["Timelines"], "/")
		recursive_search("Character", folderStructure["folders"]["Characters"], "/")
		recursive_search("Definition", folderStructure["folders"]["Definitions"], "/")
		recursive_search("Theme", folderStructure["folders"]["Themes"], "/")
		
		
		$Panel/OutputLog.text += "Timelines found: " + str(timelineFolderBreakdown.size()) + "\r\n"
		$Panel/OutputLog.text += "Characters found: " + str(characterFolderBreakdown.size()) + "\r\n"
		$Panel/OutputLog.text += "Definitions found: " + str(definitionFolderBreakdown.size()) + "\r\n"
		$Panel/OutputLog.text += "Themes found: " + str(themeFolderBreakdown.size()) + "\r\n"
		
		$Panel/OutputLog.text += "\r\n"
		$Panel/OutputLog.text += "Verifying count of JSON files for match with folder structure:\r\n"
		
		var timelinesDirectory = list_files_in_directory("res://dialogic/timelines")
		if timelinesDirectory.size() ==  timelineFolderBreakdown.size():
			$Panel/OutputLog.text += "Timeline files found: [color=green]" + str(timelinesDirectory.size()) + "[/color]\r\n"
		else:
			$Panel/OutputLog.text += "Timeline files found: [color=red]" + str(timelinesDirectory.size()) + "[/color]\r\n"
			$Panel/OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
		
		var characterDirectory = list_files_in_directory("res://dialogic/characters")
		if characterDirectory.size() ==  characterFolderBreakdown.size():
			$Panel/OutputLog.text += "Character files found: [color=green]" + str(characterDirectory.size()) + "[/color]\r\n"
		else:
			$Panel/OutputLog.text += "Character files found: [color=red]" + str(characterDirectory.size()) + "[/color]\r\n"
			$Panel/OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
			
		
		file.open("res://dialogic/definitions.json",File.READ)
		fileContent = file.get_as_text()
		json_object = JSON.new()
		
		error = json_object.parse(fileContent)
		
		if error == OK:
			definitionsFile = json_object.get_data()
			#print(folderStructure)
		else:
			print("JSON Parse Error: ", json_object.get_error_message(), " in ", error, " at line ", json_object.get_error_line())
			$Panel/OutputLog.text += "Dialogic 1.x definitions file [color=red]could not[/color] be read!\r\n"
			$Panel/OutputLog.text += "Please check the output log for the error the JSON parser encountered.\r\n"
			return
		
		if (definitionsFile["glossary"].size() + definitionsFile["variables"].size())  ==  definitionFolderBreakdown.size():
			$Panel/OutputLog.text += "Definitions found: [color=green]" + str((definitionsFile["glossary"].size() + definitionsFile["variables"].size())) + "[/color]\r\n"
			$Panel/OutputLog.text += " • Glossaries found: " + str(definitionsFile["glossary"].size()) + "\r\n"
			$Panel/OutputLog.text += " • Variables found: " + str(definitionsFile["variables"].size()) + "\r\n"
			
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
		else:
			$Panel/OutputLog.text += "Definition files found: [color=red]" + str(definitionsFile.size()) + "[/color]\r\n"
			$Panel/OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
			
		var themeDirectory = list_files_in_directory("res://dialogic/themes")
		if themeDirectory.size() ==  themeFolderBreakdown.size():
			$Panel/OutputLog.text += "Theme files found: [color=green]" + str(themeDirectory.size()) + "[/color]\r\n"
		else:
			$Panel/OutputLog.text += "Theme files found: [color=red]" + str(themeDirectory.size()) + "[/color]\r\n"
			$Panel/OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
			
		$Panel/OutputLog.text += "\r\n"
		
		$Panel/OutputLog.text += "Initial integrity check completed!\r\n"
		
		
		var directory = Directory.new()
		var directoryCheck = directory.dir_exists(conversionRootFolder)
		
		if directoryCheck: 
			$Panel/OutputPath.text += conversionRootFolder
			$Panel/OutputLog.text += "[color=yellow]Conversion folder already exists, coverting will overwrite existing files.[/color]\r\n"
		else:
			$Panel/OutputPath.text += conversionRootFolder
			$Panel/OutputLog.text += "Folders are being created in " + conversionRootFolder + ". Converted files will be located there.\r\n"
			directory.open("res://")
			directory.make_dir(conversionRootFolder)
			directory.open(conversionRootFolder)	
			directory.make_dir("characters")
			directory.make_dir("timelines")
			directory.make_dir("themes")
		
		$Panel/Begin.disabled = false	
		
	else:
		$Panel/OutputLog.text += "[X] Dialogic 1.x data [color=red]not found![/color]\r\n"
		$Panel/OutputLog.text += "Please copy the res://dialogic folder from your Dialogic 1.x project into this project and try again.\r\n"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_choose_folder_pressed():
	#var folder = FileDialog.new()
	
	$FileDialog.show()
	

func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
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
			"Timeline": timelineFolderBreakdown[structureFile] = currentFolder
			"Character": characterFolderBreakdown[structureFile] = currentFolder
			"Definition": definitionFolderBreakdown[structureFile] = currentFolder
			"Theme": themeFolderBreakdown[structureFile] = currentFolder
	
	for structureFolder in currentDictionary["folders"]:
		recursive_search(currentCheck, currentDictionary["folders"][structureFolder], currentFolder + structureFolder + "/")



func _on_begin_pressed():
	$Panel/OutputLog.text += "-----------------------------------------\r\n"
	$Panel/OutputLog.text += "Beginning file conversion:\r\n"
	$Panel/OutputLog.text += "\r\n"
	
	convertTimelines()
	convertCharacters()
	convertVariables()
	convertGlossaries()
	convertThemes()
	
	$Panel/OutputLog.text += "All conversions complete!\r\n"
	
func convertTimelines():
	$Panel/OutputLog.text += "Converting timelines: \r\n"
	for item in timelineFolderBreakdown:
		var folderPath = timelineFolderBreakdown[item]
		$Panel/OutputLog.text += "Timeline " + folderPath + item +": "
		var jsonData = {}
		var file = File.new()
		file.open("res://dialogic/timelines/" + item,File.READ)
		var fileContent = file.get_as_text()
		var json_object = JSON.new()
		
		var error = json_object.parse(fileContent)
		
		if error == OK:
			contents = json_object.get_data()
			var fileName = contents["metadata"]["name"]
			$Panel/OutputLog.text += "Name: " + fileName + ", " + str(contents["events"].size()) + " timeline events"
			
			var directory = Directory.new()
			var directoryCheck = directory.dir_exists(conversionRootFolder + "/timelines" + folderPath)
			if !directoryCheck: 
				directory.open(conversionRootFolder + "/timelines")
				
				var progresiveDirectory = ""
				for pathItem in folderPath.split('/'):
					directory.open(conversionRootFolder + "/timelines" + progresiveDirectory)
					if pathItem!= "":
						progresiveDirectory += "/" + pathItem
					if !directory.dir_exists(conversionRootFolder + "/timelines" + progresiveDirectory):
						directory.make_dir(conversionRootFolder + "/timelines" + progresiveDirectory)
				
				
			file.open(conversionRootFolder + "/timelines" + folderPath + "/" + fileName + ".dtl",File.WRITE)
			for event in contents["events"]:
				file.store_string("# timeline event node")
				file.store_string("\r\n\r\n")
			file.close()
			
			
			
			$Panel/OutputLog.text += "\r\n"
		else:
			$Panel/OutputLog.text += "[color=red]There was a problem parsing this file![/color]\r\n"
		
	$Panel/OutputLog.text += "\r\n"
	
	
func convertCharacters(): 
	$Panel/OutputLog.text += "Converting characters: \r\n"
	for item in characterFolderBreakdown:
		var folderPath = characterFolderBreakdown[item]
		$Panel/OutputLog.text += "Character " + folderPath + item +": "
		var jsonData = {}
		var file = File.new()
		file.open("res://dialogic/characters/" + item,File.READ)
		var fileContent = file.get_as_text()
		var json_object = JSON.new()
		
		var error = json_object.parse(fileContent)
		
		if error == OK:
			contents = json_object.get_data()
			var fileName = contents["name"]
			$Panel/OutputLog.text += "Name: " + fileName
			
			if ("[" in fileName) || ("]" in fileName):
				$Panel/OutputLog.text += " [color=yellow]Stripping brackets from name![/color]"
				fileName = fileName.replace("[","")
				fileName = fileName.replace("]","")
				
			
			var directory = Directory.new()
			var directoryCheck = directory.dir_exists(conversionRootFolder + "/characters" + folderPath)
			if !directoryCheck: 
				directory.open(conversionRootFolder + "/characters")
				
				var progresiveDirectory = ""
				for pathItem in folderPath.split('/'):
					directory.open(conversionRootFolder + "/characters" + progresiveDirectory)
					if pathItem!= "":
						progresiveDirectory += "/" + pathItem
					if !directory.dir_exists(conversionRootFolder + "/characters" + progresiveDirectory):
						directory.make_dir(conversionRootFolder + "/characters" + progresiveDirectory)
			
			# using the resource constructor for this one
			
			var current_character = DialogicCharacter.new()
			current_character.resource_path = conversionRootFolder + "/characters" + folderPath + "/" + fileName + ".dch"
			# Everything needs to be in exact order

			current_character.color = Color.html(contents["color"])
			var customInfoDict = {}
			customInfoDict["sound_moods"] = {}
			customInfoDict["theme"] = ""
			current_character.custom_info = customInfoDict
			current_character.description = contents["description"]
			if contents["display_name"] == "":
				current_character.display_name = contents["name"]
			else:
				current_character.display_name = contents["display_name"]
			current_character.mirror = contents["mirror_portraits"]
			current_character.name = contents["name"]
			current_character.nicknames = []
			current_character.offset = Vector2(0,0)
			current_character.portraits = {}
			current_character.scale = 1.0
			
			ResourceSaver.save(current_character.resource_path, current_character)	
			#file.open(conversionRootFolder + "/characters" + folderPath + "/" + fileName + ".dch",File.WRITE)
			#json_object = JSON.new()
			#var output_string = json_object.stringify(charData, "\r")
			#file.store_string(output_string)
			
			#file.close()
			
			
			
			$Panel/OutputLog.text += "\r\n"
		else:
			$Panel/OutputLog.text += "[color=red]There was a problem parsing this file![/color]\r\n"
			
	
	$Panel/OutputLog.text += "\r\n"
	

func convertVariables():
	$Panel/OutputLog.text += "Converting variables: \r\n"
	
	# Creating a file with a format identical to how the variables are stored in project settings
	
	var newVariableDictionary = {}
	for varItem in definitionFolderBreakdown:
		if definitionFolderBreakdown[varItem]["type"] == "variable":
			if definitionFolderBreakdown[varItem]["path"] == "/":
				newVariableDictionary[definitionFolderBreakdown[varItem]["name"]] = definitionFolderBreakdown[varItem]["value"]
			else:
				# I will fill this one in later, need to figure out the recursion for it
				pass
						
						
	
	var file = File.new()
	file.open(conversionRootFolder + "/variables.json",File.WRITE)
	var json_object = JSON.new()
	var output_string = json_object.stringify(newVariableDictionary, "\n")
	file.store_string(output_string)
	file.close()
	
	
	
	
	$Panel/OutputLog.text += "\r\n"
	

func convertGlossaries():
	$Panel/OutputLog.text += "Converting glossaries: [color=red]not currently implemented[/color] \r\n"
	
	$Panel/OutputLog.text += "\r\n"

func convertThemes():
	$Panel/OutputLog.text += "Converting themes: [color=red]not currently implemented[/color] \r\n"
	
	$Panel/OutputLog.text += "\r\n"

@tool
extends HBoxContainer

var folderStructure

var timelineFolderBreakdown:Dictionary = {}
var characterFolderBreakdown:Dictionary = {}
var definitionFolderBreakdown:Dictionary = {}
var themeFolderBreakdown:Dictionary = {}
var definitionsFile = {}

var conversionRootFolder = "res://converted-dialogic"

var contents

var conversionReady = false

func refresh():
	pass

func _on_verify_pressed():
	var file = File.new()
	
	%OutputLog.text = ""
	
	if file.file_exists("res://dialogic/settings.cfg"):
		%OutputLog.text += "[√] Dialogic 1.x data [color=green]found![/color]\r\n"
		
		if file.file_exists("res://dialogic/definitions.json"):
			%OutputLog.text += "[√] Dialogic 1.x definitions [color=green]found![/color]\r\n"
		else:
			%OutputLog.text += "[X] Dialogic 1.x definitions [color=red]not found![/color]\r\n"
			%OutputLog.text += "Please copy the res://dialogic folder from your Dialogic 1.x project into this project and try again.\r\n"
			return
			
		if file.file_exists("res://dialogic/settings.cfg"):
			%OutputLog.text += "[√] Dialogic 1.x settings [color=green]found![/color]\r\n"
		else:
			%OutputLog.text += "[X] Dialogic 1.x settings [color=red]not found![/color]\r\n"
			%OutputLog.text += "Please copy the res://dialogic folder from your Dialogic 1.x project into this project and try again.\r\n"
			return
		
		%OutputLog.text += "\r\n"
		
		%OutputLog.text += "Verifying data:\r\n"
		file.open("res://dialogic/folder_structure.json",File.READ)
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
			
		
		file.open("res://dialogic/definitions.json",File.READ)
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
		
		if (definitionsFile["glossary"].size() + definitionsFile["variables"].size())  ==  definitionFolderBreakdown.size():
			%OutputLog.text += "Definitions found: [color=green]" + str((definitionsFile["glossary"].size() + definitionsFile["variables"].size())) + "[/color]\r\n"
			%OutputLog.text += " • Glossaries found: " + str(definitionsFile["glossary"].size()) + "\r\n"
			%OutputLog.text += " • Variables found: " + str(definitionsFile["variables"].size()) + "\r\n"
			
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
			%OutputLog.text += "Definition files found: [color=red]" + str(definitionsFile.size()) + "[/color]\r\n"
			%OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
			
		var themeDirectory = list_files_in_directory("res://dialogic/themes")
		if themeDirectory.size() ==  themeFolderBreakdown.size():
			%OutputLog.text += "Theme files found: [color=green]" + str(themeDirectory.size()) + "[/color]\r\n"
		else:
			%OutputLog.text += "Theme files found: [color=red]" + str(themeDirectory.size()) + "[/color]\r\n"
			%OutputLog.text += "[color=yellow]There may be an issue, please check in Dialogic 1.x to make sure that is correct![/color]\r\n"
			
		%OutputLog.text += "\r\n"
		
		%OutputLog.text += "Initial integrity check completed!\r\n"
		
		
		var directory = Directory.new()
		var directoryCheck = directory.dir_exists(conversionRootFolder)
		
		if directoryCheck: 
			%OutputLog.text += "[color=yellow]Conversion folder already exists, coverting will overwrite existing files.[/color]\r\n"
		else:
			$Panel/OutputPath.text += conversionRootFolder
			%OutputLog.text += "Folders are being created in " + conversionRootFolder + ". Converted files will be located there.\r\n"
			directory.open("res://")
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





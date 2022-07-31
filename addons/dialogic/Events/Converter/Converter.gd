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
	pass

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

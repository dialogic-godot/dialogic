extends Node2D

var workingPath
var folderStructure

# Called when the node enters the scene tree for the first time.
func _ready():
	var file = File.new()
	
	if file.file_exists("res://dialogic/settings.cfg"):
		$Panel/OutputLog.text += "[√] Dialogic 1.x data [color=green]found![/color]\r\n"
		$Panel/OutputLog.text += "Verifying data:\r\n"
		file.open("res://dialogic/folder.json",File.READ)
		var fileContent = file.get_as_text()
		var json_object = JSON.new()
		json_object = json_object.parse(fileContent)
		folderStructure = json_object.get_data()
		
	else:
		$Panel/OutputLog.text += "[X] Dialogic 1.x data [color=red]not found![/color]\r\n"
		$Panel/OutputLog.text += "Please copy the res://dialogic folder from your Dialogic 1.x project into this project and try again.\r\n"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_choose_folder_pressed():
	#var folder = FileDialog.new()
	
	$FileDialog.show()


func _on_file_dialog_dir_selected(dir):
	workingPath = dir
	$Panel/OutputPath.text = "Output path: " + dir



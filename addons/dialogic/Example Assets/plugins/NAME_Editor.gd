#Superclass.
#Contains refrences to the editor (editor_reference) and the timeline ( timeline_reference )
extends "res://addons/dialogic/Editor/plugins/templates/EditorPlugin.gd"

#This is the editor script for the NAME plugin.
#If this plugin does not need to run in the editor, you may freely delete this script and scene.

#setup will be called from res://addons/dialogic/Editor/EditorView.gd during project load
#This is where you connect to signals and hook into Dialogic's editor features.
func setup():
	.setup()
#Superclass.
#currently a stub. This template will be updated.
extends "res://addons/dialogic/Editor/plugins/templates/RuntimePlugin.gd"

#This is the editor script for the NAME plugin.
#If this plugin does not need to run in the editor, you may freely delete this script and scene.

#setup will be called from res://addons/dialogic/Nodes/DialogNode.gd during start of a new dialog.
#This is where you connect to signals and hook into Dialogic's dialog features.
func setup():
	.setup()
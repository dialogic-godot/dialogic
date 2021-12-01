Uh, Hi there.
KvaGram the autistic duck here.
If you're reading this, that means you are playing around on my fork of dialogic. Thank you so much for the attention.
Why do I know you must be on my fork? Becouse there is no way this doc won't be changed before merging upstream.
This is just waaaay too informal to be on official documentation.

Let me just explain what a dialogic plugin is, and let some ~~poor sucker~~... err, I mean proud developer of Dialogic clean this up into a proper tutorial.

There are two types of plugins for Dialogic.
There are Editor plugins and Runtime plugins. Both function in a simular way.

Editor plugins runs in the dialogic editor, and may alter the way the dialogic editor function.
WARNING: A plugin may break Dialogic and even Godot itself. Only make an editor plugin when you know what you are doing.
Editorplugins' scene must be a DialogWindow node. This is so it can be hidden in the editor.
Editor plugins must must have a scene node that inherits the class DialogicEditorPlugin or res://addons/dialogic/Editor/plugins/templates/EditorPlugin.gd

Runtime plugins runs in the Dialog node, and may alter how events run, and how they appear.
Runtimeplugins's scene must be a Control node. Beware that this node will overlay the dialog node.
Runtimeplugins must inherit the class DialogicRuntimePlugin or res://addons/dialogic/Editor/plugins/templates/RuntimePlugin.gd

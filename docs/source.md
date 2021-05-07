## 🌳 Source structure

### / (At the root level)
`plugin.cgf` - The required file to be recognized by Godot.

`dialogic.gd` - This is the script that loads the addon. Very minimal and should probably have more stuff? Not sure.

`Dialog.tscn` - Main scene containing the text bubble and all the required sub-nodes to display your timelines in-game. I left this file in the root node because it will be easier to find and drag-drop to an existing scene.


### /Editor

`EditorView.tscn` - When you click on the Dialogic tab, this is the scene you see on the main editor panel. This contains all the sub editors and scripts needed for managing your data.

`editor_view.gd` - This is the code embedded in the `EditorView.tscn`. It handles the right click context menus, resource removing dialogs and file selectors.

`/MasterTree` - This is the [Tree](https://docs.godotengine.org/en/stable/classes/class_tree.html#class-tree) with all the resources. It handles many things like renaming, saving and several other aspects of resource management.

`/TimelineEditor` - Everything related to the timeline editor.

`/ThemeEditor` - Everything related to the theme editor.

`/DefinitionEditor` - Everything related to the definition editor.

`/SettingsEditor` - A very simple editor for changing how Dialogic behaves.

`/Pieces` - Inside this directory you have all the event nodes that populate the timeline editor. Each one has its own name and script. **The name is important** since it has to be instanced from the `editor_view.gd` when clicking on buttons of the same name.

`/Pieces/Common` - This is where some of the common element of the pieces are saved. Things like the Character Picker, the Portrait Picker or the Drag Controller are used in several event nodes, so I'm trying to make them easier to plug in to future events that might need them as well.

`/CharacterEditor` - Everything related to the character editor. This also contains the script `PortraitEntry.gd` and the scene `PortraitEntry.tscn`. When you add a new expression for one of your characters in the Character Editor this node/script will be instanced for handling the settings.

### /Fonts
This directory contains the font files and the resources to load. 

`DefaultFont.tres` - This is the default font used for dialog text such as buttons, names, and the main chat bubble.

`GlossaryFont.tres` - The default font for the small popup on hover. This is basically the same font but smaller because you know... Godot <3 Fonts

### /Images
You shouldn't open this folder expecting it to be organized. Welcome to the world of mixed naming conventions and CaSiNgStYlEs.

All icons are `.svg` files so they can scale nicely. I tried reusing many of the default Godot icons, but instead of using the native ones I copy-pasted the svgs and run with it. I should probably replace them and make the custom one more in line with the rest of the editor.

`/Images/background` - Here you will find the default background images for the dialogs. More will come in the future.

`/Images/portraits` - Some placeholder images for an example project. I might delete these since I'll probably be hosting that somewhere else.

`/Images/tutorials` - Right now it only has one file, but every image created for warnings/tutorials/tips will be placed here. Hopefully.

`/Images/Toolbar` - It contains the icons for the toolbar in the main view.


### /Nodes

`ChoiceButton.tscn` - This is the button created by Dialogic's options events. The node `/Dialog.tscn` will instance these when displaying the options to the user.

`dialog_node.gd` - The script associated with `/Dialog.tscn`. This contains all the logic behind the node and manages everything from timeline parsing, in-game signals and all the visual aspects of the dialog.

`glossary_info.gd` - Handles the logic behind the small popup that shows up when you hover the cursor on one of the highlighted words from the glossary inside a dialog. Part of this logic lives inside the `dialog_node.gd` script and should probably be moved here.

`Portrait.tscn` and `Portrait.gd` - Whenever you make a character join a scene, this is the node used for instancing and displaying an image in the screen. It also contains a few effects for fading in/out of a scene.

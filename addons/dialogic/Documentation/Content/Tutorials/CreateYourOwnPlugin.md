Uh, Hi there.
KvaGram the autistic duck here.
If you're reading this, that means you are playing around on my fork of dialogic. Thank you so much for the attention.
Why do I know you must be on my fork? Becouse there is no way this doc won't be changed before merging upstream.
This is just waaaay too informal to be on official documentation.

Let me just explain what a dialogic plugin is, and let some ~~poor sucker~~... err, I mean proud developer of Dialogic clean this up into a proper tutorial.

The plugins are based on the code structure of the Custom events.
All plugns must have a scene called PluginContainer, with a script inheriting from *(NOT-CREATED-YET)*, just like the custom events.

Just like custom events, you can create a new plugin based on a template by pressing a button in settings *(NOT-IMPLEMENTED_YET)*

All plugins are to be located in Dialogic/plugins, within their own folders.
The editor will browse though these to find all of them.

Plugins may insert a node into the following:
- EditorView/plugin_container *(must be a type of Popup)*
- EditorView/ToolBar/Plugin_buttons *(must be a type of BaseButton)*

# Theme Editor

Themes allow you to set how the dialog looks, sounds and behaves.

At the top of the Theme Editor you have a **preview field**, where you can also set the text to be previewed, the speaker of the preview and force a preview refresh.

The settings are sorted into different sections. Most of the settings are self-explanatory but some are explained a bit further.

## Dialog Text
Here you can set the look and behaviour of the text inside the dialog box.

##### Behaviour>Speed
Using this setting you can change the speed at which the text is shown, where bigger values will result in a slower speed. 
Setting this to 0 will result in the text being shown instantly.

##### Behaviour>Single Portrait Mode
If you enable this mode, there will always only be one portrait visible, the one of the character currently speaking.

## Dialog Box
### Visuals
For the background of the box you will have to choose between a solid color or a texture. For the texture you can also change it's modulation.

##### Visuals>Full width
If you enable this setting the box will be stretched from left to right.

##### Visuals>Box padding
The padding between the border of the box and the text inside the box.

##### Visuals>Bottom gap
How far the box is from the bottom.

### Next indicator
The next indicator is the little icon that appears once the text is completed.

### Behaviour
##### Behaviour>Action Key
If you do not want to use the same action as the default one (in the settings) for advancing the dialog, you can select a different one for the current theme.

##### Behaviour>Fade in time
This sets how long the theme takes to fade in. Fading only happens on dialog load and is not triggered by the `Set Theme` event.

## Name Label
The `Name label` is the section above the text box that displays the name of the currently speaking character.

##### Text>Use character Color
If you enable this, the name label will always use the color of the currently speaking character. The characters color can be edited in the [Character Editor](./Character.md).

### Box
As for the text box, you can choose between a solid color or a texture.

##### Box>Box Padding
The padding between the texture border and the text.

### Placement
Here you can set the alignment of the `Name label` as well as setting some additional offset.

## Choice Buttons
#####Advanced>Use Custom Buttons
If you enable this, you can select a scene that will be used as the buttons. Make sure the scene has a 'pressed', 'focus_entered' and 'mouse_entered' signal.

##### Advanced>Use Native Buttons
ToDo: Find out if this works in any way.

## Glossary
Here you can define how the box looks, that appears when you hover a glossary entry.

##### Visuals>Word color
This is the color, that glossary entries have in the text.

##### Behaviour>Show
If this is disabled, the glossary info box won't be shown and glossary entries won't be colored.

## Audio
This sections allows you to set audio that plays at different moments. Each of the sections works the same, so the settings will only be explained once. Dialogic uses the [RandomAudioPlayer by TimKrief](https://gitlab.com/timkrief/godot-random-audio-stream-player).

You can decide to select a single audio file or a folder where one file will be picked.
You can set a range for the `volume` (a random one in that range will be picked each time). Likewise you can set a range for the `pitch`. `Allow interrupt` decides whether the sound can be interrupted by a new sound of that type.

##### Typing Sound Effects
This sound will be played for each appearing character.

##### Next Sound Effects>Waiting
This is played once the text is completed.

##### Next Sound Effects>Passing
This is played when the player continues.

##### Choice Sound Effects>Hovered 
When a choice button is hovered.

##### Choice Sound Effects>Selecting
When a choice is selected.


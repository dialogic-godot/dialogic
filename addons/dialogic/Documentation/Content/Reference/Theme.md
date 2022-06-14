# Theme Editor

Themes allow you to set how your dialogue looks, sounds, and behaves.

At the top of the Theme Editor you have a **preview field.** Here, you can set the text to be previewed, the speaker of the preview, and force a preview refresh.

The settings are sorted into different sections. Most are self-explanatory, but some require a little more in the way of explanation.

## Dialog Text
Allows you to set the look and behavior of the text inside the dialog box.

##### Margin
Sets the individual margin between the border of the box and the edge the dialog text for a given side.

##### Behaviour>Speed
Using this setting, you can change the speed at which the text is shown. Bigger values will result in a slower speed.
Setting this to 0 will result in the text instantly appearing.

##### Behaviour>Alignment
Use this to align the text inside the box.

##### Behaviour>Single Portrait Mode
If you enable this mode, there will always only be one portrait visible. This will be the portrait of the character who is currently speaking.

##### Behaviour>Don't Close After Last Event
If enabled, the dialog box will not delete itself after the last event. Instead you will need to remove it manualy. Usefull if the box is intergrated into your design and should never vanish.


## Dialog Box
### Dialog Box>Visuals
You may choose either a solid color or a texture for the background of the box. For the texture, you can also change its modulation.

## Dialog Box>Visuals>9-Patch Margin Left/Right and Top/Bottom
Allows you to configure 9-Patch Rectangle support on the approprate sides of your image. See this tutorial for details on how a 9-patch rect works [Youtube](https://www.youtube.com/watch?v=1u4817DKvb8). Leaving these values at 0 treats the texture as a normal background texture.

##### Size and Position>Full width
This setting makes your box stretch to the full extent of the view.

##### Size and Position>Margin
Sets the individual margin between the border of the box and the edge of the viewport.


### Next indicator
An icon that appears once the text is completed.

### Dialog Box>Behaviour
##### Behaviour>Fade in time
Sets how long the theme takes to fade in. Fading only happens on dialog load and is not triggered by the `Set Theme` event.

##### Behaviour>Portraits Dim Color
Use this to change the modulation of the active character. Set it to white if you do not want any changes. 

##### Behaviour>Portraits Behind Dialog Box
If you disable this, the portraits will instead be in front of the dialog box.


## Name Label
The `Name Label` is the section above the text box that displays the name of the character who is currently speaking.

##### Behaviour>Hide name labels
If this is enabled, the name label will not be shown.

##### Text>Use character Color
If you enable this, the name label will always use the color of the currently speaking character. The characters color can be edited in the [Character Editor](./Character.md).

### Name Label>Box
As for the text box, you can choose between a solid color or a texture.

##### Box>Box Padding
The padding between the texture border and the text.

### Name Label>Placement
Here you can set the alignment of the `Name label` as well as setting some additional offset.


## Choice Buttons
You can change the look of the buttons four states, although "Disabled" currently does nothing.


## Glossary
These setting lets you define the appearance of the box that appears when you hover over a glossary entry.

##### Visuals>Word color
Sets the color of glossary word inside the dialog.

##### Behaviour>Show
If this is disabled, the glossary info box won't be shown and glossary entries won't be colored.


## Audio
This sections allows you to set audio for your dialogue. Dialogic uses the [RandomAudioPlayer by TimKrief](https://gitlab.com/timkrief/godot-random-audio-stream-player).

When selecting what audio to play, you can either select a single audio file or a folder where a file will be picked from.
You can set a range for the `volume` - a random level in that range will be picked each time it's called. Likewise, you can set a range for the `pitch`. `Allow interrupt` dictates whether or not the sound can be interrupted by a new sound of that type.

##### Typing Sound Effects
When the text scrolls across the screen, this will play a sound for each letter.

##### Next Sound Effects>Waiting
If you set a sound here, it will play once the text has finished typing.

##### Next Sound Effects>Passing
This plays when the player continues to the next dialogue box.

##### Choice Sound Effects>Hovered 
This sound plays when a character is hovering over a choice button.

##### Choice Sound Effects>Selecting
Plays when a character selects a choice button.


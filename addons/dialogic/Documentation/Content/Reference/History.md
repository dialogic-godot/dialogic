# History timeline

When enabled, the History timeline feature automatically builds a log of events that can be reviewed by the user, or if audio is enabled, replay the audio as well. As the History timeline is at its core a fancy logging system, it has many settings that need to be configured for proper use. In addition to those settings, the history timeline can also be customized further by intermediate to experienced users.

![anatomy-history](https://user-images.githubusercontent.com/7741797/156091617-7a6c0920-007a-456f-bc1f-73c8d67eb383.png)

This image gives a rough look at how a history timeline can look in game. By default a History timeline, is made up of a History node that instances a single HistoryBackground, two HistoryButtons and as many HistoryRows as neccesary. The default theme is used to style these elements, but each of these parts can be further customized and configured. The History timeline is destroyed along with the Dialogic node when the timeline ends.

## History settings
### Enable history
Allows history logs to be taken. If disabled no other history settings will be displayed, and no history log will be kept in game

### Show open button
Displays the default history open button. This button opens the history timeline and disappears while it is open. Its position is determined by the History button position setting. This button uses the Default theme by default. If you wish to customize this button, see the customize History guide below

### Show close button
Displays the default history close button. This button closes the history timeline and disappears while it is closed. Its position is determined by the History button position setting. This button uses the Default theme by default. If you wish to customize this button, see the customize History guide below

### Log all choices
Record all possible choices the player could have picked from a choice event in the format: 
\\t\[choice one\] \[choice two\] \[choice 3\]

If you need this format changed, the code can be found here:
https://github.com/coppolaemilio/dialogic/blob/5e99dfe0374695ff4ec3680bad75d17ffe939264/addons/dialogic/Nodes/History.gd#L236-L237

### Log choice answer
Record the choice ultimately selected by the player in a choice event in the format: 
\\t \<choice goes here\>

If you need this format changed, the code can be found here:
  https://github.com/coppolaemilio/dialogic/blob/5e99dfe0374695ff4ec3680bad75d17ffe939264/addons/dialogic/Nodes/History.gd#L244
  
### Log character joins
Record when a character joins a timeline in the format:
*\<display name of character\> \<character join Text\>*
Which by default displays as:
*Emilio has arrived*

### Log character joins text
The text to display after a character name when a character arrives. This defaults to 'has arrived'. This option has no effect if Log character joins is disabled
   
### Log character leaves
Record when a character leaves a timeline in the format:
*\<display name of character\> \<character leave Text\>*
Which by default displays as:
*Emilio has left*

### Log character leaves text
The text to display after a character name when a character arrives. This defaults to 'has left'. This option has no effect if Log character joins is disabled

### Scroll to bottom
Auto scrolls the history timeline to the most recent entry. Disable this if you wish for your player to start reading from the first entry and have to scroll down manually

### Reverse timeline
Add new HistoryRows to the top of the history timeline, reversing the default way the timeline is built. This option is disabled by default

### Show name colors
Use the color defined in the character within the timeline 

![image](https://user-images.githubusercontent.com/7741797/156090583-1372d00b-b2ec-4e0f-bb92-688ed08e72b5.png)

In this case the characters name woudld be blue in the history timeline

### Line break after names
Forces the character name to be logged on a separate line from the rest of the text. This option is disabled by default

### History button position
Choose the relative location on screen you want the default history open and default history close button to appear

![image](https://user-images.githubusercontent.com/7741797/156090911-d2ca4d41-995c-42e0-9c84-7309221f9e28.png)


If you wish to customize this further, consider using a custom history button and signal, described below

### Name delimiter
Type in the 'delimiter' to be affixed to the character name in the history timeline. By default this is a colon *\:* which would display as:
*Emilio: Welcome to dialogic!*
Changing this to a dash *\-* woudld display as:
*Emilio- Welcome to dialogic!*

### Screen margin
Sets a distance in pixels that the history panel will buffer away from the edge of the screen. 

![image](https://user-images.githubusercontent.com/7741797/156091395-bdb9b47d-a262-4b36-9ade-14ef7d829a62.png)

This example would give a margin of 25 pixels on the left and right sides of the screen (X axis) and 10 pixels on the top and bottom of the screen (Y axis)

### Log margin
Sets a distance in pixels that the history panel will buffer away from the HistoryRows that it contains.

![image](https://user-images.githubusercontent.com/7741797/156092238-f3527921-f974-4ca9-977b-7380f4875be9.png)

This example would give a margine of 45 pixels on the left and right sides of the screen (X axis) and 15 pixels on the top and bottom of the screen (Y axis). Note that the Y axis pixels may not be as apparent as the scrollcontainer may obscure the bottom margin.

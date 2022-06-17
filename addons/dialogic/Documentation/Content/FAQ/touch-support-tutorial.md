# Is there touch/tap support?

**How can I allow touch/tap to advance the dialog?**

'Tap to advance dialog' is supported by default as of release 1.4.2. 

By default an invisible 'Touch Button' covers the full screen when Dialog is shown, so a tap anywhere will advance dialog. If you do not want automatic resizing and full screen touch first uncheck the 'Tap area covers full screen' setting:

![image](https://user-images.githubusercontent.com/7741797/170019154-ee5f0231-b8c8-4641-a6df-0490ee165749.png)


Next go to the **DialogNode.tscn**

![image](https://user-images.githubusercontent.com/7741797/170019276-1ffcc9fe-3e4b-474d-9457-4884f941e08c.png)


And find the **TouchScreenButton** node

![image](https://user-images.githubusercontent.com/7741797/170019315-91d79111-2fda-40fc-b1b6-62c5492a81f0.png)


In the inspector, make the shape visible so you can edit it

![image](https://user-images.githubusercontent.com/7741797/170019396-35c11002-c5f8-4fd7-91bd-28f88e5d431e.png)


Then resize it to your hearts content.

**How can I select choices with touch/tap?**
Choice buttons are simply normal Godot UI buttons. This means by default only a mouse click will work on them. If you wish for otouch tap support you have 2 options
1) Emulate Mouse From Touch in your project settings

![image](https://user-images.githubusercontent.com/7741797/170020234-dd0068bb-ede6-4f3e-a3a1-2eabaa2fe76c.png)


2) Edit the **ChoiceButton.tscn**

![image](https://user-images.githubusercontent.com/7741797/170020314-968c96d4-77be-4641-8be5-4e2b16979cfb.png)


And attach or replace it with a touch buttons as your project demands.

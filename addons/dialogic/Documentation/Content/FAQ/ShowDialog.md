# Dialog doesn't show up?

Many people experience problems with getting the dialog to show up the first time they use dialogic.

**The number one problem** that leads to this problem is that your dialog is not a child of a **canvas layer**. Because of this, your dialog might be off-screen!
[Learn more about canvas layers here!](https://docs.godotengine.org/en/stable/tutorials/2d/canvas_layers.html)

Note that the dialog node is not optimised for all stretch modes, but it should work fine most of the time. 

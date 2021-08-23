# Can I use C# with Dialogic?
It is experimental! So if you want to try it out and you find issues, let us know. Usage:

`public override void _Ready()
	{
		var dialog = DialogicSharp.Start("Greeting", false);
		AddChild(dialog);
	}
`

This is the PR that added this feature: [https://github.com/coppolaemilio/dialogic/pull/217](https://github.com/coppolaemilio/dialogic/pull/217)
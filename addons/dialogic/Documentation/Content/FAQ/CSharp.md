# Can I use C# with Dialogic?

Yes, but it's experimental at the present time. If you want to try it out, and you find issues with the implementation, please let us know.

Usage:

`public override void _Ready()
	{
		var dialog = DialogicSharp.Start("Greeting");
		AddChild(dialog);
	}
`

This is the PR that added this feature: [https://github.com/coppolaemilio/dialogic/pull/217](https://github.com/coppolaemilio/dialogic/pull/217)
<p align="center">
  <img width="1280" alt="cover" src="https://user-images.githubusercontent.com/2206700/189457799-6327bab0-b085-4421-8640-6a18e395d17d.png">
</p>

<h1 align="center">Dialogic 2</h1>

<p align="center">
  Create <b>Dialogs</b>, <b>Visual Novels</b>, <b>RPGs</b>, and <b>manage Characters</b> with Godot to create your Game!
</p>

<p align="center">
  <a href="https://discord.gg/DjcDgDaTMe" target="_blank" style="text-decoration:none"><img alt="Discord" src="https://img.shields.io/discord/628713677239091231?logo=discord&labelColor=CFC9C8&color=646FA9"></a>
  <a href="https://godotengine.org/download/" target="_blank" style="text-decoration:none"><img alt="Godot v4.3+" src="https://img.shields.io/badge/Godot-v4.3+-%23478cbf?labelColor=CFC9C8&color=49A9B4" /></a>
  <a href="https://docs.dialogic.pro/introduction.html" target="_blank" style="text-decoration:none"><img alt="Dialogic 2 Documentation" src="https://img.shields.io/badge/documention-online-green?labelColor=CFC9C8&color=6BCD69"></a>
  <a href="https://github.com/dialogic-godot/dialogic/actions/workflows/unit_test.yml" target="_blank style="text-decoration:none"><img alt="GitHub Actions Workflow Status" src="https://img.shields.io/github/actions/workflow/status/dialogic-godot/dialogic/unit_test.yml?labelColor=CFC9C8&color=DBDCB8"></a>
  <a href="https://github.com/dialogic-godot/dialogic/releases"  target="_blank" style="text-decoration:none"><img alt="Latest Dialogic Release" src="https://img.shields.io/github/v/release/dialogic-godot/dialogic?include_prereleases&labelColor=CFC9C8&color=CBA18C"></a>
</p>

## Table of Contents
- [Version](#version)
- [Installation](#installation)
- [Documentation](#documentation)
- [Testing](#testing)
- [Credits](#credits)
- [License](#license)

## Version

Dialogic 2 **requires at least Godot 4.3**.

[If you are looking for the Godot 3.x version (Dialogic 1.x) you can find it here.](https://github.com/dialogic-godot/dialogic-1)

## Installation
Follow the installation instructions on our [Getting Started](https://docs.dialogic.pro/getting-started.html#1-installation--activation) documentation.

Dialogic comes with an auto-updater so you can install future versions right from within the plugin.

## Documentation
You can find the official documentation of Dialogic here: [Dialogic Documentation](https://docs.dialogic.pro/)

There is a Class Reference as well: [Class Reference](https://docs.dialogic.pro/class_index.html)


## Connect with us!
If you need help or want to share your Dialogic projects, take a look at the following options:

- Ask questions, or report bugs on our [Discord](https://discord.gg/DjcDgDaTMe)
- Report bugs and issues on the [GitHub Issues Page](https://github.com/dialogic-godot/dialogic/issues)
- Ask questions on [GitHub Discussions](https://github.com/dialogic-godot/dialogic/discussions)

## Testing
Dialogic uses [Unit Tests](https://en.wikipedia.org/wiki/Unit_testing) to ensure specific parts function as expected. These tests run on every git push and pull request. The framework to do these tests is called [gdUnit4](https://github.com/MikeSchulze/gdUnit4) and our tests reside in the [/Tests/Unit](https://github.com/dialogic-godot/dialogic/tree/main/Tests/Unit) path. We recommend installing the `gdUnit4` add-on from the `AssetLib`, with this add-on, you can run tests locally.

To get started, take a look at the existing files in the path and read the documentation to [create your first test](https://mikeschulze.github.io/gdUnit4/first_steps/firstTest/).

## Interacting with the Source Code
All methods and variables in the Dialogic 2 source **code prefixed with an underscore (`_`)** are considered *private*, for instance: `_remove_character()`.

While you can use them, they may change in their behavior or change their signature, causing breakage in your code while moving between versions.
Most private methods are used inside public ones; if you need help, check the documentation.

**Public methods and variables can be found in our [Class Reference](https://docs.dialogic.pro/class_index.html).**

During the Alpha and Beta version stages, code may change at any Dialogic Release to allow drafting a better design.
Changelogs will accommodate for these changes and inform you on how to update your code.


## Credits
Made by [Jowan-Spooner](https://github.com/Jowan-Spooner) and [Emilio Coppola](https://github.com/coppolaemilio).

Contributors: [CakeVR](https://github.com/CakeVR), [Exelia](https://github.com/exelia-antonov), [zaknafean](https://github.com/zaknafean), [and more!](https://github.com/dialogic-godot/dialogic/graphs/contributors).

Special thanks: [Arnaud](https://github.com/arnaudvergnet), [AnidemDex](https://github.com/AnidemDex), [ellogwen](https://github.com/ellogwen), [Tim Krief](https://github.com/timkrief), [Toen](https://twitter.com/ToenAndreMC), Òscar, [Francisco Presencia](https://francisco.io/), [M7mdKady14](https://github.com/M7mdKady14).

### Thank you to all my [Patreons](https://www.patreon.com/jowanspooner) and Github sponsors for making this possible!

## License
This project is licensed under the terms of the [MIT license](https://github.com/dialogic-godot/dialogic/blob/main/LICENSE).

Dialogic may use the [Roboto font](https://fonts.google.com/specimen/Roboto), licensed under [Apache license, Version 2.0](https://github.com/dialogic-godot/dialogic/tree/main/addons/dialogic/Example%20Assets/Fonts/LICENSE.txt).

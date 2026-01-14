# [![bonsai logo](readme/logo.png)](https://bonsai-framework.dev)

**A lightweight cross-platform 2D game framework written in Odin.**

Built on top of [Sokol](https://github.com/flooh/sokol-odin).

Uses [Emscripten](https://emscripten.org/) to compile to WebAssembly.

> **Note:** Looking for the CLI source code? Check out the **[CLI repository](https://github.com/nihiL7331/bonsai)**.
>
> For framework documentation, examples and tutorials, visit **[bonsai-framework.dev](https://bonsai-framework.dev)**.
>
> Found a bug or want to request a feature? Open an issue!

---

## Prerequisites

To initialize, run and build projects made with **bonsai**
it is required to install the **[CLI](https://github.com/nihiL7331/bonsai)**.

## Quick Start

If you have the **[CLI](https://github.com/nihiL7331/bonsai)** installed, simply run:

```bash
bonsai init <project_name>
```

This will initialize a new project in a directory named `<project_name>`. You can then run it by typing:

```bash
bonsai run <project_name>
```

If you wish to open it in the browser,
simply add a `--web` flag at the end of the command:

```bash
bonsai run <project_name> --web
```

This command will open a local server, and open a site with your project on your default browser.

(**Tip:** you can rapidly rebuild the web version
by opening a server in one terminal session
and running `bonsai build --web` in another)

## Hello, Pot

The main entry point for your game logic is **source/game/game.odin**.
After initialization, it already contains basic runtime functions: `init`, `draw`, `update` and `shutdown`.

Let's use them to write your first 'Hello, World!' code in **bonsai**. Rather than to the world, you'll
be saying hello to **Pot**, the framework's mascot and hero of every code example and tutorial.

We will use the `bonsai:core/render` package to do that.
We also need `bonsai:core` to get a position anchor on the screen.
Simply import it at the top of the file:

```odin
import "bonsai:core"
import "bonsai:core/render"
```

Then, in your draw functions you can use the imported functions:

```odin
draw :: proc() {
  render.setScreenSpace()

  centerPosition := core.getViewportPivot(.centerCenter)
  render.drawTextSimple(centerPosition, "Hello, Pot!", fontName = .PixelCode, pivot = .centerCenter)
}
```

Finally, your code should look like this:

```odin
// This file is the entry point for all gameplay code.

package game

import "bonsai:core"
import "bonsai:core/render"

init :: proc() {
}

update :: proc() {
}

draw :: proc() {
  render.setScreenSpace()

  centerPosition := core.getViewportPivot(.centerCenter)
  render.drawTextSimple(centerPosition, "Hello, Pot!", fontName = .PixelCode, pivot = .centerCenter)
}

shutdown :: proc() {
}
```

Run it, and you should see beautifully pixelated text saying **"Hello, Pot!"**.
And you're done!

If you wish to learn more, take a look at the introduction and documentation provided
[on the website](https://bonsai-framework.dev).

## Contributing

If you'd like to help build and expand the **bonsai** source code, feel free to open an issue or PR!

---

![pot](readme/pot.gif)

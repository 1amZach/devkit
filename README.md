# devkit

Tools I wanted while building a server: grab coords, see what an entity is, lay out props, and draw zones without guessing numbers in a config file and restarting ten times.

Works with any framework (or none). The only dependency is [ox_lib](https://github.com/overextended/ox_lib).

## Install

1. Drop the `devkit` folder into your resources.
2. Add it to `server.cfg` after ox_lib:

```
ensure ox_lib
ensure devkit
```

3. Give yourself access:

```
add_ace group.admin devkit allow
```

## Usage

`/devkit` or F7 opens the menu. You can also jump straight to a tool:

| Command | |
|---|---|
| `/devkit coords` | Toggle the coords overlay |
| `/devkit inspect` | Entity inspector |
| `/devkit prop [model]` | Prop placer |
| `/devkit poly` | Poly zone builder |
| `/devkit box` | Box zone builder |

Everything copies straight to your clipboard. Zones also get printed to the F8 console in case the clipboard eats it.

### Coords overlay

Shows your position, heading, street, area and interior/room id, plus the exact point you're looking at.

### Entity inspector

Look at anything to see its model name, hash, type, coords and net id, with its bounding box drawn around it.

- `E` copies ``{ model = `prop_name`, coords = vec4(...) },``
- `H` copies the hash
- `G` copies the vec4

### Prop placer

The prop follows where you're looking. `Enter` drops it and starts on another copy, so you can lay out a row of benches quickly. Placed props show up under **Placed props** in the menu, where you can copy them all at once.

| Key | |
|---|---|
| Scroll | Rotate |
| R | Switch axis (yaw, pitch, roll) |
| Up / Down | Raise / lower |
| G | Snap to ground |
| X | Reset pitch and roll |
| E | Copy current placement |
| Enter | Place |
| Shift | Fine steps |
| Backspace | Done |

Props are local only. Nobody else sees them, and they're removed when the resource stops.

### Zone builder

Output is ready to paste as an ox_lib zone.

**Poly:** `E` adds a point where you're looking, `X` removes the last one, scroll changes thickness. `Enter` copies:

```lua
lib.zones.poly({
    points = {
        vec3(215.12, -810.44, 30.73),
        vec3(228.90, -815.02, 30.73),
        vec3(224.31, -828.67, 30.73),
    },
    thickness = 4.00,
})
```

**Box:** follows where you're looking until you lock it with `E`. Arrows set width and length, PgUp/PgDn the height, scroll rotates.

## Config

See `config.lua`. You can change the command, keybind, ace name, decimal places and colours.

## License

MIT

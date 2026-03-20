# [TM2020 Editor Route](https://openplanet.dev/plugin/EditorRoute)

Shows visualizations of recorded runs from Test Mode and Track Validation within the Map Editor.

## Features

### Route Recording and Visualization
- **Route Recording**: Automatically record routes while testing and validating your maps in the editor. Routes are split when respawning or resetting.
- **Driven Route**: Display lines that show the driven route, allowing you to see exactly where your car has been.
- **Rotation and Bounds**: Display a gizmo that shows the rotation of the car and its bounding box.
- **Events**: Display event markers that show exactly where something happened.

### Stats, Events, and Spectrum Timeline
- **Per Route Details Panel**: Access details of recorded data and events, including:
  - Speed
  - Altitude
  - Position
  - FPS
  - And more to come
- **Event Recording**: Captures events during your drive, such as:
  - Gear Changes
  - Wheel Contact
  - And more to come
- **Spectrum Timeline**: Visualize selected details over time (e.g., Gear Shifts or FPS) with a color-coded spectrum timeline.
- **Route Player**: Hit the Play button to see your recorded car movement in real-time.
- **Middle Mouse Button Navigation**: Click the middle mouse button to navigate directly to events in the timeline.

### Import & Export
- **Export to File**: Save your recorded routes to files that are automatically organized by maps.
- **Import from File**: Import routes that you previously saved or even import routes that your friends shared with you.
- **Sharing Routes**: To share routes with your friends, simply locate the saved routes JSON file and share it with your friend. To import shared routes, simply place them in the Saved Routes folder and load them in the game.
- **Export via HTTP Post (Experimental)**: This advanced feature allows you to upload selected routes to a specified URL. This can be used in combination with [Blendermania](https://github.com/skyslide22/blendermania-addon) to export your routes to Blender.

## Contributing
If you're a developer interested in contributing new features or customizations, please explore the code, get in touch on [Discord](https://discord.com/channels/276076890714800129/1202328231819362344), and submit a pull request.

This plugin uses a custom preprocessor to add C-style macro support. The plugin code is not valid AngelScript code for OpenPlanet and must not be placed in the OpenPlanet plugin folder directly.

The project now uses the standalone PluginBuilder from the `tm-plugin-builder/` submodule. This repository contains the plugin-specific builder settings in `plugin-builder.toml` plus two helper scripts that make the common workflows easy to run.

The helper scripts use shared PowerShell logic from the submodule and resolve the builder in this order:
- use an existing local builder build if one is already available
- otherwise download a matching prebuilt builder from GitHub Releases when the submodule is checked out at an exact tag
- otherwise build the builder locally from the submodule source

### Build Debug

```powershell
.\BuildDebug.ps1
```

This script:
- Resolves PluginBuilder through the shared `tm-plugin-builder` PowerShell module.
- Uses this repository as the `--project-dir`.
- Uses `C:\Users\<YourUser>\OpenplanetNext\Plugins` as the OpenPlanet plugins folder.
- Rebuilds the `EditorRouteDev` plugin folder with preprocessed files for local testing.

### Build Release

```powershell
.\BuildRelease.ps1
```

This script:
- Resolves PluginBuilder through the shared `tm-plugin-builder` PowerShell module.
- Runs the standalone builder in release mode for this repository.
- Creates the packaged `.op` archive in `archive/<version>/`.

### Manual Equivalent Commands

If you want to bypass the helper scripts and run the builder directly after obtaining a local build:

```powershell
tm-plugin-builder/build/Release/bin/PluginBuilder.exe --command debug --project-dir . --plugins-path C:/Users/YourUsername/OpenplanetNext/Plugins
tm-plugin-builder/build/Release/bin/PluginBuilder.exe --command release --project-dir .
```

#### `//#require` Comment

To handle dependencies between AngelScript files, use the `//#require` comment to specify the required files. Paths are relative to the root folder.

Example:
```c++
//#require "My/Other/File.as"
```
This directive ensures that `My/Other/File.as` is processed before the current file.

#### Preprocessor Directives

To use builtin OpenPlanet preprocessor directives, use these predefined custom macros:
```c++
#define AS_IF #if
#define AS_ELIF #elif
#define AS_ELSE #else
#define AS_ENDIF #endif
```

Use these macros in your AngelScript files:
```angelscript
AS_IF TMNEXT
  print("I am running on Trackmania (2020)");
AS_ELIF MP4
  print("I am running on Maniaplanet 4");
AS_ELSE
  print("I am running on a different game");
AS_ENDIF
```

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

This plugin uses a custom preprocessor to add C-Style Macro support. The plugin code is not valid AngelScript code for OpenPlanet and must not be placed in the OpenPlanet plugin folder directly.

We will use the `pluginbuilder.exe` with the debug command to preprocess the plugin code and copy it to the OpenPlanet plugin folder:

### Contributing: How to Use the Debug Command
Before using the `debug` command, ensure you have the following:

1. **Prebuilt `pluginbuilder.exe`**: The executable should be placed in the root folder of the repository.
2. **Git Repository**: Ensure you have cloned the repository and are working from the root directory of the cloned repository.

#### Steps to Use the Debug Command

1. **Navigate to the Repository Root**:
   Open a command prompt or terminal and navigate to the root directory of the cloned repository.

   ```sh
   cd path/to/your/cloned/repository
   ```

2. **Verify `info.toml`**:
   Ensure the `info.toml` file exists in the root directory. The `pluginbuilder.exe` requires the working directory to be the root directory of the repository.

3. **Run the Debug Command**:
   Use the `pluginbuilder.exe` with the `debug` command. You need to specify the path where the OpenPlanet plugins are located.

   ```sh
   pluginbuilder.exe debug C:/Users/YourUsername/OpenplanetNext/Plugins
   ```

   Replace `C:/Users/YourUsername/OpenplanetNext/Plugins` with the actual path to your OpenPlanet plugins directory.

4. **Checks Performed by the Debug Command**:
   - Verifies that the current working directory contains an `info.toml` file with the `[meta]` section and `name = "Editor Route"`.
   - Ensures that the working directory is not the same as the specified OpenPlanet plugins path.

5. **Expected Behavior**:
   - Checks if the target directory  `C:/Users/YourUsername/OpenplanetNext/Plugins/EditorRouteDev` directory exists and **deletes it** if it exists. 
   - Copies whitelisted files and folders (`src`, `info.toml`, `LICENSE`, `Readme.md`) to the target directory.
   - Runs the `mcpp` C-Preprocessor on the copied `src` folder, updating the files as necessary for the debug environment.

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

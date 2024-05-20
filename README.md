# Pong Game

This is a simple Pong game implemented in Love2D with a custom resolution handling library (`resolution.lua`). The game features basic paddle and ball mechanics and allows for window resizing and fullscreen mode.

## Requirements

- [Love2D](https://love2d.org/) (version 11.3 or higher)

## Setup Instructions

1. **Clone the repository:**

   ```sh
   git clone https://github.com/yourusername/pong-game.git
   cd pong-game
   ```

2. **Ensure Love2D is installed on your system.** You can download it from the [Love2D website](https://love2d.org/).

3. **Run the game:**

   - On Windows, drag and drop the project folder onto the `love.exe` executable.
   - On macOS or Linux, use the terminal to navigate to the project folder and run:

     ```sh
     love .
     ```

## File Structure

- `main.lua`: The main entry point for the game. Handles initialization, game logic, and rendering.
- `resolution.lua`: Custom resolution handling library used to manage virtual and actual screen resolutions.
- `MyBall.lua`: Contains the definition for the ball object used in the game (if needed).
- `MyPaddle.lua`: Contains the definition for the paddle object used in the game (if needed).
- `font.ttf`: Font file used for rendering text in the game.

## Game Controls

- `W` or `S`: Move the left paddle up or down.
- `Up` or `Down` arrow keys: Move the right paddle up or down.
- `Space`: Pause or unpause the game.
- `Escape`: Exit the game.

## Customization

You can customize various aspects of the game, such as screen dimensions, paddle speed, and game logic, by modifying the relevant variables and functions in `main.lua` and the custom classes (`MyBall.lua`, `MyPaddle.lua`).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgements

- [Love2D](https://love2d.org/) - The framework used to build this game.

## Contact

For any questions or feedback, please reach out to [mzito042@uottawa.ca].


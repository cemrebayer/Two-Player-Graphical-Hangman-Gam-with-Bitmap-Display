# MIPS Assembly: Two-Player Graphical Hangman Game

## Description

A two-player graphical Hangman game implemented in MIPS assembly language for simulators like MARS or SPIM. Features include a 128x128 bitmap display for gallows/hangman visualization, dynamic partial screen clearing for efficiency, turn-based gameplay, scoring, and a hint system. This project demonstrates fundamental game logic and graphical output in a low-level environment.

## Features

*   **Two-Player Mode:** One player sets the word, the other guesses. Roles switch after each round.
*   **Graphical Interface:** Gallows and hangman parts are drawn on a 128x128 bitmap display.
*   **Partial Screen Clearing:** Only the game area is cleared each turn for better performance.
*   **Scoring System:** Reach the target score (default: 3) to win.
*   **Word Masking:** Words are hidden with underscores (`_`).
*   **Letter Tracking:** Prevents guessing the same letter twice without penalty.
*   **Lives System:** 6 lives per guessing round.
*   **Hint System:** Reveal one unguessed letter per round by entering `?`.

## Screenshots
![image alt] (https://github.com/cemrebayer/Two-Player-Graphical-Hangman-Gam-with-Bitmap-Display/blob/027d031866a41b20cfb019911b93dadc05a158c1/Hangman%20Game%20Photo.png)
# How to Run

1.  **Clone or download** this repository.
2.  **Open your MIPS simulator** (e.g., MARS).
3.  **Configure the Bitmap Display:**
    *   Ensure the "Bitmap Display" tool is open/enabled.
    *   Set the display dimensions to **128x128 pixels**.
    *   Set the base address for display to **0x10010000** (`BITMAP_BASE`).
    *   Ensure it's connected to MIPS memory.
4.  **Load the Assembly File:** Open the `your_project_filename.asm` file in the simulator.
5.  **Assemble** the code (e.g., F3 in MARS).
6.  **Run** the program (e.g., F5 in MARS).
7.  Follow the on-screen (console) prompts to play the game.

## Gameplay

1.  **Word Setting:** The designated player will be prompted to enter a word (max 31 characters, lowercase English letters only). This word will not be visible to the guessing player.
2.  **Guessing:** The other player will see the masked word (e.g., `_ _ _ _`) and will be prompted to guess a letter or enter `?` for a hint.
3.  **Turns:**
    *   Correct guess: The letter is revealed in the word.
    *   Incorrect guess: A life is lost, and a part of the hangman is drawn.
    *   Hint (`?`): One unguessed letter is revealed (can be used once per round).
4.  **Winning/Losing a Round:**
    *   The guessing player wins the round by guessing all letters before running out of lives.
    *   The setting player wins the round if the guessing player runs out of lives.
5.  **Scoring:** The winner of the round gets 1 point.
6.  **Switching Roles:** After each round, players switch roles (setter becomes guesser and vice-versa).
7.  **Winning the Game:** The first player to reach the `max_score_val` (default 3) wins the overall game.

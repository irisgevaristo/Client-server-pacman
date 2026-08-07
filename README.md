# Client-server Pacman

A multi-threaded C implementation of a client-server Pacman game system, developed for the Operating Systems (Sistemas Operativos) course.

In Client-server Pacman, multiple clients can connect concurrently to a central server using named pipes (FIFOs) to play through customizable levels. The server manages real-time state, board parsing, multi-threaded entity logic (Pacman movement, ghost AI behaviors), and IPC synchronization.

## Table of Contents

- [Features](#features)
- [Software architecture and components](#software-architecture-and-components)
- [Prerequisites](#prerequisites)
- [Running the game](#running-the-game)
  - [Compilation](#compilation)
  - [Launching the server](#launching-the-server)
  - [Launching a client](#launching-a-client)
- [Game rules and mechanics](#game-rules-and-mechanics)
  - [Client interface and input format](#client-interface-and-input-format)
  - [Ghost types and behaviors](#ghost-types-and-behaviors)
  - [Level progression and victory conditions](#level-progression-and-victory-conditions)
- [Server signals and logging](#server-signals-and-logging)
- [Author](#author)

## Features

- **Concurrent Multi-Client Server:** Supports a configurable number of active player sessions executing in parallel using worker threads and a Producer-Consumer buffer managed with POSIX semaphores and mutexes.
- **IPC Architecture via Named Pipes:** Uses dedicated FIFOs for connection registration, asynchronous client command requests, and real-time board notification updates.
- **Dynamic Board and Script Parsing:** Reads custom `.lvl` level files and entity behavior scripts defining movement rules and automated commands.
- **Fine-Grained Thread Synchronization:** Employs read-write locks (`pthread_rwlock_t`) for board state and fine-grained mutexes per grid cell to handle simultaneous entity movements safely.
- **Live Statistics Logging:** Handles OS signals (`SIGUSR1`) to rank and output active session metrics to an external log file.

## Software architecture and components

The system is designed with a clear separation between the client-side user interface and server-side game logic:

- **Client (`client.c`, `api.c`, `display.c`)**
  - **Connection API:** Creates client-specific FIFOs (`req_pipe` and `notif_pipe`) and registers with the main server FIFO.
  - **Receiver Thread:** Continuously listens for binary board updates and triggers UI re-renders.
  - **User Interface:** Uses `ncurses` to capture `W/A/S/D` or script-driven movement inputs and render walls, dots, ghosts, and portals.

- **Server (`server.c`, `board.c`, `parser.c`, `display.c`, `game.c`)**
  - **Request Buffer & Thread Pool:** Receives connection requests via a bounded buffer synchronized by POSIX semaphores (`sem_full`, `sem_empty`).
  - **Session Manager (`run_game_session`):** Spawns dedicated threads for Pacman and every ghost instance per active level.
  - **Level & Script Parser:** Reads board dimensions, ghost files (`MON`), speed timing (`TEMPO`), and movement sequences.
  - **Entity Movement Engine:** Manages fine-grained lock ordering during position updates to avoid race conditions or deadlocks.

## Prerequisites

To build and run **Pacmanist**, you need a C compiler environment supporting C99 / POSIX.1-2008 standard and the required development headers.

| Requirement | Purpose | Package Name |
| :--- | :--- | :--- |
| **GCC / Clang** | C99 / POSIX C compiler | `gcc` / `clang` |
| **GNU Make** | Build automation tool | `make` |
| **POSIX Threads & Realtime** | Multi-threading (`pthread`) and timing (`rt`) support | Included in `glibc` |
| **Ncurses Library** | Terminal GUI rendering for the client | `libncurses-dev` / `ncurses-devel` |

## Running the game

### Compilation
The project includes a structured `Makefile` for automated compilation.

To compile both the server (`pacman_server`) and client (`pacman_client`) binaries, run:
```bash
make
```

To remove compiled binaries, object files, and temporary FIFOs:
```bash
make clean
```

### Launching the server
Run the server executable by passing the levels directory, the maximum number of concurrent games allowed, and the registration pipe path:

```bash
cd server-side
./bin/PacmanIST <levels_dir> <max_games> <register_pipe>
```

**Example:**
```bash
./bin/PacmanIST ./dir1 5 /tmp/register_pipe
```

### Launching a client
Connect a client by providing a unique Client ID, the server registration pipe path, and optionally a command script file for automated inputs:

```bash
cd client-side
./bin/client <client_id> <register_pipe> [command_script]
```

**Example:**
```bash
./pacman_client player1 /tmp/register_pipe
```

## Game rules and mechanics

### Client interface and input format
In interactive mode, player controls are mapped as follows:
- `W` / `A` / `S` / `D`: Move Up, Left, Down, and Right.
- `Q`: Quit the current session.

In scripted mode, inputs are read line-by-line from a text file.

### Ghost types and behaviors
- **Standard Ghosts (`M`):** Move according to their script directions (`W`, `A`, `S`, `D`, `R` for random) or step rate (`PASSO`).
- **Charged Ghosts (`m` / `C`):** Enter a charged state that allows them to charge in a direction across multiple cells until hitting a wall, another ghost, or catching Pacman.

### Level progression and victory conditions
- **Dot Collection:** Pacman accumulates points by moving over dots (`.`) scattered across the board.
- **Portal (`@`):** Reaching the portal finishes the current level and carries accumulated points over to the next level in the directory.
- **Game Over:** If a ghost moves onto Pacman's cell (or vice-versa), Pacman dies, ending the game session.
- **Victory:** Successfully clearing all `.lvl` files in the levels directory results in a session victory.

## Server signals and logging

The server includes built-in monitoring capabilities:
- **`SIGUSR1` Signal:** Sending a `SIGUSR1` signal to the running server process triggers an active game log update:

  ```bash
  kill -SIGUSR1 <SERVER_PID>
  ```
- **`server_log.txt`:** Generates a real-time status summary containing total active games and detailed information (Level Name, Dimensions, Pacman Position, Current Points) for the Top 5 performing sessions.

## Author

- **Author:** Íris Gaspar Evaristo
- **License:** MIT License © 2026 Íris Evaristo
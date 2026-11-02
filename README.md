<p align="center">
  <img src="https://img.shields.io/badge/Language-C-00599C?style=for-the-badge&logo=c&logoColor=white" alt="C" />
  <img src="https://img.shields.io/badge/Standard-C99-00599C?style=for-the-badge&logo=c&logoColor=white" alt="C99" />
  <img src="https://img.shields.io/badge/Platform-Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
  <img src="https://img.shields.io/badge/Build-GNU_Make-064F8C?style=for-the-badge&logo=gnu&logoColor=white" alt="Make" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

<h1 align="center">🐚 MshX — A Unix Shell from Scratch</h1>

<p align="center">
  <strong>A lightweight, dependency-free Unix shell written entirely in C.</strong><br/>
  <em>Every layer handcrafted: Tokenizer → Parser → AST → Executor.</em>
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-built-in-commands">Built-ins</a> •
  <a href="#-architecture">Architecture</a> •
  <a href="#-usage-examples">Examples</a> •
  <a href="#-contributing">Contributing</a>
</p>

---

## ✨ Features

| Category | Feature | Description |
|:---:|---|---|
| ⚙️ | **Command Execution** | Run any external program with arguments via `fork`/`execv` |
| 🔗 | **Pipelines** | Chain up to 64 commands with `\|` — connected through `pipe()` + `dup2()` |
| ⚡ | **Logical Operators** | Short-circuit `&&` (AND) and `\|\|` (OR) for conditional execution |
| 🔀 | **I/O Redirection** | Input (`<`), output (`>`), and append (`>>`) redirection with proper fd management |
| 🌐 | **Glob Expansion** | POSIX-compliant wildcard matching — `*`, `?`, and `[...]` character classes |
| 💲 | **Variable Expansion** | Full `$VAR` expansion with a linked-list symbol table and scoped variable stacks |
| 🧮 | **Arithmetic Expansion** | `$((expr))` with operator-precedence parsing (shunting-yard algorithm) |
| ✂️ | **Parameter Expansion** | `${var:-default}`, `${var:=assign}`, `${var:+alt}`, `${var:?err}`, `${#var}`, prefix/suffix removal (`##`, `%%`) |
| 🏷️ | **Tilde Expansion** | `~` resolves to `$HOME`; `~user` resolves via `/etc/passwd` lookup |
| 📜 | **Command History** | Circular buffer (1,000 entries) with `!!`, `!n`, `!-n` expansion and deduplication |
| 🏃 | **Background Jobs** | Launch processes in the background with `&` (automatic `setpgid` isolation) |
| 🔍 | **Dry-Run Mode** | Preview the full execution plan — resolved paths, glob expansions, redirections — with zero side effects |
| ⏱️ | **Execution Timeline** | Profile `fork`, `execve`, `exit`, `pipe`, `redirect`, `signal`, and `stop` events with ms-precision timestamps |
| 🏠 | **Smart Prompt** | Context-aware prompt with `~` home-directory shortening: `~_~/projects:$` |
| ♻️ | **Multi-line Input** | Continue commands across lines with trailing `\` |
| 🛡️ | **Signal Handling** | Shell ignores `SIGINT`/`SIGTSTP`; child processes receive default handlers |
| 📦 | **Command Substitution** | Backtick-style `` `command` `` substitution support |
| 🔤 | **Field Splitting** | Word splitting on `$IFS` boundaries after variable expansion |

---

## 🚀 Quick Start

### Prerequisites

| Tool | Version |
|---|---|
| **GCC** (or any C99-compliant compiler) | 4.9+ recommended |
| **GNU Make** | 3.81+ |
| **Linux / POSIX environment** | Any modern distribution |

### Build & Run

```bash
# Clone the repository
git clone https://github.com/NaimurRahmannn/Mshx-shell-Linux-os.git
cd Mshx-shell-Linux-os

# Build (debug mode: -g -Wall -Wextra)
make

# Launch the shell
./mshX
```

You'll be greeted with the MshX prompt:

```
~_~:$
```

### Clean Build Artifacts

```bash
make clean
```

---

## 🛠️ Built-in Commands

### `cd` — Change Directory

Navigate the filesystem with `$HOME` and `$OLDPWD` integration.

```bash
cd              # Navigate to $HOME
cd /tmp         # Navigate to /tmp
cd -            # Return to previous directory ($OLDPWD)
```

> `cd` automatically updates the `PWD` and `OLDPWD` shell variables in the symbol table.

---

### `history` — Command History

Browse and re-execute previous commands from a 1,000-entry circular buffer.

```bash
history         # Display all history with numbered entries
history 10      # Show the last 10 commands
history -c      # Clear the entire history
```

**History expansion** works inline — no need to invoke the `history` command:

```bash
!!              # Re-execute the most recent command
!5              # Re-execute command number 5
!-2             # Re-execute the command from 2 entries ago
```

> Consecutive duplicate commands are automatically deduplicated.

---

### `dry` — Dry-Run Mode 🔍

Inspect the shell's complete execution plan without any side effects. No `fork`, no `exec`, no file I/O — just analysis.

```bash
dry ls -l *.c
```

```
GLOB: *.c -> executor.c initsh.c main.c node.c parser.c pattern.c ...
EXEC: /usr/bin/ls -l executor.c initsh.c main.c node.c parser.c ...
```

```bash
dry cat input.txt > output.txt
```

```
EXEC: /usr/bin/cat input.txt
REDIRECT: stdout -> output.txt
```

```bash
dry ls | grep .c | wc -l
```

```
PIPE: ls -> grep
PIPE: grep -> wc
EXEC: /usr/bin/ls
EXEC: /usr/bin/grep .c
EXEC: /usr/bin/wc -l
```

```bash
dry sleep 60 &
```

```
BACKGROUND:
EXEC: /usr/bin/sleep 60
```

> The `dry` command re-uses the exact same tokenizer, parser, and AST that real execution uses — the only difference is the executor prints instead of calling system APIs.

---

### `dump` — Symbol Table Inspector

Print every variable stored in the current symbol table scope, including all inherited environment variables.

```bash
dump
```

```
Symbol table [Level 0]:
===========================
  No               Symbol                    Val
------ -------------------------------- ------------
[0000] HOME                             '/home/user'
[0001] PATH                             '/usr/local/bin:/usr/bin:/bin'
[0002] PS1                              '$ '
[0003] PS2                              '> '
...
```

---

### `timeline` — Execution Profiler ⏱️

Prefix any command with `timeline` to trace kernel-level process lifecycle events with millisecond-precision timestamps.

```bash
timeline ls | grep .c
```

```
PID    EVENT                TIME(ms)
------ -------------------- --------
12345  forked               0
12345  execve               0
12346  forked               0
12346  piped(12345→12346)   0
12346  execve               0
12345  exited(0)            1
12346  exited(0)            1
```

**Tracked events:**

| Event | Description |
|---|---|
| `forked` | New child process created via `fork()` |
| `execve` | Program image replaced via `execv()` |
| `exited(n)` | Process terminated with exit code `n` |
| `signaled(n)` | Process killed by signal `n` |
| `stopped(n)` | Process suspended by signal `n` (e.g., `Ctrl+Z`) |
| `continued` | Stopped process resumed |
| `piped(A→B)` | Pipe established from PID `A` to PID `B` |
| `redirected(>file)` | File descriptor redirected to `file` |

---

## 🏗️ Architecture

MshX follows a classic **compiler-frontend pipeline** — input text is transformed through discrete stages before reaching execution:

```
┌──────────┐    ┌───────────┐    ┌──────────┐    ┌────────────┐
│  Source   │───▶│  Scanner  │───▶│  Parser  │───▶│  Executor  │
│  (stdin)  │    │(tokenizer)│    │  (AST)   │    │(fork/exec) │
└──────────┘    └───────────┘    └──────────┘    └────────────┘
                                                       │
                                           ┌───────────┴───────────┐
                                           │                       │
                                     ┌─────▼─────┐         ┌──────▼──────┐
                                     │ Built-ins  │         │  External   │
                                     │(cd,dry,...) │         │  Programs   │
                                     └───────────┘         └─────────────┘
```

### Pipeline Stages

| Stage | Module | Responsibility |
|---|---|---|
| **Input** | [`source.c`](source.c) | Character-stream abstraction with `next_char()`, `peek_char()`, and `unget_char()` |
| **Lexing** | [`scanner.c`](scanner.c) | Tokenizes raw input into tokens — handles quotes, escapes, operators (`\|`, `&&`, `\|\|`, `;`, `&`, `>`, `<`, `>>`) |
| **Parsing** | [`parser.c`](parser.c) | Recursive-descent parser that builds an AST from the token stream |
| **AST** | [`node.c`](node.c) | Tree node creation, child management, and memory lifecycle |
| **Word Expansion** | [`wordexp.c`](wordexp.c) | Tilde expansion → variable expansion → command substitution → arithmetic expansion → field splitting → pathname expansion |
| **Pattern Matching** | [`pattern.c`](pattern.c) | `fnmatch`-based glob matching with prefix/suffix extraction for parameter expansion |
| **Arithmetic** | [`shunt.c`](shunt.c) | Shunting-yard algorithm for `$((expr))` — supports all C integer operators including ternary `?:` |
| **Execution** | [`executor.c`](executor.c) | `fork`/`execv` dispatch with pipeline wiring, I/O redirection, background jobs, and dual-mode (real / dry-run) execution |
| **Variables** | [`symtab/symtab.c`](symtab/symtab.c) | Scoped, linked-list symbol table with a stack of scopes for variable lookup |
| **Initialization** | [`initsh.c`](initsh.c) | Imports environment variables into the symbol table, sets up signal handlers, initializes history |
| **Prompt** | [`prompt.c`](prompt.c) | Context-aware prompt rendering with `~` substitution |
| **Utilities** | [`strings.c`](strings.c) | Dynamic buffer management, string quoting, and character-set search helpers |

### Source Tree

```
MshX/
├── main.c                 # REPL loop — read → expand → parse → execute
├── prompt.c               # Smart prompt with ~ home substitution
├── scanner.c              # Lexical analyzer / tokenizer
├── parser.c               # Recursive-descent parser → AST
├── node.c                 # AST node creation & lifecycle management
├── executor.c             # Execution engine (fork/exec/pipe/redirect/background)
├── wordexp.c              # Word expansion (tilde, variables, commands, arithmetic, globs)
├── pattern.c              # Glob/fnmatch pattern matching
├── strings.c              # String utilities & dynamic buffer management
├── shunt.c                # Shunting-yard arithmetic expression evaluator
├── source.c               # Input source character-stream abstraction
├── initsh.c               # Shell initialization & signal setup
├── Makefile               # Build system
│
├── builtins/
│   ├── builtins.c         # Built-in command registry (dispatch table)
│   ├── cd.c               # cd — change directory with OLDPWD tracking
│   ├── dry.c              # dry — zero-side-effect execution preview
│   ├── dump.c             # dump — symbol table inspector
│   ├── history.c          # history — circular buffer with !! and !n expansion
│   ├── history.h          # History API declarations
│   ├── timeline.c         # timeline — ms-precision execution profiler
│   └── timeline.h         # Timeline event types & API declarations
│
├── symtab/
│   ├── symtab.c           # Symbol table — scoped linked-list with stack
│   └── symtab.h           # Symbol table structures & API declarations
│
├── mshX.h                 # Global declarations, built-in prototypes, word struct
├── executor.h             # Executor API & dry-run function prototypes
├── scanner.h              # Token structure & tokenizer API
├── parser.h               # Parser API
├── source.h               # Source stream structure & character-access API
└── node.h                 # AST node types, value union, & tree API
```

### Key Design Decisions

| Decision | Rationale |
|---|---|
| **Zero external dependencies** | Pure C99 with POSIX APIs only — no readline, no ncurses, no third-party libraries |
| **AST-based execution** | Commands are parsed into a tree before execution, enabling the dry-run introspection mode |
| **Dual execution modes** | A single `enum exec_mode` flag switches the same pipeline between real and dry-run execution |
| **Circular buffer history** | O(1) insertion with a constant memory ceiling of 1,000 entries |
| **Linked-list symbol table with scope stack** | Supports nested scopes and global/local variable separation |
| **Shunting-yard arithmetic** | Full C-operator precedence for `$((expr))` without an external math library |
| **Pipeline via `pipe()` + `fork()` + `dup2()`** | Multi-stage pipes (up to 64) with proper fd cleanup in both parent and child processes |
| **Signal isolation** | Shell process ignores `SIGINT`/`SIGTSTP`; child processes receive default signal disposition via `reset_signals_for_child()` |
| **Background job isolation** | Background processes call `setpgid(0, 0)` to detach from the terminal's process group |

---

## 💡 Usage Examples

### Pipes & Redirection

```bash
ls -la | grep ".c" | wc -l          # Count C source files
cat file.txt > output.txt           # Overwrite output
sort < input.txt >> results.txt     # Append sorted input
```

### Logical Operators

```bash
mkdir build && cd build              # cd only runs if mkdir succeeds
gcc main.c || echo "Build failed"    # echo only runs if gcc fails
```

### Background Execution

```bash
sleep 60 &                           # Run in background
find / -name "*.log" > logs.txt &    # Background with redirection
```

### Command Sequences

```bash
echo "Step 1" ; echo "Step 2" ; echo "Step 3"
```

### Variable & Parameter Expansion

```bash
echo $HOME                           # Simple variable expansion
echo $PATH
echo $?                              # Exit status of last command
echo $$                              # PID of the shell
echo ${HOME:-/tmp}                   # Default value if HOME is unset
echo ${#PATH}                        # Length of PATH variable
```

### Arithmetic Expansion

```bash
echo $((2 + 3 * 4))                 # Evaluates to 14
echo $(( (5 > 3) ? 10 : 20 ))       # Ternary: evaluates to 10
```

### Wildcards & Globbing

```bash
ls *.c                               # All C source files
echo src/**/*.h                      # Recursive header files
cat [Mm]akefile                      # Case-insensitive Makefile match
```

### Multi-line Commands

```bash
echo "This is a \
multi-line command"
```

---

## 🔧 Build Options

| Command | Description |
|---|---|
| `make` | Build the shell binary in debug mode (`-g -Wall -Wextra`) |
| `make clean` | Remove all compiled objects, the binary, and the `build/` directory |

The compiled binary is produced as `./mshX` in the project root. Object files are placed in `./build/`.

---

## 📊 Codebase Statistics

| Metric | Value |
|---|---|
| **Language** | C (C99) |
| **Total source files** | 20 (`.c` + `.h`) |
| **Lines of code** | ~6,800+ |
| **External dependencies** | 0 |
| **Build time** | < 2 seconds (typical) |

---

## 🤝 Contributing

Contributions are welcome! To get started:

1. **Fork** this repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m "Add my feature"`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a **Pull Request**

Please ensure your code compiles cleanly with `-Wall -Wextra` and follows the existing code style.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

Copyright © 2026 [NaimurRahmannn](https://github.com/NaimurRahmannn)



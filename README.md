# MshX

**MshX** is a Unix shell implemented from the ground up in C. It does not depend on readline, ncurses, or any third-party library — every component, from the tokenizer to the executor, is written by hand using only POSIX system calls.

The goal was simple: understand how a shell actually works by building one.

```
~_~:$ ls *.c | wc -l
20
~_~:$ dry ls *.c | wc -l
GLOB: *.c -> executor.c initsh.c main.c node.c parser.c pattern.c prompt.c scanner.c shunt.c source.c strings.c wordexp.c
PIPE: ls -> wc
EXEC: /usr/bin/ls executor.c initsh.c main.c node.c parser.c pattern.c prompt.c scanner.c shunt.c source.c strings.c wordexp.c
EXEC: /usr/bin/wc -l
```

---

## Getting Started

**One-liner install:**

```bash
curl -sSL https://raw.githubusercontent.com/NaimurRahmannn/Mshx-shell-Linux-os/main/install.sh | bash
```

This checks for dependencies, clones the repo, builds from source, and installs `mshx` to `~/.local/bin`.

**Manual build:**

```bash
git clone https://github.com/NaimurRahmannn/Mshx-shell-Linux-os.git
cd Mshx-shell-Linux-os
make
./mshX
```

**Install system-wide (after building):**

```bash
make install                        # installs to ~/.local/bin/mshx
sudo make install PREFIX=/usr/local # installs to /usr/local/bin/mshx
make uninstall                      # remove it
```

Requires GCC (or any C99 compiler), GNU Make, and a Linux/POSIX system. Run `make clean` to remove build artifacts.

---

## How It Works

Every command you type passes through four stages before anything happens:

```
Input  ──▶  Scanner  ──▶  Parser  ──▶  Executor
(text)     (tokens)      (AST)       (fork/exec)
```

**Stage 1 — Scanner** (`scanner.c`): Reads the raw character stream and produces tokens. It recognizes quoted strings (`"..."`, `'...'`), escape sequences (`\`), operators (`|`, `&&`, `||`, `;`, `&`, `>`, `>>`, `<`), variable references (`$VAR`, `${...}`), and regular words. The tokenizer uses a dynamically growing buffer that starts at 1KB and doubles as needed.

**Stage 2 — Parser** (`parser.c`): Takes the token stream and builds an Abstract Syntax Tree. Each simple command becomes a `NODE_COMMAND` node whose children are `NODE_VAR` nodes — one per word/argument. The parser stops at operator boundaries and hands control back to the main loop, which handles pipelines, logical operators, and sequences.

**Stage 3 — Word Expansion** (`wordexp.c`, 1800+ lines): Before execution, every word goes through a six-step expansion pipeline:

1. **Tilde expansion** — `~` becomes `$HOME`, `~user` resolves via `getpwnam()`
2. **Variable expansion** — `$VAR`, `${var:-default}`, `${var:=value}`, `${var:+alt}`, `${var:?error}`, `${#var}`, prefix/suffix stripping (`##`, `%%`)
3. **Command substitution** — `` `command` `` runs the command and captures its output
4. **Arithmetic expansion** — `$((2 + 3 * 4))` evaluated via a shunting-yard algorithm (`shunt.c`, 1300+ lines) supporting all C integer operators including ternary `?:`
5. **Field splitting** — results are split on `$IFS` boundaries
6. **Pathname expansion** — glob patterns (`*`, `?`, `[...]`) are matched against the filesystem using POSIX `glob()`

**Stage 4 — Executor** (`executor.c`): Dispatches commands. Built-in commands run in the shell process. External commands are executed via `fork()` + `execv()`. Pipelines are wired with `pipe()` + `dup2()`. I/O redirection opens files with appropriate flags (`O_TRUNC` for `>`, `O_APPEND` for `>>`). Background jobs are isolated with `setpgid(0, 0)`.

---

## Built-in Commands

MshX includes five built-in commands. They execute inside the shell process — no `fork()` required.

### cd

```bash
cd              # go to $HOME
cd /tmp         # go to /tmp
cd -            # go back to previous directory
```

Tracks `PWD` and `OLDPWD` in the symbol table, so `cd -` always works.

### history

Commands are stored in a circular buffer that holds up to 1,000 entries. Consecutive duplicates are automatically filtered out.

```bash
history         # show all entries with line numbers
history 20      # show the last 20
history -c      # clear everything
```

History expansion happens inline before the command is parsed:

```bash
!!              # repeat the last command
!5              # repeat command #5
!-2             # repeat the command from 2 entries ago
```

### dry

This is the command that makes MshX different from most educational shells. `dry` runs the entire parsing and expansion pipeline — tilde expansion, variable substitution, glob matching, path resolution — but stops right before any system call that would have side effects.

No `fork()`. No `exec()`. No files created. No pipes opened.

```bash
~_~:$ dry cat input.txt > output.txt
EXEC: /usr/bin/cat input.txt
REDIRECT: stdout -> output.txt
```

```bash
~_~:$ dry echo *.c | sort | head -5
PIPE: echo -> sort
PIPE: sort -> head
GLOB: *.c -> executor.c initsh.c main.c node.c parser.c ...
EXEC: /usr/bin/echo executor.c initsh.c main.c node.c parser.c ...
EXEC: /usr/bin/sort
EXEC: /usr/bin/head -5
```

```bash
~_~:$ dry sleep 300 &
BACKGROUND:
EXEC: /usr/bin/sleep 300
```

This works because `dry` simply flips a global `enum exec_mode` flag from `EXEC_REAL` to `EXEC_DRY`. The same tokenizer, parser, and AST are used — the executor just prints what it *would* do instead of doing it.

### dump

Prints every variable in the current symbol table scope — all inherited environment variables plus any shell-defined ones.

```bash
~_~:$ dump
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

### timeline

Prefix any command with `timeline` to trace its process lifecycle with millisecond timestamps.

```bash
~_~:$ timeline ls | grep .c
executor.c
initsh.c
main.c
...

PID    EVENT                TIME(ms)
------ -------------------- --------
18201  forked               0
18201  execve               0
18202  forked               0
18202  piped(18201→18202)   0
18202  execve               0
18201  exited(0)            1
18202  exited(0)            1
```

Events tracked: `forked`, `execve`, `exited(code)`, `signaled(sig)`, `stopped(sig)`, `continued`, `piped(A→B)`, `redirected(>file)`.

Internally, `timeline` uses `clock_gettime(CLOCK_MONOTONIC)` for timing and stores up to 256 events in a pre-allocated array, sorted chronologically with `qsort()` before display.

---

## What You Can Do

**Pipes** — chain up to 64 commands:
```bash
cat /var/log/syslog | grep error | sort | uniq -c | sort -rn | head
```

**I/O redirection:**
```bash
sort < input.txt > sorted.txt
echo "appended" >> log.txt
```

**Logical operators:**
```bash
mkdir build && cd build             # short-circuit AND
gcc main.c || echo "failed"         # short-circuit OR
```

**Command sequences:**
```bash
echo one ; echo two ; echo three
```

**Background jobs:**
```bash
find / -name "*.log" > results.txt &
```

**Variable expansion:**
```bash
echo $HOME $PATH $? $$
echo ${HOME:-/tmp}
echo ${#PATH}
```

**Arithmetic:**
```bash
echo $((10 + 20 * 3))
echo $(( (5 > 3) ? 100 : 0 ))
```

**Globbing:**
```bash
ls *.c
cat [Mm]akefile
```

**Multi-line input:**
```bash
echo "this continues \
on the next line"
```

---

## Signal Handling

The shell itself ignores `SIGINT` (Ctrl+C) and `SIGTSTP` (Ctrl+Z) — you won't accidentally kill your session. But every child process gets default signal handlers restored via `signal(SIGINT, SIG_DFL)` right after `fork()`, so Ctrl+C correctly terminates running commands.

`SIGTTOU` is ignored globally to prevent the shell from stopping when a background job tries to write to the terminal.

---

## Project Structure

```
├── main.c           REPL loop — read, expand history, parse, execute
├── scanner.c        Tokenizer (handles quotes, escapes, all operators)
├── parser.c         Recursive-descent parser → AST
├── node.c           AST node creation and memory management
├── executor.c       fork/exec/pipe/redirect/background execution
├── wordexp.c        Six-stage word expansion pipeline
├── shunt.c          Shunting-yard arithmetic evaluator
├── pattern.c        Glob pattern matching via fnmatch()
├── source.c         Character-stream abstraction (next, peek, unget)
├── prompt.c         Prompt rendering with ~ substitution
├── initsh.c         Environment import, signal setup, history init
├── strings.c        Buffer management and string utilities
├── builtins/
│   ├── builtins.c   Dispatch table for built-in commands
│   ├── cd.c         cd with OLDPWD tracking
│   ├── dry.c        Dry-run execution mode
│   ├── dump.c       Symbol table inspector
│   ├── history.c    Circular buffer history with expansion
│   └── timeline.c   Process lifecycle profiler
└── symtab/
    └── symtab.c     Linked-list symbol table with scope stack
```

20 source files. ~6,800 lines of C. Zero external dependencies.

---

## License

MIT — see [LICENSE](LICENSE) for details.

Copyright © 2026 [NaimurRahmannn](https://github.com/NaimurRahmannn)

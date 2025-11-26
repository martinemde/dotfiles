# `bat` Configuration and Usage Guide

This document provides reference documentation for configuring and using **`bat`**, a modern alternative to the classic Unix `cat` command. It explains the meaning of each configuration option, describes related flags and themes, and outlines example usage patterns.

---

## Overview

`bat` is a syntax-highlighting file viewer written in Rust. It extends `cat` with a range of developer-friendly features:

- Syntax highlighting for many languages
- Git integration (highlighting modified, added, or removed lines)
- Automatic paging through `less` or another pager
- Line numbering and header decorations
- Configurable themes and styles
- Support for italics, decorations, and plain output modes
- Compatibility with common Unix pipelines and scripting

`bat` can serve both as a file viewer and as a drop-in replacement for `cat`.

---

## Example Configuration

A typical configuration file (`~/.config/bat/config`) might contain:

```text
# Catppuccin theme for bat
--theme="Catppuccin Mocha"

# Show line numbers
--style="numbers,changes,header"

# Use italic text on the terminal
--italic-text=always

# Show file headers
--decorations=always
```

Each directive begins with `--` and matches the long-form command-line flag for `bat`.

---

## Option Reference

| Option                             | Description                                                                                                                                                                           | Alternatives                                                                                                        |
| ---------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `--theme="Catppuccin Mocha"`       | Selects the syntax highlighting theme. `Catppuccin Mocha` is one of the community themes. Themes control color palettes for syntax scopes.                                            | List available themes with `bat --list-themes`. Can also be set using the environment variable `BAT_THEME`.         |
| `--style="numbers,changes,header"` | Controls which style components are shown. <br>• `numbers` – show line numbers <br>• `changes` – show Git modification indicators <br>• `header` – print a header line with file name | Possible components include: `plain`, `grid`, `header`, `numbers`, `changes`, `rule`. Combine multiple with commas. |
| `--italic-text=always`             | Forces italic text rendering where supported. Useful for comment or markup scopes.                                                                                                    | Other values: `auto` (enable when supported), `never` (disable italics).                                            |
| `--decorations=always`             | Enables headers, gridlines, and other decorative elements. Setting `always` shows them even in non-interactive contexts.                                                              | `auto` (default) displays decorations only in terminals; `never` disables them entirely.                            |

---

## Additional Useful Flags

These options can be combined with or override configuration file settings:

| Option                               | Function                                                                       |
| ------------------------------------ | ------------------------------------------------------------------------------ | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--paging=auto                       | always                                                                         | never` | Controls paging behavior. When set to `auto`, `bat` pipes through a pager only when output exceeds terminal height. Use `--paging=never` to mimic `cat`. |
| `--color=auto                        | always                                                                         | never` | Controls whether syntax highlighting colors are emitted. Useful for scripting or piping output.                                                          |
| `--plain` or `-p`                    | Disables all decorations and syntax highlighting, producing plain text output. |
| `--map-syntax='pattern:Language'`    | Maps file name patterns to a specific syntax definition.                       |
| `--show-all` or `-A`                 | Displays non-printable characters such as tabs and line endings.               |
| `--strip-ansi=auto                   | yes                                                                            | no`    | Removes ANSI escape sequences before highlighting.                                                                                                       |
| `--list-themes` / `--list-languages` | Lists available themes and supported language grammars.                        |

---

## Example Usage

```bash
# View a file with syntax highlighting, numbers, and header
bat main.rs
```

```bash
# Display plain text (no colors or decorations)
bat --plain README.md
```

```bash
# Concatenate multiple files with highlighting
bat config.yaml app.rb
```

```bash
# Use bat as a drop-in replacement for cat
alias cat="bat --paging=never"
```

```bash
# Show git diffs with syntax highlighting
git show HEAD~1:src/file.rs | bat -l rs
```

```bash
# Integrate with fzf for previews
fzf --preview 'bat --color=always --style=numbers --line-range :500 {}'
```

---

## Configuration Directory

`bat` reads its configuration from:

```sh
~/.config/bat/config
```

`bat` stores syntax definitions and themes in:

```sh
~/.config/bat/syntaxes/
~/.config/bat/themes/
```

Rebuild caches after adding new themes or syntax definitions:

```bash
bat cache --build
```

---

## Environment Variables

| Variable          | Purpose                                               |
| ----------------- | ----------------------------------------------------- |
| `BAT_THEME`       | Overrides the default theme.                          |
| `BAT_PAGER`       | Sets a custom pager command (e.g., `less -FR`).       |
| `BAT_STYLE`       | Defines default style elements, similar to `--style`. |
| `BAT_CONFIG_PATH` | Points to an alternate configuration file.            |

---

## Best Practices

- Use `--paging=never` when aliasing `cat` to `bat` for scripting compatibility.
- Keep `--decorations=auto` for better pipeline behavior.
- Experiment with `--style` combinations to adjust display density.
- Rebuild caches after updating or adding themes.
- Use `bat --plain` when piping output to other commands that expect raw text.

---

## Further Reading

For the complete manual and additional examples, see:

- **Official Repository:** [sharkdp/bat on GitHub](https://github.com/sharkdp/bat)
- **Themes Collection:** [Catppuccin/bat](https://github.com/catppuccin/bat)
- **Syntax Definitions:** [bat Syntaxes](https://github.com/sharkdp/bat#adding-new-syntaxes--themes)

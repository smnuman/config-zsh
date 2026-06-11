# Zsh Non-ASCII Debugging Skill

Systematic approach for debugging zsh shell configuration issues caused by non-ASCII characters
in config files.

## When To Use

- Shell errors contain unexpected Unicode/quote characters
- `ls` produces `invalid character` errors
- Aliases or functions defined in config files don't work as expected
- General "something is wrong with my shell" with no obvious cause
- Copy-pasted config snippets behaving oddly

## Detection

### Step 1: Scan All Config Files

```bash
python3 << 'PYEOF'
import os

root = os.path.expanduser("~/.config/zsh")  # adjust to your ZDOTDIR
for dirpath, dirnames, fnames in os.walk(root):
    dirnames[:] = [d for d in dirnames if d.startswith('.') or d == 'node_modules']
    for fname in fnames:
        if not fname.endswith(('.zsh', '.sh', '.zshenv', '.zshrc', '.zprofile', 'aliases', 'exports')):
            continue
        fpath = os.path.join(dirpath, fname)
        with open(fpath, 'rb') as f:
            data = f.read()
        text = data.decode('utf-8', errors='replace')
        for lineno, line in enumerate(text.split('\n'), 1):
            for col, ch in enumerate(line):
                if ord(ch) > 127:
                    print(f"{fpath}:L{lineno}:{col} {repr(ch)} (U+{ord(ch):04X})")
PYEOF
```

### Step 2: Filter Out Intentional Unicode

Known intentional Unicode categories in shell configs:

- Emoji in prompt themes, status output, or alias values (`✅`, `❌`, `📊`, `🔒`, `🌐`, etc.)
- Box-drawing characters in documentation or help output (`├`, `─`, `└`, `│`)
- Section signs (`§`) in keybindings display
- Arrows (`→`, `←`, `↑`, `↓`) in documentation or function output
- Custom powerline/Nerd Font symbols

**Suspect characters** (almost always bugs):
- Curly/smart quotes: `'` (U+2018), `'` (U+2019), `"` (U+201C), `"` (U+201D)
- En-dash `-` (U+2013) or em-dash `—` (U+2014) where ASCII `--` is expected
- Non-breaking space `\xa0` (U+00A0) in code

### Step 3: Check Environment Variables

```bash
# Locale
locale
env | grep -E '^(LANG|LC_|LANGUAGE)'

# LS-related vars (common source of ls errors)
env | grep -E '^LS'

# Shell vars
echo "ZDOTDIR=$ZDOTDIR"
echo "TERM=$TERM"
```

### Step 4: Binary Error String Check

When a binary produces an unfamiliar error, check its strings:

```bash
strings /path/to/binary | grep -i "invalid\|error\|character"
```

For macOS `ls`:
```bash
strings /bin/ls | grep invalid
# → "invalid character '%c' in LSCOLORS env var"
```

## Fixing

### Step 5: Create Backup

```bash
TAG=$(date +%Y%m%d_%H%M%S)
cp /path/to/file /path/to/file.bak.$TAG
```

### Step 6: Replace Non-ASCII With ASCII Equivalents

| Non-ASCII | Unicode | Replace With |
|---|---|---|
| `'` (left single quote) | U+2018 | `'` (ASCII 0x27) |
| `'` (right single quote) | U+2019 | `'` (ASCII 0x27) |
| `"` (left double quote) | U+201C | `"` (ASCII 0x22) |
| `"` (right double quote) | U+201D | `"` (ASCII 0x22) |
| `-` (en-dash) | U+2013 | `--` (ASCII 0x2D x2) |
| `—` (em-dash) | U+2014 | `--` (ASCII 0x2D x2) |
| `\xa0` (non-breaking space) | U+00A0 | ` ` (ASCII 0x20) |

### Step 7: Verify

```bash
# Syntax check
ZDOTDIR=/path/to/config zsh -n -i

# Check aliases load correctly
ZDOTDIR=/path/to/config zsh -fc 'source aliases_file; alias problematic_alias'

# Test the broken command
ls -al

# Start fresh shell
exec zsh
```

### Step 8: Rollback

```bash
source /path/to/rollback_script.zsh  # if created
# OR manually:
cp /path/to/file.bak.TIMESTAMP /path/to/file
```

## Skill Context

This skill was created from debugging `ls: invalid character '` in a zsh dotfiles setup.
See `docs/DEBUG_LS_INVALID_CHAR_SUMMARY.md` and `docs/LESSONS_LEARNED.md` for full context.

## Caution

- Never blindly replace all non-ASCII — emoji and Unicode in prompts is intentional
- Always backup before editing
- Verify syntax after every change
- Changes take effect in new shell sessions, not the current one

---
name: copy
description: Copy the last response to the clipboard
disable-model-invocation: true
argument-hint: '[instructions for what to copy]'
allowed-tools: 'Bash(cat:*), Bash(pbcopy:*), Read'
---

# Copy content to my clipboard using pbcopy

```sh
pbcopy << 'EOF'
[content to copy]
EOF
```

If no arguments are provided, copy your last response.

---
name: copy
description: Copy the last response to the clipboard
argument-hint: '[instructions]'
allowed-tools: 'Bash(cat:*), Bash(pbcopy:*), Read'
disable-model-invocation: true
---

# Copy content to my clipboard using pbcopy

```sh
pbcopy << 'EOF'
[content to copy]
EOF
```

If no arguments are provided, copy your last response.

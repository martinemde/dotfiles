---
name: copy
description: Copy the last response to the clipboard with pbcopy
metadata:
  author: '@ivy (Ivy Evans)'
  version: '1.0'
argument-hint: '[instructions of what to copy]'
allowed-tools: 'Bash(pbcopy:*), Bash(cat:*), Bash(jq:*), Read'
disable-model-invocation: true
---

# Copy content to my clipboard using pbcopy

```sh
pbcopy << 'EOF'
[content to copy]
EOF
```

If arguments are provided, follow their instructions, otherwise copy your last response.

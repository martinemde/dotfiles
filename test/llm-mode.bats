#!/usr/bin/env bats

load test_helper

# Helper to render a template file
render_template() {
    local file="$1"
    chezmoi execute-template --file "$file"
}

# llm.zsh is a template, so it must be rendered before it can be sourced
render_llm_zsh() {
    local rendered="$TEST_TMPDIR/llm.zsh"
    render_template "home/dot_config/zsh/llm.zsh.tmpl" > "$rendered"
    echo "$rendered"
}

@test "llm.zsh has valid shell syntax" {
    local llm_config="home/dot_config/zsh/llm.zsh.tmpl"

    # Test that the template exists
    [ -f "$llm_config" ]

    # Test it renders
    run render_template "$llm_config"
    [ "$status" -eq 0 ]

    # Test rendered syntax is valid
    echo "$output" > "$TEST_TMPDIR/llm.zsh"
    run zsh -n "$TEST_TMPDIR/llm.zsh"
    [ "$status" -eq 0 ]
}

@test "llm.zsh sets simple prompt" {
    local llm_config
    llm_config="$(render_llm_zsh)"

    # Source the file and check PS1 is set
    run zsh -c "source $llm_config && echo \$PS1"
    [ "$status" -eq 0 ]
    [[ "$output" == *"%~ %# "* ]]
}

@test "llm.zsh sets NO_COLOR environment variable" {
    local llm_config
    llm_config="$(render_llm_zsh)"

    # Source the file and check NO_COLOR is set
    run zsh -c "source $llm_config && echo \$NO_COLOR"
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
}

@test "llm.zsh sets simple pagers" {
    local llm_config
    llm_config="$(render_llm_zsh)"

    # Source and check pager variables
    run zsh -c "source $llm_config && echo \$PAGER"
    [ "$status" -eq 0 ]
    [ "$output" = "cat" ]

    run zsh -c "source $llm_config && echo \$GIT_PAGER"
    [ "$status" -eq 0 ]
    [ "$output" = "cat" ]
}

@test "llm.zsh sets skip flags for fancy features" {
    local llm_config
    llm_config="$(render_llm_zsh)"

    # Check SKIP_ZSH_SYNTAX_HIGHLIGHTING is set
    run zsh -c "source $llm_config && echo \$SKIP_ZSH_SYNTAX_HIGHLIGHTING"
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]

    # Check SKIP_ZSH_AUTOSUGGESTIONS is set
    run zsh -c "source $llm_config && echo \$SKIP_ZSH_AUTOSUGGESTIONS"
    [ "$status" -eq 0 ]
    [ "$output" = "1" ]
}

@test "git config-llm template has valid syntax" {
    local git_config="home/dot_config/git/config-llm"

    # Test that the file exists
    [ -f "$git_config" ]

    # Test that it includes base config
    run grep "path = ~/.config/git/config" "$git_config"
    [ "$status" -eq 0 ]
}

@test "git config-llm disables pagers" {
    local git_config="home/dot_config/git/config-llm"

    # Check core pager is set to cat
    run grep "pager = cat" "$git_config"
    [ "$status" -eq 0 ]

    # Check pager section disables all pagers
    run grep -A 5 "^\[pager\]" "$git_config"
    [ "$status" -eq 0 ]
    [[ "$output" == *"diff = false"* ]]
    [[ "$output" == *"log = false"* ]]
}

@test "git config-llm disables colors" {
    local git_config="home/dot_config/git/config-llm"

    # Check color.ui is disabled
    run grep "ui = false" "$git_config"
    [ "$status" -eq 0 ]
}

@test "bat config-llm has plain style" {
    local bat_config="home/dot_config/bat/config-llm"

    # Test that the file exists
    [ -f "$bat_config" ]

    # Check for plain style
    run grep "^--style=plain" "$bat_config"
    [ "$status" -eq 0 ]

    # Check for no colors
    run grep "^--color=never" "$bat_config"
    [ "$status" -eq 0 ]

    # Check for no paging
    run grep "^--paging=never" "$bat_config"
    [ "$status" -eq 0 ]
}

@test ".zshrc template contains LLM detection logic" {
    local zshrc="home/dot_zshrc.tmpl"

    # Check for envsense detection
    run grep "envsense check agent" "$zshrc"
    [ "$status" -eq 0 ]

    # Check for LLM_AGENT_MODE export
    run grep "export LLM_AGENT_MODE=1" "$zshrc"
    [ "$status" -eq 0 ]

    # Check for return statement to skip rest of config
    run grep "return  # Skip all human-friendly configuration" "$zshrc"
    [ "$status" -eq 0 ]
}

@test ".zshrc template has conditional skip for autosuggestions" {
    local zshrc="home/dot_zshrc.tmpl"

    # Check for SKIP_ZSH_AUTOSUGGESTIONS conditional
    run grep 'if \[\[ -z "\${SKIP_ZSH_AUTOSUGGESTIONS:-}" \]\]' "$zshrc"
    [ "$status" -eq 0 ]
}

@test ".zshrc template has conditional skip for syntax highlighting" {
    local zshrc="home/dot_zshrc.tmpl"

    # Check for SKIP_ZSH_SYNTAX_HIGHLIGHTING conditional
    run grep 'if \[\[ -z "\${SKIP_ZSH_SYNTAX_HIGHLIGHTING:-}" \]\]' "$zshrc"
    [ "$status" -eq 0 ]
}

@test "mise config includes envsense" {
    local mise_config="home/dot_config/mise/config.toml"

    # Test that envsense is in the config
    run grep '"cargo:envsense"' "$mise_config"
    [ "$status" -eq 0 ]

    # Check version is pinned
    run grep '"cargo:envsense" = ' "$mise_config"
    [ "$status" -eq 0 ]
}

@test "renovate.json5 includes cargo custom manager" {
    local renovate_config="renovate.json5"

    # Check for cargo custom manager
    run grep 'cargo:' "$renovate_config"
    [ "$status" -eq 0 ]

    # Check for crate datasource
    run grep '"datasourceTemplate": "crate"' "$renovate_config"
    [ "$status" -eq 0 ]
}

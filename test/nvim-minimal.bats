#!/usr/bin/env bats

@test "Neovim plugin sources compile without loading installed plugins" {
    command -v nvim >/dev/null 2>&1 || skip "Neovim not installed"
    run nvim --headless -u NONE -i NONE '+lua for _, p in ipairs(vim.fn.glob("home/dot_config/nvim/**/*.lua", false, true)) do assert(loadfile(p), p) end' +qa
    [ "$status" -eq 0 ]
}

@test "Neovim restore template references existing plugin sources" {
    command -v chezmoi >/dev/null 2>&1 || skip "chezmoi not installed"
    run chezmoi --config /dev/null --config-format toml --source "$BATS_TEST_DIRNAME/../home" execute-template --file home/.chezmoiscripts/run_onchange_after_install-nvim-plugins.sh.tmpl
    [ "$status" -eq 0 ]
}

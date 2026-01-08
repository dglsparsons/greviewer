-- Neovim plugin luacheck config
std = "lua51"

globals = {
    "vim",
}

-- Plenary test globals
files["tests/**/*_spec.lua"] = {
    globals = {
        "describe",
        "it",
        "before_each",
        "after_each",
        "assert",
    },
}

-- Ignore line length (stylua handles formatting)
max_line_length = false

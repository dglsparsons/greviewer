local state = require("greviewer.state")
local signs = require("greviewer.ui.signs")
local virtual = require("greviewer.ui.virtual")
local comments_ui = require("greviewer.ui.comments")

local M = {}

function M.open_file(file)
    local review = state.get_review()
    if not review then
        return
    end

    local existing_buf = state.get_file_buffer(file.path)
    if existing_buf and vim.api.nvim_buf_is_valid(existing_buf) then
        vim.api.nvim_set_current_buf(existing_buf)
        return
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    state.set_file_buffer(file.path, bufnr)

    vim.api.nvim_buf_set_name(bufnr, "greviewer://" .. review.pr.number .. "/" .. file.path)

    local lines = {}
    if file.content then
        for line in file.content:gmatch("[^\n]*") do
            table.insert(lines, line)
        end
    elseif file.status == "deleted" then
        lines = { "-- File deleted --" }
    else
        lines = { "-- Unable to load file content --" }
    end

    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].bufhidden = "hide"
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].modifiable = false

    local ext = file.path:match("%.([^%.]+)$")
    if ext then
        local ft_map = {
            rs = "rust",
            lua = "lua",
            py = "python",
            js = "javascript",
            ts = "typescript",
            tsx = "typescriptreact",
            jsx = "javascriptreact",
            go = "go",
            rb = "ruby",
            md = "markdown",
            json = "json",
            yaml = "yaml",
            yml = "yaml",
            toml = "toml",
            sh = "sh",
            bash = "bash",
            zsh = "zsh",
            vim = "vim",
            c = "c",
            cpp = "cpp",
            h = "c",
            hpp = "cpp",
        }
        local ft = ft_map[ext]
        if ft then
            vim.bo[bufnr].filetype = ft
        end
    end

    vim.api.nvim_set_current_buf(bufnr)

    signs.place(bufnr, file.hunks)
    comments_ui.show_existing(bufnr, file.path)

    M.setup_keymaps(bufnr, file)
end

function M.setup_keymaps(bufnr, file)
    local review = state.get_review()

    vim.api.nvim_buf_set_var(bufnr, "greviewer_file", file)
    vim.api.nvim_buf_set_var(bufnr, "greviewer_pr_url", review.url)
end

function M.get_current_file_from_buffer()
    local ok, file = pcall(vim.api.nvim_buf_get_var, 0, "greviewer_file")
    if ok then
        return file
    end
    return nil
end

function M.get_pr_url_from_buffer()
    local ok, url = pcall(vim.api.nvim_buf_get_var, 0, "greviewer_pr_url")
    if ok then
        return url
    end
    return nil
end

return M

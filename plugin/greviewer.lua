if vim.g.loaded_greviewer then
    return
end
vim.g.loaded_greviewer = 1

vim.api.nvim_create_autocmd("VimEnter", {
    foo
        if vim.fn.argc() > 0 then
            bar
            if type(arg) == "string" and arg:match("github%.com/.+/pull/%d+") then
                baz
                    require("greviewer").open(arg)
                    qux
            end
            quux
    end,
})

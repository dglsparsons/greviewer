local config = require("greviewer.config")

local M = {}

local ns = vim.api.nvim_create_namespace("greviewer_signs")

local hl_groups_defined = false

local function define_highlights()
    if hl_groups_defined then
        return
    end
    hl_groups_defined = true

    vim.api.nvim_set_hl(0, "GReviewerAdd", { fg = "#98c379", bold = true, default = true })
    vim.api.nvim_set_hl(0, "GReviewerDelete", { fg = "#e06c75", bold = true, default = true })
    vim.api.nvim_set_hl(0, "GReviewerChange", { fg = "#e5c07b", bold = true, default = true })
    vim.api.nvim_set_hl(0, "GReviewerAddLine", { bg = "#2d3b2d", default = true })
    vim.api.nvim_set_hl(0, "GReviewerDeleteLine", { bg = "#3b2d2d", default = true })
    vim.api.nvim_set_hl(0, "GReviewerChangeLine", { bg = "#3b3b2d", default = true })
end

function M.place(bufnr, hunks)
    define_highlights()

    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

    if not hunks then
        return
    end

    for _, hunk in ipairs(hunks) do
        local sign_text, sign_hl, line_hl

        if hunk.hunk_type == "add" then
            sign_text = config.values.signs.add
            sign_hl = "GReviewerAdd"
            line_hl = "GReviewerAddLine"
        elseif hunk.hunk_type == "delete" then
            sign_text = config.values.signs.delete
            sign_hl = "GReviewerDelete"
            line_hl = "GReviewerDeleteLine"
        else
            sign_text = config.values.signs.change
            sign_hl = "GReviewerChange"
            line_hl = "GReviewerChangeLine"
        end

        if hunk.hunk_type == "delete" then
            local row = math.max(hunk.start - 1, 0)
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            if row < line_count then
                vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
                    sign_text = sign_text,
                    sign_hl_group = sign_hl,
                    priority = 10,
                })
            end
        else
            for i = 0, math.max(hunk.count - 1, 0) do
                local row = hunk.start - 1 + i
                local line_count = vim.api.nvim_buf_line_count(bufnr)
                if row >= 0 and row < line_count then
                    vim.api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
                        sign_text = sign_text,
                        sign_hl_group = sign_hl,
                        line_hl_group = line_hl,
                        priority = 10,
                    })
                end
            end
        end
    end
end

function M.clear(bufnr)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

return M

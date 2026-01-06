local M = {}

function M.setup(opts)
    local config = require("greviewer.config")
    config.setup(opts)

    if vim.fn.executable(config.values.cli_path) == 0 then
        vim.notify(
            "greviewer-cli not found. Please install it with: cargo install --path cli",
            vim.log.levels.WARN
        )
    end

    vim.api.nvim_create_user_command("GReview", function(ctx)
        M.open(ctx.args)
    end, { nargs = 1, desc = "Open PR review" })

    vim.api.nvim_create_user_command("GReviewClose", function()
        M.close()
    end, { desc = "Close PR review" })

    vim.api.nvim_create_user_command("GReviewFiles", function()
        M.show_file_picker()
    end, { desc = "Show changed files picker" })

    vim.api.nvim_create_user_command("GReviewAuth", function()
        M.check_auth()
    end, { desc = "Check GitHub authentication" })
end

function M.open(url)
    local cli = require("greviewer.cli")
    local state = require("greviewer.state")
    local buffer = require("greviewer.ui.buffer")

    vim.notify("Fetching PR data...", vim.log.levels.INFO)

    cli.fetch_pr(url, function(data, err)
        if err then
            vim.notify("Failed to fetch PR: " .. err, vim.log.levels.ERROR)
            return
        end

        state.clear_review()
        local review = state.set_review(data)
        review.url = url

        vim.notify(
            string.format("Loaded PR #%d: %s (%d files)", data.pr.number, data.pr.title, #data.files),
            vim.log.levels.INFO
        )

        if #data.files > 0 then
            buffer.open_file(data.files[1])
        else
            vim.notify("No files changed in this PR", vim.log.levels.WARN)
        end
    end)
end

function M.close()
    local state = require("greviewer.state")
    state.clear_review()
    vim.notify("Review closed", vim.log.levels.INFO)
end

function M.show_file_picker()
    local state = require("greviewer.state")
    local review = state.get_review()

    if not review then
        vim.notify("No active review", vim.log.levels.WARN)
        return
    end

    local telescope_ok, telescope = pcall(require, "telescope.pickers")
    if not telescope_ok then
        M.show_file_picker_fallback()
        return
    end

    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    local entries = {}
    for i, file in ipairs(review.files) do
        local icon = ({ add = "+", delete = "-", modified = "~", renamed = "R" })[file.status] or "?"
        table.insert(entries, {
            display = string.format("[%s] %s (+%d/-%d)", icon, file.path, file.additions or 0, file.deletions or 0),
            path = file.path,
            idx = i,
        })
    end

    telescope.new({}, {
        prompt_title = string.format("PR #%d Files", review.pr.number),
        finder = finders.new_table({
            results = entries,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry.display,
                    ordinal = entry.path,
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection then
                    state.set_current_file_idx(selection.value.idx)
                    local buffer = require("greviewer.ui.buffer")
                    buffer.open_file(review.files[selection.value.idx])
                end
            end)
            return true
        end,
    }):find()
end

function M.show_file_picker_fallback()
    local state = require("greviewer.state")
    local review = state.get_review()

    local items = {}
    for i, file in ipairs(review.files) do
        table.insert(items, string.format("%d. [%s] %s", i, file.status, file.path))
    end

    vim.ui.select(items, { prompt = "Select file:" }, function(_, idx)
        if idx then
            state.set_current_file_idx(idx)
            local buffer = require("greviewer.ui.buffer")
            buffer.open_file(review.files[idx])
        end
    end)
end

function M.next_hunk()
    local nav = require("greviewer.ui.nav")
    local config = require("greviewer.config")
    nav.next_hunk(config.values.wrap_navigation)
end

function M.prev_hunk()
    local nav = require("greviewer.ui.nav")
    local config = require("greviewer.config")
    nav.prev_hunk(config.values.wrap_navigation)
end

function M.toggle_inline()
    local virtual = require("greviewer.ui.virtual")
    virtual.toggle_at_cursor()
end

function M.add_comment()
    local comments = require("greviewer.ui.comments")
    comments.add_at_cursor()
end

function M.check_auth()
    local cli = require("greviewer.cli")
    cli.check_auth(function(ok, output)
        if ok then
            vim.notify(output, vim.log.levels.INFO)
        else
            vim.notify(output, vim.log.levels.ERROR)
        end
    end)
end

return M

local Job = require("plenary.job")
local config = require("greviewer.config")

local M = {}

function M.fetch_pr(url, callback)
    Job:new({
        command = config.values.cli_path,
        args = { "fetch", "--url", url },
        on_exit = vim.schedule_wrap(function(j, code)
            if code == 0 then
                local output = table.concat(j:result(), "\n")
                local ok, data = pcall(vim.json.decode, output)
                if ok then
                    callback(data, nil)
                else
                    callback(nil, "Failed to parse JSON: " .. output)
                end
            else
                local stderr = table.concat(j:stderr_result(), "\n")
                callback(nil, "CLI error: " .. stderr)
            end
        end),
    }):start()
end

function M.add_comment(url, comment, callback)
    Job:new({
        command = config.values.cli_path,
        args = {
            "comment",
            "--url",
            url,
            "--path",
            comment.path,
            "--line",
            tostring(comment.line),
            "--side",
            comment.side,
            "--body",
            comment.body,
        },
        on_exit = vim.schedule_wrap(function(j, code)
            if code == 0 then
                local output = table.concat(j:result(), "\n")
                local ok, data = pcall(vim.json.decode, output)
                if ok and data.success then
                    callback(data, nil)
                else
                    callback(nil, data and data.error or "Unknown error")
                end
            else
                local stderr = table.concat(j:stderr_result(), "\n")
                callback(nil, stderr)
            end
        end),
    }):start()
end

function M.fetch_comments(url, callback)
    Job:new({
        command = config.values.cli_path,
        args = { "comments", "--url", url },
        on_exit = vim.schedule_wrap(function(j, code)
            if code == 0 then
                local output = table.concat(j:result(), "\n")
                local ok, data = pcall(vim.json.decode, output)
                if ok then
                    callback(data.comments, nil)
                else
                    callback(nil, "Failed to parse JSON")
                end
            else
                local stderr = table.concat(j:stderr_result(), "\n")
                callback(nil, stderr)
            end
        end),
    }):start()
end

function M.check_auth(callback)
    Job:new({
        command = config.values.cli_path,
        args = { "auth" },
        on_exit = vim.schedule_wrap(function(j, code)
            local output = table.concat(j:result(), "\n")
            callback(code == 0, output)
        end),
    }):start()
end

return M

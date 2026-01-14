local Job = require("plenary.job")

---@class NRAIModule
local M = {}

local PROMPT_TEMPLATE = [[
You are an expert code reviewer helping a developer understand a pull request efficiently.

## Your Task

Analyze this PR and return a JSON response that:
1. Orders hunks in a logical sequence for review
2. Annotates each hunk with confidence and a summary

## Step 1: Understand the Goal

First, read the PR title and description to understand what this change is trying to accomplish.
Identify the core purpose: Is it a bug fix? New feature? Refactor? Performance improvement?

## Step 2: Order the Hunks

Arrange hunks so a reviewer can build understanding progressively:

1. **Foundation first**: Type definitions, interfaces, structs, constants
2. **Core logic**: The main implementation that achieves the PR's goal
3. **Integration**: Where the new code connects to existing code
4. **Supporting changes**: Error handling, edge cases, utilities
5. **Tests**: Unit tests, integration tests
6. **Peripheral**: Config, build files, documentation, formatting-only changes

Within each category, order by dependency (if A uses B, show B first).

## Step 3: Annotate Each Hunk

For each hunk provide:

**confidence (1-5):**
- 5: Trivial - imports, formatting, renames, obvious one-liners
- 4: Clear - standard patterns, well-understood changes, good error handling
- 3: Reasonable - logic changes that follow from the PR goal, may need verification
- 2: Careful - non-obvious logic, potential edge cases, implicit assumptions
- 1: Risky - complex changes, unclear purpose, touches sensitive areas (auth, payments, data migration)

**summary** (optional): One sentence explaining what this change achieves within the PR's goal.
- Skip for trivial changes where the code is self-explanatory (imports, renames, formatting)
- Focus on the PURPOSE within the PR, not a description of the code itself
- Bad: "Adds an if statement that checks if input is null"
- Bad: "Calls validate() before process()"
- Good: "Prevents the crash reported in issue #123 by validating before the parser runs"
- Good: "Enables the new Validator to intercept requests before they reach the handler"

**category**: One of: foundation, core, integration, support, test, peripheral

## Output Format

Return ONLY valid JSON (no markdown, no explanation):
{
  "goal": "Brief statement of what this PR accomplishes",
  "hunk_order": [
    {
      "file": "path/to/file.rs",
      "hunk_index": 0,
      "confidence": 4,
      "category": "core",
      "summary": "Implements the validation logic that prevents invalid states"
    },
    {
      "file": "path/to/file.rs",
      "hunk_index": 1,
      "confidence": 5,
      "category": "peripheral"
    }
  ]
}

Note: `summary` can be omitted for trivial/self-explanatory hunks.

---

PR Title: %s

PR Description:
%s

Files Changed:
%s

Diff:
%s
]]

---Build file list with status for the prompt
---@param files NRFile[]
---@return string
local function build_file_list(files)
    local lines = {}
    for _, file in ipairs(files) do
        local icon = ({ added = "+", deleted = "-", modified = "~", renamed = "R" })[file.status] or "?"
        table.insert(lines, string.format("[%s] %s (+%d/-%d)", icon, file.path, file.additions or 0, file.deletions or 0))
    end
    return table.concat(lines, "\n")
end

---Build unified diff from files for the prompt
---@param files NRFile[]
---@return string
local function build_diff(files)
    local parts = {}
    for _, file in ipairs(files) do
        if #file.hunks > 0 then
            table.insert(parts, string.format("--- a/%s\n+++ b/%s", file.path, file.path))
            for hunk_idx, hunk in ipairs(file.hunks) do
                local header = string.format("@@ hunk %d @@", hunk_idx - 1)
                table.insert(parts, header)

                local hunk_lines = {}
                local added_set = {}
                local deleted_set = {}

                for _, ln in ipairs(hunk.added_lines or {}) do
                    added_set[ln] = true
                end
                for i, pos in ipairs(hunk.deleted_at or {}) do
                    deleted_set[pos] = hunk.old_lines[i]
                end

                local start_line = hunk.start or 1
                local end_line = start_line + (hunk.count or 1) - 1

                for ln = start_line, end_line do
                    if deleted_set[ln] then
                        table.insert(hunk_lines, "-" .. deleted_set[ln])
                    end
                    if added_set[ln] then
                        table.insert(hunk_lines, "+<added line " .. ln .. ">")
                    elseif not deleted_set[ln] then
                        table.insert(hunk_lines, " <context line " .. ln .. ">")
                    end
                end

                table.insert(parts, table.concat(hunk_lines, "\n"))
            end
        end
    end
    return table.concat(parts, "\n\n")
end

---Build the prompt for AI analysis
---@param review NRReview
---@return string
function M.build_prompt(review)
    local title = review.pr and review.pr.title or "Unknown"
    local description = review.pr and review.pr.description or "(No description provided)"
    local file_list = build_file_list(review.files)
    local diff = build_diff(review.files)

    return string.format(PROMPT_TEMPLATE, title, description, file_list, diff)
end

---Parse JSON response from opencode
---@param output string
---@return NRAIAnalysis|nil, string|nil
local function parse_response(output)
    local json_start = output:find("{")
    local json_end = output:reverse():find("}")
    if not json_start or not json_end then
        return nil, "No JSON object found in response"
    end

    json_end = #output - json_end + 1
    local json_str = output:sub(json_start, json_end)

    local ok, data = pcall(vim.json.decode, json_str)
    if not ok then
        return nil, "Failed to parse JSON: " .. tostring(data)
    end

    if type(data.goal) ~= "string" then
        return nil, "Missing or invalid 'goal' field"
    end

    if type(data.hunk_order) ~= "table" then
        return nil, "Missing or invalid 'hunk_order' field"
    end

    ---@type NRAIHunk[]
    local hunk_order = {}
    for i, item in ipairs(data.hunk_order) do
        if type(item.file) ~= "string" then
            return nil, string.format("hunk_order[%d]: missing 'file'", i)
        end
        if type(item.hunk_index) ~= "number" then
            return nil, string.format("hunk_order[%d]: missing 'hunk_index'", i)
        end
        if type(item.confidence) ~= "number" or item.confidence < 1 or item.confidence > 5 then
            return nil, string.format("hunk_order[%d]: invalid 'confidence' (must be 1-5)", i)
        end
        if type(item.category) ~= "string" then
            return nil, string.format("hunk_order[%d]: missing 'category'", i)
        end

        table.insert(hunk_order, {
            file = item.file,
            hunk_index = item.hunk_index,
            confidence = item.confidence,
            category = item.category,
            summary = item.summary,
        })
    end

    ---@type NRAIAnalysis
    local analysis = {
        goal = data.goal,
        hunk_order = hunk_order,
    }

    return analysis, nil
end

---Run AI analysis on a PR review
---@param review NRReview
---@param callback fun(analysis: NRAIAnalysis|nil, err: string|nil)
function M.analyze_pr(review, callback)
    local config = require("neo_reviewer.config")
    local prompt = M.build_prompt(review)

    local cmd = config.values.ai.command
    local model = config.values.ai.model

    local stdout_lines = {}
    local stderr_lines = {}

    Job:new({
        command = cmd,
        args = { "run", "--model", model, prompt },
        on_stdout = function(_, line)
            table.insert(stdout_lines, line)
        end,
        on_stderr = function(_, line)
            table.insert(stderr_lines, line)
        end,
        on_exit = vim.schedule_wrap(function(_, code)
            if code ~= 0 then
                local stderr = table.concat(stderr_lines, "\n")
                callback(nil, "opencode failed: " .. stderr)
                return
            end

            local output = table.concat(stdout_lines, "\n")
            local analysis, err = parse_response(output)
            callback(analysis, err)
        end),
    }):start()
end

return M

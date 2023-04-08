local M = {}

local signs = require("coverage.signs")
local xmlreader = require("xmlreader")

--- Loads a coverage report.
-- This method should perform whatever steps are necessary to generate a coverage report.
-- The coverage report results should passed to the callback, which will be cached by the plugin.
-- @param callback called with results of the coverage report
M.load = function(callback)
    local reader = xmlreader.from_file("tests/jacoco.xml") -- TODO - put file path in options 

    if not reader then
        print("xml file was not loaded")
        vim.notify("could not load xml file")
        return
    end

    local package_name
    local sourcefile_name
    local data = {}
    local coveredlines = {}
    local uncoveredlines = {}

    while reader:read() do
        if reader:local_name() == "package" and reader:node_type() == "element" then
            package_name = reader:get_attribute("name")
        end

        if reader:local_name() == "sourcefile" and reader:node_type() == "element" then
            sourcefile_name = reader:get_attribute("name")
        end

        if reader:local_name() == "line" and reader:node_type() == "element" then
            local line_number = reader:get_attribute("nr")
            local covered = reader:get_attribute("cb") ~= "0" or reader:get_attribute("ci") ~= "0"

            if covered then
                table.insert(coveredlines, line_number)
            else
                table.insert(uncoveredlines, line_number)
            end
        end

        if reader:local_name() == "sourcefile" and reader:node_type() == "end element" then
            local source_data= {
                source_path = package_name .. "/" .. sourcefile_name,
                coveredlines = coveredlines,
                uncoveredlines = uncoveredlines
            }
            table.insert(data, source_data)
            coveredlines = {}
            uncoveredlines = {}
        end
    end

    callback(data)
end

--- Returns a list of signs that will be placed in buffers.
-- This method should use the coverage data (previously generated via the load method) to 
-- return a list of signs.
-- @return list of signs
M.sign_list = function(data)
    local sign_list = {}
    for _, source_data in pairs(data) do
        local buffer = vim.fn.bufnr( "src/main/java/" .. source_data.source_path, false)

        if buffer ~= -1 then
            for _, line in ipairs(source_data.coveredlines) do
                table.insert(sign_list, signs.new_covered(buffer, line))
            end

            for _, line in ipairs(source_data.uncoveredlines) do
                table.insert(sign_list, signs.new_uncovered(buffer, line))
            end
        end
    end
    return sign_list
end

--- Returns a summary report.
-- @return summary report
M.summary = function(data)
    print("java coverage summary was called")
    -- TODO: generate a summary report in the format
    return {
        files = {
            { -- all fields, except filename, are optional - the report will be blank if the field is nil
                -- filename = fname,            -- filename displayed in the report
                -- statements = statements,     -- number of total statements in the file
                -- missing = missing,           -- number of lines missing coverage (uncovered) in the file
                -- excluded = excluded,         -- number of lines excluded from coverage reporting in the file
                -- branches = branches,         -- number of total branches in the file
                -- partial = partial_branches,  -- number of branches that are partially covered in the file
                -- coverage = coverage,         -- coverage percentage (float) for this file
            }
        },
        totals = { -- optional
            -- statements = total_statements,     -- number of total statements in the report
            -- missing = total_missing,           -- number of lines missing coverage (uncovered) in the report
            -- excluded = total_excluded,         -- number of lines excluded from coverage reporting in the report
            -- branches = total_branches,         -- number of total branches in the report
            -- partial = total_partial_branches,  -- number of branches that are partially covered in the report
            -- coverage = total_coverage,         -- coverage percentage to display in the report
        }
    }
end

return M

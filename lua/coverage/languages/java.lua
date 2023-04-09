local M = {}

local signs = require("coverage.signs")
local xmlreader = require("xmlreader")

local opts = {
   coverage_file = "target/jacoco.xml"
}

local files_line_coverage = function(xmlfile)
    local reader = xmlreader.from_file(xmlfile)

    if not reader then
        print("error reading coverage file: " .. xmlfile)
        return
    end

    local files_line_coverage = {}

    local package_name
    local sourcefile_name
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
            table.insert(files_line_coverage, source_data)
            coveredlines = {}
            uncoveredlines = {}
        end
    end
    return files_line_coverage
end

local files_summary = function(xmlfile)
    local reader = xmlreader.from_file(xmlfile)

    if not reader then
        print("error reading coverage file: " .. xmlfile)
        return
    end

    local files_summary = {}
    local file_summary = {}
    local class_name
    local counters = {}

    while reader:read() do
        if reader:local_name() == "class" and reader:node_type() == "element" then
            class_name = reader:get_attribute("name")
            counters = {}
        end

        if reader:local_name() == "counter" and reader:node_type() == "element" then
            local counter_type = reader:get_attribute("type")
            local counter_missed = tonumber(reader:get_attribute("missed"))
            local counter_covered = tonumber(reader:get_attribute("covered"))

            counters[counter_type] = {
                missed = counter_missed,
                covered = counter_covered,
                total = counter_missed + counter_covered
            }
        end

        if reader:local_name() == "class" and reader:node_type() == "end element" then
            file_summary.filename = class_name
            file_summary.statements = counters['INSTRUCTION'].total
            file_summary.missing = counters['INSTRUCTION'].missed
            if counters['BRANCH'] then
                file_summary.branches = counters['BRANCH'].total
                file_summary.partial = counters['BRANCH'].missed
            else
                file_summary.branches = 0
                file_summary.partial = 0
            end

            file_summary.coverage =  math.floor(
                counters['INSTRUCTION'].covered / counters['INSTRUCTION'].total * 100)

            table.insert(files_summary, file_summary)

            file_summary = {}
            class_name = nil
            counters = {}
        end
    end

    return files_summary
end

local totals = function(xmlfile)
    local reader = xmlreader.from_file(xmlfile)

    if not reader then
        print("error reading coverage file: " .. xmlfile)
        return
    end

    local totals = {}
    local counters = {}

    while reader:read() do

        if reader:local_name() == "counter" and reader:node_type() == "element" then
            local counter_type = reader:get_attribute("type")
            local counter_missed = tonumber(reader:get_attribute("missed"))
            local counter_covered = tonumber(reader:get_attribute("covered"))

            counters[counter_type] = {
                missed = counter_missed,
                covered = counter_covered,
                total = counter_missed + counter_covered
            }
        end

        if reader:local_name() == "report" and reader:node_type() == "end element" then

            totals.statements = counters['INSTRUCTION'].total
            totals.missing = counters['INSTRUCTION'].missed
            if counters['BRANCH'] then
                totals.branches = counters['BRANCH'].total
                totals.partial = counters['BRANCH'].missed
            else
                totals.branches = 0
                totals.partial = 0
            end

            totals.coverage =  math.floor(
                counters['INSTRUCTION'].covered / counters['INSTRUCTION'].total * 100)

        end
    end

    return totals
end

M.setup = function(config)
    if config ~= nil then
        opts = vim.tbl_deep_extend("force", opts, config)
    end
end

--- Loads a coverage report.
-- This method should perform whatever steps are necessary to generate a coverage report.
-- The coverage report results should passed to the callback, which will be cached by the plugin.
-- @param callback called with results of the coverage report
M.load = function(callback)
    local data = {}
    data.line_coverage = files_line_coverage(opts.coverage_file)
    data.files_summary = files_summary(opts.coverage_file)
    data.totals = totals(opts.coverage_file)

    callback(data)
end


--- Returns a list of signs that will be placed in buffers.
-- This method should use the coverage data (previously generated via the load method) to 
-- return a list of signs.
-- @return list of signs
M.sign_list = function(data)
    local sign_list = {}
    for _, source_data in pairs(data.line_coverage) do
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
    return {
        files = data.files_summary,
        totals = {
            statements = data.totals.statements,     -- number of total statements in the report
            missing = data.totals.missing,           -- number of lines missing coverage (uncovered) in the report
            branches = data.totals.branches,         -- number of total branches in the report
            partial = data.totals.partial,           -- number of branches that are partially covered in the report
            coverage = data.totals.coverage,         -- coverage percentage to display in the report
        }
    }
end

return M

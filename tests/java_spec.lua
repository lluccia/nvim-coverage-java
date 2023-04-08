describe("coverage-java", function()

    it("can load module", function()
        require("coverage.languages.java")
    end)

    it("can get covered and uncovered lines", function()
        local coverage_java = require("coverage.languages.java")

        local actual_data
        coverage_java.load(function(data)
            actual_data = data
        end)

        assert.equal(6, #actual_data.line_coverage)
        local files = {}

        for _, file in pairs(actual_data.line_coverage) do
            table.insert(files, file.source_path)
        end
        assert.same({
             'dev/conca/mavenconversion/model/Artifact.java',
             'dev/conca/mavenconversion/JarFinder.java',
             'dev/conca/mavenconversion/SearchJars.java',
             'dev/conca/mavenconversion/Checksum.java',
             'dev/conca/mavenconversion/mavencentral/ArtifactSearchResult.java',
             'dev/conca/mavenconversion/mavencentral/MavenCentralSearch.java',
        }, files)

        local first_file = actual_data.line_coverage[1]

        assert.equal("dev/conca/mavenconversion/model/Artifact.java", first_file.source_path)

        assert.same({ "32", "36", "37", "40", "48", "56", "64", "68",
            "69", "72", "76", "77", "80", "84", "85", "88", "92", "93" }, first_file.uncoveredlines)

        assert.same({ "8", "44", "45", "52", "53", "60", "61", "96",
            "97", "98", "99", "100", "104" }, first_file.coveredlines)
    end)

    it("can get coverage data per file", function()
        local coverage_java = require("coverage.languages.java")

        local actual_data
        coverage_java.load(function(data)
            actual_data = data
        end)

        assert.equal(7, #actual_data.files_summary)

        local first_file = actual_data.files_summary[1]

        assert.equals("dev/conca/mavenconversion/model/Artifact", first_file.filename)
        assert.equals(107, first_file.statements)
        assert.equals(44, first_file.missing)
        assert.equals(0, first_file.branches)
        assert.equals(0, first_file.partial)
        assert.equals(58, first_file.coverage)

    end)

    it("can report summary data", function()
        local coverage_java = require("coverage.languages.java")

        local files_summary = {}
        local file_summary = {
            filename = 'dev/conca/mavenconversion/model/Artifact',
            statements = 107,
            missing = 44,
            branches = 0,
            partial = 0,
            coverage = 58,
        }

        table.insert(files_summary, file_summary)

        local data = {
            files_summary = files_summary,
            total_statements = 517,
            total_missing = 417,
            total_branches = 18,
            total_partial_branches = 14,
            total_coverage = 22,
        }

        local summary = coverage_java.summary(data)

        local first_file = summary.files[1]
        assert.same({
            filename = "dev/conca/mavenconversion/model/Artifact",
            statements = 107,
            missing = 44,
            branches = 0,
            partial = 0,
            coverage = 58,
        }, first_file)

        assert.same({
            statements = 517,
            missing = 417,
            branches = 18,
            partial = 14,
            coverage = 22,
        }, summary.totals)
    end)
end)

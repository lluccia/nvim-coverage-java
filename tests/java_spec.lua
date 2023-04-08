describe("coverage-java", function()

    it("can load module", function()
        require("coverage.languages.java")
    end)

    it("can get covered and uncovered lines", function()
        local coverage_java = require("coverage.languages.java")
        local actual_data
        local callback = function(data)
            actual_data = data
        end
        coverage_java.load(callback)

        assert.equal(6, #actual_data)
        local files = {}

        for _, file in pairs(actual_data) do
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

        local first_file = actual_data[1]

        assert.equal("dev/conca/mavenconversion/model/Artifact.java", first_file.source_path)

        assert.same({ "32", "36", "37", "40", "48", "56", "64", "68",
            "69", "72", "76", "77", "80", "84", "85", "88", "92", "93" }, first_file.uncoveredlines)

        assert.same({ "8", "44", "45", "52", "53", "60", "61", "96",
            "97", "98", "99", "100", "104" }, first_file.coveredlines)
    end)

end)

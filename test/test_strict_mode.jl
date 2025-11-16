# Copyright (c) 2025 TOON Format Organization
# SPDX-License-Identifier: MIT

using Test
using TOON

@testset "Strict Mode Error Handling" begin
    @testset "Array Count Mismatch Errors" begin
        # Inline array count mismatch
        @test_throws Exception TOON.decode("[5]: 1,2,3", options=TOON.DecodeOptions(strict=true))
        
        # List array count mismatch
        input = """
        [3]:
        - 1
        - 2
        """
        @test_throws Exception TOON.decode(input, options=TOON.DecodeOptions(strict=true))
        
        # Tabular array count mismatch
        input = """
        users[3]{name,age}:
          Alice,30
          Bob,25
        """
        @test_throws Exception TOON.decode(input, options=TOON.DecodeOptions(strict=true))
        
        # Non-strict mode allows mismatches
        result = TOON.decode("[5]: 1,2,3", options=TOON.DecodeOptions(strict=false))
        @test length(result) == 3
    end
    
    @testset "Row Width Mismatch Errors" begin
        # Too few values in row
        input = """
        users[2]{name,age,city}:
          Alice,30
          Bob,25,NYC
        """
        @test_throws Exception TOON.decode(input, options=TOON.DecodeOptions(strict=true))
        
        # Too many values in row
        input = """
        users[2]{name,age}:
          Alice,30,extra
          Bob,25
        """
        @test_throws Exception TOON.decode(input, options=TOON.DecodeOptions(strict=true))
        
        # Non-strict mode allows width mismatches
        input = """
        users[2]{name,age}:
          Alice,30,extra
          Bob
        """
        result = TOON.decode(input, options=TOON.DecodeOptions(strict=false))
        @test length(result["users"]) == 2
    end
    
    @testset "Missing Colon Errors" begin
        # Missing colon after key
        @test_throws Exception TOON.decode("name Alice", options=TOON.DecodeOptions(strict=true))
        
        # Missing colon after array header
        @test_throws Exception TOON.decode("[3] 1,2,3", options=TOON.DecodeOptions(strict=true))
        
        # Missing colon in nested object
        input = """
        user
          name: Alice
        """
        @test_throws Exception TOON.decode(input, options=TOON.DecodeOptions(strict=true))
    end
    
    @testset "Invalid Escape Sequence Errors" begin
        # Invalid escape sequences
        @test_throws ArgumentError TOON.decode("text: \"bad\\xescape\"")
        @test_throws ArgumentError TOON.decode("text: \"bad\\uescape\"")
        @test_throws ArgumentError TOON.decode("text: \"bad\\0escape\"")
        @test_throws ArgumentError TOON.decode("text: \"bad\\aescape\"")
        
        # Valid escape sequences should work
        result = TOON.decode("text: \"good\\nescape\"")
        @test result["text"] == "good\nescape"
        
        result = TOON.decode("text: \"good\\\\escape\"")
        @test result["text"] == "good\\escape"
        
        result = TOON.decode("text: \"good\\\"escape\"")
        @test result["text"] == "good\"escape"
        
        result = TOON.decode("text: \"good\\rescape\"")
        @test result["text"] == "good\rescape"
        
        result = TOON.decode("text: \"good\\tescape\"")
        @test result["text"] == "good\tescape"
    end
    
    @testset "Unterminated String Errors" begin
        # Unterminated quoted string
        @test_throws Exception TOON.decode("name: \"unterminated")
        
        # Unterminated quoted key
        @test_throws Exception TOON.decode("\"unterminated: value")
        
        # Unterminated escape at end
        @test_throws ArgumentError TOON.decode("text: \"ends with\\\"")
    end
    
    @testset "Indentation Errors" begin
        # Not a multiple of indentSize
        @test_throws Exception TOON.decode("   value: 1", options=TOON.DecodeOptions(indent=2, strict=true))
        
        # Tabs in indentation
        @test_throws Exception TOON.decode("\tvalue: 1", options=TOON.DecodeOptions(strict=true))
        @test_throws Exception TOON.decode("  \tvalue: 1", options=TOON.DecodeOptions(strict=true))
        
        # Non-strict mode allows invalid indentation
        result = TOON.decode("   value: 1", options=TOON.DecodeOptions(indent=2, strict=false))
        @test haskey(result, "value")
    end
    
    @testset "Blank Line Errors" begin
        # Blank line inside inline array (not applicable - inline is single line)
        
        # Blank line inside list array
        input = """
        [3]:
        - 1

        - 2
        - 3
        """
        @test_throws Exception TOON.decode(input, options=TOON.DecodeOptions(strict=true))
        
        # Blank line inside tabular array
        input = """
        users[3]{name,age}:
          Alice,30

          Bob,25
          Charlie,35
        """
        @test_throws Exception TOON.decode(input, options=TOON.DecodeOptions(strict=true))
        
        # Blank lines outside arrays are OK
        input = """
        name: Alice

        age: 30
        """
        result = TOON.decode(input, options=TOON.DecodeOptions(strict=true))
        @test result["name"] == "Alice"
        @test result["age"] == 30
    end
    
    @testset "Path Expansion Conflict Errors" begin
        # Conflict: segment already exists as non-object
        input = """
        a: 1
        a.b: 2
        """
        @test_throws Exception TOON.decode(input, options=TOON.DecodeOptions(expandPaths="safe", strict=true))
        
        # Non-strict mode uses last-write-wins
        result = TOON.decode(input, options=TOON.DecodeOptions(expandPaths="safe", strict=false))
        @test haskey(result, "a")
        
        # No conflict when both are objects
        input = """
        a.b: 1
        a.c: 2
        """
        result = TOON.decode(input, options=TOON.DecodeOptions(expandPaths="safe", strict=true))
        @test result["a"]["b"] == 1
        @test result["a"]["c"] == 2
        
        # Conflict with nested object
        input = """
        a.b.c: 1
        a.b: 2
        """
        @test_throws Exception TOON.decode(input, options=TOON.DecodeOptions(expandPaths="safe", strict=true))
    end
    
    @testset "Error Messages Include Line Numbers" begin
        # Missing colon error should include line number
        input = """
        name: Alice
        age 30
        city: NYC
        """
        try
            TOON.decode(input, options=TOON.DecodeOptions(strict=true))
            @test false  # Should have thrown
        catch e
            msg = string(e)
            @test occursin("line", lowercase(msg)) || occursin("2", msg)
        end
        
        # Indentation error should include line number
        input = """
        name: Alice
           age: 30
        """
        try
            TOON.decode(input, options=TOON.DecodeOptions(indent=2, strict=true))
            @test false  # Should have thrown
        catch e
            msg = string(e)
            @test occursin("line", lowercase(msg)) || occursin("2", msg)
        end
        
        # Tab error should include line number
        input = """
        name: Alice
        \tage: 30
        """
        try
            TOON.decode(input, options=TOON.DecodeOptions(strict=true))
            @test false  # Should have thrown
        catch e
            msg = string(e)
            @test occursin("line", lowercase(msg)) || occursin("2", msg)
        end
    end
    
    @testset "Multiple Primitives at Root" begin
        # Multiple primitives at root should error in strict mode
        input = """
        42
        hello
        """
        # This should be treated as an object with keys, not multiple primitives
        # Actually, this is invalid TOON - only one primitive allowed at root
        # The decoder will try to parse as object and fail on missing colons
        @test_throws Exception TOON.decode(input, options=TOON.DecodeOptions(strict=true))
    end
    
    @testset "Strict Mode Can Be Disabled" begin
        # All the above errors should be lenient when strict=false
        
        # Count mismatch
        result = TOON.decode("[5]: 1,2,3", options=TOON.DecodeOptions(strict=false))
        @test length(result) == 3
        
        # Invalid indentation
        result = TOON.decode("   value: 1", options=TOON.DecodeOptions(indent=2, strict=false))
        @test haskey(result, "value")
        
        # Path expansion conflict
        input = """
        a: 1
        a.b: 2
        """
        result = TOON.decode(input, options=TOON.DecodeOptions(expandPaths="safe", strict=false))
        @test haskey(result, "a")
    end
end

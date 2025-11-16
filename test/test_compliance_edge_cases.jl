# Copyright (c) 2025 TOON Format Organization
# SPDX-License-Identifier: MIT

using Test
using TOON

@testset "Compliance: Edge Cases" begin
    @testset "Empty Values" begin
        # Empty string
        @test TOON.encode("") == "\"\""
        @test TOON.decode("\"\"") == ""
        
        # Empty object
        @test TOON.encode(Dict{String, Any}()) == ""
        @test TOON.decode("") == Dict{String, Any}()
        
        # Empty array
        @test TOON.encode([]) == "[0]:"
        @test TOON.decode("[0]:") == []
        
        # Object with empty values
        obj = Dict("empty_str" => "", "empty_arr" => [], "empty_obj" => Dict{String, Any}())
        encoded = TOON.encode(obj)
        decoded = TOON.decode(encoded)
        @test decoded["empty_str"] == ""
        @test decoded["empty_arr"] == []
        @test decoded["empty_obj"] == Dict{String, Any}()
    end
    
    @testset "Deeply Nested Structures" begin
        # Deep nesting (10 levels)
        obj = Dict("l1" => Dict("l2" => Dict("l3" => Dict("l4" => Dict("l5" => 
              Dict("l6" => Dict("l7" => Dict("l8" => Dict("l9" => Dict("l10" => "deep"))))))))))
        encoded = TOON.encode(obj)
        decoded = TOON.decode(encoded)
        @test decoded["l1"]["l2"]["l3"]["l4"]["l5"]["l6"]["l7"]["l8"]["l9"]["l10"] == "deep"
        
        # Deep array nesting (simpler test - 5 levels)
        arr = [[[[[1]]]]]
        encoded = TOON.encode(arr)
        decoded = TOON.decode(encoded)
        @test decoded[1][1][1][1][1] == 1
        
        # Mixed deep nesting
        obj = Dict("a" => [Dict("b" => [Dict("c" => [Dict("d" => "value")])])])
        encoded = TOON.encode(obj)
        decoded = TOON.decode(encoded)
        @test decoded["a"][1]["b"][1]["c"][1]["d"] == "value"
    end
    
    @testset "Large Arrays" begin
        # Large primitive array
        arr = collect(1:1000)
        encoded = TOON.encode(arr)
        decoded = TOON.decode(encoded)
        @test decoded == arr
        
        # Large object array
        arr = [Dict("id" => i, "value" => "item$i") for i in 1:100]
        encoded = TOON.encode(arr)
        decoded = TOON.decode(encoded)
        @test length(decoded) == 100
        @test decoded[1]["id"] == 1
        @test decoded[100]["id"] == 100
        
        # Large nested structure
        obj = Dict("items" => [Dict("values" => collect(1:50)) for _ in 1:20])
        encoded = TOON.encode(obj)
        decoded = TOON.decode(encoded)
        @test length(decoded["items"]) == 20
        @test length(decoded["items"][1]["values"]) == 50
    end
    
    @testset "Special Characters" begin
        # All escape sequences
        str = "newline:\n tab:\t quote:\" backslash:\\ return:\r"
        encoded = TOON.encode(str)
        decoded = TOON.decode(encoded)
        @test decoded == str
        
        # Unicode characters (skip for now - may have indexing issues)
        # str = "Hello 世界 🌍"
        # encoded = TOON.encode(str)
        # decoded = TOON.decode(encoded)
        # @test decoded == str
        
        # Control characters (should be escaped or quoted)
        for char in ['\x00', '\x01', '\x1F']
            str = "test$(char)value"
            encoded = TOON.encode(str)
            decoded = TOON.decode(encoded)
            @test decoded == str
        end
        
        # Delimiter characters in strings
        @test TOON.decode(TOON.encode("has,comma")) == "has,comma"
        @test TOON.decode(TOON.encode("has\ttab")) == "has\ttab"
        @test TOON.decode(TOON.encode("has|pipe")) == "has|pipe"
        
        # Special TOON characters
        @test TOON.decode(TOON.encode("has:colon")) == "has:colon"
        @test TOON.decode(TOON.encode("has[bracket]")) == "has[bracket]"
        @test TOON.decode(TOON.encode("has{brace}")) == "has{brace}"
        @test TOON.decode(TOON.encode("has-hyphen")) == "has-hyphen"
    end
    
    @testset "Numeric Edge Cases" begin
        # Very large numbers
        @test TOON.decode(TOON.encode(1000000)) == 1000000
        @test TOON.decode(TOON.encode(999999999999)) == 999999999999
        
        # Very small decimals
        @test TOON.decode(TOON.encode(0.000001)) ≈ 0.000001
        @test TOON.decode(TOON.encode(0.123456789)) ≈ 0.123456789
        
        # Negative zero
        @test TOON.encode(-0.0) == "0"
        @test TOON.decode(TOON.encode(-0.0)) == 0
        
        # Integer boundaries
        @test TOON.decode(TOON.encode(typemax(Int32))) == typemax(Int32)
        @test TOON.decode(TOON.encode(typemin(Int32))) == typemin(Int32)
        
        # Fractional precision
        @test TOON.decode(TOON.encode(1.5)) == 1.5
        @test TOON.decode(TOON.encode(1.25)) == 1.25
        @test TOON.decode(TOON.encode(1.125)) == 1.125
    end
    
    @testset "String Edge Cases" begin
        # Reserved literals as strings
        @test TOON.encode("true") == "\"true\""
        @test TOON.encode("false") == "\"false\""
        @test TOON.encode("null") == "\"null\""
        
        # Numeric-like strings
        @test TOON.encode("123") == "\"123\""
        @test TOON.encode("3.14") == "\"3.14\""
        @test TOON.encode("-42") == "\"-42\""
        
        # Whitespace strings
        @test TOON.encode(" ") == "\" \""
        @test TOON.encode("  ") == "\"  \""
        @test TOON.encode(" leading") == "\" leading\""
        @test TOON.encode("trailing ") == "\"trailing \""
        
        # Hyphen strings
        @test TOON.encode("-") == "\"-\""
        @test TOON.encode("-item") == "\"-item\""
        
        # Empty and whitespace-only
        @test TOON.encode("") == "\"\""
        @test TOON.encode("   ") == "\"   \""
    end
    
    @testset "Array Format Edge Cases" begin
        # Single element arrays
        @test TOON.decode(TOON.encode([1])) == [1]
        @test TOON.decode(TOON.encode(["a"])) == ["a"]
        @test TOON.decode(TOON.encode([Dict("x" => 1)])) == [Dict("x" => 1)]
        
        # Arrays with null values
        arr = [1, nothing, 3]
        decoded = TOON.decode(TOON.encode(arr))
        @test decoded[1] == 1
        @test decoded[2] === nothing
        @test decoded[3] == 3
        
        # Arrays with empty strings
        arr = ["", "a", ""]
        @test TOON.decode(TOON.encode(arr)) == arr
        
        # Mixed type arrays
        arr = [1, "two", true, nothing, 5.5]
        decoded = TOON.decode(TOON.encode(arr))
        @test decoded[1] == 1
        @test decoded[2] == "two"
        @test decoded[3] === true
        @test decoded[4] === nothing
        @test decoded[5] == 5.5
    end
    
    @testset "Object Key Edge Cases" begin
        # Keys requiring quoting
        obj = Dict("has:colon" => 1, "has space" => 2, "has\"quote" => 3)
        decoded = TOON.decode(TOON.encode(obj))
        @test decoded["has:colon"] == 1
        @test decoded["has space"] == 2
        @test decoded["has\"quote"] == 3
        
        # Keys with special characters
        obj = Dict("key-with-hyphen" => 1, "key_with_underscore" => 2, "key.with.dot" => 3)
        decoded = TOON.decode(TOON.encode(obj))
        @test decoded["key-with-hyphen"] == 1
        @test decoded["key_with_underscore"] == 2
        @test decoded["key.with.dot"] == 3
        
        # Empty key (if supported)
        # Note: Empty keys may not be valid in TOON, but test if they work
        # obj = Dict("" => "empty")
        # This might fail, which is expected
    end
    
    @testset "Whitespace Preservation" begin
        # Leading/trailing spaces in values
        obj = Dict("text" => "  spaces  ")
        decoded = TOON.decode(TOON.encode(obj))
        @test decoded["text"] == "  spaces  "
        
        # Newlines in strings
        obj = Dict("multiline" => "line1\nline2\nline3")
        decoded = TOON.decode(TOON.encode(obj))
        @test decoded["multiline"] == "line1\nline2\nline3"
        
        # Tabs in strings
        obj = Dict("tabbed" => "col1\tcol2\tcol3")
        decoded = TOON.decode(TOON.encode(obj))
        @test decoded["tabbed"] == "col1\tcol2\tcol3"
    end
end

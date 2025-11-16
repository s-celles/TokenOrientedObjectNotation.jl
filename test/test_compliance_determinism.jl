# Copyright (c) 2025 TOON Format Organization
# SPDX-License-Identifier: MIT

using Test
using TOON

@testset "Compliance: Determinism Tests" begin
    @testset "Primitive Determinism" begin
        # Same input should always produce same output
        @test TOON.encode(42) == TOON.encode(42)
        @test TOON.encode("hello") == TOON.encode("hello")
        @test TOON.encode(true) == TOON.encode(true)
        @test TOON.encode(nothing) == TOON.encode(nothing)
        
        # Multiple encodings should be identical
        for _ in 1:10
            @test TOON.encode(3.14) == "3.14"
        end
    end
    
    @testset "Object Determinism" begin
        obj = Dict("name" => "Alice", "age" => 30)
        encoded1 = TOON.encode(obj)
        encoded2 = TOON.encode(obj)
        @test encoded1 == encoded2
        
        # Multiple encodings
        results = [TOON.encode(obj) for _ in 1:5]
        @test all(r == results[1] for r in results)
    end
    
    @testset "Array Determinism" begin
        arr = [1, 2, 3, 4, 5]
        encoded1 = TOON.encode(arr)
        encoded2 = TOON.encode(arr)
        @test encoded1 == encoded2
        
        # Multiple encodings
        results = [TOON.encode(arr) for _ in 1:5]
        @test all(r == results[1] for r in results)
    end
    
    @testset "Complex Structure Determinism" begin
        obj = Dict(
            "users" => [
                Dict("id" => 1, "name" => "Alice"),
                Dict("id" => 2, "name" => "Bob")
            ],
            "config" => Dict("timeout" => 30)
        )
        
        encoded1 = TOON.encode(obj)
        encoded2 = TOON.encode(obj)
        @test encoded1 == encoded2
        
        # Multiple encodings
        results = [TOON.encode(obj) for _ in 1:5]
        @test all(r == results[1] for r in results)
    end
    
    @testset "Idempotence" begin
        # encode(decode(encode(x))) == encode(x)
        obj = Dict("name" => "Alice", "values" => [1, 2, 3])
        encoded1 = TOON.encode(obj)
        decoded = TOON.decode(encoded1)
        encoded2 = TOON.encode(decoded)
        @test encoded1 == encoded2
        
        # Multiple round-trips
        current = obj
        for _ in 1:3
            encoded = TOON.encode(current)
            current = TOON.decode(encoded)
        end
        @test TOON.encode(current) == TOON.encode(obj)
    end
    
    @testset "Options Determinism" begin
        arr = [1, 2, 3]
        
        # Same options should produce same output
        opts = TOON.EncodeOptions(indent=4, delimiter=TOON.TAB)
        @test TOON.encode(arr, options=opts) == TOON.encode(arr, options=opts)
        
        # Different options should produce different output
        opts1 = TOON.EncodeOptions(delimiter=TOON.COMMA)
        opts2 = TOON.EncodeOptions(delimiter=TOON.TAB)
        @test TOON.encode(arr, options=opts1) != TOON.encode(arr, options=opts2)
    end
end

# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# E2E pipeline tests for MinixSDK.jl.
# Tests the full service generation pipeline: function → cross-compilation →
# C service boilerplate generation → output validation.

using Test

include(joinpath(@__DIR__, "..", "src", "MinixSDK.jl"))
using .MinixSDK

@testset "E2E Pipeline Tests" begin

    @testset "Full pipeline: function → cross_compile → generate service" begin
        # Step 1: cross-compile a Julia function to Minix.
        output_file = cross_compile_to_minix(identity)
        @test output_file == "minix_service.c"

        # Step 2: generate the C service boilerplate.
        c_source = generate_minix_service("my_driver", "return_value(42);")
        @test c_source isa String
        @test contains(c_source, "#include <minix/drivers.h>")
        @test contains(c_source, "Julia-generated logic")
    end

    @testset "Full pipeline: multiple services generated sequentially" begin
        services = [
            ("disk_driver",   "read_sector(buf, lba);"),
            ("net_driver",    "send_packet(data, len);"),
            ("audio_driver",  "play_sample(buf, rate);"),
            ("input_driver",  "poll_keyboard();"),
        ]
        for (name, body) in services
            code = generate_minix_service(name, body)
            @test code isa String
            @test contains(code, "#include <minix/drivers.h>")
            @test contains(code, "Julia-generated logic")
        end
    end

    @testset "Full pipeline: various Julia functions cross-compiled" begin
        fns = [sin, cos, tan, identity, sqrt, abs, sum, prod]
        for fn in fns
            result = cross_compile_to_minix(fn)
            @test result == "minix_service.c"
        end
    end

    @testset "Error handling: empty service name and body" begin
        code = generate_minix_service("", "")
        @test code isa String
        @test contains(code, "#include <minix/drivers.h>")
    end

    @testset "Error handling: service name with special characters" begin
        for name in ["service-v2", "service_2.0", "my service", "s!@#$%"]
            code = generate_minix_service(name, "do_work();")
            @test code isa String
            @test !isempty(code)
        end
    end

    @testset "Round-trip consistency: cross_compile always returns same filename" begin
        # All compilations produce the same output filename (stub behaviour).
        for fn in [identity, sin, () -> 42]
            @test cross_compile_to_minix(fn) == "minix_service.c"
        end
    end

    @testset "Round-trip consistency: generate_minix_service is deterministic" begin
        # Same inputs always produce the same output.
        name = "stable_driver"
        body = "process_irq();"
        code1 = generate_minix_service(name, body)
        code2 = generate_minix_service(name, body)
        @test code1 == code2
    end

end

# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# Property-based invariant tests for MinixSDK.jl.

using Test

include(joinpath(@__DIR__, "..", "src", "MinixSDK.jl"))
using .MinixSDK

@testset "Property-Based Tests" begin

    @testset "cross_compile_to_minix always returns 'minix_service.c'" begin
        fns = [identity, sin, cos, sqrt, abs, () -> 1, (x) -> x^2]
        for _ in 1:50
            fn = rand(fns)
            result = cross_compile_to_minix(fn)
            @test result == "minix_service.c"
            @test result isa String
        end
    end

    @testset "generate_minix_service always contains required headers" begin
        for _ in 1:50
            name = "service_$(rand(1:9999))"
            body = "op_$(rand(1:9999))();"
            code = generate_minix_service(name, body)
            @test code isa String
            @test contains(code, "#include <minix/drivers.h>")
            @test contains(code, "Julia-generated logic")
        end
    end

    @testset "generate_minix_service is non-empty for any inputs" begin
        for _ in 1:50
            name = rand(["", "a", "driver_$(rand(1:999))", "x_y_z"])
            body = rand(["", "return 0;", "process();", "init_$(rand(1:99))();"])
            code = generate_minix_service(name, body)
            @test !isempty(code)
        end
    end

    @testset "generate_minix_service output is always a valid String" begin
        for _ in 1:50
            code = generate_minix_service("svc_$(rand(1:99999))", "work();")
            @test code isa String
            @test ncodeunits(code) > 0
        end
    end

    @testset "generate_minix_service is deterministic (same in → same out)" begin
        for _ in 1:30
            name = "det_svc_$(rand(1:999))"
            body = "do_work_$(rand(1:999))();"
            code1 = generate_minix_service(name, body)
            code2 = generate_minix_service(name, body)
            @test code1 == code2
        end
    end

    @testset "exports are always defined" begin
        for _ in 1:20
            @test isdefined(MinixSDK, :cross_compile_to_minix)
            @test isdefined(MinixSDK, :generate_minix_service)
        end
    end

end

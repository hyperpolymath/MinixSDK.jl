# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# BenchmarkTools benchmarks for MinixSDK.jl.

using BenchmarkTools

include(joinpath(@__DIR__, "..", "src", "MinixSDK.jl"))
using .MinixSDK

println("=== MinixSDK.jl Benchmarks ===")

# --- cross_compile_to_minix ---

println("\n-- cross_compile_to_minix --")

# Small: identity function (no-op).
b_compile_identity = @benchmark cross_compile_to_minix(identity)
println("cross_compile_to_minix (identity): ", median(b_compile_identity))

# Medium: arithmetic function.
b_compile_sin = @benchmark cross_compile_to_minix(sin)
println("cross_compile_to_minix (sin):      ", median(b_compile_sin))

# Large: anonymous lambda.
b_compile_lambda = @benchmark cross_compile_to_minix(() -> sum(1:1000))
println("cross_compile_to_minix (lambda):   ", median(b_compile_lambda))

# --- generate_minix_service ---

println("\n-- generate_minix_service --")

# Small: minimal name and body.
b_gen_small = @benchmark generate_minix_service("drv", "")
println("generate_minix_service (empty body): ", median(b_gen_small))

# Medium: typical driver body.
b_gen_medium = @benchmark generate_minix_service(
    "disk_driver",
    "read_sector(buf, lba); write_sector(buf, lba); sync_cache();"
)
println("generate_minix_service (medium body): ", median(b_gen_medium))

# Large: long generated body string.
large_body = "op_$(i)(); " ^ 100
b_gen_large = @benchmark generate_minix_service("big_driver", $large_body)
println("generate_minix_service (large body):  ", median(b_gen_large))

const std = @import("std");
const solana = @import("solana-program-sdk");
const base58 = @import("base58");

pub fn build(b: *std.Build) !void {
    // Program build configuration
    const target = b.resolveTargetQuery(solana.sbf_target);
    const optimize = .ReleaseFast;
    const program = b.addSharedLibrary(.{
        .name = "token",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Adding required dependencies, link the program properly
    _ = solana.buildProgram(b, program, target, optimize);

    // Install the program artifact
    b.installArtifact(program);

    // Optional: generate a keypair for the program
    base58.generateProgramKeypair(b, program);

    // Run unit tests
    const test_step = b.step("test", "Run unit tests");
    const lib_unit_tests = b.addTest(.{
        .root_source_file = b.path("src/main_test.zig"),
    });

    const run_unit_tests = b.addRunArtifact(lib_unit_tests);
    test_step.dependOn(&run_unit_tests.step);
}

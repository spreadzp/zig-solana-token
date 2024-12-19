const std = @import("std");
const testing = std.testing;

test "initialize fund - positive test" {
    const MAX_NAME_LEN = 64;
    const TOKEN_CLASSES = 3;

    const FundAccount = struct {
        name: [MAX_NAME_LEN]u8,
        admin: [32]u8,
        total_supply: [TOKEN_CLASSES]u64,
    };

    var fund = FundAccount{
        .name = [_]u8{0} ** MAX_NAME_LEN,
        .admin = [_]u8{1} ** 32,
        .total_supply = [_]u64{0} ** TOKEN_CLASSES,
    };

    const name = "Test Fund";
    @memcpy(fund.name[0..name.len], name);
    try testing.expectEqualStrings(name, std.mem.sliceTo(&fund.name, 0));
    try testing.expectEqual(@as(u64, 0), fund.total_supply[0]);
}

test "token operations - positive test" {
    const TOKEN_CLASSES = 3;
    const UserAccount = struct {
        balances: [TOKEN_CLASSES]u64,
    };

    var sender = UserAccount{
        .balances = [_]u64{100} ** TOKEN_CLASSES,
    };
    var receiver = UserAccount{
        .balances = [_]u64{0} ** TOKEN_CLASSES,
    };

    // Test transfer
    const amount: u64 = 50;
    const class: u8 = 0;

    sender.balances[class] -= amount;
    receiver.balances[class] += amount;

    try testing.expectEqual(@as(u64, 50), sender.balances[class]);
    try testing.expectEqual(@as(u64, 50), receiver.balances[class]);
}

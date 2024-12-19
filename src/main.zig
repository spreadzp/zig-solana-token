const std = @import("std");
const sol = @import("solana-program-sdk");

const ix = @import("instruction.zig");
const state = @import("state.zig");
const ProgramError = @import("error.zig").ProgramError;

/// Maximum length for fund names
pub const MAX_NAME_LEN = 64;
/// Number of token classes (A=0, B=1, C=2)
pub const TOKEN_CLASSES = 3;

/// Fund account data structure
pub const FundAccount = struct {
    /// Fund name, padded with zeros if shorter than MAX_NAME_LEN
    name: [MAX_NAME_LEN]u8,
    /// Public key of the fund administrator
    admin: [32]u8,
    /// Total supply for each token class
    total_supply: [TOKEN_CLASSES]u64,
};

/// User account data structure
pub const UserAccount = struct {
    /// Token balances for each class
    balances: [TOKEN_CLASSES]u64,
};

/// Contract-specific error types
pub const ContractError = error{
    NameTooLong,
    InvalidTokenClass,
    TokenClassBRestricted,
    InsufficientFunds,
    InsufficientBalance,
};

/// Program entrypoint - handles incoming instruction data
export fn entrypoint(input: [*]u8) u64 {
    var context = sol.Context.load(input) catch return 1;
    processInstruction(context.program_id, context.accounts[0..context.num_accounts], context.data) catch |err| return @intFromError(err);
    return 0;
}

/// Processes incoming instructions by type
fn processInstruction(_: *sol.PublicKey, accounts: []sol.Account, data: []const u8) ProgramError!void {
    const instruction_type: *const ix.InstructionType = @ptrCast(data);
    switch (instruction_type.*) {
        ix.InstructionType.init => try handleInit(accounts[0], data[1..]),
        ix.InstructionType.increment => try handleIncrement(accounts[0]),
        ix.InstructionType.add => try handleAdd(accounts[0], data[1..]),
    }
}

/// Handles account initialization
/// Params:
///   - account: Account to initialize
///   - data: Initialization data containing account type
fn handleInit(account: sol.Account, data: []const u8) ProgramError!void {
    const init: *align(1) const ix.InitData = @ptrCast(data);
    const account_type: state.AccountType = @enumFromInt(account.data()[0]);

    if (account_type != state.AccountType.Uninitialized) {
        return ProgramError.AlreadyInUse;
    }
    if (init.account_type == state.AccountType.Uninitialized) {
        return ProgramError.InvalidAccountType;
    }
    if (account.data()[1..].len != init.account_type.sizeOfData()) {
        return ProgramError.IncorrectSize;
    }
    account.data()[0] = @intFromEnum(init.account_type);
}

/// Increments the amount in an account by 1
/// Params:
///   - account: Account to increment
fn handleIncrement(account: sol.Account) ProgramError!void {
    const account_type: state.AccountType = @enumFromInt(account.data()[0]);
    switch (account_type) {
        state.AccountType.Uninitialized => return ProgramError.Uninitialized,
        state.AccountType.SmallInt => {
            var accountData: *align(1) state.SmallIntData = @ptrCast(account.data()[1..]);
            accountData.amount += 1;
        },
        state.AccountType.BigInt => {
            var accountData: *align(1) state.BigIntData = @ptrCast(account.data()[1..]);
            accountData.amount += 1;
        },
    }
}

/// Adds a specified amount to an account
/// Params:
///   - account: Account to add to
///   - data: Data containing amount to add
fn handleAdd(account: sol.Account, data: []const u8) ProgramError!void {
    const add: *align(1) const ix.AddData = @ptrCast(data);
    const account_type: state.AccountType = @enumFromInt(account.data()[0]);
    switch (account_type) {
        state.AccountType.Uninitialized => return ProgramError.Uninitialized,
        state.AccountType.SmallInt => {
            var accountData: *align(1) state.SmallIntData = @ptrCast(account.data()[1..]);
            accountData.amount += add.amount;
        },
        state.AccountType.BigInt => {
            var accountData: *align(1) state.BigIntData = @ptrCast(account.data()[1..]);
            accountData.amount += add.amount;
        },
    }
}

/// Initializes a new fund with a name and admin
/// Params:
///   - fund: Fund account to initialize
///   - name: Name of the fund
///   - admin: Public key of the administrator
fn initialize_fund(fund: *FundAccount, name: []const u8, admin: [32]u8) !void {
    if (name.len > MAX_NAME_LEN) return ContractError.NameTooLong;

    @memcpy(fund.name[0..name.len], name);
    if (name.len < MAX_NAME_LEN) {
        @memset(fund.name[name.len..], 0);
    }

    fund.admin = admin;
    fund.total_supply = [_]u64{0} ** TOKEN_CLASSES;
}

/// Mints new tokens for a user
/// Params:
///   - fund: Fund account to mint from
///   - user: User account to mint to
///   - class: Token class to mint
///   - amount: Amount to mint
fn mint_tokens(fund: *FundAccount, user: *UserAccount, class: u8, amount: u64) !void {
    if (class >= TOKEN_CLASSES) return ContractError.InvalidTokenClass;
    if (class == 1) return ContractError.TokenClassBRestricted;

    fund.total_supply[class] += amount;
    user.balances[class] += amount;
}

/// Transfers tokens between users
/// Params:
///   - sender: Account sending tokens
///   - receiver: Account receiving tokens
///   - class: Token class to transfer
///   - amount: Amount to transfer
fn transfer(sender: *UserAccount, receiver: *UserAccount, class: u8, amount: u64) !void {
    if (class >= TOKEN_CLASSES) return ContractError.InvalidTokenClass;
    if (class == 1) return ContractError.TokenClassBRestricted;
    if (sender.balances[class] < amount) return ContractError.InsufficientBalance;

    sender.balances[class] -= amount;
    receiver.balances[class] += amount;
}

test "initialize fund - positive test" {
    var fund = FundAccount{
        .name = [_]u8{0} ** MAX_NAME_LEN,
        .admin = [_]u8{1} ** 32,
        .total_supply = [_]u64{0} ** TOKEN_CLASSES,
    };
    const name = "Test Fund";
    try initialize_fund(&fund, name, fund.admin);
    try std.testing.expectEqualStrings(name, std.mem.sliceTo(&fund.name, 0));
    try std.testing.expectEqual(@as(u64, 0), fund.total_supply[0]);
}

test "initialize fund - negative test (name too long)" {
    var fund = FundAccount{
        .name = [_]u8{0} ** MAX_NAME_LEN,
        .admin = [_]u8{1} ** 32,
        .total_supply = [_]u64{0} ** TOKEN_CLASSES,
    };
    const name = [_]u8{'A'} ** (MAX_NAME_LEN + 1);
    try std.testing.expectError(ContractError.NameTooLong, initialize_fund(&fund, &name, fund.admin));
}

test "mint tokens - positive test" {
    var fund = FundAccount{
        .name = [_]u8{0} ** MAX_NAME_LEN,
        .admin = [_]u8{1} ** 32,
        .total_supply = [_]u64{0} ** TOKEN_CLASSES,
    };
    var user = UserAccount{
        .balances = [_]u64{0} ** TOKEN_CLASSES,
    };
    try mint_tokens(&fund, &user, 0, 100);
    try std.testing.expectEqual(@as(u64, 100), fund.total_supply[0]);
    try std.testing.expectEqual(@as(u64, 100), user.balances[0]);
}

test "mint tokens - negative test (invalid class)" {
    var fund = FundAccount{
        .name = [_]u8{0} ** MAX_NAME_LEN,
        .admin = [_]u8{1} ** 32,
        .total_supply = [_]u64{0} ** TOKEN_CLASSES,
    };
    var user = UserAccount{
        .balances = [_]u64{0} ** TOKEN_CLASSES,
    };
    try std.testing.expectError(ContractError.InvalidTokenClass, mint_tokens(&fund, &user, TOKEN_CLASSES, 100));
}

test "mint tokens - negative test (class B restricted)" {
    var fund = FundAccount{
        .name = [_]u8{0} ** MAX_NAME_LEN,
        .admin = [_]u8{1} ** 32,
        .total_supply = [_]u64{0} ** TOKEN_CLASSES,
    };
    var user = UserAccount{
        .balances = [_]u64{0} ** TOKEN_CLASSES,
    };
    try std.testing.expectError(ContractError.TokenClassBRestricted, mint_tokens(&fund, &user, 1, 100));
}

test "transfer tokens - positive test" {
    var sender = UserAccount{
        .balances = [_]u64{100} ** TOKEN_CLASSES,
    };
    var receiver = UserAccount{
        .balances = [_]u64{0} ** TOKEN_CLASSES,
    };
    try transfer(&sender, &receiver, 0, 50);
    try std.testing.expectEqual(@as(u64, 50), sender.balances[0]);
    try std.testing.expectEqual(@as(u64, 50), receiver.balances[0]);
}

test "transfer tokens - negative test (insufficient balance)" {
    var sender = UserAccount{
        .balances = [_]u64{50} ** TOKEN_CLASSES,
    };
    var receiver = UserAccount{
        .balances = [_]u64{0} ** TOKEN_CLASSES,
    };
    try std.testing.expectError(ContractError.InsufficientBalance, transfer(&sender, &receiver, 0, 100));
}

test "transfer tokens - negative test (class B restricted)" {
    var sender = UserAccount{
        .balances = [_]u64{100} ** TOKEN_CLASSES,
    };
    var receiver = UserAccount{
        .balances = [_]u64{0} ** TOKEN_CLASSES,
    };
    try std.testing.expectError(ContractError.TokenClassBRestricted, transfer(&sender, &receiver, 1, 50));
}

test {
    std.testing.refAllDecls(@This());
}

# solana-token-zig

A simple token program implementation for Solana using Zig programming language. This program demonstrates basic token functionality including initialization, minting, and transfers.

## Features

- Multiple token classes (A, B, C)
- Fund account management
- Token minting and transfers
- Restricted operations for Class B tokens

## Getting Started

### Prerequisites

1. Install [Solana CLI tools](https://docs.solana.com/cli/install-solana-cli-tools)
2. Set up Solana environment:
   ```bash
   export SOLANA_HOME=~/.local/share/solana
   ```

### Compiler Setup

You'll need a Zig compiler built with Solana's LLVM fork. You can either:

- Build it following the instructions at [solana-zig-bootstrap](https://github.com/joncinque/solana-zig-bootstrap)
- Download from the [GitHub releases page](https://github.com/joncinque/solana-zig-bootstrap/releases)
- Use the provided helper script:
  ```bash
  ./install-solana-zig.sh
  ```

### Dependencies

This project uses the Zig package manager and requires [solana-program-sdk-zig](https://github.com/joncinque/solana-program-sdk-zig).

Install dependencies:
```bash
zig fetch --save https://github.com/joncinque/base58-zig/archive/refs/tags/v0.13.3.tar.gz
zig fetch --save https://github.com/joncinque/solana-sdk-zig/archive/refs/tags/v0.13.1.tar.gz
```

## Development

### Building the Program

Build the token program:
```bash
./solana-zig/zig build
```

### Running Tests

Execute the test suite:
```bash
./solana-zig/zig build test --summary all
```

### Deployment

1. Start a local test validator:
   ```bash
   solana-test-validator
   ```

2. Deploy the program:
   ```bash
   solana program deploy zig-out/lib/token.so
   ```

## Program Structure

- `src/main.zig`: Main program logic and instruction handling
- `src/state.zig`: Account state definitions
- `src/instruction.zig`: Instruction data structures
- `src/error.zig`: Error type definitions

## Testing

### Unit Tests

The program includes comprehensive unit tests covering:
- Fund initialization
- Token minting
- Token transfers
- Error handling

### Integration Tests

For integration testing with the Solana runtime:

1. Navigate to the test directory:
   ```bash
   cd program-test/
   ```

2. Run the test script:
   ```bash
   ./test.sh
   ```

Note: Integration tests require both Rust compiler and solana-zig compiler.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

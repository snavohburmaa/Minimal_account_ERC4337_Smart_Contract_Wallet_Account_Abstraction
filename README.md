# ACC Abstraction - Minimal Account Abstraction Implementation

A minimal, production-ready implementation of ERC-4337 Account Abstraction on Ethereum. This project provides a simplified smart contract wallet that supports gasless transactions, signature verification, and programmable transaction execution through the EntryPoint contract.

## Overview

Account Abstraction (ERC-4337) allows Ethereum accounts to be smart contracts instead of externally owned accounts (EOAs), enabling:

- **Smart Contract Wallets**: Use smart contracts as accounts with custom logic
- **Gasless Transactions**: Support for paymasters to sponsor transaction fees
- **Signature Flexibility**: Custom signature schemes beyond ECDSA
- **Transaction Batching**: Execute multiple operations in a single transaction
- **Social Recovery**: Implement custom recovery mechanisms

This project implements a minimal but complete account abstraction contract that serves as a foundation for building more advanced smart contract wallets.

## Features

- ✅ ERC-4337 compliant account contract
- ✅ EIP-191 signature verification (ECDSA)
- ✅ EntryPoint integration for user operations
- ✅ Owner-based access control with Ownable
- ✅ Executable function for arbitrary contract calls
- ✅ Prefunding support for gas management
- ✅ Comprehensive test suite
- ✅ Deployment scripts with network configuration
- ✅ User operation generation and signing utilities

## Tech Stack

- **Solidity**: ^0.8.20
- **Foundry**: Development, testing, and deployment framework
- **Account Abstraction**: [account-abstraction](https://github.com/eth-infinitism/account-abstraction) library
- **OpenZeppelin Contracts**: Security-audited contract library

## Installation

### Prerequisites

- [Foundry](https://book.getfoundry.com/getting-started/installation) (latest version)
- Git

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd ACC-abstraction
```

2. Install dependencies:
```bash
forge install
```

3. Build the project:
```bash
forge build
```

## Project Structure

```
ACC-abstraction/
├── src/
│   └── ethereum/
│       └── MinimalAcc.sol          # Main account abstraction contract
├── test/
│   └── ethereum/
│       └── MinimalAccountTest.t.sol # Test suite
├── script/
│   ├── DeployMinimal.s.sol         # Deployment script
│   ├── HelperConfig.s.sol          # Network configuration
│   └── SendPackedUserOp.s.sol      # User operation utilities
├── lib/                             # Dependencies
│   ├── account-abstraction/        # ERC-4337 implementation
│   ├── openzeppelin-contracts/     # OpenZeppelin library
│   └── forge-std/                  # Foundry standard library
└── foundry.toml                     # Foundry configuration
```

## Usage

### Deploying the Contract

1. Set up your environment variables:
```bash
export PRIVATE_KEY=your_private_key
export RPC_URL=your_rpc_url
```

2. Deploy to a network:
```bash
forge script script/DeployMinimal.s.sol:DeployMinimal --rpc-url $RPC_URL --broadcast --verify
```

### Creating and Signing User Operations

The `SendPackedUserOp` contract provides utilities for generating and signing user operations:

```solidity
// Generate a signed user operation
PackedUserOperation memory userOp = sendPackedUserOp.generateSignedUserOperation(
    callData,      // Encoded function call
    config         // Network configuration
);
```

### Executing Transactions

The `MinimalAccount` contract allows execution of arbitrary calls:

- **Owner or EntryPoint**: Can execute any function call
- **Others**: Restricted by `requireFromEntryPointOrOwner` modifier

```solidity
// Execute a function call
minimalAccount.excute(
    destination,   // Target contract address
    value,         // ETH value to send
    functionData   // Encoded function call
);
```

## Testing

Run the test suite:

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run specific test
forge test --match-test testOwnerCanExcuteCommands
```

### Test Coverage

The test suite includes:

- ✅ Owner can execute commands
- ✅ Non-owner cannot execute commands
- ✅ Signature recovery and validation
- ✅ User operation signing and verification

## Key Concepts

### Account Abstraction (ERC-4337)

Account Abstraction allows smart contracts to act as accounts, enabling:

1. **User Operations**: Special transaction-like objects that are validated and executed through the EntryPoint
2. **EntryPoint**: Singleton contract that validates and executes user operations
3. **Bundlers**: Off-chain actors that bundle and submit user operations to the blockchain
4. **Paymasters**: Contracts that can sponsor transaction fees for users

### MinimalAccount Architecture

```
User Operation
    ↓
EntryPoint (validateUserOp)
    ↓
MinimalAccount.validateUserOp()
    ├── _validateSignature()  # Verify EIP-191 signature
    └── _payPrefund()         # Handle gas prefunding
    ↓
MinimalAccount.excute()
    └── External call execution
```

### Signature Verification

The contract uses EIP-191 (Ethereum Signed Message) format:

1. User operation hash is generated by EntryPoint
2. Hash is converted to Ethereum signed message format
3. ECDSA signature is recovered and verified against owner

## Network Configuration

The `HelperConfig` contract supports multiple networks:

- **Local/Anvil**: Chain ID 31337 (for testing)
- **Ethereum Sepolia**: Chain ID 11155111
- **zkSync Sepolia**: Chain ID 300 (placeholder)

Add your network configuration in `script/HelperConfig.s.sol`:

```solidity
function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
    return NetworkConfig({
        entryPoint: 0x...,
        account: 0x...
    });
}
```

## Security Considerations

- ⚠️ **Owner Management**: The contract uses OpenZeppelin's `Ownable` for access control
- ⚠️ **Signature Validation**: Currently supports single owner ECDSA signatures
- ⚠️ **Nonce Management**: Nonce validation is not implemented in this minimal version
- ⚠️ **Gas Limits**: Be careful with gas limits to prevent DoS attacks

**Note**: This is a minimal implementation for educational purposes. For production use, consider:

- Implementing proper nonce validation
- Adding social recovery mechanisms
- Supporting multiple owners/signers
- Implementing rate limiting
- Adding comprehensive audit trails

## Development

### Adding Features

1. Extend `MinimalAccount` contract with new functionality
2. Add corresponding tests in `MinimalAccountTest.t.sol`
3. Update deployment scripts if needed

### Code Style

- Follow Solidity style guide
- Use NatSpec comments for public functions
- Maintain consistent naming conventions
- Add error messages for custom errors

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details


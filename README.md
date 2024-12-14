# Hemswap Cross-Chain Bridge

## Overview
A secure, efficient cross-chain token bridge built on Across Protocol's infrastructure, enabling seamless asset transfers across multiple blockchain networks.

## Key Features
- 🌉 Multi-Chain Token Transfers
- 🔒 Advanced Security Mechanisms
- 📊 Comprehensive Transfer Tracking
- 💸 Dynamic Fee Calculation

## Architecture Components
### Core Infrastructure
- **Across Protocol Integration**
  - Leverages Across Protocol's V3 Core Router
  - Seamless cross-chain transfer execution
  - Automatic liquidity management

### Transfer Mechanism
- Unique transfer ID generation
- Detailed transfer metadata tracking
- Cross-chain transfer execution with status tracking

## Transfer Tracking
Transfer statuses:
- `INITIATED`: Transfer started
- `COMPLETED`: Transfer successful
- `FAILED`: Transfer unsuccessful

### Key Methods
- `getUserTransfers()`: Retrieve user's recent transfers
- `getTransferDetails()`: Get specific transfer details
- `getTotalTransfers()`: Get total number of bridge transfers

## Security Features
- SafeERC20 token handling
- ReentrancyGuard protection
- Ownership-based access control
- Comprehensive input validation

## Fee Management
- Dynamic fee calculation via Across Protocol Core Router
- Estimated fee calculation through `getEstimatedBridgeFee()`

## Deployment Requirements
- Solidity 0.8.19
- OpenZeppelin Contracts
- Across Protocol Interfaces

### Required Environment Variables
- `PRIVATE_KEY`: Deployment wallet private key
- `ACROSS_CORE_ROUTER`: Across Protocol Core Router address
- `ACROSS_SPOKE_POOL`: Spoke Pool contract address

## Deployment
```bash
npx hardhat deploy --network [target_network]
```

## Testing
```bash
npx hardhat test
```

## Supported Networks
- Ethereum Mainnet
- Arbitrum
- Optimism

## Disclaimer
Experimental implementation. Use at your own risk.

## License
MIT License

## Author
[Mujeeb Sulayman](https://x.com/thehemjay)

# Hemswap Cross-Chain Bridge

## Overview
A secure, efficient cross-chain token bridge built on Across Protocol's infrastructure, enabling seamless asset transfers across multiple blockchain networks.

## Key Features
- 🌉 Multi-Chain Support
- 💧 Liquidity Provider Management
- 🔒 Advanced Security Mechanisms
- 💸 Flexible Bridge Fee Configuration
- 🔄 Comprehensive Transfer Tracking

## Architecture Components
### Core Infrastructure
- **V3 Core Router**: Cross-chain transfer routing
- **Spoke Pools**: Network-specific liquidity pools
- **Hub Pool**: Central liquidity management

### Liquidity Management
- Dynamic liquidity provider tracking
- Configurable liquidity addition/withdrawal
- Total liquidity monitoring

### Transfer Mechanism
- Unique transfer ID generation
- Detailed transfer metadata tracking
- Bridge fee calculation
- Cross-chain transfer execution

## Security Considerations
- ReentrancyGuard protection
- Ownership-based access control
- Maximum bridge fee limit
- Comprehensive input validation

## Configuration
### Constructor Parameters
- `_coreRouterAddress`: Across Protocol Core Router address
- `_spokePoolAddress`: Spoke Pool contract address
- `_hubPoolAddress`: Hub Pool contract address
- `_initialBridgeFee`: Initial bridge fee percentage

### Environment Variables
Refer to `.env` file for configuration:
- `PRIVATE_KEY`: Deployment wallet private key
- `INFURA_PROJECT_ID`: Network access credentials
- `ACROSS_HUB_POOL_ADDRESS`: Across Protocol Hub Pool
- `ACROSS_SPOKE_POOL_ADDRESS`: Across Protocol Spoke Pool

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

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
  - Leverages Across Protocol's native liquidity infrastructure
  - Uses V3 Core Router for cross-chain transfers
  - Seamless liquidity management

### Transfer Mechanism
- Unique transfer ID generation
- Detailed transfer metadata tracking
- Dynamic fee estimation
- Cross-chain transfer execution

### Liquidity Management
- **Fully Managed by Across Protocol**
  - No custom liquidity provider management
  - Utilizes Across Protocol's battle-tested liquidity pools
  - Automatic liquidity routing and optimization

## Transfer Tracking
- Enhanced transfer status tracking
- Comprehensive transfer metadata
- Transfer status enum:
  - `INITIATED`: Transfer started
  - `COMPLETED`: Transfer successful
  - `FAILED`: Transfer unsuccessful

### Transfer Tracking Methods
- `getUserTransfers(address user, uint256 limit)`: Retrieve user's recent transfers
- `getTransferDetails(bytes32 transferId)`: Get specific transfer details
- `getTotalTransfers()`: Get total number of bridge transfers

### Transfer Events
- `TransferInitiated`: Detailed transfer start information
- `TransferStatusUpdated`: Real-time transfer status updates

## Fee Management
- Dynamic fee calculation via Across Protocol Core Router
- Relies on `coreRouter.calculateDepositV3Fee()` for accurate fee estimation

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

## Author
[Mujeeb Sulayman](https://x.com/thehemjay)

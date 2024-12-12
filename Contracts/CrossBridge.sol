// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@across-protocol/contracts/interfaces/V3CoreRouterInterface.sol";
import "@across-protocol/contracts/interfaces/SpokePoolInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title HemswapCrossBridge
 * @notice Cross-Chain Bridge implementing Across Protocol's infrastructure
 * @dev Supports cross-chain token transfers with advanced liquidity management
 */
contract HemswapCrossBridge is Ownable, ReentrancyGuard {
    // Across Protocol Core Components
    V3CoreRouterInterface public coreRouter;
    SpokePoolInterface public spokePool;
    address public hubPool;

    // Liquidity Provider Management
    mapping(address => uint256) public liquidityProviders;
    uint256 public totalLiquidity;

    // Bridge Fee Configuration
    uint256 public constant MAX_BRIDGE_FEE_PERCENTAGE = 1000; // 10%
    uint256 public bridgeFeePercentage;

    // Transfer Tracking
    struct CrossChainTransfer {
        address sender;
        address recipient;
        address token;
        uint256 amount;
        uint256 sourceChain;
        uint256 destinationChain;
        uint256 timestamp;
        bool completed;
    }

    mapping(bytes32 => CrossChainTransfer) public transfers;

    // Events
    event LiquidityAdded(address provider, uint256 amount);
    event LiquidityRemoved(address provider, uint256 amount);
    event CrossChainTransferInitiated(
        bytes32 transferId,
        address indexed sender,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 sourceChain,
        uint256 destinationChain
    );
    event CrossChainTransferCompleted(
        bytes32 transferId,
        address indexed recipient,
        uint256 amount
    );
    event BridgeFeeUpdated(uint256 newFeePercentage);

    constructor(
        address _coreRouterAddress,
        address _spokePoolAddress,
        address _hubPoolAddress,
        uint256 _initialBridgeFee
    ) {
        require(_coreRouterAddress != address(0), "Invalid Core Router");
        require(_spokePoolAddress != address(0), "Invalid Spoke Pool");
        require(_hubPoolAddress != address(0), "Invalid Hub Pool");
        
        coreRouter = V3CoreRouterInterface(_coreRouterAddress);
        spokePool = SpokePoolInterface(_spokePoolAddress);
        hubPool = _hubPoolAddress;
        
        bridgeFeePercentage = _initialBridgeFee;
    }

    /**
     * @notice Add liquidity to the bridge
     * @param token ERC20 token address
     * @param amount Liquidity amount
     */
    function addLiquidity(address token, uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid liquidity amount");
        
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        liquidityProviders[msg.sender] += amount;
        totalLiquidity += amount;

        emit LiquidityAdded(msg.sender, amount);
    }

    /**
     * @notice Remove liquidity from the bridge
     * @param token ERC20 token address
     * @param amount Liquidity amount to withdraw
     */
    function removeLiquidity(address token, uint256 amount) external nonReentrant {
        require(liquidityProviders[msg.sender] >= amount, "Insufficient liquidity");
        
        liquidityProviders[msg.sender] -= amount;
        totalLiquidity -= amount;
        
        IERC20(token).transfer(msg.sender, amount);

        emit LiquidityRemoved(msg.sender, amount);
    }

    /**
     * @notice Initiate cross-chain token transfer
     * @param token Token address
     * @param amount Transfer amount
     * @param recipient Destination wallet address
     * @param destinationChainId Target blockchain network ID
     */
    function bridgeTokens(
        address token,
        uint256 amount,
        address recipient,
        uint256 destinationChainId
    ) external payable nonReentrant {
        require(amount > 0, "Invalid transfer amount");
        
        // Calculate bridge fee
        uint256 bridgeFee = (amount * bridgeFeePercentage) / 10000;
        uint256 transferAmount = amount - bridgeFee;

        // Transfer tokens from sender
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(address(coreRouter), transferAmount);

        // Generate unique transfer ID
        bytes32 transferId = keccak256(
            abi.encodePacked(msg.sender, recipient, token, amount, block.timestamp)
        );

        // Store transfer details
        transfers[transferId] = CrossChainTransfer({
            sender: msg.sender,
            recipient: recipient,
            token: token,
            amount: transferAmount,
            sourceChain: block.chainid,
            destinationChain: destinationChainId,
            timestamp: block.timestamp,
            completed: false
        });

        // Execute cross-chain transfer via Across Protocol
        coreRouter.depositV3{value: msg.value}(
            recipient,
            token,
            transferAmount,
            destinationChainId,
            abi.encode(transferId),
            bridgeFeePercentage
        );

        emit CrossChainTransferInitiated(
            transferId,
            msg.sender,
            recipient,
            token,
            transferAmount,
            block.chainid,
            destinationChainId
        );
    }

    /**
     * @notice Update bridge fee percentage
     * @param newFeePercentage New fee percentage (basis points)
     */
    function updateBridgeFee(uint256 newFeePercentage) external onlyOwner {
        require(
            newFeePercentage <= MAX_BRIDGE_FEE_PERCENTAGE, 
            "Fee exceeds maximum limit"
        );
        bridgeFeePercentage = newFeePercentage;
        emit BridgeFeeUpdated(newFeePercentage);
    }

    /**
     * @notice Update Across Protocol contract addresses
     */
    function updateProtocolAddresses(
        address _newCoreRouter,
        address _newSpokePool,
        address _newHubPool
    ) external onlyOwner {
        require(_newCoreRouter != address(0), "Invalid Core Router");
        require(_newSpokePool != address(0), "Invalid Spoke Pool");
        require(_newHubPool != address(0), "Invalid Hub Pool");

        coreRouter = V3CoreRouterInterface(_newCoreRouter);
        spokePool = SpokePoolInterface(_newSpokePool);
        hubPool = _newHubPool;
    }

    // Fallback and receive functions
    receive() external payable {}
    fallback() external payable {}
}

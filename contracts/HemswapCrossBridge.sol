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
    mapping(address => bool) public authorizedLiquidityProviders;
    uint256 public totalLiquidity;

    // Enhanced Transfer Tracking
    struct CrossChainTransfer {
        bytes32 transferId;
        address sender;
        address recipient;
        address token;
        uint256 amount;
        uint256 sourceChain;
        uint256 destinationChain;
        uint256 timestamp;
        TransferStatus status;
    }

    enum TransferStatus {
        INITIATED,
        COMPLETED,
        FAILED
    }

    // Mapping to store transfers
    mapping(bytes32 => CrossChainTransfer) public transfers;

    // Mapping to track user's transfers
    mapping(address => bytes32[]) public userTransfers;

    // Total number of transfers
    uint256 public totalTransfers;

    // Events with more comprehensive information
    event TransferInitiated(
        bytes32 indexed transferId,
        address indexed sender,
        address indexed recipient,
        address token,
        uint256 amount,
        uint256 sourceChain,
        uint256 destinationChain,
        uint256 timestamp
    );

    event TransferStatusUpdated(
        bytes32 indexed transferId,
        TransferStatus status,
        string message
    );

    event LiquidityAdded(address provider, uint256 amount);
    event LiquidityRemoved(address provider, uint256 amount);
    event LiquidityProviderAdded(address provider);
    event LiquidityProviderRemoved(address provider);

    constructor(
        address _coreRouterAddress,
        address _spokePoolAddress,
        address _hubPoolAddress
    ) {
        require(_coreRouterAddress != address(0), "Invalid Core Router");
        require(_spokePoolAddress != address(0), "Invalid Spoke Pool");
        require(_hubPoolAddress != address(0), "Invalid Hub Pool");

        coreRouter = V3CoreRouterInterface(_coreRouterAddress);
        spokePool = SpokePoolInterface(_spokePoolAddress);
        hubPool = _hubPoolAddress;
    }

    /**
     * @notice Add an authorized liquidity provider
     * @param provider Address of the liquidity provider to authorize
     */
    function addLiquidityProvider(address provider) external onlyOwner {
        require(provider != address(0), "Invalid provider address");
        require(
            !authorizedLiquidityProviders[provider],
            "Provider already authorized"
        );

        authorizedLiquidityProviders[provider] = true;

        emit LiquidityProviderAdded(provider);
    }

    /**
     * @notice Remove an authorized liquidity provider
     * @param provider Address of the liquidity provider to remove
     */
    function removeLiquidityProvider(address provider) external onlyOwner {
        require(
            authorizedLiquidityProviders[provider],
            "Provider not authorized"
        );

        authorizedLiquidityProviders[provider] = false;

        emit LiquidityProviderRemoved(provider);
    }

    /**
     * @notice Add liquidity to the bridge
     * @param token ERC20 token address
     * @param amount Liquidity amount
     */
    function addLiquidity(address token, uint256 amount) external nonReentrant {
        // Restrict liquidity addition to authorized providers
        require(
            authorizedLiquidityProviders[msg.sender],
            "Not an authorized liquidity provider"
        );
        require(amount > 0, "Invalid liquidity amount");

        // Validate token is a contract
        require(token.code.length > 0, "Invalid token address");

        // Check sender's token balance
        uint256 senderBalance = IERC20(token).balanceOf(msg.sender);
        require(senderBalance >= amount, "Insufficient token balance");

        // Check sender's token allowance
        uint256 currentAllowance = IERC20(token).allowance(
            msg.sender,
            address(this)
        );
        require(currentAllowance >= amount, "Insufficient token allowance");

        // Perform token transfer with safety checks
        bool transferSuccess = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(transferSuccess, "Token transfer failed");

        // Verify the contract received the correct amount
        uint256 receivedBalance = IERC20(token).balanceOf(address(this));
        require(
            receivedBalance >= amount,
            "Received less tokens than expected"
        );

        // Update liquidity tracking
        liquidityProviders[msg.sender] += amount;
        totalLiquidity += amount;

        emit LiquidityAdded(msg.sender, amount);
    }

    /**
     * @notice Remove liquidity from the bridge
     * @param token ERC20 token address
     * @param amount Liquidity amount to withdraw
     */
    function removeLiquidity(
        address token,
        uint256 amount
    ) external nonReentrant {
        // Restrict liquidity removal to authorized providers
        require(
            authorizedLiquidityProviders[msg.sender],
            "Not an authorized liquidity provider"
        );
        require(
            liquidityProviders[msg.sender] >= amount,
            "Insufficient liquidity"
        );

        // Validate token is a contract
        require(token.code.length > 0, "Invalid token address");

        // Update liquidity tracking
        liquidityProviders[msg.sender] -= amount;
        totalLiquidity -= amount;

        // Transfer tokens back to the provider
        bool transferSuccess = IERC20(token).transfer(msg.sender, amount);
        require(transferSuccess, "Token transfer failed");

        emit LiquidityRemoved(msg.sender, amount);
    }

    /**
     * @notice Retrieve transfers for a specific user
     * @param user Address of the user
     * @param limit Maximum number of transfers to retrieve
     * @return userTransferList Array of transfer IDs
     */
    function getUserTransfers(
        address user,
        uint256 limit
    ) external view returns (bytes32[] memory userTransferList) {
        bytes32[] memory allUserTransfers = userTransfers[user];

        // Determine the number of transfers to return
        uint256 transferCount = allUserTransfers.length;
        uint256 returnCount = limit > 0 && limit < transferCount
            ? limit
            : transferCount;

        userTransferList = new bytes32[](returnCount);

        // Return most recent transfers first
        for (uint256 i = 0; i < returnCount; i++) {
            userTransferList[i] = allUserTransfers[transferCount - 1 - i];
        }
    }

    /**
     * @notice Retrieve transfer details by transfer ID
     * @param transferId Unique identifier of the transfer
     * @return transfer Details of the cross-chain transfer
     */
    function getTransferDetails(
        bytes32 transferId
    ) external view returns (CrossChainTransfer memory transfer) {
        transfer = transfers[transferId];
        require(transfer.transferId != 0, "Transfer not found");
    }

    /**
     * @notice Get total number of transfers
     * @return Total number of transfers initiated
     */
    function getTotalTransfers() external view returns (uint256) {
        return totalTransfers;
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
        require(recipient != address(0), "Invalid recipient");

        // Validate token is a contract
        require(token.code.length > 0, "Invalid token address");

        // Check sender's token balance
        uint256 senderBalance = IERC20(token).balanceOf(msg.sender);
        require(senderBalance >= amount, "Insufficient token balance");

        // Check sender's token allowance
        uint256 currentAllowance = IERC20(token).allowance(
            msg.sender,
            address(this)
        );
        require(currentAllowance >= amount, "Insufficient token allowance");

        // Perform token transfer with safety checks
        bool transferSuccess = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        require(transferSuccess, "Token transfer failed");

        // Verify the contract received the correct amount
        uint256 receivedBalance = IERC20(token).balanceOf(address(this));
        require(
            receivedBalance >= amount,
            "Received less tokens than expected"
        );

        // Approve core router with additional safety checks
        IERC20(token).approve(address(coreRouter), 0); // Clear previous approval
        bool approveSuccess = IERC20(token).approve(
            address(coreRouter),
            amount
        );
        require(approveSuccess, "Token approval failed");

        // Verify approval was successful
        uint256 routerAllowance = IERC20(token).allowance(
            address(this),
            address(coreRouter)
        );
        require(routerAllowance >= amount, "Router approval failed");

        // Generate unique transfer ID
        bytes32 transferId = keccak256(
            abi.encodePacked(
                msg.sender,
                recipient,
                token,
                amount,
                destinationChainId,
                block.timestamp
            )
        );

        // Store transfer information
        transfers[transferId] = CrossChainTransfer({
            transferId: transferId,
            sender: msg.sender,
            recipient: recipient,
            token: token,
            amount: amount,
            sourceChain: block.chainid,
            destinationChain: destinationChainId,
            timestamp: block.timestamp,
            status: TransferStatus.INITIATED
        });

        // Track user's transfers
        userTransfers[msg.sender].push(transferId);
        userTransfers[recipient].push(transferId);

        // Increment total transfers
        totalTransfers++;

        // Emit enhanced transfer initiated event
        emit TransferInitiated(
            transferId,
            msg.sender,
            recipient,
            token,
            amount,
            block.chainid,
            destinationChainId,
            block.timestamp
        );

        // Execute cross-chain transfer via Across Protocol
        try
            coreRouter.depositV3{value: msg.value}(
                recipient,
                token,
                amount,
                destinationChainId,
                abi.encode(transferId),
                0 // Let Across Protocol determine the fee
            )
        {
            // Update transfer status to completed
            transfers[transferId].status = TransferStatus.COMPLETED;
            emit TransferStatusUpdated(
                transferId,
                TransferStatus.COMPLETED,
                "Transfer completed successfully"
            );
        } catch Error(string memory reason) {
            // Update transfer status to failed
            transfers[transferId].status = TransferStatus.FAILED;
            emit TransferStatusUpdated(
                transferId,
                TransferStatus.FAILED,
                reason
            );
            // Revert with the specific error from the core router
            revert(
                string(
                    abi.encodePacked("Cross-chain transfer failed: ", reason)
                )
            );
        } catch {
            // Update transfer status to failed
            transfers[transferId].status = TransferStatus.FAILED;
            emit TransferStatusUpdated(
                transferId,
                TransferStatus.FAILED,
                "Transfer failed unexpectedly"
            );
            // Catch any other unexpected errors
            revert("Cross-chain transfer failed unexpectedly");
        }
    }

    /**
     * @notice Get estimated bridge fee from Across Protocol
     * @param token Token address for transfer
     * @param amount Transfer amount
     * @param destinationChainId Target blockchain network ID
     * @return estimatedFee Estimated fee in the native token
     */
    function getEstimatedBridgeFee(
        address token,
        uint256 amount,
        uint256 destinationChainId
    ) external view returns (uint256 estimatedFee) {
        // Use Across Protocol's fee estimation method
        // Note: Actual implementation depends on Across Protocol's interface
        estimatedFee = coreRouter.calculateDepositV3Fee(
            token,
            amount,
            destinationChainId
        );
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

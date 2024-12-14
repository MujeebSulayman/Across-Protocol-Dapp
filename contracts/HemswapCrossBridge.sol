// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@across-protocol/contracts/interfaces/V3CoreRouterInterface.sol";
import "@across-protocol/contracts/interfaces/SpokePoolInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title HemswapCrossBridge
 * @notice Cross-Chain Bridge implementing Across Protocol's infrastructure
 * @dev Supports cross-chain token transfers using Across Protocol's liquidity
 */
contract HemswapCrossBridge is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Across Protocol Core Components
    V3CoreRouterInterface public coreRouter;
    SpokePoolInterface public spokePool;
    address public hubPool;

    // Transfer Tracking
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

    // Store transfers
    mapping(bytes32 => CrossChainTransfer) public transfers;

    // Track user's transfers
    mapping(address => bytes32[]) public userTransfers;

    // Total transfers
    uint256 public totalTransfers;

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

        uint256 transferCount = allUserTransfers.length;
        uint256 returnCount = limit > 0 && limit < transferCount
            ? limit
            : transferCount;

        userTransferList = new bytes32[](returnCount);

        for (uint256 i = 0; i < returnCount; i++) {
            userTransferList[i] = allUserTransfers[transferCount - 1 - i];
        }
    }

    function getTransferDetails(
        bytes32 transferId
    ) external view returns (CrossChainTransfer memory transfer) {
        transfer = transfers[transferId];
        require(transfer.transferId != 0, "Transfer not found");
    }

    function getEstimatedBridgeFee(
        address token,
        uint256 amount,
        uint256 destinationChainId
    ) external view returns (uint256 estimatedFee) {
        estimatedFee = coreRouter.calculateDepositV3Fee(
            token,
            amount,
            destinationChainId
        );
    }

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

    /**
     * @notice Reset token approval for a specific token
     * @param token Token address to reset approval
     * @param spender Address to reset approval for
     */
    function resetTokenApproval(address token, address spender) external {
        IERC20(token).forceApprove(spender, 0);
    }

    function safeTokenApprove(
        address token,
        address spender,
        uint256 amount
    ) external {
        IERC20(token).forceApprove(spender, 0);
        IERC20(token).safeIncreaseAllowance(spender, amount);
    }

    function bridgeTokens(
        address token,
        uint256 amount,
        address recipient,
        uint256 destinationChainId
    ) external payable nonReentrant {
        require(amount > 0, "Invalid transfer amount");
        require(recipient != address(0), "Invalid recipient");

        require(token.code.length > 0, "Invalid token address");

        uint256 senderBalance = IERC20(token).balanceOf(msg.sender);
        require(senderBalance >= amount, "Insufficient token balance");

        uint256 currentAllowance = IERC20(token).allowance(
            msg.sender,
            address(this)
        );
        require(currentAllowance >= amount, "Insufficient token allowance");

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
        IERC20(token).forceApprove(address(coreRouter), 0);
        bool approveSuccess = IERC20(token).safeIncreaseAllowance(
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

        userTransfers[msg.sender].push(transferId);
        userTransfers[recipient].push(transferId);

        totalTransfers++;

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

        // Reset approval after transfer to prevent potential reuse
        IERC20(token).forceApprove(address(this), 0);

        // Execute cross-chain transfer via Across Protocol
        try
            coreRouter.depositV3{value: msg.value}(
                recipient,
                token,
                amount,
                destinationChainId,
                abi.encode(transferId),
                0
            )
        {
            // Update transfer status
            transfers[transferId].status = TransferStatus.COMPLETED;
            emit TransferStatusUpdated(
                transferId,
                TransferStatus.COMPLETED,
                "Transfer completed successfully"
            );
        } catch Error(string memory reason) {
            transfers[transferId].status = TransferStatus.FAILED;
            emit TransferStatusUpdated(
                transferId,
                TransferStatus.FAILED,
                reason
            );
            // Revert with error from the core router
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
            revert("Cross-chain transfer failed unexpectedly");
        }
    }

    /**
     * @notice Get total number of transfers
     * @return Total number of transfers initiated
     */
    function getTotalTransfers() external view returns (uint256) {
        return totalTransfers;
    }

    receive() external payable {}

    fallback() external payable {}
}

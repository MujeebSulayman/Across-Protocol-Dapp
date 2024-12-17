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

    mapping(bytes32 => CrossChainTransfer) public transfers;
    mapping(address => bytes32[]) public userTransfers;

    uint256 public totalTransfers;

    //  Events
    event TransferInitiated(
        bytes32 indexed transferId,
        address indexed sender,
        address indexed recipient,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 sourceChain,
        uint256 destinationChain,
        uint32 quoteTimestamp,
        uint32 fillDeadline,
        uint32 exclusivityDeadline
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
        
        // More efficient retrieval of recent transfers
        for (uint256 i = 0; i < returnCount; i++) {
            userTransferList[i] = allUserTransfers[transferCount - returnCount + i];
        }
    }

    function getTransferDetails(
        bytes32 transferId
    ) external view returns (CrossChainTransfer memory transfer) {
        transfer = transfers[transferId];
        require(transfer.sender != address(0), "Transfer not found");
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

    function resetTokenApproval(address token, address spender) external nonReentrant {
        IERC20(token).safeApprove(spender, 0);
    }

    function safeTokenApprove(
        address token,
        address spender,
        uint256 amount
    ) external nonReentrant {
        IERC20(token).safeApprove(spender, amount);
    }


    function bridgeTokensV3(
        address token,
        uint256 amount,
        address recipient,
        uint256 destinationChainId,
        address outputToken,
        address exclusiveRelayer
    ) external payable nonReentrant {
        require(amount > 0, "Invalid transfer amount");
        require(recipient != address(0), "Invalid recipient");
        require(token.code.length > 0, "Invalid token address");
        require(outputToken == address(0) || outputToken.code.length > 0, "Invalid output token");

        // Calculate estimated output amount and fee
        uint256 estimatedFee = coreRouter.calculateDepositV3Fee(
            token,
            amount,
            destinationChainId
        );
        uint256 outputAmount = amount - estimatedFee;

        // Transfer tokens from sender to contract
        IERC20 inputToken = IERC20(token);
        uint256 senderBalance = inputToken.balanceOf(msg.sender);
        require(senderBalance >= amount, "Insufficient token balance");

        uint256 currentAllowance = inputToken.allowance(
            msg.sender,
            address(this)
        );
        require(currentAllowance >= amount, "Insufficient token allowance");

        inputToken.safeTransferFrom(msg.sender, address(this), amount);

        // Approve core router
        inputToken.safeApprove(address(coreRouter), amount);

        uint32 quoteTimestamp = uint32(block.timestamp);
        uint32 fillDeadline = uint32(block.timestamp + 7 days);
        uint32 exclusivityDeadline = exclusiveRelayer != address(0) 
            ? uint32(block.timestamp + 1 hours) 
            : 0;

        // Bridge tokens via Across Protocol
        bytes32 transferId = coreRouter.depositV3(
            recipient,
            token,
            amount,
            destinationChainId,
            outputToken,
            exclusiveRelayer,
            quoteTimestamp,
            fillDeadline,
            exclusivityDeadline
        );

        // Store transfer details
        CrossChainTransfer memory newTransfer = CrossChainTransfer({
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

        transfers[transferId] = newTransfer;
        userTransfers[msg.sender].push(transferId);
        totalTransfers++;

        // Emit transfer initiated event
        emit TransferInitiated(
            transferId,
            msg.sender,
            recipient,
            token,
            outputToken,
            amount,
            outputAmount,
            block.chainid,
            destinationChainId,
            quoteTimestamp,
            fillDeadline,
            exclusivityDeadline
        );
    }

    function handleV3AcrossMessage(
        address tokenSent,
        uint256 amount,
        address relayer,
        bytes memory message
    ) external {
        emit TransferStatusUpdated(
            keccak256(abi.encodePacked(tokenSent, amount, relayer)),
            TransferStatus.COMPLETED,
            "Cross-chain transfer received"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Swap is Initializable {
    address public treasury;
    address public owner;
    uint8 public taxFee;
    uint256 private _requestId;

    enum RequestStatus {
        Pending,
        Cancelled,
        Rejected,
        Approved
    }

    struct SwapRequest {
        uint256 id;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        address destToken;
        uint256 destAmount;
        RequestStatus status;
    }

    mapping(uint256 => SwapRequest) public requests;

    event SwapRequestCreated(
        uint256 requestId,
        address sender,
        address receiver,
        address token,
        uint256 amount,
        address destToken,
        uint256 destAmount
    );
    event SwapRequestApproved(uint256 requestId);
    event SwapRequestRejected(uint256 requestId);
    event SwapRequestCancelled(uint256 requestId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _treasury) public initializer {
        owner = msg.sender;
        treasury = _treasury;
        taxFee = 5;
    }

    function setTaxFee(uint8 _taxFee) external onlyOwner {
        require(_taxFee <= 100);
        taxFee = _taxFee;
    }

    function requestSwap(
        address _receiver,
        address _token,
        uint256 _amount,
        address _destToken,
        uint256 _destAmount
    ) external {
        require(_receiver != address(0), "Invalid receiver address");
        require(_token != address(0), "Invalid token address");
        require(_destToken != address(0), "Invalid dest token address");

        address sender = msg.sender;

        IERC20 token = IERC20(_token);
        token.transferFrom(sender, address(this), _amount);

        SwapRequest memory request = SwapRequest({
            id: ++_requestId,
            sender: sender,
            receiver: _receiver,
            token: _token,
            amount: _amount,
            destToken: _destToken,
            destAmount: _destAmount,
            status: RequestStatus.Pending
        });

        requests[_requestId] = request;

        emit SwapRequestCreated(
            _requestId,
            sender,
            _receiver,
            _token,
            _amount,
            _destToken,
            _destAmount
        );
    }

    function approveSwap(uint256 _reqId) external onlyOwner {
        SwapRequest memory request = requests[_reqId];

        require(request.id != 0, "Invalid request id");
        require(msg.sender == request.receiver, "Only receiver can approve");
        require(
            request.status == RequestStatus.Pending,
            "Request is not pending"
        );

        IERC20 token = IERC20(request.token);
        IERC20 destToken = IERC20(request.destToken);

        uint256 senderReceivedAmount = request.amount -
            ((100 - taxFee) * request.destAmount) /
            100;

        uint256 receiverReceivedAmount = ((100 - taxFee) * request.amount) /
            100;

        destToken.transferFrom(msg.sender, address(this), request.destAmount);
        destToken.transfer(request.sender, senderReceivedAmount);
        token.transfer(msg.sender, receiverReceivedAmount);
        token.transfer(treasury, (taxFee * request.amount) / 100);
        destToken.transfer(treasury, (taxFee * request.destAmount) / 100);

        requests[_reqId].status = RequestStatus.Approved;
        emit SwapRequestApproved(_requestId);
    }

    function rejectSwap(uint256 _reqId) external onlyOwner {
        SwapRequest memory request = requests[_reqId];
        require(request.id != 0, "Invalid request id");
        require(
            request.status == RequestStatus.Pending,
            "Request is not pending"
        );
        require(msg.sender == request.receiver, "Not the receiver");
        IERC20 token = IERC20(request.token);
        token.transfer(request.sender, request.amount);
        requests[_reqId].status = RequestStatus.Rejected;
        emit SwapRequestRejected(_reqId);
    }

    function cancelSwap(uint256 _reqId) external {
        SwapRequest memory request = requests[_reqId];
        require(request.id != 0, "Invalid request id");
        require(
            request.status == RequestStatus.Pending,
            "Request is not pending"
        );
        require(msg.sender == request.sender, "Not the sender");
        IERC20 token = IERC20(request.token);
        token.transfer(request.sender, request.amount);
        requests[_reqId].status = RequestStatus.Cancelled;
        emit SwapRequestCancelled(_reqId);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    receive() external payable {
        revert("Invalid function call");
    }

    fallback() external payable {
        revert("Invalid function call");
    }
}

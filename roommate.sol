// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SharedHousingAgreement {
    address public landlord;
    string public houseAddress;

    uint256 public totalMonthlyRent; // wei
    uint256 public securityDepositPerPerson; // wei
    uint256 public leaseStart;
    uint256 public leaseEnd;

    bool public agreementActive;

    struct Roommate {
        bool isActive;
        bool depositPaid;
        uint256 joinedAt;
        uint256 lastRentPaidMonth; // 0 = chưa trả lần nào
        uint256 depositAmount; // số tiền đã cọc
    }

    mapping(address => Roommate) public roommates;
    address[] public roommateList;

    uint256 public commonFund; // quỹ chung đóng điện nước
    mapping(address => uint256) public commonFundContribution;

    // Vote để kick người không trả tiền
    mapping(address => mapping(address => bool)) public kickVotes; // kickVotes[target][voter]
    mapping(address => uint256) public kickVoteCount;

    event RoommateAdded(address indexed roommate);
    event DepositPaid(address indexed roommate, uint256 amount);
    event RentPaid(address indexed roommate, uint256 amount, uint256 forMonth);
    event CommonFundDeposited(address indexed from, uint256 amount);
    event BillPaidByLandlord(uint256 amount, string description);
    event RoommateKicked(address indexed kicked, uint256 votes);
    event RoommateLeft(address indexed roommate, uint256 depositReturned);
    event AgreementTerminated(uint256 timestamp);

    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only landlord");
        _;
    }

    modifier onlyActiveRoommate() {
        require(roommates[msg.sender].isActive, "Not active roommate");
        _;
    }

    modifier onlyActiveAgreement() {
        require(agreementActive, "Agreement not active");
        _;
    }

    constructor(
        string memory _houseAddress,
        uint256 _totalMonthlyRent,
        uint256 _securityDepositPerPerson,
        uint256 _leaseDurationInDays
    ) {
        landlord = msg.sender;
        houseAddress = _houseAddress;
        totalMonthlyRent = _totalMonthlyRent;
        securityDepositPerPerson = _securityDepositPerPerson;
        leaseStart = block.timestamp;
        leaseEnd = block.timestamp + (_leaseDurationInDays * 1 days);
        agreementActive = true;
    }

    function addRoommate(address _roommate) external onlyLandlord onlyActiveAgreement {
        require(_roommate!= address(0), "Invalid address");
        require(!roommates[_roommate].isActive, "Already a roommate");

        roommates[_roommate] = Roommate({
            isActive: true,
            depositPaid: false,
            joinedAt: block.timestamp,
            lastRentPaidMonth: 0,
            depositAmount: 0
        });

        roommateList.push(_roommate);
        emit RoommateAdded(_roommate);
    }

    function payDeposit() external payable onlyActiveRoommate onlyActiveAgreement {
        Roommate storage r = roommates[msg.sender];
        require(!r.depositPaid, "Deposit already paid");
        require(msg.value == securityDepositPerPerson, "Incorrect deposit amount");

        r.depositPaid = true;
        r.depositAmount = msg.value;
        emit DepositPaid(msg.sender, msg.value);
    }

    function getCurrentMonth() public view returns (uint256) {
        return (block.timestamp - leaseStart) / 30 days + 1;
    }

    function getRentPerPerson() public view returns (uint256) {
        uint256 activeCount = getActiveRoommateCount();
        require(activeCount > 0, "No active roommates");
        return totalMonthlyRent / activeCount;
    }

    function payRent() external payable onlyActiveRoommate onlyActiveAgreement {
        Roommate storage r = roommates[msg.sender];
        require(r.depositPaid, "Pay deposit first");

        uint256 currentMonth = getCurrentMonth();
        require(r.lastRentPaidMonth < currentMonth, "Rent for this month already paid");

        uint256 rentDue = getRentPerPerson();
        require(msg.value == rentDue, "Incorrect rent amount");

        r.lastRentPaidMonth = currentMonth;

        (bool sent, ) = landlord.call{value: msg.value}("");
        require(sent, "Failed to send rent to landlord");

        emit RentPaid(msg.sender, msg.value, currentMonth);
    }

    function contributeToCommonFund() external payable onlyActiveRoommate {
        require(msg.value > 0, "Must send ETH");
        commonFund += msg.value;
        commonFundContribution[msg.sender] += msg.value;
        emit CommonFundDeposited(msg.sender, msg.value);
    }

    function payBillFromCommonFund(uint256 _amount, string memory _description)
        external
        onlyLandlord
    {
        require(_amount <= commonFund, "Not enough in common fund");
        commonFund -= _amount;

        (bool sent, ) = landlord.call{value: _amount}("");
        require(sent, "Failed to pay bill");

        emit BillPaidByLandlord(_amount, _description);
    }

    function voteToKick(address _target) external onlyActiveRoommate {
        require(roommates[_target].isActive, "Target not active");
        require(_target!= msg.sender, "Cannot vote yourself");
        require(!kickVotes[_target][msg.sender], "Already voted");

        kickVotes[_target][msg.sender] = true;
        kickVoteCount[_target]++;

        uint256 activeCount = getActiveRoommateCount();
        // Cần > 50% vote để kick
        if (kickVoteCount[_target] * 2 > activeCount) {
            _kickRoommate(_target);
        }
    }

    function _kickRoommate(address _target) internal {
        roommates[_target].isActive = false;
        // Mất cọc nếu bị kick vì không trả tiền
        emit RoommateKicked(_target, kickVoteCount[_target]);
    }

    function leaveRoom() external onlyActiveRoommate {
        Roommate storage r = roommates[msg.sender];
        uint256 currentMonth = getCurrentMonth();
        require(r.lastRentPaidMonth >= currentMonth, "Pay current month rent first");

        r.isActive = false;
        uint256 depositToReturn = r.depositAmount;
        r.depositAmount = 0;

        if (depositToReturn > 0) {
            (bool sent, ) = msg.sender.call{value: depositToReturn}("");
            require(sent, "Failed to return deposit");
        }

        emit RoommateLeft(msg.sender, depositToReturn);
    }

    function terminateAgreement() external onlyLandlord {
        require(block.timestamp >= leaseEnd, "Lease not ended yet");
        agreementActive = false;

        // Trả cọc cho tất cả roommate còn active
        for (uint i = 0; i < roommateList.length; i++) {
            address rAddr = roommateList[i];
            if (roommates[rAddr].isActive && roommates[rAddr].depositAmount > 0) {
                uint256 amount = roommates[rAddr].depositAmount;
                roommates[rAddr].depositAmount = 0;
                (bool sent, ) = rAddr.call{value: amount}("");
                require(sent, "Failed to return deposit");
            }
        }

        emit AgreementTerminated(block.timestamp);
    }

    function getActiveRoommateCount() public view returns (uint256 count) {
        for (uint i = 0; i < roommateList.length; i++) {
            if (roommates[roommateList[i]].isActive) {
                count++;
            }
        }
    }

    function getRoommateList() external view returns (address[] memory) {
        return roommateList;
    }

    function isRentOverdue(address _roommate) external view returns (bool) {
        if (!roommates[_roommate].isActive) return false;
        uint256 currentMonth = getCurrentMonth();
        // Cho phép trễ 5 ngày
        uint256 dueDate = leaseStart + (currentMonth * 30 days);
        return block.timestamp > dueDate + 5 days &&
               roommates[_roommate].lastRentPaidMonth < currentMonth;
    }

    receive() external payable {
        revert("Use specific functions");
    }
}
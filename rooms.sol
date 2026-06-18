// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract RoomRental {
    address public landlord;
    address public tenant;
    
    uint256 public rentAmount; // wei
    uint256 public depositAmount; // wei
    uint256 public rentDueDate; // timestamp
    uint256 public leaseStart;
    uint256 public leaseEnd;
    
    string public roomAddress;
    bool public isActive;
    bool public depositPaid;
    
    enum RentStatus { NotPaid, Paid, Overdue }
    RentStatus public currentRentStatus;
    
    event RentPaid(address indexed tenant, uint256 amount, uint256 timestamp);
    event DepositPaid(address indexed tenant, uint256 amount);
    event LeaseTerminated(address indexed by, uint256 timestamp);
    event TenantAssigned(address indexed tenant);
    
    modifier onlyLandlord() {
        require(msg.sender == landlord, "Only landlord");
        _;
    }
    
    modifier onlyTenant() {
        require(msg.sender == tenant, "Only tenant");
        _;
    }
    
    modifier onlyActive() {
        require(isActive, "Lease not active");
        _;
    }
    
    constructor(
        address _landlord,
        string memory _roomAddress,
        uint256 _rentAmount,
        uint256 _depositAmount,
        uint256 _leaseDurationInDays
    ) {
        landlord = _landlord;
        roomAddress = _roomAddress;
        rentAmount = _rentAmount;
        depositAmount = _depositAmount;
        leaseStart = block.timestamp;
        leaseEnd = block.timestamp + (_leaseDurationInDays * 1 days);
        rentDueDate = block.timestamp + 30 days;
        isActive = true;
        currentRentStatus = RentStatus.NotPaid;
    }
    
    function assignTenant(address _tenant) external onlyLandlord {
        require(tenant == address(0), "Tenant already assigned");
        tenant = _tenant;
        emit TenantAssigned(_tenant);
    }
    
    function payDeposit() external payable onlyTenant onlyActive {
        require(!depositPaid, "Deposit already paid");
        require(msg.value == depositAmount, "Incorrect deposit amount");
        depositPaid = true;
        emit DepositPaid(msg.sender, msg.value);
    }
    
    function payRent() external payable onlyTenant onlyActive {
        require(depositPaid, "Pay deposit first");
        require(msg.value == rentAmount, "Incorrect rent amount");
        require(block.timestamp <= rentDueDate + 5 days, "Too late to pay");
        
        currentRentStatus = RentStatus.Paid;
        rentDueDate += 30 days; // gia hạn tháng tiếp theo
        
        (bool sent, ) = landlord.call{value: msg.value}("");
        require(sent, "Failed to send rent");
        
        emit RentPaid(msg.sender, msg.value, block.timestamp);
    }
    
    function checkRentStatus() public view returns (RentStatus) {
        if (block.timestamp > rentDueDate) {
            return RentStatus.Overdue;
        }
        return currentRentStatus;
    }
    
    function terminateLease() external onlyActive {
        require(msg.sender == landlord || msg.sender == tenant, "Not authorized");
        isActive = false;
        
        // Trả cọc cho tenant nếu chưa quá hạn
        if (depositPaid && address(this).balance >= depositAmount) {
            (bool sent, ) = tenant.call{value: depositAmount}("");
            require(sent, "Failed to return deposit");
        }
        
        emit LeaseTerminated(msg.sender, block.timestamp);
    }
    
    function withdraw() external onlyLandlord {
        require(!isActive, "Lease still active");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds");
        (bool sent, ) = landlord.call{value: balance}("");
        require(sent, "Withdraw failed");
    }
    
    function getLeaseInfo() external view returns (
        string memory,
        address,
        address,
        uint256,
        bool
    ) {
        return (
            roomAddress,
            landlord,
            tenant,
            rentAmount,
            depositAmount,
            leaseEnd,
            isActive
        );
    }
}

contract RoomRentalFactory {
    address[] public allRentals;
    mapping(address => address[]) public landlordToRentals;
    mapping(address => address[]) public tenantToRentals;
    
    event RentalCreated(
        address indexed rentalAddress,
        address indexed landlord,
        string roomAddress,
        uint256 rentAmount
    );
    
    function createRoomRental(
        string memory _roomAddress,
        uint256 _rentAmount,
        uint256 _depositAmount,
        uint256 _leaseDurationInDays
    ) external returns (address) {
        RoomRental newRental = new RoomRental(
            msg.sender,
            _roomAddress,
            _rentAmount,
            _depositAmount,
            _leaseDurationInDays
        );
        
        address rentalAddr = address(newRental);
        allRentals.push(rentalAddr);
        landlordToRentals[msg.sender].push(rentalAddr);
        
        emit RentalCreated(rentalAddr, msg.sender, _roomAddress, _rentAmount);
        return rentalAddr;
    }
    
    function getAllRentals() external view returns (address[] memory) {
        return allRentals;
    }
    
    function getRentalsByLandlord(address _landlord) external view returns (address[] memory) {
        return landlordToRentals[_landlord];
    }
    
    function getTotalRentals() external view returns (uint256) {
        return allRentals.length;
    }
}

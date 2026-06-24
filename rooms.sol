// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
=====================================================
HỆ THỐNG QUẢN LÝ THUÊ PHÒNG PHIÊN BẢN NÂNG CẤP
=====================================================

Chức năng:
- Tạo hợp đồng thuê phòng
- Gán người thuê
- Đóng tiền cọc
- Đóng tiền thuê hàng tháng
- Tính phí phạt trả trễ
- Lưu lịch sử thanh toán
- Hoàn cọc có xác nhận
- Kết thúc hợp đồng

*/

import “@openzeppelin/contracts/security/ReentrancyGuard.sol”;

contract RoomRental is ReentrancyGuard {

// Chủ nhà
address public landlord;
// Người thuê
address public tenant;
// Địa chỉ phòng
string public roomAddress;
// Tiền thuê mỗi tháng
uint256 public rentAmount;
// Tiền cọc
uint256 public depositAmount;
// Hạn thanh toán tiếp theo
uint256 public rentDueDate;
// Ngày bắt đầu
uint256 public leaseStart;
// Ngày kết thúc
uint256 public leaseEnd;
// Trạng thái hợp đồng
bool public isActive;
// Đã đóng cọc chưa
bool public depositPaid;
// Chủ nhà xác nhận hoàn cọc
bool public depositRefundApproved;
// Phí phạt trễ hạn (%)
uint256 public lateFeePercent = 10;
enum RentStatus {
    NotPaid,
    Paid,
    Overdue
}
RentStatus public currentRentStatus;
struct Payment {
    uint256 amount;
    uint256 timestamp;
}
Payment[] public payments;
event TenantAssigned(address tenant);
event DepositPaid(address tenant, uint256 amount);
event RentPaid(address tenant, uint256 amount);
event DepositRefundApproved();
event LeaseTerminated(address by);
modifier onlyLandlord() {
    require(msg.sender == landlord, "Chi chu nha");
    _;
}
modifier onlyTenant() {
    require(msg.sender == tenant, "Chi nguoi thue");
    _;
}
modifier onlyActive() {
    require(isActive, "Hop dong da ket thuc");
    _;
}
constructor(
    string memory _roomAddress,
    uint256 _rentAmount,
    uint256 _depositAmount,
    uint256 _leaseDurationDays
) {
    landlord = msg.sender;
    roomAddress = _roomAddress;
    rentAmount = _rentAmount;
    depositAmount = _depositAmount;
    leaseStart = block.timestamp;
    leaseEnd = block.timestamp + (_leaseDurationDays * 1 days);
    rentDueDate = block.timestamp + 30 days;
    isActive = true;
    currentRentStatus = RentStatus.NotPaid;
}
/*
    Gán người thuê
*/
function assignTenant(
    address _tenant
)
    external
    onlyLandlord
{
    require(
        tenant == address(0),
        "Da co nguoi thue"
    );
    require(
        _tenant != address(0),
        "Dia chi khong hop le"
    );
    tenant = _tenant;
    emit TenantAssigned(_tenant);
}
/*
    Đóng tiền cọc
*/
function payDeposit()
    external
    payable
    onlyTenant
    onlyActive
    nonReentrant
{
    require(
        !depositPaid,
        "Da dong coc"
    );
    require(
        msg.value == depositAmount,
        "Sai so tien coc"
    );
    depositPaid = true;
    emit DepositPaid(
        msg.sender,
        msg.value
    );
}
/*
    Đóng tiền thuê
*/
function payRent()
    external
    payable
    onlyTenant
    onlyActive
    nonReentrant
{
    require(
        depositPaid,
        "Can dong coc truoc"
    );
    require(
        block.timestamp < leaseEnd,
        "Hop dong het han"
    );
    uint256 requiredAmount = rentAmount;
    // Tính phí phạt nếu quá hạn
    if (block.timestamp > rentDueDate) {
        uint256 lateFee =
            (rentAmount * lateFeePercent)
            / 100;
        requiredAmount += lateFee;
    }
    require(
        msg.value == requiredAmount,
        "Sai so tien thanh toan"
    );
    payments.push(
        Payment(
            msg.value,
            block.timestamp
        )
    );
    currentRentStatus = RentStatus.Paid;
    rentDueDate += 30 days;
    (bool sent, ) =
        landlord.call{value: msg.value}("");
    require(sent, "Chuyen tien that bai");
    emit RentPaid(
        msg.sender,
        msg.value
    );
}
/*
    Chủ nhà xác nhận hoàn cọc
*/
function approveDepositRefund()
    external
    onlyLandlord
{
    depositRefundApproved = true;
    emit DepositRefundApproved();
}
/*
    Kết thúc hợp đồng
*/
function terminateLease()
    external
    onlyActive
    nonReentrant
{
    require(
        msg.sender == landlord ||
        msg.sender == tenant,
        "Khong du quyen"
    );
    isActive = false;
    if (
        depositPaid &&
        depositRefundApproved &&
        address(this).balance >= depositAmount
    ) {
        (bool sent, ) =
            tenant.call{
                value: depositAmount
            }("");
        require(
            sent,
            "Hoan coc that bai"
        );
    }
    emit LeaseTerminated(
        msg.sender
    );
}
/*
    Xem trạng thái tiền thuê
*/
function checkRentStatus()
    public
    view
    returns(RentStatus)
{
    if(
        block.timestamp > rentDueDate
    ) {
        return RentStatus.Overdue;
    }
    return currentRentStatus;
}
/*
    Số lần thanh toán
*/
function getPaymentCount()
    external
    view
    returns(uint256)
{
    return payments.length;
}
/*
    Thông tin hợp đồng
*/
function getLeaseInfo()
    external
    view
    returns(
        string memory,
        address,
        address,
        uint256,
        uint256,
        uint256,
        bool
    )
{
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
/*
    Chủ nhà rút tiền còn lại
*/
function withdrawRemaining()
    external
    onlyLandlord
    nonReentrant
{
    require(
        !isActive,
        "Hop dong con hieu luc"
    );
    uint256 balance =
        address(this).balance;
    require(
        balance > 0,
        "Khong co tien"
    );
    (bool sent, ) =
        landlord.call{
            value: balance
        }("");
    require(
        sent,
        "Rut tien that bai"
    );
}

}

/*
Factory tạo nhiều hợp đồng thuê phòng
*/
contract RoomRentalFactory {

address[] public rentals;
event RentalCreated(
    address rental,
    address landlord
);
function createRental(
    string memory roomAddress,
    uint256 rentAmount,
    uint256 depositAmount,
    uint256 durationDays
)
    external
    returns(address)
{
    RoomRental rental =
        new RoomRental(
            roomAddress,
            rentAmount,
            depositAmount,
            durationDays
        );
    address rentalAddress =
        address(rental);
    rentals.push(
        rentalAddress
    );
    emit RentalCreated(
        rentalAddress,
        msg.sender
    );
    return rentalAddress;
}
function getAllRentals()
    external
    view
    returns(address[] memory)
{
    return rentals;
}
function getTotalRentals()
    external
    view
    returns(uint256)
{
    return rentals.length;
}

}
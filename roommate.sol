// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*

HỢP ĐỒNG QUẢN LÝ NHÀ TRỌ GHÉP / Ở CHUNG NHIỀU NGƯỜI

Mục tiêu:

* Một chủ nhà quản lý một căn nhà.
* Nhiều người thuê cùng ở chung.
* Mỗi người phải đóng:
    * Tiền cọc
    * Tiền thuê hàng tháng
* Có quỹ chung:
    * Điện
    * Nước
    * Internet
    * Vệ sinh
* Có cơ chế biểu quyết:
    * Đuổi người vi phạm
    * Không đóng tiền
    * Gây ảnh hưởng tới tập thể

=========================================================
*/

contract SharedHousingAgreement {

/*
-----------------------------------------------------
THÔNG TIN CHUNG CỦA CĂN NHÀ
-----------------------------------------------------
*/
// Địa chỉ ví của chủ nhà
address public landlord;
// Địa chỉ căn nhà
string public houseAddress;
// Tổng tiền thuê cả căn mỗi tháng
uint256 public totalMonthlyRent;
// Tiền cọc mỗi người
uint256 public securityDepositPerPerson;
// Thời gian bắt đầu hợp đồng
uint256 public leaseStart;
// Thời gian kết thúc hợp đồng
uint256 public leaseEnd;
// Trạng thái hợp đồng
bool public agreementActive;
/*
-----------------------------------------------------
THÔNG TIN MỖI NGƯỜI THUÊ
-----------------------------------------------------
*/
struct Roommate {
    // Có còn ở trong nhà không
    bool isActive;
    // Đã đóng cọc chưa
    bool depositPaid;
    // Thời điểm tham gia
    uint256 joinedAt;
    // Tháng gần nhất đã đóng tiền thuê
    uint256 lastRentPaidMonth;
    // Số tiền cọc đã đóng
    uint256 depositAmount;
}
/*
Lưu thông tin roommate theo địa chỉ ví
*/
mapping(address => Roommate) public roommates;
/*
Danh sách tất cả roommate từng tham gia
*/
address[] public roommateList;
/*
-----------------------------------------------------
QUỸ CHUNG
-----------------------------------------------------
*/
// Tổng số tiền trong quỹ
uint256 public commonFund;
/*
Theo dõi từng người đã đóng vào quỹ bao nhiêu
*/
mapping(address => uint256)
    public commonFundContribution;
/*
-----------------------------------------------------
HỆ THỐNG BỎ PHIẾU KICK
-----------------------------------------------------
*/
/*
kickVotes[target][voter]
Ví dụ:
A bỏ phiếu kick B
kickVotes[B][A] = true
*/
mapping(address => mapping(address => bool))
    public kickVotes;
/*
Số phiếu kick của mỗi người
*/
mapping(address => uint256)
    public kickVoteCount;
/*
-----------------------------------------------------
SỰ KIỆN (EVENT)
-----------------------------------------------------
*/
event RoommateAdded(address roommate);
event DepositPaid(
    address roommate,
    uint256 amount
);
event RentPaid(
    address roommate,
    uint256 amount,
    uint256 month
);
event CommonFundDeposited(
    address roommate,
    uint256 amount
);
event BillPaidByLandlord(
    uint256 amount,
    string description
);
event RoommateKicked(
    address roommate,
    uint256 votes
);
event RoommateLeft(
    address roommate,
    uint256 depositReturned
);
event AgreementTerminated(
    uint256 timestamp
);
/*
-----------------------------------------------------
MODIFIER
-----------------------------------------------------
*/
// Chỉ chủ nhà
modifier onlyLandlord() {
    require(
        msg.sender == landlord,
        "Only landlord"
    );
    _;
}
// Chỉ roommate đang hoạt động
modifier onlyActiveRoommate() {
    require(
        roommates[msg.sender].isActive,
        "Not active roommate"
    );
    _;
}
// Hợp đồng còn hiệu lực
modifier onlyActiveAgreement() {
    require(
        agreementActive,
        "Agreement not active"
    );
    _;
}
/*
-----------------------------------------------------
KHỞI TẠO HỢP ĐỒNG
-----------------------------------------------------
*/
constructor(
    string memory _houseAddress,
    uint256 _totalMonthlyRent,
    uint256 _securityDepositPerPerson,
    uint256 _leaseDurationInDays
) {
    landlord = msg.sender;
    houseAddress = _houseAddress;
    totalMonthlyRent =
        _totalMonthlyRent;
    securityDepositPerPerson =
        _securityDepositPerPerson;
    leaseStart =
        block.timestamp;
    leaseEnd =
        block.timestamp +
        (_leaseDurationInDays * 1 days);
    agreementActive = true;
}
/*
-----------------------------------------------------
THÊM NGƯỜI THUÊ MỚI
-----------------------------------------------------
*/
function addRoommate(
    address _roommate
)
    external
    onlyLandlord
    onlyActiveAgreement
{
    /*
    Chủ nhà thêm một thành viên mới
    vào căn nhà.
    */
}
/*
-----------------------------------------------------
ĐÓNG TIỀN CỌC
-----------------------------------------------------
*/
function payDeposit()
    external
    payable
{
    /*
    Roommate gửi đúng số tiền cọc.
    Sau khi đóng:
    - depositPaid = true
    - lưu số tiền cọc
    */
}
/*
-----------------------------------------------------
XÁC ĐỊNH THÁNG HIỆN TẠI
-----------------------------------------------------
*/
function getCurrentMonth()
    public
    view
    returns(uint256)
{
    /*
    Ví dụ:
    Tháng đầu tiên = 1
    Sau 30 ngày = tháng 2
    Sau 60 ngày = tháng 3
    */
}
/*
-----------------------------------------------------
TÍNH TIỀN THUÊ MỖI NGƯỜI
-----------------------------------------------------
*/
function getRentPerPerson()
    public
    view
    returns(uint256)
{
    /*
    Ví dụ:
    Tiền nhà = 12 ETH
    Có 4 người
    => mỗi người 3 ETH
    */
}
/*
-----------------------------------------------------
ĐÓNG TIỀN THUÊ THÁNG
-----------------------------------------------------
*/
function payRent()
    external
    payable
{
    /*
    Điều kiện:
    - Đã đóng cọc
    - Chưa đóng tháng hiện tại
    Sau đó:
    - Chuyển tiền cho chủ nhà
    - Ghi nhận tháng đã thanh toán
    */
}
/*
-----------------------------------------------------
ĐÓNG GÓP QUỸ CHUNG
-----------------------------------------------------
*/
function contributeToCommonFund()
    external
    payable
{
    /*
    Quỹ dùng cho:
    - Điện
    - Nước
    - Wifi
    - Dịch vụ chung
    */
}
/*
-----------------------------------------------------
CHỦ NHÀ THANH TOÁN HÓA ĐƠN
-----------------------------------------------------
*/
function payBillFromCommonFund(
    uint256 amount,
    string memory description
)
    external
{
    /*
    Trừ tiền từ quỹ chung.
    Ví dụ:
    amount = 500000
    description =
    "Hoa don Internet thang 5"
    */
}
/*
-----------------------------------------------------
BỎ PHIẾU ĐUỔI THÀNH VIÊN
-----------------------------------------------------
*/
function voteToKick(
    address target
)
    external
{
    /*
    Mỗi roommate được bỏ phiếu
    một lần cho mỗi người.
    Nếu số phiếu > 50%
    thì người đó bị kick.
    */
}
/*
-----------------------------------------------------
THÀNH VIÊN TỰ RỜI ĐI
-----------------------------------------------------
*/
function leaveRoom()
    external
{
    /*
    Điều kiện:
    - Đã trả tiền tháng hiện tại
    Sau đó:
    - Trả lại tiền cọc
    - Hủy trạng thái active
    */
}
/*
-----------------------------------------------------
KẾT THÚC HỢP ĐỒNG
-----------------------------------------------------
*/
function terminateAgreement()
    external
{
    /*
    Sau khi hết hạn thuê:
    - Chủ nhà đóng hợp đồng
    - Hoàn tiền cọc
    - Kết thúc hệ thống
    */
}
/*
-----------------------------------------------------
THỐNG KÊ
-----------------------------------------------------
*/
/*
Đếm số roommate còn hoạt động
*/
function getActiveRoommateCount()
    public
    view
    returns(uint256)
{}
/*
Trả về toàn bộ danh sách roommate
*/
function getRoommateList()
    external
    view
    returns(address[] memory)
{}
/*
Kiểm tra có đang nợ tiền nhà hay không
*/
function isRentOverdue(
    address roommate
)
    external
    view
    returns(bool)
{}

}
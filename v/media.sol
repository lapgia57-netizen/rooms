// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract NomadJourney {
    // Trạng thái hành trình
    enum JourneyStatus {
        TAI_NHA,    // Đang ở nhà
        DI_DU_MUC,  // Đang đi du mục
        TRU_VE      // Đã trở về
    }

    // Cấu trúc lưu thông tin chuyến đi
    struct Trip {
        uint256 startTime;
        uint256 endTime;
        string destination;
        string experiences;
    }

    // Biến trạng thái
    address public owner;
    JourneyStatus public status;
    Trip[] public trips;
    uint256 public totalDays;

    // Sự kiện (events)
    event StartJourney(uint256 timestamp, string destination);
    event ReturnHome(uint256 timestamp, string experiences);
    event AddExperience(string experience);

    // Modifier: Chỉ owner mới thực thi
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    // Modifier: Chỉ khi đang ở nhà mới được đi
    modifier atHome() {
        require(status == JourneyStatus.TAI_NHA, "Already on journey");
        _;
    }

    // Modifier: Chỉ khi đang du mục mới được trở về
    modifier onJourney() {
        require(status == JourneyStatus.DI_DU_MUC, "Not on journey");
        _;
    }

    // Constructor: Khởi tạo chủ sở hữu hợp đồng
    constructor() {
        owner = msg.sender;
        status = JourneyStatus.TAI_NHA;
    }

    // Hàm bắt đầu du mục
    function startJourney(string memory _destination) external onlyOwner atHome {
        // Cập nhật trạng thái
        status = JourneyStatus.DI_DU_MUC;

        // Tạo chuyến đi mới
        Trip memory newTrip = Trip({
            startTime: block.timestamp,
            endTime: 0,
            destination: _destination,
            experiences: ""
        });
        trips.push(newTrip);

        emit StartJourney(block.timestamp, _destination);
    }

    // Hàm trở về nhà
    function returnHome(string memory _experiences) external onlyOwner onJourney {
        // Cập nhật trạng thái
        status = JourneyStatus.TRU_VE;

        // Cập nhật chuyến đi hiện tại
        uint256 lastIndex = trips.length - 1;
        trips[lastIndex].endTime = block.timestamp;
        trips[lastIndex].experiences = _experiences;

        // Tính số ngày du mục
        uint256 daysSpent = (block.timestamp - trips[lastIndex].startTime) / 1 days;
        totalDays += daysSpent;

        // Chuyển trạng thái về nhà sau khi trở về
        status = JourneyStatus.TAI_NHA;

        emit ReturnHome(block.timestamp, _experiences);
    }

    // Hàm thêm trải nghiệm mới (có thể gọi khi đang du mục hoặc đã về)
    function addExperience(string memory _experience) external onlyOwner {
        require(trips.length > 0, "No trip recorded");
        
        uint256 lastIndex = trips.length - 1;
        if (bytes(trips[lastIndex].experiences).length > 0) {
            // Nếu đã có experiences, nối thêm
            trips[lastIndex].experiences = string(abi.encodePacked(
                trips[lastIndex].experiences,
                "; ",
                _experience
            ));
        } else {
            trips[lastIndex].experiences = _experience;
        }

        emit AddExperience(_experience);
    }

    // Hàm reset hành trình (bắt đầu lại)
    function resetJourney() external onlyOwner {
        delete trips;
        totalDays = 0;
        status = JourneyStatus.TAI_NHA;
    }

    // Hàm xem thông tin chuyến đi gần nhất
    function getLastTrip() external view returns (uint256 start, uint256 end, string memory dest, string memory exp) {
        require(trips.length > 0, "No trips yet");
        Trip storage lastTrip = trips[trips.length - 1];
        return (lastTrip.startTime, lastTrip.endTime, lastTrip.destination, lastTrip.experiences);
    }

    // Hàm xem số lượng chuyến đi
    function getTripCount() external view returns (uint256) {
        return trips.length;
    }

    // Hàm lấy thông tin một chuyến đi cụ thể
    function getTrip(uint256 index) external view returns (Trip memory) {
        require(index < trips.length, "Index out of range");
        return trips[index];
    }

    // Hàm kiểm tra trạng thái hiện tại (dạng string)
    function getStatus() external view returns (string memory) {
        if (status == JourneyStatus.TAI_NHA) return "At Home";
        if (status == JourneyStatus.DI_DU_MUC) return "On Journey";
        if (status == JourneyStatus.TRU_VE) return "Returned";
        return "Unknown";
    }
}
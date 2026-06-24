// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/*
==================================================
QUẢN LÝ NHIỀU NƠI Ở CỦA MỘT NGƯỜI
==================================================
Ví dụ:
- Đang thuê phòng A
- Thuê thêm căn hộ B
Hợp đồng cho phép theo dõi:
- Địa chỉ nơi ở
- Ngày bắt đầu
- Ngày kết thúc
- Trạng thái hiện tại
*/
contract MultiResidenceRegistry {
    struct Residence {
        string residenceName;
        string location;
        uint256 startDate;
        uint256 endDate;
        bool active;
    }
    mapping(address => Residence[]) private residences;
    event ResidenceAdded(
        address indexed resident,
        string residenceName
    );
    event ResidenceClosed(
        address indexed resident,
        uint256 index
    );
    /*
    Thêm nơi ở mới
    */
    function addResidence(
        string memory _name,
        string memory _location,
        uint256 _endDate
    ) external {
        residences[msg.sender].push(
            Residence({
                residenceName: _name,
                location: _location,
                startDate: block.timestamp,
                endDate: _endDate,
                active: true
            })
        );
        emit ResidenceAdded(
            msg.sender,
            _name
        );
    }
    /*
    Kết thúc nơi ở
    */
    function closeResidence(
        uint256 _index
    ) external {
        require(
            _index < residences[msg.sender].length,
            "Khong ton tai"
        );
        residences[msg.sender][_index]
            .active = false;
        emit ResidenceClosed(
            msg.sender,
            _index
        );
    }
    /*
    Xem số nơi ở đã đăng ký
    */
    function getResidenceCount()
        external
        view
        returns(uint256)
    {
        return residences[msg.sender].length;
    }
    /*
    Xem thông tin nơi ở
    */
    function getResidence(
        uint256 _index
    )
        external
        view
        returns(
            string memory,
            string memory,
            uint256,
            uint256,
            bool
        )



    {
        Residence storage r =
            residences[msg.sender][_index];
        return (
            r.residenceName,
            r.location,
            r.startDate,
            r.endDate,
            r.active
        );
    }
}
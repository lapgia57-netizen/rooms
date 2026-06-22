// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ContentPublisher is Ownable, ReentrancyGuard {
    
    struct Content {
        uint256 id;
        address author;
        string title;
        string description;           // Nội dung văn bản chính
        string ipfsContentHash;       // IPFS hash của nội dung đầy đủ (markdown, json...)
        string[] imageIpfsHashes;     // Mảng hash nhiều hình ảnh
        string category;              // Ví dụ: "news", "blog", "art", "tutorial"
        uint256 timestamp;
        uint256 likes;
        bool isPublished;             // Có công khai hay không
        bool isDeleted;               // Soft delete
    }

    uint256 public contentCount;
    mapping(uint256 => Content) public contents;
    mapping(address => uint256[]) public userContents;     // Danh sách nội dung của từng user
    mapping(uint256 => mapping(address => bool)) public hasLiked; // Tránh like nhiều lần

    // Events
    event ContentCreated(uint256 indexed id, address indexed author, string title);
    event ContentUpdated(uint256 indexed id, address indexed author);
    event ContentPublished(uint256 indexed id, bool isPublished);
    event ContentLiked(uint256 indexed id, address indexed liker);
    event ContentDeleted(uint256 indexed id);

    constructor() Ownable(msg.sender) {}

    // ====================== MAIN FUNCTIONS ======================

    function createContent(
        string memory _title,
        string memory _description,
        string memory _ipfsContentHash,
        string[] memory _imageIpfsHashes,
        string memory _category
    ) external {
        require(bytes(_title).length > 0, "Title khong duoc de trong");
        require(bytes(_ipfsContentHash).length > 0, "IPFS content hash khong hop le");

        contentCount++;
        uint256 newId = contentCount;

        contents[newId] = Content({
            id: newId,
            author: msg.sender,
            title: _title,
            description: _description,
            ipfsContentHash: _ipfsContentHash,
            imageIpfsHashes: _imageIpfsHashes,
            category: _category,
            timestamp: block.timestamp,
            likes: 0,
            isPublished: true,
            isDeleted: false
        });

        userContents[msg.sender].push(newId);

        emit ContentCreated(newId, msg.sender, _title);
    }

    function updateContent(
        uint256 _id,
        string memory _title,
        string memory _description,
        string memory _ipfsContentHash,
        string[] memory _imageIpfsHashes,
        string memory _category
    ) external {
        Content storage content = contents[_id];
        require(content.author == msg.sender, "Chi tac gia moi duoc sua");
        require(!content.isDeleted, "Bai viet da bi xoa");

        content.title = _title;
        content.description = _description;
        content.ipfsContentHash = _ipfsContentHash;
        content.imageIpfsHashes = _imageIpfsHashes;
        content.category = _category;

        emit ContentUpdated(_id, msg.sender);
    }

    function togglePublish(uint256 _id) external {
        Content storage content = contents[_id];
        require(content.author == msg.sender || owner() == msg.sender, "Khong co quyen");
        require(!content.isDeleted, "Bai viet da bi xoa");

        content.isPublished = !content.isPublished;
        emit ContentPublished(_id, content.isPublished);
    }

    function likeContent(uint256 _id) external nonReentrant {
        Content storage content = contents[_id];
        require(content.id != 0, "Bai viet khong ton tai");
        require(!content.isDeleted, "Bai viet da bi xoa");
        require(!hasLiked[_id][msg.sender], "Da like roi");

        content.likes++;
        hasLiked[_id][msg.sender] = true;

        emit ContentLiked(_id, msg.sender);
    }

    function softDelete(uint256 _id) external {
        Content storage content = contents[_id];
        require(content.author == msg.sender || owner() == msg.sender, "Khong co quyen");
        content.isDeleted = true;
        emit ContentDeleted(_id);
    }

    // ====================== VIEW FUNCTIONS ======================

    function getContent(uint256 _id) external view returns (Content memory) {
        require(contents[_id].id != 0, "Bai viet khong ton tai");
        return contents[_id];
    }

    function getUserContents(address _user) external view returns (uint256[] memory) {
        return userContents[_user];
    }

    function getAllContents(uint256 start, uint256 limit) external view returns (Content[] memory) {
        uint256 end = start + limit > contentCount ? contentCount : start + limit;
        Content[] memory result = new Content[](end - start);
        uint256 counter = 0;

        for (uint256 i = start + 1; i <= end; i++) {
            if (!contents[i].isDeleted && contents[i].isPublished) {
                result[counter] = contents[i];
                counter++;
            }
        }
        // Cắt bớt mảng nếu có nội dung bị xóa
        assembly {
            mstore(result, counter)
        }
        return result;
    }

    // ====================== ADMIN FUNCTIONS ======================

    function adminDelete(uint256 _id) external onlyOwner {
        contents[_id].isDeleted = true;
        emit ContentDeleted(_id);
    }
}
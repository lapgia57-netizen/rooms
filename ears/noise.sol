// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract NoiseFilterManager {
    address public owner;
    
    // Cấu trúc dữ liệu audio
    struct AudioRecord {
        address uploader;
        string ipfsHash;        // Hash file audio gốc (IPFS/Arweave)
        string filteredIpfsHash; // Hash file sau lọc tạp âm
        uint256 timestamp;
        uint256 noiseLevel;     // Mức tạp âm ước tính (0-100)
        bool isApproved;
        uint256 upvotes;
    }
    
    mapping(uint256 => AudioRecord) public audioRecords;
    uint256 public recordCount;
    
    // Events
    event AudioUploaded(uint256 indexed recordId, address uploader, string ipfsHash);
    event AudioFiltered(uint256 indexed recordId, string filteredHash, uint256 noiseLevel);
    event AudioApproved(uint256 indexed recordId, address approver);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Chi owner moi duoc goi");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // Upload audio gốc
    function uploadAudio(string memory _ipfsHash, uint256 _estimatedNoise) external {
        require(bytes(_ipfsHash).length > 0, "IPFS hash khong hop le");
        
        recordCount++;
        audioRecords[recordCount] = AudioRecord({
            uploader: msg.sender,
            ipfsHash: _ipfsHash,
            filteredIpfsHash: "",
            timestamp: block.timestamp,
            noiseLevel: _estimatedNoise,
            isApproved: false,
            upvotes: 0
        });
        
        emit AudioUploaded(recordCount, msg.sender, _ipfsHash);
    }
    
    // Cập nhật kết quả sau khi lọc tạp âm (thường do oracle/off-chain service gọi)
    function updateFilteredAudio(
        uint256 _recordId, 
        string memory _filteredHash, 
        uint256 _finalNoiseLevel
    ) external onlyOwner {
        require(_recordId > 0 && _recordId <= recordCount, "Record khong ton tai");
        AudioRecord storage record = audioRecords[_recordId];
        
        record.filteredIpfsHash = _filteredHash;
        record.noiseLevel = _finalNoiseLevel;
        
        emit AudioFiltered(_recordId, _filteredHash, _finalNoiseLevel);
    }
    
    // Phê duyệt audio đã lọc (có thể dùng DAO voting)
    function approveAudio(uint256 _recordId) external {
        require(_recordId > 0 && _recordId <= recordCount, "Record khong ton tai");
        AudioRecord storage record = audioRecords[_recordId];
        require(!record.isApproved, "Da duoc approve roi");
        
        record.isApproved = true;
        emit AudioApproved(_recordId, msg.sender);
    }
    
    // Upvote (cộng đồng xác nhận chất lượng lọc)
    function upvote(uint256 _recordId) external {
        require(_recordId > 0 && _recordId <= recordCount, "Record khong ton tai");
        audioRecords[_recordId].upvotes++;
    }
    
    // Lấy thông tin record
    function getAudioRecord(uint256 _recordId) external view returns (AudioRecord memory) {
        require(_recordId > 0 && _recordId <= recordCount, "Record khong ton tai");
        return audioRecords[_recordId];
    }
    
    // Transfer ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner moi khong hop le");
        owner = newOwner;
    }
}
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.34;

/*
    This contract is a marketplace for music where users can buy and sell music tracks. 
    It allows artists to list their tracks for sale and buyers to purchase them using Ether. 
    The contract keeps track of the ownership of the tracks and ensures that only the rightful owner can sell them.
*/
contract MusicMarketplace {

    //Variables
    address public owner;
    uint8 public feePercentage;

    struct Track {
        uint256 id;
        string title;
        string artistName;
        uint256 price;
        address artistAddress;
    }

    struct Artist {
        string name;
        address artistAddress;
    }

    struct Purchase {
        uint256 trackId;
        address buyer;
        uint256 amountPaid;
    }

    Artist[] public artistList;
    Track[] public trackList;
    Purchase[] public purchaseList;

    mapping(address => uint256) private artistBalances; //mapping to track the balance of each artist
    mapping(address => Track[]) private artistTracks; //mapping to track the tracks listed by each artist

    mapping(bytes32 => bool) private artistNameExists;
    mapping(address => bool) private artistAddressExists;
    mapping(address => uint256) private artistIndex; //mapping to track the index of the artist in the artistList array
    mapping(address => mapping(uint256 => bool)) private buyerPurchases; //mapping to track the purchases made by each buyer


    constructor() {
        owner = msg.sender;
        feePercentage = 5; // 5% fee on each sale
    }

    //Modifiers
    modifier uniqueArtistName(string memory _name) {
        require(!artistNameExists[keccak256(bytes(_name))], "Artist name already exists");
        _;
    }

    modifier uniqueArtistAddress(address _artistAddress) {
        require(!artistAddressExists[_artistAddress], "Artist address already exists");
        _;
    }

    modifier onlyArtist() {
        require(artistAddressExists[msg.sender], "Only registered artists can perform this action");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action");
        _;
    }

    //Events
    event ArtistRegistered(string name, address artistAddress);
    event TrackRegistered(uint256 trackId, string title, string artistName, uint256 price, address artistAddress);
    event PurchaseRegistered(uint256 trackId, address buyer, uint256 amountPaid);

    //External Functions
    function donate() external payable {
        require(msg.value > 0, "Donation must be greater than 0");
    }

    /* Artist related functions (onlyArtist ROLE) */
    //1. Register as an artist
    function registerArtist(string memory _name) uniqueArtistName(_name) uniqueArtistAddress(msg.sender) external {
        artistList.push(Artist(_name, msg.sender));
        artistNameExists[keccak256(bytes(_name))] = true;
        artistAddressExists[msg.sender] = true;
        artistIndex[msg.sender] = artistList.length;
        emit ArtistRegistered(_name, msg.sender);
    }

    //2. Update artist name
    function updateArtistName(string memory _newName) uniqueArtistName(_newName) onlyArtist external {
        uint256 index = artistIndex[msg.sender] - 1;
        bytes32 oldNameHash = keccak256(bytes(artistList[index].name));
        artistNameExists[oldNameHash] = false;
        artistList[index].name = _newName;
        artistNameExists[keccak256(bytes(_newName))] = true;
    }

    //3. Register a track for sale
    function registerTrack(string memory _title, uint256 _price) onlyArtist external {
        require(_price > 0, "Price must be greater than 0");
        trackList.push(Track(trackList.length, _title, artistList[artistIndex[msg.sender] - 1].name, _price, msg.sender));
        artistTracks[msg.sender].push(Track(trackList.length, _title, artistList[artistIndex[msg.sender] - 1].name, _price, msg.sender));
        emit TrackRegistered(trackList.length - 1, _title, artistList[artistIndex[msg.sender] - 1].name, _price, msg.sender);
    }

    //5. Udate track price
    function updateTrackPrice(uint256 _trackId, uint256 _newPrice) onlyArtist external {
        require(_trackId < trackList.length, "Track does not exist");
        Track storage track = trackList[_trackId];
        require(track.artistAddress == msg.sender, "Only the artist who listed the track can update the price");
        require(_newPrice > 0, "Price must be greater than 0");
        track.price = _newPrice;
    }

    //4. Withdraw artist earnings
    function withdrawEarnings() onlyArtist external {
        uint256 balance = artistBalances[msg.sender];
        require(balance > 0, "No earnings to withdraw");
        artistBalances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    /* Buyers related functions. No roles required, anyone can buy tracks. Only once track purchase per wallet */
    // 1. Purchase a track
    function purchaseTrack(uint256 _trackId) external payable {
        require(_trackId < trackList.length, "Track does not exist");
        Track memory track = trackList[_trackId];
        require(msg.value == track.price, "Please enter the exact price to purchase the track");

        // Check if the buyer has already purchased the track. Else record the purchase
        require(!buyerPurchases[msg.sender][_trackId], "You have already purchased this track");
        buyerPurchases[msg.sender][_trackId] = true;

        // Calculate fee and update artist balance
        uint256 fee = (msg.value * feePercentage) / 100;
        artistBalances[track.artistAddress] += (msg.value - fee);

        // Record the purchase
        purchaseList.push(Purchase(_trackId, msg.sender, msg.value));
        emit PurchaseRegistered(_trackId, msg.sender, msg.value);
    }

    /* Admin functions */
    //1. Update fee percentage
    function updateFeePercentage(uint8 _newFeePercentage) onlyOwner external {
        require(_newFeePercentage <= 100, "Fee percentage must be between 0 and 100");
        feePercentage = _newFeePercentage;
    }

    //2. Withdraw contract balance
    function withdrawContractBalance() onlyOwner external {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No balance to withdraw");
        (bool success, ) = owner.call{value: contractBalance}("");
        require(success, "Withdrawal failed");
    }

    //Internal Functions
}
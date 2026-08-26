//SPDX-License-Identifier: MIT

//version 0.8.24
pragma solidity ^0.8.24;

/*
    This contract is a marketplace for music where users can buy and sell music tracks. 
    It allows artists to list their tracks for sale and buyers to purchase them using Ether. 
    The contract keeps track of the ownership of the tracks and ensures that only the rightful owner can sell them.

    Basic rules:
    1. Artists can list their tracks for sale by providing the track's metadata and price. (OK registerTrack())
    2. Buyers can purchase tracks by sending the required amount of Ether to the contract. (OK purchaseTrack())
    3. Any track can only be sold by its current owner.
    4. There are unlimited copies of each track available for sale.
    5. The contract will emit events for track listings, purchases, and ownership transfers to keep a record of all transactions.
    6. The contract will maintain a list of all artists and buyers who have interacted with the marketplace.
    7. The contract will provide functions to retrieve information about tracks, artists, and buyers.
    8. A user can be both an artist and a buyer, and the contract will handle their roles accordingly.
    9. A user can only purchase a track if they have enough Ether to cover the price of the track.
    10. A user can only buy a track once, and they will not be able to purchase the same track again.
    11. Users can register as artists by providing their name and address, and the contract will store this information for future reference.

*/
contract MusicMarketplace {

    //Variables
    //Marketplace owner and fee percentage
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

    mapping(address => int256) private artistBalances; //mapping to track the balance of each artist
    mapping(address => Track[]) private artistTracks; //mapping to track the tracks listed by each artist

    mapping(bytes32 => bool) private artistNameExists;
    mapping(address => bool) private artistAddressExists;
    mapping(address => uint256) private artistIndex; //mapping to track the index of the artist in the artistList array


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

    //Events
    event ArtistRegistered(string name, address artistAddress);
    event TrackRegistered(uint256 trackId, string title, string artistName, uint256 price, address artistAddress);
    event PurchaseRegistered(uint256 trackId, address buyer, uint256 amountPaid);

    //External Functions
    function donate() external payable {
        require(msg.value > 0, "Donation must be greater than 0");
    }

    function getArtists() external view returns (Artist[] memory) {
        return artistList;
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

    //4. Withdraw artist earnings
    function withdrawEarnings() onlyArtist external {
        int256 balance = artistBalances[msg.sender];
        require(balance > 0, "No earnings to withdraw");
        artistBalances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: uint256(balance)}("");
        require(success, "Withdrawal failed");
    }

    /* Buyers related functions. No roles required, anyone can buy tracks */
    // 1. Purchase a track
    function purchaseTrack(uint256 _trackId) external payable {
        require(_trackId < trackList.length, "Track does not exist");
        Track memory track = trackList[_trackId];
        require(msg.value >= track.price, "Insufficient funds to purchase the track");

        // Calculate fee and artist earnings
        uint256 fee = (msg.value * feePercentage) / 100;
        uint256 artistEarnings = msg.value - fee;

        // Update artist balance
        artistBalances[track.artistAddress] += int256(artistEarnings);

        // Record the purchase
        purchaseList.push(Purchase(_trackId, msg.sender, msg.value));
        emit PurchaseRegistered(_trackId, msg.sender, msg.value);
    }
    //Internal Functions
}
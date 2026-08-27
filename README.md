# music-marketplace

This contract is a marketplace for music where users can buy and sell music tracks. 
It allows artists to list their tracks for sale and buyers to purchase them using Ether. 
The contract keeps track of the ownership of the tracks and ensures that only the rightful owner can sell them.

Basic rules:
1. The deployer of the contract is the owner of the marketplace. He can set the fee percentage for each sale and withdraw the contract balance.
2. A user can be both an artist and a buyer, and the contract will handle their roles accordingly.
3. Any user can register as an artist and list their tracks for sale. The artist name must be unique.
4. Any artist can update their name and the price of their tracks.
5. Artists can withdraw their earnings from the sales of their tracks.
6. Buyers can purchase tracks by sending the required amount of Ether to the contract.
7. Any user can donate Ether to the contract, which will be added to the contract balance.
8. A user can only purchase a track if they have enough Ether to cover the price of the track.
9. There are unlimited copies of each track available for sale. But only one copy can be purchased by a buyer.
10. The contract will emit events for track listings and to keep a record of all transactions.
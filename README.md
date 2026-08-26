# music-marketplace
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

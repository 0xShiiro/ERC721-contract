// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMArketResale is IERC721Receiver, ReentrancyGuard {
    // constructor() IERC721Receiver() ReentrancyGuard() {}
    uint256 private _itemid = 0;
    uint256 private _itemSold = 0;

    address payable owner;
    uint256 private listing_fees = 0.0025 ether;

    struct Item {
        uint256 _id;
        uint256 _tokenid;
        address payable seller;
        address payable owner;
        uint256 price;
        bool isSold;
    }
    ERC721Enumerable nft;

    constructor(ERC721Enumerable _nft) {
        owner = payable(msg.sender);
        nft = _nft;
    }

    mapping(uint256 => Item) private ItemVault;

    event ItemListed(
        uint256 indexed _id,
        uint256 indexed _tokenid,
        address seller,
        address owner,
        uint256 price,
        bool isSold
    );

    function listSale(uint256 tokenId, uint256 price) public payable {
        require(msg.value == listing_fees, "Listing fees not met");
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "You are not the owner of this token"
        );
        require(price > 0, "Price must be greater than 0");
        require(msg.value == listing_fees, "Listing fees not met");
        _itemid++;
        ItemVault[_itemid] = Item(
            _itemid,
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        nft.transferFrom(msg.sender, address(this), tokenId);
        emit ItemListed(_itemid, tokenId, msg.sender, msg.sender, price, false);
    }

    function buyNFT(uint256 _id) public payable nonReentrant {
        Item storage item = ItemVault[_id];
        uint tokenId = item._tokenid;
        require(item._id != 0, "Item not found");
        require(!item.isSold, "Item already sold");
        require(msg.value == item.price, "Price not met");
        item.isSold = true;
        payable(msg.sender).transfer(listing_fees);
        item.seller.transfer(msg.value);
        nft.transferFrom(address(this), msg.sender, item._tokenid);
        _itemSold++;
        delete ItemVault[_id];
        delete ItemVault[tokenId];
    }

    function getItems() public view returns (Item[] memory) {
        uint itemcount = _itemid - _itemSold;
        Item[] memory items = new Item[](itemcount);
        for (uint256 i = 1; i <= itemcount; i++) {
            if (ItemVault[i].owner == address(this)) {
                items[i - 1] = ItemVault[i];
            }
        }
        return items;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot Send nfts to vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}

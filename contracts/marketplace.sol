//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Marketplace is Ownable {

    struct Order {
        uint256 id;
        uint256 tokenID;
        uint256 price;
        address tokenContract;
        address seller;
        bool filled;
    }

    event OrderCreated (
        uint256 id,
        uint256 tokenID,
        uint256 price,
        address tokenContract,
        address seller
    );

    uint256 internal orderID;

    mapping(uint256 => Order) internal orders;

    uint256 internal listingPrice;

    error InsufficienlistingPrice(
        uint256 required,
        uint256 provided
    );

    constructor(uint256 listingPrice_) {
        listingPrice = listingPrice_;
    }

    function getListingPrice() external view returns(uint256) {
        return listingPrice;
    }

    function setListingPrice(uint256 newPrice_) external onlyOwner() {
        listingPrice = newPrice_;
    }

    // @dev for putting nft up for sale
    // @param

    function createListingOrder(address tokenContract_, uint256 tokenID_, uint256 price_) external payable returns (bool success) {
        if(msg.value < listingPrice) revert InsufficienlistingPrice(listingPrice, msg.value);

        // transfer the token over;
        IERC721 tokenContract = IERC721(tokenContract_);
        tokenContract.safeTransferFrom(msg.sender, address(this), tokenID_);

        orderID++;
        Order storage newOrder = orders[orderID];
        newOrder.id = orderID;
        newOrder.tokenID = tokenID_;
        newOrder.price = price_;
        newOrder.tokenContract = tokenContract_;
        newOrder.seller = msg.sender;
        newOrder.filled = false;

        return true;
    }

    function cancelListingOrder(uint256 orderID_) external returns (bool success) {
        require(orderExist(orderID_), "no order exist with this ID");
        require(orders[orderID_].seller == msg.sender, "You cannot cancel order not created by you");
        delete orders[orderID_];
        return true;
    }
    
    function orderExist(uint256 orderID_) internal view returns(bool exist) {
        exist = orders[orderID_].id != 0;
    }

    function purchase(uint256 orderID_) external payable returns (bool success) {
        require(orderExist(orderID_), "order does not exist!");
        require(orders[orderID_].filled == false, "This token has been purchased!");
        require(msg.value == orders[orderID_].price, "insufficient amount!");
        Order storage order = orders[orderID_];
        IERC721 tokenContract = IERC721(order.tokenContract);
        tokenContract.safeTransferFrom(address(this), msg.sender, order.tokenID);
        order.filled = true;
        return true;
    }

    function getOrders() external view returns (Order[] memory) {

    }
}
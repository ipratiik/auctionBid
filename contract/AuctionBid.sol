// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AuctionBid {
    address public owner;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;
    bool public ended;
    mapping(address => uint256) public pendingReturns;

    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);

    error AuctionAlreadyEnded();
    error BidNotHighEnough(uint256 highestBid);
    error AuctionNotYetEnded();
    error AuctionEndAlreadyCalled();

    // auction duration fixed — no input required
    uint256 constant BIDDING_TIME = 5 minutes;   // you can change the duration here

    constructor() {
        owner = msg.sender;
        auctionEndTime = block.timestamp + BIDDING_TIME;
    }

    function bid() external payable {
        if (block.timestamp > auctionEndTime) revert AuctionAlreadyEnded();
        if (msg.value <= highestBid) revert BidNotHighEnough(highestBid);

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() external returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        if (amount > 0) {
            pendingReturns[msg.sender] = 0;
            if (!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function endAuction() external {
        if (block.timestamp < auctionEndTime) revert AuctionNotYetEnded();
        if (ended) revert AuctionEndAlreadyCalled();

        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        payable(owner).transfer(highestBid);
    }
}


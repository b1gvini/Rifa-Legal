// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./RifaToken.sol";

contract GerenciadorRifa {
    enum Status {
        CLOSED,
        OPEN
    }
    address[] private players;
    address private tokenAddress;
    address private owner;
    Status private lotteryStatus;

    modifier isOwner() {
        require(msg.sender == owner, "Sender not owner");
        _;
    }

    constructor(address token) {
        owner = msg.sender;
        tokenAddress = token;
        lotteryStatus = Status.CLOSED;
    }

    event BuyTicket(address indexed buyer, uint256 amount);
    event NewWinner(address indexed winner, uint256 amount);

    function buyTicket(uint256 amount) public returns (bool) {
        require(lotteryStatus == Status.OPEN, "Lottery closed");
        //require(amount == 500, "Ticket price: 500 tokens");
        RifaToken(tokenAddress).transferFrom(msg.sender, address(this), amount);
        players.push(msg.sender);
        emit BuyTicket(msg.sender, amount);
        return true;
    }

    function giftWinner() public isOwner returns (bool) {
        require(lotteryStatus == Status.OPEN, "Lottery closed");
        require(players.length > 0, "No players in the lottery");
        uint256 winnerIndex = random() % players.length;
        uint256 prizeAmount = RifaToken(tokenAddress).balanceOf(address(this));
        address winner = players[winnerIndex];
        RifaToken(tokenAddress).transfer(winner, prizeAmount);
        emit NewWinner(winner, prizeAmount);
        lotteryStatus = Status.CLOSED; // Optionally close the lottery after gifting
        players = new address[](0); // Optionally reset players for the next round
        return true;
    }

    function getValueGift() public view returns (uint256) {
        require(lotteryStatus == Status.OPEN, "Lottery closed");
        return RifaToken(tokenAddress).balanceOf(address(this));
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function statusOpen() public isOwner {
        lotteryStatus = Status.OPEN;
    }

    function statusClosed() public isOwner {
        lotteryStatus = Status.CLOSED;
    }

    function getStatusLottery() public view returns (Status) {
        return lotteryStatus;
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    // Função para receber ETH, não necessária se o contrato só trabalhar com MyToken
    receive() external payable {}
}
// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0 < 0.9.0;

contract Lottery {
    address public manager;
    address payable[] public players;
    address payable public winner;
    uint256 public ticketPrice;
    uint256 public minimumPlayers;
    uint256 public ticketCount;
    uint256 private ticketIndex;

    enum LotteryState { Open, Closed, Finished }
    LotteryState public currentState;

    event NewPlayerEntered(address indexed player);
    event LotteryClosed();
    event WinnerPicked(address indexed winner);

    constructor(uint256 _ticketPrice, uint256 _minimumPlayers) {
        manager = msg.sender;
        ticketPrice = _ticketPrice;
        minimumPlayers = _minimumPlayers;
        currentState = LotteryState.Open;
        ticketCount = 0;
        ticketIndex = 0;
    }

    modifier restricted() {
        require(msg.sender == manager, "Only the manager can call this function.");
        _;
    }

    function enter() public payable {
        require(currentState == LotteryState.Open, "Lottery is not currently open for entries.");
        require(msg.value == ticketPrice, "Ticket price must be equal to the required ticket price.");
        players.push(payable(msg.sender));
        ticketCount++;
        emit NewPlayerEntered(msg.sender);

        if (ticketCount >= minimumPlayers) {
            currentState = LotteryState.Closed;
            emit LotteryClosed();
        }
    }

    function pickWinner() public restricted {
        require(currentState == LotteryState.Closed, "Lottery must be closed before picking a winner.");
        require(ticketIndex < ticketCount, "No more players to pick a winner from.");

        uint256 randomIndex = random() % (ticketCount - ticketIndex);
        winner = players[randomIndex + ticketIndex];
        ticketIndex++;

        currentState = LotteryState.Finished;
        emit WinnerPicked(winner);

        payable(winner).transfer(address(this).balance);
    }

    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getCurrentState() public view returns (LotteryState) {
        return currentState;
    }
}

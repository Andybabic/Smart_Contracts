// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address private manager;
    address payable[] private players;
    address payable private winner;
    uint256 public ticketPrice;
    uint256 public minimumPlayers;
    uint256 public ticketCount;
    uint256 private ticketIndex;
    uint256 private timeoutToRestart;
    uint256 private timeoutStamp;

    enum LotteryState {
        Open,
        Closed,
        Joining,
        Finished
    }
    LotteryState private currentState;

    event NewPlayerEntered(address indexed player);
    event LotteryClosed();
    event WinnerPicked(address indexed winner);
    event CurrentStatus(LotteryState status);
    event TimeLeft(uint256 time);

    struct LastWinners {
        address id;
        bool isWinner;
    }

    LastWinners[] private lastWinners;

    constructor(
        uint256 _ticketPrice,
        uint256 _minimumPlayers,
        uint256 _timeoutToStart
    ) {
        manager = msg.sender;
        ticketPrice = _ticketPrice;
        minimumPlayers = _minimumPlayers;
        timeoutToRestart = _timeoutToStart;
        currentState = LotteryState.Open;
        ticketCount = 0;
        ticketIndex = 0;
    }

    modifier restricted() {
        require(
            msg.sender == manager,
            "Only the manager can call this function."
        );
        _;
    }

    function enter(uint256 _ticketPrice) public payable {
        if (timeoutStamp > block.timestamp) {
            string memory secondsLeft = getTimoutDifference();
            string memory err = string(
                abi.encodePacked(
                    "Lottery is not currently open for entries. Please wait ",
                    secondsLeft
                )
            );
            require(block.timestamp > timeoutStamp, err);
        }
        require(
            _ticketPrice >= ticketPrice,
            "Ticket price must be equal to the required ticket price."
        );
        require(
            !this.hasPlayerEntered(msg.sender),
            "This Player has already entered"
        );
        currentState = LotteryState.Open;
        players.push(payable(msg.sender));
        ticketCount++;
        emit NewPlayerEntered(msg.sender);

        if (ticketCount >= minimumPlayers) {
            currentState = LotteryState.Closed;
            emit LotteryClosed();
            pickWinner();
            timeoutStamp = block.timestamp + timeoutToRestart;
        }
    }

    function pickWinner() public restricted {
        require(
            currentState == LotteryState.Closed,
            "Lottery must be closed before picking a winner."
        );
        require(
            ticketIndex < ticketCount,
            "No more players to pick a winner from."
        );

        uint256 randomIndex = random() % (ticketCount - ticketIndex);
        winner = players[randomIndex + ticketIndex];
        ticketIndex++;

        currentState = LotteryState.Finished;
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == winner) {
                lastWinners.push(LastWinners(winner, true));
            } else {
                lastWinners.push(LastWinners(winner, false));
            }
        }
        emit WinnerPicked(winner);
        payable(winner).transfer(address(this).balance);
        delete players;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.prevrandao,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function getTimoutDifference()
        private
        view
        returns (string memory timeLeft)
    {
        return
            string(
                abi.encodePacked(timeoutStamp - block.timestamp, " seconds")
            );
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getCurrentState() public view returns (LotteryState) {
        return currentState;
    }

    function hasPlayerEntered(address player) public view returns (bool) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == player) {
                return true; // Player is found in the array
            }
        }
        return false; // Player is not found in the array
    }

    function checkIfWinner() public view returns (LastWinners memory myPlayer) {
        require(lastWinners.length > 0, "There are no Winners yet.");
        for (uint256 i = 0; i < lastWinners.length; i++) {
            if (lastWinners[i].id == msg.sender) {
                return lastWinners[i];
            }
        }
        return LastWinners(address(0), false);
    }
}

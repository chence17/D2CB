// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
import "./SafeMath.sol";
import "./Strings.sol";


contract D2CB {
    using SafeMath for uint;
    using Strings for *;
    struct lottery {
        uint8[6] redNumber;
        uint8 blueNumber;
    }
    struct lotteries {
        lottery[] data;
        bool isValid;
    }
    mapping(address => lotteries) public database;
    address payable public chairman;
    address payable[] public players;
    lottery public prizeLottery;
    mapping(address => uint[6]) public prizeResult;
    uint[6] public prizeQuantity = [0, 0, 0, 0, 0, 0];
    uint[6] public prizeAmount = [0, 0, 0, 0, 0, 0];
    // Accumulate, Current
    uint[2] public prizePool = [0, 0];

    enum state {OPEN, CLOSED, CALCULATING}
    state public lotteryState;
    // .01 ETH
    // 1 ETH = 10e3 Finney
    // 1 ETH = 10e9 GWei
    // 1 ETH = 10e18 Wei
    uint public tokenPerBet = 10e15; // 0.01 ETH = 10 Finney = 10e16 Wei
    // 期数
    uint public lotteryId;
    uint public maximumBet;
    uint public currentBet;

    constructor() public {
        lotteryId = 0;
        lotteryState = state.CLOSED;
    }

    function startNewLottery(uint betQuantity) public {
        require(lotteryState == state.CLOSED, "Already Started!");
        lotteryState = state.OPEN;
        lotteryId = lotteryId + 1;
        maximumBet = betQuantity;
        currentBet = 0;
        chairman = payable(msg.sender);
        prizePool[0] = address(this).balance;
        prizePool[1] = 0;
        for (uint i=0; i<players.length; i++){
            delete database[players[i]];
            delete prizeResult[players[i]];
        }
        delete players;
        delete prizeLottery;
        delete prizeQuantity;
        delete prizeAmount;
    }

    function parseBetString(string memory betString) public pure returns(uint8[] memory){
        Strings.slice memory betData = betString.toSlice();
        Strings.slice memory delim = " ".toSlice();
        uint8[] memory parts = new uint8[](betData.count(delim) + 1);
        for(uint i = 0; i < parts.length; i++) {
            parts[i] = uint8(Strings.stringToUint(betData.split(delim).toString()));
        }
        return parts;
    }

    function parseBetNumber(uint8[] memory betNumber) public pure returns(string memory){
        string memory s = "";
        string memory delim = " ";
        for(uint i = 0; i < betNumber.length; i++) {
            s = string(abi.encodePacked(s, Strings.uintToString(betNumber[i]), delim));
        }
        return s;
    }

    function getRedNumber(uint8[] memory betNumber) public pure returns(uint8[6] memory){
        uint8[6] memory redNumber;
        for(uint i=0; i<6; i++){
            redNumber[i] = betNumber[i];
        }
        return redNumber;
    }

    function bet(string memory betString) public payable {
        require(msg.value>=tokenPerBet, "Value Invalid!");
        // RBN_1 RBN_2 RBN_3 RBN_4 RBN_5 RBN_6 BBN_1
        require(lotteryState == state.OPEN, "Not Start Yet!");
        uint8[] memory betNumber = parseBetString(betString);
        require(betNumber.length==7, "Single Bet Number Invalid!");
        lottery memory betLottery;
        betLottery.redNumber = getRedNumber(betNumber);
        betLottery.blueNumber = betNumber[6];
        if (database[msg.sender].isValid) {
            database[msg.sender].data.push(betLottery);
        } else {
            database[msg.sender].isValid = true;
            database[msg.sender].data.push(betLottery);
            players.push(payable(msg.sender));
        }
        currentBet = currentBet+1;
        // chairman.transfer(tokenPerBet);
    }

    function fulfillLottery() public {
        require(msg.sender==chairman, "Only Chairman Can Do This!");
        require(lotteryState == state.OPEN, "Not Start Yet!");
        lotteryState = state.CALCULATING;
        generatePrizeLottery();
        calculatePrize();
        distributePrize();
        lotteryState = state.CLOSED;
    }

    function generatePrizeLottery() public {
        require(lotteryState == state.CALCULATING, "Only When Calculationg Can Do This!");
        // uint randNonce = 0;
        // prizeLottery.blueNumber = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, randNonce)))%16) + 1;
        // for(uint i=0; i<6; i++){
        //     randNonce = randNonce+1;
        //     prizeLottery.redNumber[i] = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, randNonce)))%33) + 1;
        // }
        prizeLottery.blueNumber = 8;
        prizeLottery.redNumber[0] = 2;
        prizeLottery.redNumber[1] = 10;
        prizeLottery.redNumber[2] = 15;
        prizeLottery.redNumber[3] = 17;
        prizeLottery.redNumber[4] = 23;
        prizeLottery.redNumber[5] = 27;
    }

    function checkRedNumber(uint8[6] memory redNumber) public view returns(uint){
        require(lotteryState == state.CALCULATING, "Only When Calculationg Can Do This!");
        uint validNumber = 0;
        for (uint i=0; i<6; i++){
            for (uint j=0; j<6; j++){
                if (redNumber[i]==prizeLottery.redNumber[j]){
                    validNumber = validNumber+1;
                    break;
                }
            }
        }
        return validNumber;
    }

    function calculatePrize() public {
        require(lotteryState == state.CALCULATING, "Only When Calculationg Can Do This!");
        prizePool[1] = SafeMath.sub(address(this).balance, prizePool[0]);
        prizeQuantity = [0, 0, 0, 0, 0, 0];
        prizeAmount = [0, 0, 0, 0, 0, 0];
        for (uint i=0; i<players.length; i++){
            prizeResult[players[i]] = [0, 0, 0, 0, 0, 0];
            for (uint j=0; j<database[players[i]].data.length; j++){
                uint blueCorrect = 0;
                if (database[players[i]].data[j].blueNumber==prizeLottery.blueNumber){
                    blueCorrect = 1;
                }
                uint redCorrect = checkRedNumber(database[players[i]].data[j].redNumber);
                if (blueCorrect==1){
                    if (redCorrect==6){
                        prizeResult[players[i]][0]++;
                        prizeQuantity[0]++;
                    } else if (redCorrect==5){
                        prizeResult[players[i]][2]++;
                        prizeQuantity[2]++;
                    } else if (redCorrect==4){
                        prizeResult[players[i]][3]++;
                        prizeQuantity[3]++;
                    } else if (redCorrect==3){
                        prizeResult[players[i]][4]++;
                        prizeQuantity[4]++;
                    } else if (redCorrect==2){
                        prizeResult[players[i]][5]++;
                        prizeQuantity[5]++;
                    } else if (redCorrect==1){
                        prizeResult[players[i]][5]++;
                        prizeQuantity[5]++;
                    } else if (redCorrect==0){
                        prizeResult[players[i]][5]++;
                        prizeQuantity[5]++;
                    }
                } else {
                    if (redCorrect==4){
                        prizeResult[players[i]][4]++;
                        prizeQuantity[4]++;
                    } else if (redCorrect==5){
                        prizeResult[players[i]][3]++;
                        prizeQuantity[3]++;
                    } else if (redCorrect==6){
                        prizeResult[players[i]][1]++;
                        prizeQuantity[1]++;
                    }
                }
            }
        }
        // 3rd Prize
        prizeAmount[2] = SafeMath.mul(tokenPerBet, 600);
        // 4th Prize
        prizeAmount[3] = SafeMath.mul(tokenPerBet, 40);
        // 5th Prize
        prizeAmount[4] = SafeMath.mul(tokenPerBet, 2);
        // 6th Prize
        prizeAmount[5] = SafeMath.mul(tokenPerBet, 1);
        uint usedPrize = 0;
        usedPrize = SafeMath.add(usedPrize, SafeMath.mul(prizeAmount[5], prizeQuantity[5]));
        usedPrize = SafeMath.add(usedPrize, SafeMath.mul(prizeAmount[4], prizeQuantity[4]));
        usedPrize = SafeMath.add(usedPrize, SafeMath.mul(prizeAmount[3], prizeQuantity[3]));
        usedPrize = SafeMath.add(usedPrize, SafeMath.mul(prizeAmount[2], prizeQuantity[2]));
        uint highestPrize = SafeMath.sub(prizePool[1], usedPrize);
        // 2nd Prize
        if (prizeQuantity[1]==0){
            prizeAmount[1] = 0;
        } else {
            prizeAmount[1] = SafeMath.div(SafeMath.div(SafeMath.mul(highestPrize, 1), 4), prizeQuantity[1]);
        }
        // 1st Prize
        if (prizeQuantity[0]==0){
            prizeAmount[0] = 0;
        } else {
            prizeAmount[0] = SafeMath.div(SafeMath.add(SafeMath.div(SafeMath.mul(highestPrize, 3), 4), prizePool[0]), prizeQuantity[0]);
        }
    }

    function distributePrize() public {
        require(lotteryState == state.CALCULATING, "Only When Calculationg Can Do This!");
        for (uint i=0; i<players.length; i++){
            uint prizeValue = 0;
            for (uint j=0; j<6; j++){
                prizeValue = SafeMath.add(prizeValue, SafeMath.mul(prizeResult[players[i]][j], prizeAmount[j]));
            }
            if (prizeValue!=0){
                players[i].transfer(prizeValue);
            }
        }
    }

    function querryBetInformation() public view returns(string memory){
        require((lotteryState == state.OPEN)||(lotteryState == state.CLOSED), "Only When OPEN or CLOSED Can Do This!");
        if (database[msg.sender].isValid){
            string memory s = "";
            for (uint i=0; i<database[msg.sender].data.length; i++){
                for(uint j=0; j<6; j++){
                    s = string(abi.encodePacked(s, Strings.uintToString(database[msg.sender].data[i].redNumber[j]), " "));
                }
                s = string(abi.encodePacked(s, Strings.uintToString(database[msg.sender].data[i].blueNumber), "\n"));
            }
            return s;
        } else {
            return "";
        }
    }

    function querryPrizeInformation() public view returns(string memory){
        require(lotteryState == state.CLOSED, "Only When CLOSED Can Do This!");
        if (database[msg.sender].isValid){
            string memory s = "";
            for (uint i=0; i<6; i++){
                s = string(abi.encodePacked(s, Strings.uintToString(prizeResult[msg.sender][i]), " "));
            }
            s = string(abi.encodePacked(s, "\n"));
            for (uint i=0; i<6; i++){
                s = string(abi.encodePacked(s, Strings.uintToString(SafeMath.mul(prizeResult[msg.sender][i], prizeAmount[i])), " "));
            }
            return s;
        } else {
            return "";
        }
    }

    function addressToString(address account) public pure returns(string memory) {
        bytes memory data = abi.encodePacked(account);
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function querryPlayers() public view returns (string memory){
        require(lotteryState == state.OPEN, "Only When OPEN Can Do This!");
        string memory s = "";
        for(uint i=0; i<players.length; i++){
            s = string(abi.encodePacked(s, addressToString(players[i]), "\n"));
        }
        return s;
    }

    function querryChairman() public view returns (string memory){
        require(lotteryState == state.OPEN, "Only When OPEN Can Do This!");
        return addressToString(chairman);
    }

    function querryBalance() public view returns (uint) {
        return address(this).balance;
    }

    function querryLotteryState() public view returns(string memory){
        if (lotteryState == state.OPEN){
            return "OPEN";
        } else if (lotteryState == state.CLOSED){
            return "CLOSED";
        } else if (lotteryState == state.CALCULATING){
            return "CALCULATING";
        } else {
            return "Error";
        }
    }

    function querryAccPrizePool() public view returns(uint) {
        require((lotteryState == state.OPEN)||(lotteryState == state.CLOSED), "Only When OPEN or CLOSED Can Do This!");
        return prizePool[0];
    }

    function querryCurPrizePool() public view returns(uint) {
        require((lotteryState == state.OPEN)||(lotteryState == state.CLOSED), "Only When OPEN or CLOSED Can Do This!");
        return SafeMath.sub(address(this).balance, prizePool[0]);
    }

    function querryPrizeLottery() public view returns(string memory) {
        require(lotteryState == state.CLOSED, "Only When CLOSED Can Do This!");
        string memory s = "";
        string memory delim = " ";
        for(uint i = 0; i < 6; i++) {
            s = string(abi.encodePacked(s, Strings.uintToString(prizeLottery.redNumber[i]), delim));
        }
        s = string(abi.encodePacked(s, Strings.uintToString(prizeLottery.blueNumber)));
        return s;
    }

    function querryPrizeQuantity() public view returns(string memory) {
        require(lotteryState == state.CLOSED, "Only When CLOSED Can Do This!");
        string memory s = "";
        for(uint i = 0; i < 6; i++) {
            s = string(abi.encodePacked(s, Strings.uintToString(prizeQuantity[i]), " "));
        }
        return s;
    }

    function querryPrizeAmount() public view returns(string memory) {
        require(lotteryState == state.CLOSED, "Only When CLOSED Can Do This!");
        string memory s = "";
        string memory delim = " ";
        for(uint i = 0; i < 6; i++) {
            s = string(abi.encodePacked(s, Strings.uintToString(prizeAmount[i]), delim));
        }
        return s;
    }

    function querryLotteryId() public view returns(uint) {
        return lotteryId;
    }

    function querryMaximumBet() public view returns(uint) {
        require(lotteryState == state.OPEN, "Only When OPEN Can Do This!");
        return maximumBet;
    }

    function querryCurrentBet() public view returns(uint) {
        require(lotteryState == state.OPEN, "Only When OPEN Can Do This!");
        return currentBet;
    }

    function deposit() public payable {}

}

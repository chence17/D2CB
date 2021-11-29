pragma solidity ^0.6.6;

contract Governance {
    uint256 public oneTime;
    address public lottery;
    address public randomness;
    constructor() public {
        oneTime = 1;
    }
    function init(address _lottery, address _randomness) public {
        require(_randomness != address(0), "no-randomnesss-address");
        require(_lottery != address(0), "no-lottery-address-given");
        //require(oneTime > 0, "can-only-be-called-once");
        //one_time = oneTime - 1;
        randomness = _randomness;
        lottery = _lottery;
    }
}

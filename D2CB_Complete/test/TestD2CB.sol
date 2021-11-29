pragma solidity ^0.6.6;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/D2CB.sol";

contract TestD2CB {

  function testParseBetNumber() public {
    D2CB d = D2CB(DeployedAddresses.D2CB());

    address payable expected;
    d.startNewLottery(10);

    // Assert.equal(d.querryChairman(), expected, "Wrong!");
  }
}

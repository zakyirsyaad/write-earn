// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract WriteToEarn is Ownable {
    constructor() Ownable(msg.sender) {}
}

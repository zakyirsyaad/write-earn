// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;


contract WriteAI is ERC20 {
    constructor() ERC20("WriteAI", "WAI") {
        _mint(msg.sender, 1000000000000000000000000);
    }
}

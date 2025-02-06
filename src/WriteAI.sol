// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract WriteAI is ERC20, Ownable {
    // Events
    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);

    constructor() ERC20("WriteAI", "WAI") Ownable(msg.sender) {
        _mint(msg.sender, 1000000000000000000000000); // 1 million tokens with 18 decimals
    }

    // Allow owner to mint new tokens
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    // Allow users to burn their tokens
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
}

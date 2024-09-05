// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable2Step {
    address private minter;

    constructor() Ownable(msg.sender) ERC20("Reward", "RWD") {}

    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    modifier onlyMinter() {
        require(minter == msg.sender, "Only minter allowed to mint");
        _;
    }
}

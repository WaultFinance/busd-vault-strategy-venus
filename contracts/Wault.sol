//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IBEP20.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/SafeMath.sol";
import "./libraries/ERC20.sol";

import "hardhat/console.sol";

contract Wault is ERC20 {
    using SafeERC20 for IBEP20;
    using Address for address;
    using SafeMath for uint256;

    address public governance;
    address public deployer;

    uint256 public INITIAL_SUPPLY = 100000000; // 100,000,000

    modifier onlyGovernance {
        require(msg.sender == governance, "!governance");
        _;
    }
    
    constructor() 
        ERC20("Wault Finance", "WAULT")
    {
        governance = msg.sender;
        deployer = msg.sender;

        _mint(governance, INITIAL_SUPPLY.mul(1e18));
    }

    function setGovernance(address _governance) onlyGovernance external {
        require(msg.sender == governance || msg.sender == deployer, "!governance or deployer");
        governance = _governance;
    }

    function mint(address _to, uint _amount) external onlyGovernance {
        _mint(_to, _amount);
    }
}
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IController.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/ERC20.sol";

import "hardhat/console.sol";

contract WaultValutBusd is ERC20, IVault {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;

    uint256 public min = 10000;
    uint256 public constant max = 10000;

    address public governance;
    address public controller;

    constructor(address _token, address _controller) 
        ERC20(
            string(abi.encodePacked("Wault ", ERC20(_token).name())),
            string(abi.encodePacked("wault", ERC20(_token).symbol()))
        )
    {
        token = IERC20(_token);
        governance = msg.sender;
        controller = _controller;
    }

    function balance() public view returns (uint) {
        return token.balanceOf(address(this)) + IController(controller).balanceOf(address(token));
    }

    function setMin(uint256 _min) external {
        require(msg.sender == governance, "!governance");
        min = _min;
    }
    
    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) public {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function available() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function getPricePerFullShare() public override view returns (uint) {
        return balance().mul(1e18).div(totalSupply());
    }

    function invest() internal {
        // TODO [#1]: Maybe need to check for minimum invest something like
        // if it have more than 0.1 Tokens then invest to save gas fee
        uint256 availableBalance = available();
        token.safeTransfer(controller, availableBalance);
        IController(controller).invest(address(token), availableBalance);
    }

    function deposit(uint256 _amount) public override {
        uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _amount;
        } else {
            shares = (_amount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
        invest();
    }

    function depositAll() external override {
        deposit(token.balanceOf(msg.sender));
    }

    function withdraw(uint256 _shares) public override {
        uint256 _send = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint256 _before = token.balanceOf(address(this));
        if (_before < _send) {
            uint256 _withdraw = _send.sub(_before);
            IController(controller).withdraw(address(token), _withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(_before);
            if (_diff < _withdraw) {
                _send = _before.add(_diff);
            }
        }

        token.safeTransfer(msg.sender, _send);
    }

    function withdrawAll() external override {
        withdraw(balanceOf(msg.sender));
    }
}
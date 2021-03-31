//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IController.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/SafeMath.sol";
import "../libraries/ERC20.sol";

import "hardhat/console.sol";

contract WaultBusdVault is ERC20, IVault {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    IERC20 public token;

    uint256 public min = 10;
    uint256 public constant max = 10000;

    address public governance;
    address public strategist = address(0xC627D743B1BfF30f853AE218396e6d47a4f34ceA);
    address public controller;

    modifier onlyAdmin {
        require(msg.sender == governance || msg.sender == strategist, "!governance or strategist");
        _;
    }

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

    function setMin(uint256 _min) external onlyAdmin {
        min = _min;
    }
    
    function setGovernance(address _governance) public onlyAdmin {
        governance = _governance;
    }

    function setStrategist(address _strategist) public onlyAdmin {
        strategist = _strategist;
    }

    function setController(address _controller) public onlyAdmin {
        controller = _controller;
    }

    function available() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    function invest() internal {
        // TODO [#1]: Maybe need to check for minimum invest something like
        // if it have more than 0.1 Tokens then invest to save gas fee
        uint256 availableBalance = available();
        token.safeTransfer(controller, availableBalance);
        IController(controller).invest(address(token), availableBalance);
    }

    function deposit(uint256 _amount) public override {
        require(_amount >= min.mul(1e18), "deposit amount is too small");

        // uint256 _pool = balance();
        uint256 _before = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _after = token.balanceOf(address(this));
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint256 shares = _amount;
        // if (totalSupply() > 0) {
        //     shares = (_amount.mul(totalSupply())).div(_pool);
        // }
        _mint(msg.sender, shares);
        invest();
    }

    function depositAll() external override {
        deposit(token.balanceOf(msg.sender));
    }

    function withdraw(uint256 _shares) public override {
        // uint256 _send = (balance().mul(_shares)).div(totalSupply());
        if (balanceOf(msg.sender) < _shares) _shares = balanceOf(msg.sender);
        require(_shares > 0, "!available balance");

        _burn(msg.sender, _shares);

        // Check balance
        uint256 _before = token.balanceOf(address(this));
        if (_before < _shares) {
            uint256 _withdraw = _shares.sub(_before);
            IController(controller).withdraw(address(token), _withdraw);
            uint256 _after = token.balanceOf(address(this));
            uint256 _diff = _after.sub(_before);
            if (_diff < _withdraw) {
                _shares = _before.add(_diff);
            }
        }

        token.safeTransfer(msg.sender, _shares);
    }

    function withdrawAll() external override {
        withdraw(balanceOf(msg.sender));
    }

    function balanceOfRewards(address _user) external view returns (uint256 _rewards, uint256 _waults) {
        require(_user != address(0), "invalid address");
        (_rewards, _waults) = IController(controller).balanceOfRewards(address(token), _user);
    }

    function claimSome(uint256 _amount) public {
        require(_amount > 0, "invalid amount");

        IController(controller).claim(address(token), _amount);
    }

    function claim() external {
        (,uint256 _waults) = IController(controller).balanceOfRewards(address(token), msg.sender);
        claimSome(_waults);
    }

    function emergencyWithdraw() external onlyAdmin {
        withdraw(balance());
    }
}
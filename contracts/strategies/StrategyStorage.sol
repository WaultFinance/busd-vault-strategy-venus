//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IController.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/SafeMath.sol";

contract StrategyStorage {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public controller;
    address public governance;
    address public strategist = address(0xC627D743B1BfF30f853AE218396e6d47a4f34ceA);
    address public harvester;
    
    uint256 public _performanceFee = 450;
    uint256 public _strategistReward = 0;
    uint256 public _withdrawalFee = 0;
    uint256 public _harvesterReward = 0;
    uint256 internal _withdrawalMax = 10000;
    uint256 public constant FEE_DENOMINATOR = 10000;
    uint256 public blocksPerMin = 20;

    uint256 public targetBorrowLimit;
    uint256 public targetBorrowUnit;

    bool public paused;

    modifier onlyController {
        require(msg.sender == controller, "!controller");
        _;
    }

    modifier onlyGovernance {
        require(msg.sender == governance, "!governance");
        _;
    }

    function setGovernance(address _governance) external onlyGovernance {
        governance = _governance;
    }

    function setController(address _controller) external onlyGovernance {
        controller = _controller;
    }

    function setStrategist(address _strategist) external onlyGovernance {
        strategist = _strategist;
    }

    function setHarvester(address _harvester) external onlyGovernance {
        harvester = _harvester;
    }

    function setPerformanceFee(uint256 performanceFee) external onlyGovernance {
        require(msg.sender == governance, "!governance");
        _performanceFee = performanceFee;
    }

    function setStrategistReward(uint256 strategistReward) external onlyGovernance {
        require(msg.sender == governance, "!governance");
        _strategistReward = strategistReward;
    }

    function setWithdrawalFee(uint256 withdrawalFee) external onlyGovernance {
        require(msg.sender == governance, "!governance");
        _withdrawalFee = withdrawalFee;
    }

    function setHarvesterReward(uint256 harvesterReward) external onlyGovernance {
        require(msg.sender == governance, "!governance");
        _harvesterReward = harvesterReward;
    }

    function setBlocksPerMin(uint256 _blocks) external onlyGovernance {
        blocksPerMin = _blocks;
    }

    function vaults(address underlying) public view returns (address) {
        return IController(controller).vaults(underlying);
    }

    function getFee(uint amount) public view returns (uint) {
        return amount.mul(_withdrawalFee).div(FEE_DENOMINATOR);
    }

    function _sendToVaultWithFee(address underlying, uint amount) internal {
        uint256 _fee = getFee(amount);
        if (_fee > 0) {
            IERC20(underlying).safeTransfer(IController(controller).rewards(), _fee);
        }
        _sendToVault(underlying, amount.sub(_fee));
    }

    function _sendToVault(address underlying, uint256 amount) internal {
        address vault = vaults(underlying);
        require(vault != address(0), "Not a vault!");
        IERC20(underlying).safeTransfer(vault, amount);
    }
    function _sendToWalletWithFee(address underlying, address recipient, uint256 amount) internal {
        uint256 _fee = getFee(amount);
        require(recipient != address(0), "Not a vault!");
        IERC20(underlying).safeTransfer(recipient, amount.sub(_fee));
        if (_fee > 0) {
            IERC20(underlying).safeTransfer(IController(controller).rewards(), _fee);
        }
    }
}

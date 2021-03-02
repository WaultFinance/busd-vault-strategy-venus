//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBEP20.sol";

// interface IFToken is IBEP20 {
abstract contract IFToken is IBEP20 {

    uint256 public totalBorrows;

    uint256 public reserveFactor;

    function mint(address user, uint256 amount) external virtual returns (bytes memory);

    function borrow(address borrower, uint256 borrowAmount)
        external virtual
        returns (bytes memory);

    function withdraw(
        address payable withdrawer,
        uint256 withdrawTokensIn,
        uint256 withdrawAmountIn
    ) external virtual returns (uint256, bytes memory);

    function underlying() external virtual view returns (address);

    function accrueInterest() external virtual;

    function getAccountState(address account)
        external virtual
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function MonitorEventCallback(
        address who,
        bytes32 funcName,
        bytes calldata payload
    ) external virtual;

    //用户存借取还操作后的兑换率
    function exchangeRateCurrent() external virtual view returns (uint256 exchangeRate);

    function repay(address borrower, uint256 repayAmount)
        external virtual
        returns (uint256, bytes memory);

    function borrowBalanceStored(address account)
        external virtual
        view
        returns (uint256);

    function exchangeRateStored() external virtual view returns (uint256 exchangeRate);

    function liquidateBorrow(
        address liquidator,
        address borrower,
        uint256 repayAmount,
        address fTokenCollateral
    ) external virtual returns (bytes memory);

    function borrowBalanceCurrent(address account) external virtual returns (uint256);

    function balanceOfUnderlying(address owner) external virtual returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external virtual;

    function _addReservesFresh(uint256 addAmount) external virtual;

    function cancellingOut(address striker)
        external virtual
        returns (bool strikeOk, bytes memory strikeLog);

    function APR() external virtual view returns (uint256);

    function APY() external virtual view returns (uint256);

    function calcBalanceOfUnderlying(address owner)
        external virtual
        view
        returns (uint256);

    function borrowSafeRatio() external virtual view returns (uint256);

    function tokenCash(address token, address account)
        external virtual
        view
        returns (uint256);

    function getBorrowRate() external virtual view returns (uint256);

    function addTotalCash(uint256 _addAmount) external virtual;
    function subTotalCash(uint256 _subAmount) external virtual;

    function totalCash() external virtual view returns (uint256);
    function totalReserves() external virtual view returns (uint256);
}
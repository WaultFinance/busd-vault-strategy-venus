// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategy {
    function want() external view returns (address);

    function deposit() external;

    // Controller | Vault role - withdraw should always return to Vault
    function withdraw(uint256) external;

    // Controller | Vault role - withdraw should always return to Vault
    function withdrawAll() external returns (uint256);

    function balanceOf() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);
    
    function supplyRatePerBlock() external view returns (uint256);
}
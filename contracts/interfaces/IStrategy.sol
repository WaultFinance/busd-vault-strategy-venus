// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategy {
    function getWant() external view returns (address);

    function deposit() external;

    // Controller | Vault role - withdraw should always return to Vault
    function withdraw(uint256) external;

    // Controller role - withdraw should always return to recipient wallet directly
    function withdraw(address, uint256) external;

    // Controller | Vault role - withdraw should always return to Vault
    function withdrawAll() external returns (uint256);

    function withdrawAsWault(address, uint256) external returns (uint256);

    function harvest() external returns (uint256);

    function balanceOf() external view returns (uint256);

    function withdrawalFee() external view returns (uint256);
    
    function supplyRatePerBlock() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyXvsRatePerBlock() external returns (uint256);
    
    function borrowXvsRatePerBlock() external returns (uint256);

    function totalSupplyApy() external returns (uint256);

    function totalApy() external returns (uint256);

    function venusSpeeds() external returns (uint256, uint256, uint256);

    function borrowLimit() external view returns (uint256);

    function totalVTokenSupply() external view returns (uint256);

    function totalVTokenBorrows() external returns (uint256);

    function pause() external;

    function unpause() external;
}
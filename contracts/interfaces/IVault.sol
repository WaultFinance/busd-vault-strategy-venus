//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IVault {
    // // Returns the unwrapped native token address that the Vault takes as deposit.
    // function token() external view returns (address);

    // // Returns the vault’s wrapped token name as a string, e.g. “yearn Dai Stablecoin".
    // function name() external view returns (string memory);

    // // Returns the vault’s wrapped token symbol as a string, e.g. “yDai”.
    // function symbol() external view returns (string memory);

    // // Returns the amount of decimals for this vault’s wrapped token as a uint8.
    // function decimals() external view returns (uint8);

    // The calculation is nativeTokenBalance / yTokenTotolSupply
    function getPricePerFullShare() external view returns (uint256);

    // Deposits the specified amount of the native unwrapped token (same as token() returns) into the Vault.
    function deposit(uint256) external;

    // Deposits the maximum available amount of the native unwrapped token (same as token() returns) into the Vault.
    function depositAll() external;

    // Withdraws the specified amount of the native unwrapped token (same as token() returns) from the Vault.
    function withdraw(uint256) external;

    // Withdraws the maximum available amount of the native unwrapped token (same as token() returns) from the Vault.
    function withdrawAll() external;
}
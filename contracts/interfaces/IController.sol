// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IController {
    function withdraw(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function invest(address, uint256) external;

    function rewards() external view returns (address);

    function vaults(address) external view returns (address);

    function strategies(address) external view returns (address);

    function balanceOfRewards(address _token, address _user) external view returns (uint256 _rewards, uint256 _waults);

    function claim(address _token, uint256 _amount) external;
}
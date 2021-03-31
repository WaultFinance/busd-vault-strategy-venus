// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapRouter {
  function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountsOut(
      uint amountIn,
      address[] memory path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
      uint amountOut,
      address[] memory path
    ) external view returns (uint[] memory amounts);
}
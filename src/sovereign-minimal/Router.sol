// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ISovereignPool } from "@valantislabs/contracts/pools/interfaces/ISovereignPool.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SovereignPoolSwapContextData, SovereignPoolSwapParams } from "@valantislabs/contracts/pools/structs/SovereignPoolStructs.sol";

contract Router {
    mapping(address => mapping(address => address)) public getPool;
    address[] public allPools;

    event PoolAdded(address indexed token0, address indexed token1, address pool);

    function addPool(address token0, address token1, address pool) external {
        require(getPool[token0][token1] == address(0) && getPool[token1][token0] == address(0), "Pool already exists");
        getPool[token0][token1] = pool;
        getPool[token1][token0] = pool;
        allPools.push(pool);
        emit PoolAdded(token0, token1, pool);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts) {
        require(path.length >= 2, "Invalid path");

        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            address input = path[i];
            address output = path[i + 1];
            address pool = getPool[input][output];
            require(pool != address(0), "Pool does not exist");

            IERC20(input).transferFrom(msg.sender, pool, amounts[i]);

            bool isZeroToOne = input == ISovereignPool(pool).token0();

            (amounts[i + 1]) = _executeSwap(
                isZeroToOne,
                amounts[i],
                amountOutMin,
                deadline,
                to,
                output,
                pool
            );
        }

        require(amounts[amounts.length - 1] >= amountOutMin, "Insufficient output amount");
    }

    function _executeSwap(
        bool isZeroToOne,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address to,
        address output,
        address pool
    ) internal returns (uint256 amountOut) {
        (/*uint256 amountInUsed*/, uint256 swapAmountOut) = ISovereignPool(pool).swap(
            SovereignPoolSwapParams({
                isSwapCallback: false,
                isZeroToOne: isZeroToOne,
                amountIn: amountIn,
                amountOutMin: amountOutMin,
                deadline: deadline,
                recipient: to,
                swapTokenOut: output,
                swapContext: SovereignPoolSwapContextData({
                    externalContext: "",
                    verifierContext: "",
                    swapFeeModuleContext: "",
                    swapCallbackContext: ""
                })
            })
        );

        return swapAmountOut;
    }

    function addLiquidity(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) external {
        address pool = getPool[token0][token1];
        require(pool != address(0), "Pool does not exist");

        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);

        IERC20(token0).approve(pool, amount0);
        IERC20(token1).approve(pool, amount1);

        ISovereignPool(pool).depositLiquidity(
            amount0,
            amount1,
            msg.sender,
            "",
            ""
        );
    }

    function removeLiquidity(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        address to
    ) external {
        address pool = getPool[token0][token1];
        require(pool != address(0), "Pool does not exist");

        ISovereignPool(pool).withdrawLiquidity(
            amount0,
            amount1,
            msg.sender,
            to,
            ""
        );
    }
}

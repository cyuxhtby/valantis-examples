// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ISovereignPool } from "@valantislabs/contracts/pools/interfaces/ISovereignPool.sol";
import { IExtendedSovereignALM } from "./interfaces/IExtendedSovereignALM.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SovereignPoolSwapContextData, SovereignPoolSwapParams } from "@valantislabs/contracts/pools/structs/SovereignPoolStructs.sol";
import "forge-std/console.sol";

contract Router {
    
    error Router__InvalidPath();
    error Router__PoolAlreadyExists();
    error Router__ZeroAmount();
    error Router__PoolDoesNotExist();
    error Router__InsufficientOutputAmount();

    mapping(address => mapping(address => address)) public getPool;
    address public alm;
    address[] public allPools;

    event PoolAdded(address indexed token0, address indexed token1, address pool);

    function setALM(address _alm) external {
        alm = _alm;
    }

    function addPool(address token0, address token1, address pool) external {
        if (getPool[token0][token1] != address(0) || getPool[token1][token0] != address(0)) {
            revert Router__PoolAlreadyExists();
        }
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
        if (path.length < 2) revert Router__InvalidPath();
        if (amountIn == 0) revert Router__ZeroAmount();

        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        address pool = getPool[path[0]][path[1]];
        if (pool == address(0)) revert Router__PoolDoesNotExist();

        uint256 currentSwapFeeBips = ISovereignPool(pool).defaultSwapFeeBips();

        uint256 fee = (amountIn * currentSwapFeeBips) / 10000;
        uint256 amountInAfterFee = amountIn - fee;

        for (uint256 i; i < path.length - 1; i++) {
            amounts[i + 1] = _swapTokens(
                path[i],
                path[i + 1],
                amounts[i],
                amountInAfterFee,
                amountOutMin,
                to,
                deadline
            );
        }

        if (amounts[amounts.length - 1] < amountOutMin) {
            revert Router__InsufficientOutputAmount();
        }
        }

    function _swapTokens(
        address input,
        address output,
        uint256 amountIn,
        uint256 amountInAfterFee,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) internal returns (uint256 amountOut) {
        address swapPool = getPool[input][output];
        if (swapPool == address(0)) revert Router__PoolDoesNotExist();

        IERC20(input).transferFrom(msg.sender, swapPool, amountIn);

        bool isZeroToOne = input == ISovereignPool(swapPool).token0();

        amountOut = _executeSwap(
            isZeroToOne,
            amountInAfterFee,
            amountOutMin,
            deadline,
            to,
            output,
            swapPool
        );
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
        if (pool == address(0)) revert Router__PoolDoesNotExist();

        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);

        IERC20(token0).approve(alm, amount0);
        IERC20(token1).approve(alm, amount1);

        IERC20(token0).approve(pool, amount0);
        IERC20(token1).approve(pool, amount1);

        IExtendedSovereignALM(alm).depositLiquidity(amount0, amount1, abi.encode(msg.sender));
    }

    function removeLiquidity(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        address to
    ) external {
        address pool = getPool[token0][token1];
        if (pool == address(0)) revert Router__PoolDoesNotExist();

        IExtendedSovereignALM(alm).withdrawLiquidity(amount0, amount1, 0, 0, to, "");
    }

    function onDepositLiquidityCallback(uint256 _amount0, uint256 _amount1, bytes memory _data) external {}
}
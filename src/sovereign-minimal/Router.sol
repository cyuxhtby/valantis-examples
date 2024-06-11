// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ISovereignPool } from "@valantislabs/contracts/pools/interfaces/ISovereignPool.sol";
import { IExtendedSovereignALM } from "./interfaces/IExtendedSovereignALM.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SovereignPoolSwapContextData, SovereignPoolSwapParams } from "@valantislabs/contracts/pools/structs/SovereignPoolStructs.sol";
import "forge-std/console.sol";

contract Router {
    mapping(address => mapping(address => address)) public getPool;
    address public alm;
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
        require(path.length >= 2, "Router: invalid path");

        require(amountIn > 0, "Router: zero amount");

        amounts = new uint256[](path.length);
        amounts[0] = amountIn;

        address pool = getPool[path[0]][path[1]];
        require(pool != address(0), "Router: invalid path");

        // uint256 currentSwapFeeBips = ISovereignPool(pool).getCurrentSwapFeeBips();

        // uint256 fee = (amountIn * currentSwapFeeBips) / 10000;
        // uint256 amountInAfterFee = amountIn - fee;

        uint256 fee = (amountIn * ISovereignPool(pool).defaultSwapFeeBips() / 10000);
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

        require(amounts[amounts.length - 1] >= amountOutMin, "Router: insufficient output amount");
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
        require(swapPool != address(0), "Router: invalid path");

        // IERC20(input).approve(swapPool, amountIn); // Redundant

        // Transfer from msg.sender to pool
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
        console.log("_executeSwap called with:");
        console.log("isZeroToOne:", isZeroToOne);
        console.log("amountIn:", amountIn);
        console.log("amountOutMin:", amountOutMin);
        console.log("deadline:", deadline);
        console.log("to:", to);
        console.log("output:", output);
        console.log("pool:", pool);

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

        console.log("swapAmountOut:", swapAmountOut);
        console.log("amountIn:", amountIn);
        console.log("amountOutMin:", amountOutMin);
        console.log("swapAmountOut:", swapAmountOut);

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

        console.log("Router token0 allowance for pool before approve:", IERC20(token0).allowance(address(this), pool));
        console.log("Router token1 allowance for pool before approve:", IERC20(token1).allowance(address(this), pool));

        IERC20(token0).approve(pool, amount0);
        IERC20(token1).approve(pool, amount1);

        console.log("Router token0 allowance for pool after approve:", IERC20(token0).allowance(address(this), pool));
        console.log("Router token1 allowance for pool after approve:", IERC20(token1).allowance(address(this), pool));

        console.log("Router token0 balance before transfer:", IERC20(token0).balanceOf(address(this)));
        console.log("Router token1 balance before transfer:", IERC20(token1).balanceOf(address(this)));
        require(IERC20(token0).balanceOf(address(this)) >= amount0, "Router: insufficient token0 balance");
        require(IERC20(token1).balanceOf(address(this)) >= amount1, "Router: insufficient token1 balance");

        IERC20(token0).transfer(alm, amount0);
        IERC20(token1).transfer(alm, amount1);

        console.log("Router token0 balance after transfer:", IERC20(token0).balanceOf(address(this)));
        console.log("Router token1 balance after transfer:", IERC20(token1).balanceOf(address(this)));

        console.log("ALM token0 balance after transfer:", IERC20(token0).balanceOf(alm));
        console.log("ALM token1 balance after transfer:", IERC20(token1).balanceOf(alm));

        console.log("ALM token0 balance before deposit:", IERC20(token0).balanceOf(alm));
        console.log("ALM token1 balance before deposit:", IERC20(token1).balanceOf(alm));

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
        require(pool != address(0), "Pool does not exist");

        ISovereignPool(pool).withdrawLiquidity(
            amount0,
            amount1,
            alm,
            to,
            ""
        );
    }

    function onDepositLiquidityCallback(uint256 _amount0, uint256 _amount1, bytes memory _data) external {}

    function setALM(address _alm) external {
        alm = _alm;
    }
}

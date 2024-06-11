// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ISovereignALM } from "@valantislabs/contracts/ALM/interfaces/ISovereignALM.sol";

/**
    @title Extended Sovereign ALM interface
    @notice Extends the ISovereignALM interface to include the depositLiquidity function required by the Router
 */
interface IExtendedSovereignALM is ISovereignALM {
     /**
        @notice Allows the router to deposit liquidity into the ALM.
        @param _amount0 Amount of token0 being deposited.
        @param _amount1 Amount of token1 being deposited.
        @param _data Context data passed by the ALM.
        @return amount0Deposited Actual amount of token0 deposited.
        @return amount1Deposited Actual amount of token1 deposited.
     */
    function depositLiquidity(uint256 _amount0, uint256 _amount1, bytes memory _data) external returns (uint256 amount0Deposited, uint256 amount1Deposited);
}
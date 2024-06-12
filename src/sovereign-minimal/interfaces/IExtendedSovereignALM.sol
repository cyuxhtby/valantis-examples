// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ISovereignALM } from "@valantislabs/contracts/ALM/interfaces/ISovereignALM.sol";

 /**
    @title Extended Sovereign ALM interface
    @notice Extends the ISovereignALM interface to include liquidity provisioning functions required by router
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

    /**
        @notice Allows the router to withdraw liquidity from the ALM.
        @param _amount0 Amount of token0 to withdraw.
        @param _amount1 Amount of token1 to withdraw.
        @param _minAmount0 Minimum amount of token0 to receive.
        @param _minAmount1 Minimum amount of token1 to receive.
        @param _recipient Address to receive the withdrawn tokens.
        @param _verificationContext Additional context data.
     */
    function withdrawLiquidity(
        uint256 _amount0,
        uint256 _amount1,
        uint256 _minAmount0,
        uint256 _minAmount1,
        address _recipient,
        bytes memory _verificationContext
    ) external;
}
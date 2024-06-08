// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISovereignVaultMinimal} from "@valantislabs/contracts/pools/interfaces/ISovereignVaultMinimal.sol";
import {ISovereignPool} from "@valantislabs/contracts/pools/interfaces/ISovereignPool.sol";

contract SovereignVault is ISovereignVaultMinimal {
    using SafeERC20 for IERC20;

    error SovereignVault__getReservesForPool_invalidPool();
    error SovereignVault__claimPoolManagerFees_onlyPool();
    error SovereignVault__quoteToRecipient_onlyALM();

    ISovereignPool public pool;
    address public alm;

    function setPool(address _pool) external {
        pool = ISovereignPool(_pool);
    }

    function setALM(address _alm) external {
        alm = _alm;
    }

    function getTokensForPool(address) external view override returns (address[] memory tokens) {
        tokens = new address[](2);
        tokens[0] = pool.token0();
        tokens[1] = pool.token1();
        // TODO: Support for additional tokens for multi-hop swaps
    }

    function getReservesForPool(address _pool, address[] calldata _tokens)
        external
        view
        override
        returns (uint256[] memory)
    {
        if (_pool != address(pool)) revert SovereignVault__getReservesForPool_invalidPool();

        uint256[] memory reserves = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            reserves[i] = IERC20(_tokens[i]).balanceOf(address(this));
        }

        return reserves;
    }

    function quoteToRecipient(bool _isZeroToOne, uint256 _amount, address) external {
        if (msg.sender != alm) revert SovereignVault__quoteToRecipient_onlyALM();

        if (_amount == 0) return;

        if (_isZeroToOne) {
            IERC20(pool.token1()).safeApprove(address(pool), _amount);
        } else {
            IERC20(pool.token0()).safeApprove(address(pool), _amount);
        }
    }

    function claimPoolManagerFees(uint256 _feePoolManager0, uint256 _feePoolManager1) external override {
        if (msg.sender != address(pool)) revert SovereignVault__claimPoolManagerFees_onlyPool();

        IERC20(pool.token0()).safeTransfer(msg.sender, _feePoolManager0);
        IERC20(pool.token1()).safeTransfer(msg.sender, _feePoolManager1);
    }
}

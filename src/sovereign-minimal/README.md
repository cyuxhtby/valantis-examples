# Sovereign Pool Minimal Implementation

Minimal implementation of a Valantis enabled DEX using the Sovereign Pool and an Algorithmic Liquidity Module (AML).

## Contracts

- `SovereignPool.sol`: Manages liquidity deposits, withdrawals, and user interactions. Acts as the core pool and main entry point for the DEX.
- `SovereignALM.sol`: Handles the underlying pricing logic for swaps. This modules offers an open design space, but this implementation enforces a standard x*y=k invariant.

## How to Use

1. Deploy `SovereignALM.sol`.
2. Deploy `SovereignPool.sol` with the address of the deployed `SovereignALM`.
3. Interact with `SovereignPool.sol` for all user actions like adding/removing liquidity and swapping tokens.

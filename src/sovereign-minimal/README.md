# Sovereign Pool Minimal Implementation

Minimal implementation of a Valantis enabled DEX using the Sovereign Pool and an Algorithmic Liquidity Module (AML).

## Contracts

- `SovereignPool.sol`: While capable of supporting multiple Valantis modules, with this minimal implementation it primarily serves as a reserve storage for a single token pair.
- `SovereignALM.sol`: Handles the underlying pricing logic for swaps. This modules offers an open design space, but this implementation enforces a standard x*y=k invariant.
- `SovereignPoolFactory.sol`: Responsible for deploying `SovereignPool` contracts for new token pairs. 
- `Router.sol`: Facilitates multi-token swaps and acts as the main entry point for user interactions.

## How to Use

1. Deploy `SovereignALM.sol`.
2. Deploy `Router.sol.`
2. Deploy `SovereignPoolFactory.sol` with the address of the Router.
3. Use `SovereignPoolFactory.sol` to deploy `SovereignPool` with the address of the deployed `SovereignALM`.
4. Deploy `Router.sol` and configure it to interact with the `SovereignPools`.
5. Interact with `Router.sol` for all user actions like adding/removing liquidity and swapping tokens.


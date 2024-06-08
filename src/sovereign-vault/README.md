# Sovereign Pool with Sovereign Vault Implementation

This DEX is built using the Valantis Sovereign Pool, an Algorithmic Liquidity Module, and a Sovereign Vault. The Valantis SovereignVault serves as a dedicated liquidity hub for multiple assets, it facilitates multi-hop swaps between assets and reduces liquidity fragmentation for protocols wishing to incorporate it.
 
## Contracts

- `SovereignVault.sol`: A dedicated composable vault for holding all LP reserves between liquidity provisions and swaps.
- `SovereignPool.sol`: Entrypoint contract that interacts with liquidity providers and traders, delegating its token0 and token1 reserves to the SovereignVault.
- `SovereignALM.sol`: Handles underlying pricing logic for swaps.
- `SovereignPoolFactory.sol`: Deploys and initializes SovereignPool instances.

## How to Use

1. Deploy `SovereignVault.sol`.
2. Deploy `SovereignALM.sol`.
3. Deploy `SovereignPoolFactory.sol`.
4. Use `SovereignPoolFactory.sol` to deploy `SovereignPool` with the address of the deployed `SovereignALM` and `SovereignVault`.
5. Interact with `SovereignPool.sol` for all user actions like adding/removing liquidity and swapping tokens.
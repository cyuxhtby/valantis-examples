// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IPoolDeployer } from '@valantislabs/contracts/protocol-factory/interfaces/IPoolDeployer.sol';

import { SovereignPool } from './SovereignPool.sol';
import { SovereignPoolConstructorArgs } from '@valantislabs/contracts/pools/structs/SovereignPoolStructs.sol';

interface IRouter {
    function addPool(address token0, address token1, address pool) external;
    function getPool(address token0, address token1) external view returns (address pool);
}

/// @notice modified SovereignPoolFactory to work with router
contract SovereignPoolFactory is IPoolDeployer {
    /************************************************
     *  STORAGE
     ***********************************************/

    /**
        @notice Stores router address for registering new pairs
     */
    address public immutable router;

    /**
        @notice Nonce used to derive unique CREATE2 salts. 
     */
    uint256 public nonce;

    /************************************************
     *  Events
     ***********************************************/
    event PoolCreated(address indexed token0, address indexed token1, address pool);

    /************************************************
     *  Constructor
     ***********************************************/

    constructor(address _router) {
        router = _router;
    }
    /************************************************
     *  EXTERNAL FUNCTIONS
     ***********************************************/

    function deploy(bytes32, bytes calldata _constructorArgs) external override returns (address deployment) {
        SovereignPoolConstructorArgs memory args = abi.decode(_constructorArgs, (SovereignPoolConstructorArgs));

        // Salt to trigger a create2 deployment,
        // as create is prone to re-org attacks
        bytes32 salt = keccak256(abi.encode(nonce, block.chainid, _constructorArgs));
        deployment = address(new SovereignPool{ salt: salt }(args));

        nonce++;

        // Check if the pool already exists for a given pair
        require(IRouter(router).getPool(args.token0, args.token1) == address(0), "Pool already exists");

        IRouter(router).addPool(args.token0, args.token1, deployment);
        emit PoolCreated(args.token0, args.token1, deployment);
    }
}

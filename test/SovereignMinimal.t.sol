// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {SovereignPool} from "../src/sovereign-minimal/SovereignPool.sol";
import {SovereignALM} from "../src/sovereign-minimal/SovereignALM.sol";
import {SovereignPoolFactory} from "../src/sovereign-minimal/SovereignPoolFactory.sol";
import {Router} from "../src/sovereign-minimal/Router.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    SovereignPoolConstructorArgs,
    SovereignPoolSwapParams,
    SovereignPoolSwapContextData
} from "@valantislabs/contracts/pools/structs/SovereignPoolStructs.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract SovereignMinimalTest is Test {
    SovereignPoolFactory public factory;
    SovereignPool public pool;
    SovereignALM public alm;
    Router public router;
    MockToken public token0;
    MockToken public token1;

    address public deployer = address(0x1234);
    address public user = address(0x5678);

    function setUp() public {
        token0 = new MockToken("USDC", "USDC");
        token1 = new MockToken("DAI", "DAI");

        token0.mint(user, 1000e18);
        token1.mint(user, 1000e18);

        vm.prank(deployer);
        alm = new SovereignALM(address(pool));

        vm.prank(deployer);
        router = new Router();

        vm.prank(deployer);
        factory = new SovereignPoolFactory(address(router));

        SovereignPoolConstructorArgs memory args = SovereignPoolConstructorArgs({
            token0: address(token0),
            token1: address(token1),
            sovereignVault: address(0), // Not in use
            verifierModule: address(0), // Not in use
            protocolFactory: address(factory),
            poolManager: deployer, 
            isToken0Rebase: false,
            isToken1Rebase: false,
            token0AbsErrorTolerance: 0,
            token1AbsErrorTolerance: 0,
            defaultSwapFeeBips: 0
        });
        vm.prank(deployer);
        pool = new SovereignPool(args);

        vm.prank(deployer);
        pool.setALM(address(alm));

        router.addPool(address(token0), address(token1), address(pool), address(alm));

        vm.startPrank(user);
        token0.approve(address(router), 1000e18);
        token1.approve(address(router), 1000e18);
        vm.stopPrank();
    }

}

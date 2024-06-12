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
        router = new Router();

        vm.prank(deployer);
        factory = new SovereignPoolFactory(address(router));

        SovereignPoolConstructorArgs memory args = SovereignPoolConstructorArgs({
            token0: address(token0),
            token1: address(token1),
            sovereignVault: address(0), // Not in use
            verifierModule: address(0), // Not in use
            protocolFactory: address(factory),
            poolManager: deployer, // Set deployer as pool manager
            isToken0Rebase: false,
            isToken1Rebase: false,
            token0AbsErrorTolerance: 0,
            token1AbsErrorTolerance: 0,
            defaultSwapFeeBips: 0
        });
        vm.prank(deployer);
        pool = new SovereignPool(args);

        alm = new SovereignALM(address(pool));

        vm.prank(deployer);
        pool.setALM(address(alm));

        vm.prank(deployer);
        router.setALM(address(alm));

        router.addPool(address(token0), address(token1), address(pool));

        vm.startPrank(user);
        token0.approve(address(router), type(uint256).max);
        token1.approve(address(router), type(uint256).max);
        vm.stopPrank();

        // vm.prank(address(router));
        // token0.approve(address(alm), type(uint256).max);
        // token1.approve(address(alm), type(uint256).max);
    }

    function testAddLiquidity() public {
        uint256 amount0 = 500e18;
        uint256 amount1 = 500e18;

        // assertEq(token0.allowance(user, address(router)), type(uint256).max);
        // assertEq(token1.allowance(user, address(router)), type(uint256).max);

        vm.prank(user);
        router.addLiquidity(address(token0), address(token1), amount0, amount1);

        console.log("ALM token0 balance after addLiquidity:", token0.balanceOf(address(alm)));
        console.log("ALM token1 balance after addLiquidity:", token1.balanceOf(address(alm)));
        console.log("User token0 balance after addLiquidity:", token0.balanceOf(user));
        console.log("User token1 balance after addLiquidity:", token1.balanceOf(user));
        console.log("Pool token0 balance after addLiquidity:", token0.balanceOf(address(pool)));
        console.log("Pool token1 balance after addLiquidity:", token1.balanceOf(address(pool)));
        console.log("Router token0 allowance after addLiquidity:", token0.allowance(user, address(router)));
        console.log("Router token1 allowance after addLiquidity:", token1.allowance(user, address(router)));

        assertEq(token0.balanceOf(address(pool)), amount0);
        assertEq(token1.balanceOf(address(pool)), amount1);
    }

    function testRemoveLiquidity() public {
        uint256 amount0 = 500e18;
        uint256 amount1 = 500e18;

        vm.prank(user);
        router.addLiquidity(address(token0), address(token1), amount0, amount1);

        vm.prank(user);
        router.removeLiquidity(address(token0), address(token1), amount0, amount1, user);

        // Assert that user's balance is restored
        assertEq(token0.balanceOf(address(user)), 1000e18);
        assertEq(token1.balanceOf(address(user)), 1000e18);

        // Assert that the pool's balance is zero
        assertEq(token0.balanceOf(address(pool)), 0);
        assertEq(token1.balanceOf(address(pool)), 0);
    }

    function testSwap() public {
        uint256 amount0 = 500e18;
        uint256 amount1 = 500e18;
        uint256 swapAmount = 100e18;

        vm.prank(user);
        router.addLiquidity(address(token0), address(token1), amount0, amount1);

        // Transfer swapAmount from the user to the router
        vm.prank(user);
        token0.transfer(address(router), swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token1);
        vm.prank(user);
        uint256[] memory amounts = router.swapExactTokensForTokens(
            swapAmount,
            1, // amountOutMin
            path, // path
            user, // to
            block.timestamp + 1 hours
        );

        uint256 fee = (swapAmount * 30) / 10000; // 0.3% fee
        uint256 amountInAfterFee = swapAmount - fee;
        uint256 amountOut = amounts[1];

        console.log("Calculated fee:", fee);
        console.log("Amount in after fee:", amountInAfterFee);
        console.log("Amount out:", amountOut);

        assertEq(token0.balanceOf(address(user)), 400e18 - swapAmount);
        assertEq(token1.balanceOf(address(user)), 500e18 + amountOut);

        assertEq(token0.balanceOf(address(pool)), 700e18);
        assertEq(token1.balanceOf(address(pool)), 500e18 - amountOut);
    }

}
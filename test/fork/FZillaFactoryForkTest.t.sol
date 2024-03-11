// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";


//1 factory 
//2 router
//3 mint tokens
//4 pair creation
//5 addlquidity
//6 swap!

contract FZillaFactoryTest is Test {
    IFZillaFactory ifzillaFactory;
    IFZillaERC20 ifzillaERC20;
    ERC20Mock tokenA;
    ERC20Mock tokenB;

    address feeTo = 0x42913243e1cD5591aDAfB9A134f1362B8e86499C;
    address feeToSetter = 0x6A396A60775F4951f4E033eBC01f13a24023a092;

    address user = makeAddr("user");
    

    function setUp() public {
        require(block.chainid == 314, "Not on correct network");
        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();
        ifzillaFactory = IFZillaFactory(0xD4745e9442c40942F6f4f252b223229160F8dc71);
        ifzillaERC20 = IFZillaERC20(0xc3f11c20C6cbe40089A428f0C9559aDf42DeDEcE);
    }

    //fee tests

    function test_getFeeReceiver() public {
        assertEq(ifzillaFactory.feeTo(), feeTo);
        assertEq(ifzillaFactory.feeToSetter(), feeToSetter);
    }

    function test_feeSetterCanChangeFeeTo() public {
        address newFeeToAddress = makeAddr("feeToNew");
        vm.prank(feeToSetter);
        ifzillaFactory.setFeeTo(newFeeToAddress);
        assertEq(ifzillaFactory.feeTo(), newFeeToAddress);
    }

    function test_feeSetterCanChangeFeeToSetter() public {
        address newFeeToSetterAddress = makeAddr("feeToNewSetter");
        vm.prank(feeToSetter);
        ifzillaFactory.setFeeToSetter(newFeeToSetterAddress);
        assertEq(ifzillaFactory.feeToSetter(), newFeeToSetterAddress);
    }

    function test_createPair() public {
        address user = makeAddr("user");
        vm.deal(user, 1e18);

        vm.startPrank(user);
        tokenA.mint(user, 1e18);
        tokenB.mint(user, 1e18);

        uint256 amountOfPairsBeforeCreation = ifzillaFactory.allPairsLength();
        ifzillaFactory.createPair(address(tokenA), address(tokenB));
        
        uint256 amountOfPairsAfterCreation = ifzillaFactory.allPairsLength();
        assertEq((amountOfPairsBeforeCreation + 1), amountOfPairsAfterCreation);

        vm.stopPrank();
    }

    function test_cantCreatePairIfAlreadyExists() public {
        address user = makeAddr("user");
        vm.deal(user, 1e18);

        vm.startPrank(user);
        tokenA.mint(user, 1e18);
        tokenB.mint(user, 1e18);

        ifzillaFactory.createPair(address(tokenA), address(tokenB));
        vm.expectRevert("FZilla: PAIR_EXISTS");
        ifzillaFactory.createPair(address(tokenA), address(tokenB));

        vm.stopPrank();
    }
    


}


//using interfaces and these contracts because of solidity complier versions

interface IFZillaFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


interface IFZillaERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}
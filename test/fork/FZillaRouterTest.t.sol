// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";


//1 factory 
//2 router
//3 mint tokens
//4 pair creation
//5 addlquidity
//6 swap!

contract FZillaRouterTest is Test {
    IFZillaFactory ifzillaFactory;
    IFZillaPair ifzillaPair;
    IFZillaRouter02 ifzillaRouter;
    IERC20 iWeth;
    ERC20Mock tokenA;
    ERC20Mock tokenB;

    address[] path;

    address user = makeAddr("user");
    address lpProvider = makeAddr("lpProvider");
    

    function setUp() public {
        require(block.chainid == 314, "Not on correct network");
        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();
        ifzillaFactory = IFZillaFactory(0xD4745e9442c40942F6f4f252b223229160F8dc71);
        ifzillaRouter = IFZillaRouter02(0x0A2B871064C0d2D8001Cb80c0245a027a00af703);
        iWeth = IERC20(0x60E1773636CF5E4A227d9AC24F20fEca034ee25A);
        
        //Make Pair
        vm.deal(user, 1e18);
        vm.startPrank(user);
        tokenA.mint(user, 1e18);
        tokenB.mint(user, 1e18);
        address pair = ifzillaFactory.createPair(address(tokenA), address(tokenB));
        ifzillaPair = IFZillaPair(pair);
        vm.stopPrank();
    }


    function test_basicRouterInfo() public {  
        assertEq(ifzillaRouter.factory(), address(ifzillaFactory));
        assertEq(ifzillaRouter.WETH(), 0x60E1773636CF5E4A227d9AC24F20fEca034ee25A);
    }

    function test_addLiquidity() public {
        vm.startPrank(lpProvider);
        tokenA.mint(lpProvider, 1e18);
        tokenB.mint(lpProvider, 1e18);
        tokenA.approve(address(ifzillaRouter), 1e18);
        tokenB.approve(address(ifzillaRouter), 1e18);
        uint256 tokenABalanceBeforeTransfer = tokenA.balanceOf(lpProvider);
        uint256 tokenBBalanceBeforeTransfer = tokenB.balanceOf(lpProvider);
        (uint amountTokenA, uint amountTokenB, uint liquidity) = ifzillaRouter.addLiquidity(
            address(tokenA),
            address(tokenB),
            5e17,
            5e17,
            1000,
            1000,
            lpProvider,
            block.timestamp
        );

        
        assertEq(ifzillaPair.balanceOf(lpProvider), liquidity); // check lpProvider got lp tokens

        //check if tokens were transfered out of lpProvider and to the pair
        uint256 tokenABalanceAfterTransfer = tokenA.balanceOf(lpProvider);
        uint256 tokenBBalanceAfterTransfer = tokenB.balanceOf(lpProvider);
        assertEq(tokenABalanceBeforeTransfer, tokenABalanceAfterTransfer + 5e17);
        assertEq(tokenBBalanceBeforeTransfer, tokenBBalanceAfterTransfer + 5e17);
        // check 

        uint256 pairTokenABalanceAfterTransfer = tokenA.balanceOf(address(ifzillaPair));
        uint256 pairTtokenBBalanceAfterTransfer = tokenB.balanceOf(address(ifzillaPair));
        assertEq(pairTokenABalanceAfterTransfer, 5e17);
        assertEq(pairTtokenBBalanceAfterTransfer, 5e17);
        vm.stopPrank();
        
    }

    //same test as above but FUZZED!
    function test_fuzzAddLiquidity(uint256 amountOne, uint256 amountTwo) public {
        vm.startPrank(lpProvider);
        vm.assume(amountOne > 1000);
        vm.assume(amountTwo > 1000);
        vm.assume(amountOne < 2**112-1);    //max value as determined by the _update function in the pair
        vm.assume(amountTwo < 2**112-1);  //max value as determined by the _update function in the pair

        tokenA.mint(lpProvider, amountOne);
        tokenB.mint(lpProvider, amountTwo);
        tokenA.approve(address(ifzillaRouter), amountOne);
        tokenB.approve(address(ifzillaRouter), amountTwo);
        uint256 tokenABalanceBeforeTransfer = tokenA.balanceOf(lpProvider);
        uint256 tokenBBalanceBeforeTransfer = tokenB.balanceOf(lpProvider);


        (uint amountTokenA, uint amountTokenB, uint liquidity) = ifzillaRouter.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountOne,
            amountTwo,
            1000,
            1000,
            lpProvider,
            block.timestamp
        );

        vm.stopPrank();

        
        assertEq(ifzillaPair.balanceOf(lpProvider), liquidity); // check lpProvider got lp tokens

        //check if tokens were transfered out of lpProvider and to the pair
        uint256 tokenABalanceAfterTransfer = tokenA.balanceOf(lpProvider);
        uint256 tokenBBalanceAfterTransfer = tokenB.balanceOf(lpProvider);
        assertEq(tokenABalanceBeforeTransfer, tokenABalanceAfterTransfer + amountOne);
        assertEq(tokenBBalanceBeforeTransfer, tokenBBalanceAfterTransfer + amountTwo);
        // check 

        uint256 pairTokenABalanceAfterTransfer = tokenA.balanceOf(address(ifzillaPair));
        uint256 pairTtokenBBalanceAfterTransfer = tokenB.balanceOf(address(ifzillaPair));
        assertEq(pairTokenABalanceAfterTransfer, amountOne);
        assertEq(pairTtokenBBalanceAfterTransfer, amountTwo);   
        vm.stopPrank();
    }

    function test_addLiqudityEth() public {
        address pairAToWeth = ifzillaFactory.createPair(address(tokenA), 0x60E1773636CF5E4A227d9AC24F20fEca034ee25A);
        IFZillaPair iTokenAToWethPair = IFZillaPair(pairAToWeth);
        vm.deal(lpProvider, 5e18);
        vm.startPrank(lpProvider);
        tokenA.mint(lpProvider, 1e18);
        tokenA.approve(address(ifzillaRouter), 1e18);
        uint256 tokenABalanceBeforeTransfer = tokenA.balanceOf(lpProvider);
        uint256 ethBalanceBeforeTransfer = lpProvider.balance;


        (uint amountToken, uint amountTokenEth, uint liquidity) = ifzillaRouter.addLiquidityETH{value: 5e17}(
            address(tokenA),
            5e17,
            10000,
            5e17,
            lpProvider,
            block.timestamp
        );

        
        assertEq(iTokenAToWethPair.balanceOf(lpProvider), liquidity); // check lpProvider got lp tokens

        //check if tokens were transfered out of lpProvider and to the pair
        uint256 tokenABalanceAfterTransfer = tokenA.balanceOf(lpProvider);
        assertEq(tokenABalanceBeforeTransfer, tokenABalanceAfterTransfer + 5e17);
        assertEq(lpProvider.balance, 5e18 - 5e17);
        // check 

        uint256 pairTokenABalanceAfterTransfer = tokenA.balanceOf(address(iTokenAToWethPair));
        uint256 pairContractWethBalance = iWeth.balanceOf(address(iTokenAToWethPair));
        assertEq(pairTokenABalanceAfterTransfer, 5e17);
        assertEq(pairContractWethBalance, 5e17);
    }


    function test_removeLiquidity() public {
        vm.startPrank(lpProvider);
        tokenA.mint(lpProvider, 1e18);
        tokenB.mint(lpProvider, 1e18);
        tokenA.approve(address(ifzillaRouter), 1e18);
        tokenB.approve(address(ifzillaRouter), 1e18);
        (uint amountTokenA, uint amountTokenB, uint liquidity) = ifzillaRouter.addLiquidity(
            address(tokenA),
            address(tokenB),
            5e17,
            5e17,
            1000,
            1000,
            lpProvider,
            block.timestamp
        );

        uint256 tokenABalanceBeforeRemovingLiquidity = tokenA.balanceOf(lpProvider);
        uint256 tokenBBalanceBeforeRemovingLiquidity = tokenB.balanceOf(lpProvider);

        ifzillaPair.approve(address(ifzillaRouter), liquidity);

        (uint pairTokenABeforeRemoval, uint pairTokenBBeforeRemoval, ) = ifzillaPair.getReserves();

        (uint amountA, uint amountB) = ifzillaRouter.removeLiquidity(
            address(tokenA),
            address(tokenB), 
            liquidity, //Trading in all the tokens I get in from above
            10000,
            10000, 
            lpProvider, 
            block.timestamp);

        uint256 tokenABalanceAfterRemovingLiquidity = tokenA.balanceOf(lpProvider);
        uint256 tokenBBalanceAfterRemovingLiquidity = tokenB.balanceOf(lpProvider);

        
        assertEq(ifzillaPair.balanceOf(lpProvider), 0); //make sure LP provider no longer has their LP tokens

        (uint pairTokenAAfterRemoval, uint pairTokenBAfterRemoval, ) = ifzillaPair.getReserves();
        assertEq(tokenABalanceBeforeRemovingLiquidity, pairTokenAAfterRemoval + amountA);
        assertEq(tokenBBalanceBeforeRemovingLiquidity, pairTokenBAfterRemoval + amountB);
        vm.stopPrank();
    }


    function test_removeLiquidityEth() public {
        address pairAToWeth = ifzillaFactory.createPair(address(tokenA), 0x60E1773636CF5E4A227d9AC24F20fEca034ee25A);
        IFZillaPair iTokenAToWethPair = IFZillaPair(pairAToWeth);
        vm.deal(lpProvider, 5e18);
        vm.startPrank(lpProvider);
        tokenA.mint(lpProvider, 1e18);
        tokenA.approve(address(ifzillaRouter), 1e18);
        uint256 tokenABalanceBeforeTransfer = tokenA.balanceOf(lpProvider);
        uint256 ethBalanceBeforeTransfer = lpProvider.balance;


        (uint amountToken, uint amountTokenEth, uint liquidity) = ifzillaRouter.addLiquidityETH{value: 5e17}(
            address(tokenA),
            5e17,
            10000,
            5e17,
            lpProvider,
            block.timestamp
        );

        //check if tokens were transfered out of lpProvider and to the pair
        uint256 tokenABalanceAfterTransfer = tokenA.balanceOf(lpProvider);
        uint256 lpProviderBalanceBeforeTransfer = lpProvider.balance;
        uint256 pairTokenABalanceAfterTransferBeforeRemoval = tokenA.balanceOf(address(iTokenAToWethPair));
        uint256 pairContractWethBalanceBeforeRemoval = iWeth.balanceOf(address(iTokenAToWethPair));


        //removing eth liqudity
        iTokenAToWethPair.approve(address(ifzillaRouter), liquidity);
        (uint amountTokenAFromPair, uint amountEthFromPair) = ifzillaRouter.removeLiquidityETH(
            address(tokenA), 
            liquidity, //all lp tokens
            5e17 - 1000, 
            5e17 - 1000, 
            lpProvider, 
            block.timestamp
        );

        assertEq(iTokenAToWethPair.balanceOf(lpProvider), 0); //make sure LP provider no longer has their LP tokens

        //make sure pair has less tokens/weth than before
        assertEq(iWeth.balanceOf(address(iTokenAToWethPair)), pairContractWethBalanceBeforeRemoval - amountEthFromPair);
        assertEq(tokenA.balanceOf(address(iTokenAToWethPair)), pairTokenABalanceAfterTransferBeforeRemoval - amountTokenAFromPair);
        //make sure user has more tokens/eth than before
        assertEq(address(lpProvider).balance, lpProviderBalanceBeforeTransfer + amountEthFromPair);
        assertEq(tokenA.balanceOf(lpProvider), tokenABalanceAfterTransfer + amountTokenAFromPair);
    }

    function test_swapExactTokensForTokens() public {
        // setting up pair
        vm.startPrank(lpProvider);
        tokenA.mint(lpProvider, 1e18);
        tokenB.mint(lpProvider, 1e18);
        tokenA.approve(address(ifzillaRouter), 1e18);
        tokenB.approve(address(ifzillaRouter), 1e18);
        uint256 tokenABalanceBeforeTransfer = tokenA.balanceOf(lpProvider);
        uint256 tokenBBalanceBeforeTransfer = tokenB.balanceOf(lpProvider);
        (uint amountTokenA, uint amountTokenB, uint liquidity) = ifzillaRouter.addLiquidity(
            address(tokenA),
            address(tokenB),
            5e17,
            5e17,
            1000,
            1000,
            lpProvider,
            block.timestamp
        );
        vm.stopPrank();

        address swapper = makeAddr("swapper");
        tokenA.mint(swapper, 1e18);
        uint256 pairTokenABalanceBeforeTransfer = tokenA.balanceOf(address(ifzillaPair));
        uint256 pairTokenBBalanceBeforeTransfer = tokenB.balanceOf(address(ifzillaPair));

        vm.startPrank(swapper);
        tokenA.approve(address(ifzillaRouter), 1e15);
        
        path.push(address(tokenA));
        path.push(address(tokenB));
        uint[] memory amounts = ifzillaRouter.swapExactTokensForTokens(
            1e15,
            1e14,
            path,
            swapper,
            block.timestamp
        );

        vm.stopPrank();

        //make sure swapper got new tokens, and swapped old tokens
        uint256 userTokenABalanceAfterSwap = tokenA.balanceOf(swapper);
        assertEq(userTokenABalanceAfterSwap, tokenABalanceBeforeTransfer - 1e15);
        assertEq(amounts[1], tokenB.balanceOf(swapper));

        //pair value adjustments
        uint256 pairTokenABalanceAfterSwap = tokenA.balanceOf(address(ifzillaPair));
        assertEq(pairTokenABalanceBeforeTransfer + amounts[0], pairTokenABalanceAfterSwap); //token A went up
        assertEq(pairTokenBBalanceBeforeTransfer - amounts[1], tokenB.balanceOf(address(ifzillaPair))); //tokenb went down, sent to buyer
    }

    function test_swapExactEthForTokens() public {
        address pairAToWeth = ifzillaFactory.createPair(address(tokenA), 0x60E1773636CF5E4A227d9AC24F20fEca034ee25A);
        IFZillaPair iTokenAToWethPair = IFZillaPair(pairAToWeth);
        vm.deal(lpProvider, 5e18);
        vm.startPrank(lpProvider);
        tokenA.mint(lpProvider, 1e18);
        tokenA.approve(address(ifzillaRouter), 1e18);


        (uint amountToken, uint amountTokenEth, uint liquidity) = ifzillaRouter.addLiquidityETH{value: 5e17}(
            address(tokenA),
            5e17,
            10000,
            5e17,
            lpProvider,
            block.timestamp
        );

        vm.stopPrank();

        address swapper = makeAddr("swapper");
        vm.deal(swapper, 1e18);
        tokenA.mint(swapper, 1e18);
        uint256 pairTokenABalanceBeforeTransfer = tokenA.balanceOf(address(pairAToWeth));
        uint256 pairWethBalanceBeforeTransfer = iWeth.balanceOf(address(pairAToWeth));
        uint256 swapperTokenABalanceBeforeTransfer = tokenA.balanceOf(swapper);

        vm.startPrank(swapper);
        tokenA.approve(address(ifzillaRouter), 1e15);
        path.push(address(iWeth));
        path.push(address(tokenA));
        uint[] memory amounts = ifzillaRouter.swapExactETHForTokens{value: 2e15}(
            1e15,
            path,
            swapper,
            block.timestamp
        );

        vm.stopPrank();

        //swapper adjustment check
        assertEq(swapper.balance, 1e18 - amounts[0]); //eth adjustment, less eth
        assertEq(tokenA.balanceOf(swapper), swapperTokenABalanceBeforeTransfer  + amounts[1]); //tokenA adjustment, more tokens, 
        //pair adjustment check
        assertEq(iWeth.balanceOf(address(pairAToWeth)), pairWethBalanceBeforeTransfer + amounts[0]); //weth adjustment, more weth
        assertEq(pairTokenABalanceBeforeTransfer, tokenA.balanceOf(address(pairAToWeth)) + amounts[1]);//tokenA, less tokenA

    }

    function test_swapExactTokensForEth() public {
        address pairAToWeth = ifzillaFactory.createPair(address(tokenA), 0x60E1773636CF5E4A227d9AC24F20fEca034ee25A);
        IFZillaPair iTokenAToWethPair = IFZillaPair(pairAToWeth);
        vm.deal(lpProvider, 5e18);
        vm.startPrank(lpProvider);
        tokenA.mint(lpProvider, 1e18);
        tokenA.approve(address(ifzillaRouter), 1e18);


        (uint amountToken, uint amountTokenEth, uint liquidity) = ifzillaRouter.addLiquidityETH{value: 5e17}(
            address(tokenA),
            5e17,
            10000,
            5e17,
            lpProvider,
            block.timestamp
        );

        vm.stopPrank();

        address swapper = makeAddr("swapper");
        vm.deal(swapper, 1e18);
        tokenA.mint(swapper, 1e18);
        uint256 pairTokenABalanceBeforeTransfer = tokenA.balanceOf(address(pairAToWeth));
        uint256 pairWethBalanceBeforeTransfer = iWeth.balanceOf(address(pairAToWeth));
        uint256 swapperTokenABalanceBeforeTransfer = tokenA.balanceOf(swapper);

        vm.startPrank(swapper);
        tokenA.approve(address(ifzillaRouter), 1e15);
        path.push(address(tokenA));
        path.push(address(iWeth));
        uint[] memory amounts = ifzillaRouter.swapExactTokensForETH(
            1e15,
            5e14,
            path,
            swapper,
            block.timestamp
        );

        vm.stopPrank();

        //swapper adjustment check
        assertEq(tokenA.balanceOf(swapper), swapperTokenABalanceBeforeTransfer  - amounts[0]); //tokenA adjustment, less tokens, 
        assertEq(swapper.balance, 1e18 + amounts[1]); //eth adjustment, more eth
        // //pair adjustment check
        assertEq(tokenA.balanceOf(address(pairAToWeth)), pairTokenABalanceBeforeTransfer + amounts[0]);//tokenA, more tokenA
        assertEq(iWeth.balanceOf(address(pairAToWeth)), pairWethBalanceBeforeTransfer - amounts[1]); //weth adjustment, less weth

    }

}


//using interfaces and these contracts because of solidity complier versions




interface IFZillaRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    
}

interface IFZillaRouter02 is IFZillaRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


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


interface IFZillaPair {
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

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

}
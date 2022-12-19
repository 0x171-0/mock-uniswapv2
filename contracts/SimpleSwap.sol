// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ISimpleSwap } from "./interface/ISimpleSwap.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract SimpleSwap is ISimpleSwap, ERC20 {
    /* ------------------------------------------------------ */
    /*                         CONFIG                         */
    /* ------------------------------------------------------ */
    uint256 public constant MINIMUM_LIQUIDITY = 0;
    uint256 public FEEPERSENT_NUMERATOR = 0; // feePersent / 1000, ex when feePersent = 3, 0.003 %
    uint256 private FLOATPADDING = 1000;
    uint256 private FEEPERSENT_DENOMINATOR = 1000;
    /* ------------------------------------------------------ */
    /*                        DATA SETS                       */
    /* ------------------------------------------------------ */
    address public s_tokenA;
    address public s_tokenB;
    uint256 private s_reserveA;
    uint256 private s_reserveB;
    /* ------------------------------------------------------ */
    /*                        MODIFIERS                       */
    /* ------------------------------------------------------ */
    uint256 private s_unlocked = 1;
    modifier lock() {
        require(s_unlocked == 1, "SimpleSwap: LOCKED");
        s_unlocked = 0;
        _;
        s_unlocked = 1;
    }

    constructor(address _tokenA, address _tokenB) public ERC20("SimpleSwap", "SPI") {
        require(_tokenA != address(0), "SimpleSwap: TOKENA_IS_NOT_CONTRACT");
        require(_tokenB != address(0), "SimpleSwap: TOKENB_IS_NOT_CONTRACT");
        require(_tokenA != _tokenB, "SimpleSwap: TOKENA_TOKENB_IDENTICAL_ADDRESS");
        s_tokenA = _tokenA;
        s_tokenB = _tokenB;
    }

    /* ------------------------------------------------------ */
    /*                     PUBLIC FUNCTION                    */
    /* ------------------------------------------------------ */
    function getReserves() public view override returns (uint256 reserveA, uint256 reserveB) {
        return (s_reserveA, s_reserveB);
    }

    /* ------------------------------------------------------ */
    /*                    EXTERNAL FUNCTION                   */
    /* ------------------------------------------------------ */
    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external override lock returns (uint256 amountOut) {
        address _tokenA = s_tokenA;
        address _tokenB = s_tokenB;

        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(tokenIn == _tokenA || tokenIn == _tokenB, "SimpleSwap: INVALID_TOKEN_IN");
        require(tokenOut == _tokenA || tokenOut == _tokenB, "SimpleSwap: INVALID_TOKEN_OUT");
        require(tokenIn != tokenOut, "SimpleSwap: IDENTICAL_ADDRESS");
        require(msg.sender != _tokenA && msg.sender != _tokenB, "SimpleSwap: INVALID_TO");

        (uint256 reserveInput, uint256 reserveOutput) = tokenIn == _tokenA
            ? (s_reserveA, s_reserveB)
            : (s_reserveB, s_reserveA);
        require(reserveInput > 0 && reserveOutput > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY");

        ERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        require(
            ERC20(tokenIn).balanceOf(address(this)) - reserveInput >= amountIn,
            "SimpleSwap: INSUFFICIENT_TRANSFERD_AMOUNT"
        );

        uint256 amountOutput = _getAmountOut(amountIn, reserveInput, reserveOutput);
        // uint256 amountOutput2 = _getAmountOut2(amountIn, reserveInput, reserveOutput);
        // if (amountOutput != amountOutput2) {
        //     console.log("amountOutput=>", amountOutput);
        //     console.log("amountOutput2=>", amountOutput2);
        // }
        require(amountOutput > 0, "SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");
        require(amountOutput < reserveOutput, "SimpleSwap: INSUFFICIENT_LIQUIDITY");

        ERC20(tokenOut).approve(msg.sender, amountOutput);
        ERC20(tokenOut).transfer(msg.sender, amountOutput);

        uint256 newReserveA = ERC20(_tokenA).balanceOf(address(this));
        uint256 newReserveB = ERC20(_tokenB).balanceOf(address(this));
        uint256 balanceAForK = newReserveA * FLOATPADDING;
        uint256 balanceBForK = newReserveB * FLOATPADDING;
        tokenIn == _tokenA
            ? (balanceAForK = balanceAForK - amountIn * FEEPERSENT_NUMERATOR)
            : (balanceBForK = balanceBForK - amountIn * FEEPERSENT_NUMERATOR);
        require(
            (balanceAForK * balanceBForK) >= reserveInput * reserveOutput * FLOATPADDING**2,
            "SimpleSwap: INVALID K"
        );

        _updateReserves(newReserveA, newReserveB);

        emit Swap(msg.sender, tokenIn, tokenOut, amountIn, amountOutput);

        return amountOutput;
    }

    function addLiquidity(uint256 amountAIn, uint256 amountBIn)
        external
        override
        lock
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        require(amountAIn > 0 && amountBIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        (uint256 actualAmount, uint256 actualBmount) = _getActualAmount(amountAIn, amountBIn);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = mint(actualAmount, actualBmount);

        ERC20(s_tokenA).transferFrom(msg.sender, address(this), actualAmount);
        ERC20(s_tokenB).transferFrom(msg.sender, address(this), actualBmount);
    }

    function removeLiquidity(uint256 liquidity) external override lock returns (uint256 amountA, uint256 amountB) {
        address _tokenA = s_tokenA;
        address _tokenB = s_tokenB;

        uint256 balanceA = ERC20(_tokenA).balanceOf(address(this));
        uint256 balanceB = ERC20(_tokenB).balanceOf(address(this));

        uint256 _totalSupply = totalSupply();
        uint256 amountA = (liquidity * balanceA) / _totalSupply;
        uint256 amountB = (liquidity * balanceB) / _totalSupply;
        require(amountA > 0 && amountB > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_BURNED");

        transfer(address(this), liquidity);
        _burn(address(this), liquidity);

        ERC20(_tokenA).transfer(msg.sender, amountA);
        ERC20(_tokenB).transfer(msg.sender, amountB);

        _updateReserves(balanceA - liquidity, balanceB - liquidity);
        emit RemoveLiquidity(msg.sender, amountA, amountB, liquidity);
        return (amountA, amountB);
    }

    function getTokenA() external view override returns (address tokenA) {
        return s_tokenA;
    }

    function getTokenB() external view override returns (address tokenB) {
        return s_tokenB;
    }

    /* ------------------------------------------------------ */
    /*                    INTERNAL FUNCTION                   */
    /* ------------------------------------------------------ */
    function mint(uint256 amountAIn, uint256 amountBIn)
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        uint256 amountA = amountAIn;
        uint256 amountB = amountBIn;

        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            liquidity = sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
            _mint(address(this), MINIMUM_LIQUIDITY);
        } else {
            liquidity = min((amountA * _totalSupply) / s_reserveA, (amountB * _totalSupply) / s_reserveB);
        }

        require(liquidity > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY_MINTED");

        _mint(msg.sender, liquidity);

        uint256 newReserveA = ERC20(s_tokenA).balanceOf(address(this)) + amountAIn;
        uint256 newReserveB = ERC20(s_tokenB).balanceOf(address(this)) + amountBIn;
        _updateReserves(newReserveA, newReserveB);

        emit AddLiquidity(msg.sender, amountA, amountB, liquidity);
    }

    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveInput,
        uint256 reserveOutput
    ) internal view returns (uint256) {
        uint256 amountInWithFee = amountIn * (FEEPERSENT_DENOMINATOR - FEEPERSENT_NUMERATOR);
        return (amountInWithFee * reserveOutput) / (reserveInput * FEEPERSENT_DENOMINATOR + amountInWithFee);
    }

    function _getAmountOut2(
        uint256 amountIn,
        uint256 reserveInput,
        uint256 reserveOutput
    ) internal view returns (uint256) {
        uint256 oldK = reserveInput * reserveOutput;
        uint256 amountInWithFee = (amountIn * (FEEPERSENT_DENOMINATOR - FEEPERSENT_NUMERATOR)) / FEEPERSENT_DENOMINATOR;
        uint256 newReserveInput = reserveInput + amountInWithFee;
        // @dev (newReserveInput - 1) if for round to 1
        uint256 newReserveOutput = (oldK + (newReserveInput - 1)) / newReserveInput;
        return reserveOutput - newReserveOutput;
    }

    function _getActualAmount(uint256 amountAIn, uint256 amountBIn)
        internal
        returns (uint256 actualAmountOfA, uint256 actualAmountOfB)
    {
        if (s_reserveA == 0 && s_reserveB == 0) return (amountAIn, amountBIn);
        uint256 actualAmountOfA = amountAIn;
        uint256 actualAmountOfB = amountBIn;
        if (s_reserveA > 0) {
            uint256 porpotionA = (amountAIn * s_reserveB) / (s_reserveA);
            if (amountBIn > porpotionA) actualAmountOfB = porpotionA;
        }
        if (s_reserveB > 0) {
            uint256 porpotionB = (amountBIn * (s_reserveA)) / (s_reserveB);
            if (amountAIn > porpotionB) actualAmountOfA = porpotionB;
        }
        return (actualAmountOfA, actualAmountOfB);
    }

    function _updateReserves(uint256 balanceA, uint256 balanceB) private {
        s_reserveA = balanceA;
        s_reserveB = balanceB;
    }

    /* ------------------------------------------------------ */
    /*                      Math library                      */
    /* ------------------------------------------------------ */
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

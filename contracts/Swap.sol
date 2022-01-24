// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract Swap {

    uint internal fee = 300;
    address public wethTokenAddress;
    address public daoTokenAddress;
    AggregatorV3Interface internal priceFeed;


    struct Pair {
    address token1;
    address token2;
    uint amountOfToken1;
    uint amountOfToken2;
    uint totalFeesPayed;
    uint numOfProviders;
    }

    struct Provider {
    address providerAddress;
    address token1;
    address token2;
    uint amountOfToken1;
    uint amountOfToken2;
    }

    Pair[] public tokenPairs;
    Provider[] public providers;

    mapping(address => uint) public tokenBalance;
    mapping(address => mapping(address => uint)) public constantOfThePair;
    mapping(address => Provider) public providerMapping;
    // Mapping tracks Token => Weth => Pair struct.
    mapping(address => mapping(address => Pair)) public pairMapping;


    constructor(address _wethTokenAddress, address _addressOfEthUsdPriceFeed, address _daoTokenAddress) {
        wethTokenAddress = _wethTokenAddress;
        priceFeed = AggregatorV3Interface(_addressOfEthUsdPriceFeed);
        daoTokenAddress = _daoTokenAddress;
    }


    function checkPriceOfAPair(address _token) public view returns (uint) {
        uint map1 = pairMapping[_token][wethTokenAddress].amountOfToken2 * 10000;
        uint map2 = pairMapping[_token][wethTokenAddress].amountOfToken1;
        uint ratioRatio = map1 / map2;
        return ratioRatio;
    }


    function createPair(address _tokenToCreatePoolWith, uint _amountOfToken, uint _wethToSend) public {
    // Check if pair exists function.
        if (checkIfPairExists(_tokenToCreatePoolWith)) {
            uint ratio = checkPriceOfAPair(_tokenToCreatePoolWith);
            uint wethToReceive = _amountOfToken * ratio;
            uint wethToReceiveHere = wethToReceive / 10000;
            addToPair(_tokenToCreatePoolWith, _amountOfToken, wethToReceiveHere);
            pairMapping[_tokenToCreatePoolWith][wethTokenAddress].numOfProviders += 1;
        } else {
            IERC20(_tokenToCreatePoolWith).transferFrom(msg.sender, address(this), _amountOfToken);
            IERC20(wethTokenAddress).transferFrom(msg.sender, address(this), _wethToSend);
            pairMapping[_tokenToCreatePoolWith][wethTokenAddress].token1 = _tokenToCreatePoolWith;
            pairMapping[_tokenToCreatePoolWith][wethTokenAddress].token2 = wethTokenAddress;
            pairMapping[_tokenToCreatePoolWith][wethTokenAddress].amountOfToken1 = pairMapping[_tokenToCreatePoolWith][wethTokenAddress].amountOfToken1 + _amountOfToken;
            pairMapping[_tokenToCreatePoolWith][wethTokenAddress].amountOfToken2 = pairMapping[_tokenToCreatePoolWith][wethTokenAddress].amountOfToken2 + _wethToSend;
            pairMapping[_tokenToCreatePoolWith][wethTokenAddress].numOfProviders += 1;
            tokenPairs.push(Pair(_tokenToCreatePoolWith, wethTokenAddress, _amountOfToken, _wethToSend, 0, 0));
            providers.push(Provider(msg.sender, _tokenToCreatePoolWith, wethTokenAddress, _amountOfToken, _wethToSend));
            tokenBalance[_tokenToCreatePoolWith] = tokenBalance[_tokenToCreatePoolWith] + _amountOfToken;
            tokenBalance[wethTokenAddress] = tokenBalance[wethTokenAddress] + _wethToSend;
            setConst(_tokenToCreatePoolWith, _amountOfToken, _wethToSend);
        }
    }


    function setConst(address _tokenToCreatePoolWith, uint _amountOfToken, uint _amountOfWeth) internal returns(uint) {
        constantOfThePair[_tokenToCreatePoolWith][wethTokenAddress] = _amountOfToken * _amountOfWeth;
        uint constOfThisPair = constantOfThePair[_tokenToCreatePoolWith][wethTokenAddress];
        return constOfThisPair;
    }


    function getLatestPrice() public view returns (uint) {
            (, int price, , , ) = priceFeed.latestRoundData();
            uint adjustedPrice = uint(price) * 10**10;
            return adjustedPrice;
        }


    function checkIfPairExists(address _tokenToCreatePoolWith) public returns (bool) {
        for (uint index = 0; index < tokenPairs.length; index++) {
            if (tokenPairs[index].token1 == _tokenToCreatePoolWith) {
                return true;
        } else {
            return false;
            }
        }
    }

        // ADD TO PAIR FUNCTIONS


    function addToPair(address _token, uint _amount, uint _amountOfWeth) public {
        pairMapping[_token][wethTokenAddress].amountOfToken1 += _amount;
        pairMapping[_token][wethTokenAddress].amountOfToken2 += _amountOfWeth;
        providers.push(Provider(msg.sender, _token, wethTokenAddress, _amount, _amountOfWeth));
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        IERC20(wethTokenAddress).transferFrom(msg.sender, address(this), _amountOfWeth);
    }


        // SWAP FUNCTIONS


    function swapTokens(address _token, address _tokenToSendBack, uint _amount) external {
        require(IERC20(_token).balanceOf(msg.sender) > _amount);
        


        uint feeToPay = calculateFee(_amount) + _amount;
        pairMapping[daoTokenAddress][wethTokenAddress].totalFeesPayed += feeToPay;

        // Fee will always be payed in weth.
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        IERC20(wethTokenAddress).transferFrom(msg.sender, address(this), feeToPay);
        tokenBalance[_token] += _amount;
        uint constOfThisPairNow = constantOfThePair[_token][wethTokenAddress];
        uint howMuchShouldBeInThePool = constOfThisPairNow / tokenBalance[_token];
        uint toSend = tokenBalance[_tokenToSendBack] - howMuchShouldBeInThePool;
        IERC20(_tokenToSendBack).transfer(msg.sender, toSend);
    }


    // FEE FUNCTIONS


    function calculateFee(uint _amount) public view returns(uint) {
        uint feeToPay = (_amount * fee) / 100;
        return feeToPay;
    }




    // PAYING OUT PROVIDERS FUNCTION



    function payOutToProviders(address _token) public view returns (uint) {
        uint totalAmount = 0;
        for (uint index = 0; index < providers.length; index++) {
            if (providers[index].token1 == _token){
            totalAmount += providers[index].amountOfToken1;   
            }
        }
        for (uint i = 0; i < providers.length; i++) {
            uint providersTokens = providers[i].amountOfToken1;
            uint percentageOfThePool = (providersTokens * 100) / totalAmount;
            uint totalFeesPayedForThisPair = pairMapping[_token][wethTokenAddress].totalFeesPayed;
            uint yieldToPayWeth = ((percentageOfThePool / (10 * 10**10)) * totalFeesPayedForThisPair) / 100;
            // Fee will be payed by half weth and half token of the pool in this case dao.
            // Which means I should send some to the contract when it starts.
            return yieldToPayWeth;
        }
    }

    function pay() public {

        uint yield = payOutToProviders(daoTokenAddress);
        IERC20(daoTokenAddress).transfer(msg.sender, yield);
        IERC20(wethTokenAddress).transfer(msg.sender, yield);
    }


    // HELPER FUNCTIONS


    function withdraw() public {
        uint amountOfWethInContract = IERC20(wethTokenAddress).balanceOf(address(this));
        uint amountOfDaoInContract = IERC20(daoTokenAddress).balanceOf(address(this));
        IERC20(daoTokenAddress).transfer(msg.sender, amountOfDaoInContract);
        IERC20(wethTokenAddress).transfer(msg.sender, amountOfWethInContract);
    }


    function checkBalance() public view returns(uint, uint, uint, uint) {
        uint daoBalance = IERC20(daoTokenAddress).balanceOf(msg.sender);
        uint wethBalance = IERC20(wethTokenAddress).balanceOf(msg.sender);
        uint daoBalanceOfContract = IERC20(daoTokenAddress).balanceOf(address(this));
        uint wethBalanceOfContract = IERC20(wethTokenAddress).balanceOf(address(this));
        return (daoBalance, wethBalance, daoBalanceOfContract, wethBalanceOfContract);
    }

}




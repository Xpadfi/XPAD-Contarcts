// SPDX-License-Identifier: MIT
// Copyright 2021

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IPresale.sol";
import "./IPresaleFactory.sol";

contract Presale is IPresale, Ownable {
  using SafeMath for uint256;

  //
  // GLOBAL VARS
  //
  
  // Address owning the project
  address public override projectOwner;
  // The token getting pre-sold
  address public override tokenAddress;
  // The amount of tokens getting pre-sold
  uint256 public override presaleTokenAmount;
  // The price per ETH at presale
  uint256 public override presalePricePerETH;
  // The starting block of the presale
  uint256 public override startBlock;
  // The ending block of the presale
  uint256 public override endBlock;
  // The softcap the project intends to hit
  uint256 public override softCap;
  // The hard cap the project intends to hit
  uint256 public override hardCap;
  // The minimum amount of ETH that could be used to buy in
  uint256 public override minBuy;
  // The maximum amount of ETH that could be used to buy in
  uint256 public override maxBuy;

  // The factory
  IPresaleFactory public factory;

  // 
  // MAPPINGS
  //

  /**
   * @notice Mapping for tokens bought by the address
   */
  mapping(address => uint256) public tokensBought;

  /**
   * @notice Mapping for address if it has claimed or not
   */
  mapping(address => bool) public hasClaimed;

  /**
   * @notice Mapping for a tier to the token allocation it has
   */
  mapping(Tier => uint256) public tierAllocation;


  //
  // FUNCTIONS
  //

  /**
   * @notice Initialize a Presale contract
   * @param _projectOwner Address owning the project
   * @param _tokenAddress The token getting pre-sold
   * @param _presaleTokenAmount The amount of tokens getting pre-sold
   * @param _presalePricePerETH The price per ETH at presale
   * @param _startBlock The starting block of the presale
   * @param _endBlock The ending block of the presale
   * @param _softCap The soft cap the project intends to hit
   * @param _hardCap The hard cap the project intends to hit
   * @param _minBuy The minimum amount of ETH that could be used to buy in
   * @param _maxBuy The maximum amount of ETH that could be used to buy in
   */
  constructor(
    address _projectOwner, address _tokenAddress, uint256 _presaleTokenAmount,
    uint256 _presalePricePerETH, uint256 _startBlock, uint256 _endBlock, 
    uint256 _softCap, uint256 _hardCap, uint256 _minBuy, uint256 _maxBuy
  ) {
    // Initalize presale variables
    projectOwner = _projectOwner;
    tokenAddress = _tokenAddress;
    presaleTokenAmount = _presaleTokenAmount;
    presalePricePerETH = _presalePricePerETH;
    startBlock = _startBlock;
    endBlock = _endBlock;
    softCap = _softCap;
    hardCap = _hardCap;
    minBuy = _minBuy;
    maxBuy = _maxBuy;
    factory = IPresaleFactory(owner());
    _setTierAllocations();
  }
  
  /**
   * @notice Allows a user to participate in the presale and buy the token
   * @param _tokenAmount The amount of tokens the user wants to buy
   */
  function buy(uint256 _tokenAmount) external override payable {
    // Check if presale has began
    require(block.number >= startBlock, "Presale::buy: Presale hasn't started");
    // Check if presale has ended
    require(block.number < endBlock, "Presale::buy: Presale has ended");

    // Check if correct amount of ETH is sent
    require(msg.value == _tokenAmount.mul(presalePricePerETH),
      "Presale::buy: Wrong amount of ETH sent");
    // Check if hardcap is hit
    require(address(this).balance.add(msg.value) < hardCap, 
      "Presale::buy: Hardcap has been hit");

    // Check the user's tier
    Tier userTier = _determineTier(_msgSender());
    require(tierAllocation[userTier] >= _tokenAmount, 
      "Presale::buy: The allocation for the tier has been exhausted");

    // Add to the tokens bought by the user
    tokensBought[_msgSender()] = tokensBought[_msgSender()].add(_tokenAmount);
    // Remove tokens from the user's tier
    tierAllocation[userTier] = tierAllocation[userTier].sub(_tokenAmount);

    // Check if token amount is atleast as much as min buy
    require(tokensBought[_msgSender()] >= minBuy.mul(presalePricePerETH), 
      "Presale::buy: Tokens bought should exceed mininum amount");
    // Check if token amount is atmost as much as max buy
    require(tokensBought[_msgSender()] <= maxBuy.mul(presalePricePerETH), 
      "Presale::buy: Tokens bought should exceed mininum amount");
  }

  /**
   * @notice Allows a user to claim tokens after presale if the softcap was hit
   */
  function claimTokens() external override {
    require(block.number > endBlock, 
      "Presale::claimTokens: Presale hasn't ended yet");
    require(address(this).balance >= softCap, 
      "Presale::claimTokens: Soft cap wasn't hit");
    require(hasClaimed[_msgSender()] , 
      "Presale::claimTokens: Address has already claimed tokens");
    
    // Transfer the tokens bought
    IERC20(tokenAddress).transfer(_msgSender(), tokensBought[_msgSender()]);
  }

  /**
   * @notice Allows a user to claim ETH after presale if the softcap wasn't hit
   */
  function claimETH() external override {
    require(block.number >= endBlock, 
      "Presale::claimTokens: Presale hasn't ended yet");
    require(address(this).balance < softCap, 
      "Presale::claimETH: Soft cap was hit");
    require(hasClaimed[_msgSender()] , 
      "Presale::claimETH: Address has already claimed ETH");

    // Transfer the ETH sent
    payable(_msgSender()).transfer(tokensBought[_msgSender()]
      .mul(presalePricePerETH));
  }

  /**
   * @notice Function to withdraw funds to the launchpad team wallet
   * @param _payee The wallet the funds are withdrawn to
   */
  function withdrawFunds(address _payee) external override onlyOwner {
    require(block.number >= endBlock, 
      "Presale::claimTokens: Presale hasn't ended yet");
    require(address(this).balance >= softCap, 
      "Presale::claimTokens: Soft cap wasn't hit");
    require(address(this).balance > 0, 
      "Presale::withdrawFunds: No ETH in contract");
    
    payable(_payee).transfer(address(this).balance);  
  }

  /**
   * @notice Function to withdraw unsold tokens to the launchpad team wallet
   * @param _payee The wallet the funds are withdrawn to
   */
  function withdrawUnsoldTokens(address _payee) external override onlyOwner {
    require(block.number >= endBlock, 
      "Presale::claimTokens: Presale hasn't ended yet");
    require(address(this).balance >= softCap, 
      "Presale::claimTokens: Soft cap wasn't hit");
    require(address(this).balance > 0, 
      "Presale::withdrawFunds: No ETH in contract");
    
    IERC20(tokenAddress).transfer(
      _payee, IERC20(tokenAddress).balanceOf(address(this)));
  }

  //
  // INTERNAL FUNCTIONS
  //

  /**
   * @notice Sets the tier allocation in the constructor
   */
  function _setTierAllocations() internal {
    tierAllocation[Tier.DIAMOND] = presaleTokenAmount.mul(50).div(100);
    tierAllocation[Tier.PLATINUM] = presaleTokenAmount.mul(20).div(100);
    tierAllocation[Tier.GOLD] = presaleTokenAmount.mul(15).div(100);
    tierAllocation[Tier.SILVER] = presaleTokenAmount.mul(10).div(100);
    tierAllocation[Tier.BRONZE] = presaleTokenAmount.mul(5).div(100);
    tierAllocation[Tier.NONE] = 0;
  }

  /**
   * @notice Determines the tier of a user based on the amount staked and 
   * block they staked/unstaked at
   * @param _staker The user who's tier needs to be determined
   */
  function _determineTier(address _staker) internal view returns(Tier) {
    // Need to stake for atleast 1500 blocks for belonging in Tier
    if (factory.stakedBlock(_staker)
      .add(factory.minBlocksStaked()) > startBlock) {
      return Tier.NONE;
    }

    // Return tiers based on amount staked
    if (factory.stakedAmount(_staker) >= factory.tierDiamond()) {
      return Tier.DIAMOND;
    } else if (factory.stakedAmount(_staker) >= factory.tierPlatinum()) {
      return Tier.PLATINUM;
    } else if (factory.stakedAmount(_staker) >= factory.tierGold()) {
      return Tier.GOLD;
    } else if (factory.stakedAmount(_staker) >= factory.tierSilver()) {
      return Tier.SILVER;
    } else if (factory.stakedAmount(_staker) >= factory.tierBronze()) {
      return Tier.BRONZE;
    } else {
      return Tier.NONE;
    }
  }  

  receive() payable external {}
}
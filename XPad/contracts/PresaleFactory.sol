// SPDX-License-Identifier: MIT
// Copyright 2021

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IPresaleFactory.sol";
import "./Presale.sol";

/**
  @dev The PresaleFactory Smart contract forms the basis of a tiered launchpad
  and allows launch of multiple presales while making sure presalers are have
  staked their tokens for an appropriate amount of time
 */
contract PresaleFactory is IPresaleFactory, Ownable {
  using SafeMath for uint256;
  
  //
  // GLOBAL VARS
  //

  // The native token of the Launchpad
  address public override nativeToken;
  // Total presales
  uint256 public override presaleTotal = 0;
  // Minimum blocks needed to stake
  uint256 public override minBlocksStaked;
  
  // Staking tiers
  // Diamond Tier = 200 Tokens
  uint256 public override tierDiamond = 200 ether;
  // Platinum Tier = 100 Tokens
  uint256 public override tierPlatinum = 100 ether;
  // Gold Tier = 50 Tokens
  uint256 public override tierGold = 50 ether;
  // Silver Tier = 20 Tokens
  uint256 public override tierSilver = 20 ether;
  // Bronze Tier = 10 Tokens
  uint256 public override tierBronze = 10 ether;
  
  //
  // MAPPINGS
  //

  /**
   * @notice Map of an id to a presale address
  */
  mapping(uint256 => address) public override presaleMap; 

  /**
   * @notice Map of staker to amount staked block
  */
  mapping(address => uint256) public override stakedBlock;

  /**
   * @notice Map of staker to amount staked block
  */
  mapping(address => uint256) public override stakedAmount;

  //
  // FUNCTIONS
  //

  /**
   * @notice Initialize the factory contract with the native token
   * @param _nativeToken The address of then native token
   * @param _minBlocksStaked The address of then native token
   */
  constructor(address _nativeToken, uint256 _minBlocksStaked) {
    nativeToken = _nativeToken;
    minBlocksStaked = _minBlocksStaked;
  }


  /**
   * @notice Creates and initializes a Presale contract
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
   * @return uint256 The id of the presale
   * @return uint256 The address of the presale
   */
  function createPresale(
    address _projectOwner, address _tokenAddress, uint256 _presaleTokenAmount,
    uint256 _presalePricePerETH, uint256 _startBlock, uint256 _endBlock, 
    uint256 _softCap, uint256 _hardCap, uint256 _minBuy, uint256 _maxBuy
  ) override external onlyOwner returns (uint256, address) {
    // Checking if start block is lesser than end block
    require(_startBlock < _endBlock, 
      "PresaleFactory::createPresale: Start block can't exceed end block");
    // Checking if soft cap block is lesser than hard cap
    require(_softCap <= _hardCap, 
      "PresaleFactory::createPresale: Soft cap can't exceed hard cap");
    // Checking if soft cap block is lesser than hard cap
    require(_minBuy <= _maxBuy, 
      "PresaleFactory::createPresale: Min buy can't exceed max buy");
    // Check if smart contract has permission to transfer presale tokens
    require(IERC20(_tokenAddress).allowance(_msgSender(), address(this)) >=
      _presaleTokenAmount, "PresaleFactory::stake: Allowance amount low");

    // Deploying presale
    Presale presale = new Presale(
      _projectOwner, _tokenAddress, _presaleTokenAmount,_presalePricePerETH, 
      _startBlock, _endBlock, _softCap, _hardCap, _minBuy, _maxBuy
    );

    uint256 presaleId = presaleTotal;
    address presaleAddress = address(presale);

    // Transfer presale tokens from owner to presale address
    IERC20(_tokenAddress).transferFrom(
      _msgSender(), presaleAddress, _presaleTokenAmount
    );

    // Adding presale to map
    presaleMap[presaleId] = presaleAddress;
    // Incrementing total number of presales created
    presaleTotal = presaleTotal.add(1);
    // Emitting event of presale acreation    
    emit PresaleCreated(presaleId, presaleAddress);

    // Returning the presale id and address
    return (presaleId, presaleAddress);
  }

  /**
   * @notice Allows staking of the native token
   * @param _stakeAmount The amount of tokens needed to be staked   
   * @return uint256 Returns the total amount still staked
   */
  function stake(uint256 _stakeAmount) external override returns (uint256) {
    // Check if smart contract has permission to transfer native tokens
    require(IERC20(nativeToken).allowance(_msgSender(), address(this)) >=
      _stakeAmount, "PresaleFactory::stake: Allowance amount low");
    
    // Adding stake amount to map
    stakedAmount[_msgSender()] = stakedAmount[_msgSender()].add(_stakeAmount);
    // Transferring the token to the contract
    IERC20(nativeToken).transferFrom(_msgSender(), address(this), _stakeAmount);
    // Set last stake block to current block
    stakedBlock[_msgSender()] = block.number;
    // Emitting event that user has staked
    emit Staked(_msgSender(), _stakeAmount);

    // Returning the total amount still staked
    return stakedAmount[_msgSender()];
  }

  /**
   * @notice Allows unstaking of the staked native token
   * @param _unstakeAmount The amount of tokens needed to be unstaked
   * @return uint256 Returns the total amount still staked
   */
  function unstake(uint256 _unstakeAmount) external override returns (uint256) {
    // Adding stake amount to map
    stakedAmount[_msgSender()] = stakedAmount[_msgSender()].sub(_unstakeAmount);
    // Transferring the token to the contract
    IERC20(nativeToken).transfer(_msgSender(), _unstakeAmount);
    // Set last stake block to current block
    stakedBlock[_msgSender()] = block.number;
    // Emitting event that user has unstaked
    emit Unstaked(_msgSender(), _unstakeAmount);

    // Returning the total amount still staked
    return stakedAmount[_msgSender()];
  }

  /**
   * @notice Changes the amount of blocks needed to be staked by the users
   * @param _minBlocksStaked The minimum blocks needed to stake
   */
  function setMinBlocksStaked(uint256 _minBlocksStaked) 
  external override onlyOwner {
    minBlocksStaked = _minBlocksStaked;
  }

  /**
   * @notice Withdraw the funds from a particular presale
   * @param _id The presale
   */
  function withdrawPresaleFunds(uint256 _id) external onlyOwner {
    IPresale(presaleMap[_id]).withdrawFunds(payable(owner()));
  }

  receive() external payable {}
}
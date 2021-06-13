// SPDX-License-Identifier: MIT
// Copyright 2021

pragma solidity ^0.8.4;

/**
  @dev The IPresaleFactory interface includes all the functions for the 
  PresaleFactory smart contract, and can be used by contract makers to freely
  interact with any iteration of the PresaleFactory Smart Contract
 */
interface IPresaleFactory {
  //
  // FUNCTIONS
  //

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
    address _projectOwner,
    address _tokenAddress,
    uint256 _presaleTokenAmount,
    uint256 _presalePricePerETH,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _softCap,
    uint256 _hardCap,
    uint256 _minBuy,
    uint256 _maxBuy
  ) external returns (uint256, address);

  /**
   * @notice Allows staking of the native token
   * @param _stakeAmount The amount of tokens needed to be staked   
   * @return uint256 Returns the total amount still staked
   */
  function stake(uint256 _stakeAmount) external returns (uint256);

  /**
   * @notice Allows unstaking of the staked native token
   * @param _unstakeAmount The amount of tokens needed to be unstaked
   * @return uint256 Returns the total amount still staked
   */
  function unstake(uint256 _unstakeAmount) external returns (uint256);

  /**
   * @notice Changes the amount of blocks needed to be staked by the users
   * @param _minBlocksStaked The minimum blocks needed to stake
   */
  function setMinBlocksStaked(uint256 _minBlocksStaked) external;

  //
  // VIEW FUNCTIONS
  //

  /**
   * @notice Returns the presale address based on the id
   * @param _id The id of the presale
   * @return address The address of the presale
   */
  function presaleMap(uint256 _id) external view returns (address);

  /**
   * @notice The total number of presales created
   * @param _staker The address of the staker
   * @return uint256 The block when the staker staked
   */
  function stakedBlock(address _staker) external view returns (uint256);

  /**
   * @notice The total number of presales created
   * @param _staker The address of the staker
   * @return uint256 The amount the staker
   */
  function stakedAmount(address _staker) external view returns (uint256);

  /**
   * @notice The total number of presales created
   * @return uint256 The address of the presale
   */
  function presaleTotal() external view returns (uint256);

  /**
   * @notice The address of the native token
   * @return adress The address of the native token
   */
  function nativeToken() external view returns (address);

    /**
   * @notice The minimum number of blocks needed to be staked to be in a tier
   * @return uint256 The number of blocks
   */
  function minBlocksStaked() external view returns (uint256);

  /**
   * @notice The total number of tokens required to be staked to be in Diamond
   * Tier 
   * @return uint256 The number of tokens
   */
  function tierDiamond() external view returns (uint256);

  /**
   * @notice The total number of tokens required to be staked to be in Platinum
   * Tier
   * @return uint256 The number of tokens
   */
  function tierPlatinum() external view returns (uint256);

  /**
   * @notice The total number of tokens required to be staked to be in tier Gold
   * Tier
   * @return uint256 The number of tokens
   */
  function tierGold() external view returns (uint256);
  
  /**
   * @notice The total number of tokens required to be staked to be in Silver
   * Tier
   * @return uint256 The number of tokens
   */
  function tierSilver() external view returns (uint256);

    /**
   * @notice The total number of tokens required to be staked to be in Bronze
   * Tier
   * @return uint256 The number of tokens
   */
  function tierBronze() external view returns (uint256);

  //
  // EVENTS
  //

  /**
   * @notice Emitted on presale creation
   * @param _id Id of the presale
   * @param _presaleAddress Address of the presale
   */
  event PresaleCreated(uint256 _id, address _presaleAddress);
 
  /**
   * @notice Emitted on staking
   * @param _staker The address of the staker
   * @param _stakedAmount The amount staked
   */
  event Staked(address _staker, uint256 _stakedAmount);
  
  /**
   * @notice Emitted on unstaking
   * @param _unstaker The address of the unstaker
   * @param _unstakedAmount The amount unstaked
   */
  event Unstaked(address _unstaker, uint256 _unstakedAmount);
}
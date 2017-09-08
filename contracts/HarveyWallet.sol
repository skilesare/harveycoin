pragma solidity ^0.4.15;

import './HarveyCustodian.sol';


contract HarveyWallet {

  /**
   * @dev owner of the wallet
   */
  mapping(address => bool) public owner;

  /**
   * @dev custodian the wallet is subject to
   */
  address public custodian;

  /**
   * @dev last timestamp a catchup was performed
   */
  uint256 public lastCatchup;

  /**
   * @dev timestamp that the wallet minted coins by making a donation
   */
  uint256 public mintStart;

  /**
   * @dev amount minted
   */
  uint256 public minted;

  /**
   * @dev amount redeemed
   */
  uint256 public redeemed;


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    assert(owner[msg.sender] == true);
    _;
  }


  /**
   * @dev Throws if the account hasn't minted coins
   */
  modifier onlyMinted() {
    assert(minted > 0);
    _;
  }

  /**
   * @dev lets the contract recieve ether
   */
  function () payable{

  }

  /**
   * @dev Creates a new wallet
   * @param _custodian - the custodian that this wallet subscribes to
   */
  function HarveyWallet(address _custodian) {
    assert(_custodian != 0);
    //the owner will start as the address creating the contract
    owner[msg.sender] = true;
    custodian = _custodian;
    lastCatchup = now;
  }

  /**
   * @dev sets the value of an owner
   * @param _newOwner - the address of a potential owner
   * @param _isOwner - the value of ownership
   */
  function setOwner(address _newOwner, bool _isOwner) onlyOwner returns (bool){
      owner[_newOwner] = _isOwner;
  }

  /**
   * @dev sets the value of an owner
   * @param _payTo - the address of the person you want to pay
   * @param _amount - the amount to pay
   */
  function pay(address _payTo, uint _amount) onlyOwner returns(bool){
      assert(HarveyCustodian(custodian).validWallets(_payTo) == true);
      //uint thisAmount = _amount;
      catchup();
      HarveyWallet(_payTo).catchup();
      //uint remainingBalance = address(this).balance;
      assert(address(this).balance > _amount);
      _payTo.transfer(_amount);
      Transfer(_payTo, _amount);
  }

  /**
   * @dev calculates the amount of a catchup
   */
  function calcCatchup() constant returns (uint){
      uint currentBalance = address(this).balance;
      uint periodLength = (now - lastCatchup);
      uint periodDecay = ( periodLength * 1 ether) / 5 years;
      uint owed = (currentBalance * periodDecay) / 1 ether;
      return owed;
  }

  /**
   * @dev catches up the wallet so that it is current and can transact
   */
  function catchup(){
    assert(lastCatchup < now);
    uint amount = calcCatchup();
    HarveyCustodian(custodian).sendDecay.value(amount)();
    lastCatchup = now;
    Catchup(amount);
  }

  /**
   * @dev mints new coins and transfers the donation to the custodian
   */
  function mint() payable returns (bool){
    assert(minted == 0);
    assert(mintStart == 0);
    minted = minted + msg.value;
    mintStart = now;
    HarveyCustodian(custodian).mint.value(msg.value)();
    Mint(msg.sender, msg.value);
    return true;
  }

  /**
   * @dev removes coins from the system and returns ether back to the minter
   * @param _amount - the amount to pull back
   */
  function unMint(uint256 _amount) returns (bool){
    uint available = HarveyCustodian(custodian).availableToRedeem(minted, redeemed, mintStart);
    assert(available > 0);
    uint drain = HarveyCustodian(custodian).drain();
    assert(_amount < drain);
    HarveyCustodian(custodian).unMint(msg.sender, _amount);
    redeemed = redeemed + _amount;
    Unmint(msg.sender, _amount);
    return true;
  }


    event Mint( address indexed from, uint value);
    event Unmint( address indexed to, uint value);
    event Transfer(address indexed to, uint value);
    event Catchup(uint value);
}

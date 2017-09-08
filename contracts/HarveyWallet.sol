pragma solidity ^0.4.15;

import './HarveyCustodian.sol';


contract HarveyWallet {

  mapping(address => bool) public owner;
  address public custodian;
  uint256 public lastCatchup;
  uint256 public mintStart;
  uint256 public minted;
  uint256 public redeemed;


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    assert(owner[msg.sender] == true);
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyCustodian() {
    assert(msg.sender == custodian);
    _;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyMinted() {
    assert(minted > 0);
    _;
  }

  function () payable{

  }

  function HarveyWallet(address _custodian) {
    //the owner will start as the address creating the contract
    owner[msg.sender] = true;
    custodian = _custodian;
    lastCatchup = now;
  }

  function setOwner(address _newOwner, bool _isOwner) onlyOwner returns (bool){
      owner[_newOwner] = _isOwner;
  }


  function pay(address _payTo, uint _amount) onlyOwner returns(bool){
      assert(HarveyCustodian(custodian).validWallets(_payTo) == true);
      uint thisAmount = _amount;
      catchup();
      HarveyWallet(_payTo).catchup();
      uint remainingBalance = address(this).balance;
      assert(address(this).balance > _amount);
      _payTo.transfer(_amount);
      Transfer(_payTo, _amount);
  }

  function calcCatchup() constant returns (uint){
      uint currentBalance = address(this).balance;
      uint periodLength = (now - lastCatchup);
      uint periodDecay = ( periodLength * 1 ether) / 5 years;
      uint owed = (currentBalance * periodDecay) / 1 ether;
      return owed;
  }

  function catchup(){
    assert(lastCatchup < now);
    uint amount = calcCatchup();
    HarveyCustodian(custodian).sendDecay.value(amount)();
    lastCatchup = now;
    Catchup(amount);
  }

  function mint() payable returns (bool){
    assert(minted == 0);
    assert(mintStart == 0);
    minted = minted + msg.value;
    mintStart = now;
    HarveyCustodian(custodian).mint.value(msg.value)();
    Mint(msg.sender, msg.value);
    return true;
  }

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

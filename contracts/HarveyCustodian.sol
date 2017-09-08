pragma solidity ^0.4.15;

contract HarveyCustodian {
    uint256 public drain;
    address public treasury;
    uint256 public totalMinted;
    uint256 public totalDrained;

  address public owner;

  mapping(address => bool) public validWallets;
  address[] public wallets;

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    assert(msg.sender == owner);
    _;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyValidWallet() {
    assert(validWallets[msg.sender] == true);
    _;
  }

  function () payable {
      revert();
    }


  function HarveyCustodian() {
    //the owner will start as the address creating the contract
    owner = msg.sender;
  }

  function setOwner(address _newOwner) onlyOwner returns (bool){
      owner = _newOwner;
  }

  function setTreasury(address _newTreasury) onlyOwner returns (bool){
      treasury = _newTreasury;
  }

  function unMint(address _to, uint256 _amount) onlyValidWallet returns (bool){
        drain = drain - _amount;
        totalDrained = totalDrained + _amount;
        _to.transfer(_amount);
        Redeemer(_to, msg.sender, _amount);
        return true;
  }

  function mint() payable onlyValidWallet returns(bool){
        treasury.transfer(msg.value);
        totalMinted = totalMinted + msg.value;
        NewMinter(msg.sender, msg.value);
        return true;
  }

  function sendDecay() payable returns(bool){
        drain = drain + msg.value;
        return true;
  }

  function setValidWallet(address _wallet, bool _validity) onlyOwner returns(bool){
      validWallets[_wallet] = _validity;
      wallets.push(_wallet);
  }

  function calcVested(uint256 _mintStart) constant returns(uint256){

      if((_mintStart + 5 years) < now){
          return 1 ether; //100%
      }
      uint vested = 1 ether - ((((_mintStart + 5 years) - now) * 1 ether) / 5 years);

      return vested;
  }

  function availableToRedeem(uint256 _minted, uint256 _redeemed, uint256 _mintStart ) constant returns(uint256){
       uint available = (_minted * calcVested(_mintStart)) / 1 ether;
       available = available - _redeemed;
       return available;
  }


    event NewMinter( address indexed from, uint value);
    event Redeemer( address indexed to, address indexed wallet, uint value);
}

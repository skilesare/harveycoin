pragma solidity ^0.4.15;

contract HarveyCustodian {

    /**
    * @dev holds the value available to be redeemed by minters
    */
    uint256 public drain;



    /**
    * @dev keeps track of the total drained
    */
    uint256 public totalMinted;

    /**
    * @dev holds the total drained from the stem
    */
    uint256 public totalDrained;

    /**
    * @dev the wallet that holds the tresury's funds
    */
    address public treasury;

    /**
    * @dev the owner of the custodian
    */
    address public owner;

    /**
    * @dev a list of wallets in the system
    */
    address[] public wallets;

    /**
    * @dev controls the validity of wallets so that fradulent wallets can be cut off
    */
    mapping(address => bool) public validWallets;


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    /**
    * @dev Throws if called by a wallet that isn't valid
    */
    modifier onlyValidWallet() {
        assert(validWallets[msg.sender] == true);
        _;
    }

    /**
    * @dev makes the custdian not accept ether except through other explicit payable functions
    */
    function () payable {
        revert();
        }


    /**
    * @dev constructor
    */
    function HarveyCustodian() {
        //the owner will start as the address creating the contract
        owner = msg.sender;
    }

    /**
    * @dev sets the owner of the custodian
    * @param _newOwner - the new owner of the contract
    */
    function setOwner(address _newOwner) onlyOwner returns (bool){
        owner = _newOwner;
    }

    /**
    * @dev sets the tresury wallet for the custodian
    * @param _newTreasury - the tresury wallet to put donated funds into
    */
    function setTreasury(address _newTreasury) onlyOwner returns (bool){
        treasury = _newTreasury;
    }


    /**
    * @dev send drained funds back to minters.  can only be called from wallets
    * @param _to - address to put the ETH
    * @param _amount - amount to drain
    */
    function unMint(address _to, uint256 _amount) onlyValidWallet returns (bool){
            drain = drain - _amount;
            totalDrained = totalDrained + _amount;
            _to.transfer(_amount);
            Redeemer(_to, msg.sender, _amount);
            return true;
    }

    /**
    * @dev adds donations to the tresury
    */
    function mint() payable onlyValidWallet returns(bool){
            treasury.transfer(msg.value);
            totalMinted = totalMinted + msg.value;
            NewMinter(msg.sender, msg.value);
            return true;
    }

    /**
    * @dev processes the decay catchup payments and adds them to the drain
    */
    function sendDecay() payable returns(bool){
            drain = drain + msg.value;
            return true;
    }

    /**
    * @dev sets the validity of a wallet
    * @param _wallet - wallet in cosideration
    * @param _validity - true or false depending on the validity of a wallet
    */
    function setValidWallet(address _wallet, bool _validity) onlyOwner returns(bool){
        validWallets[_wallet] = _validity;
        wallets.push(_wallet);
    }

    /**
    * @dev calculates how vested over a 5 year period an account is based on the startdate
    * @param _mintStart - Date of the donation
    */
    function calcVested(uint256 _mintStart) constant returns(uint256){

        if((_mintStart + 5 years) < now){
            return 1 ether; //100%
        }
        uint vested = 1 ether - ((((_mintStart + 5 years) - now) * 1 ether) / 5 years);

        return vested;
    }

    /**
    * @dev calculates how much ETH can be redeemed.
    * @param _minted - amount minted
    * @param _redeemed - amount already redeemed
    * @param _mintStart - date the donation was made
    */
    function availableToRedeem(uint256 _minted, uint256 _redeemed, uint256 _mintStart ) constant returns(uint256){
        uint available = (_minted * calcVested(_mintStart)) / 1 ether;
        available = available - _redeemed;
        return available;
    }


        event NewMinter( address indexed from, uint value);
        event Redeemer( address indexed to, address indexed wallet, uint value);
}

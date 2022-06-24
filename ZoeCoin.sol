//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ZoeCoin is ERC20 {
    uint oneWei = 1 wei;
    address payable private _owner;
    address payable private _wallet;
    string private _symbol;
    uint256 private _accountLimit;
    uint256 private _taxRate;
    uint256 private _price;

    constructor(uint256 taxValue, uint256 priceValue, uint256 limitValue, uint256 supplyValue) ERC20("Zoe Coin", "ZoeCoin") {
        _wallet = payable(address(this));
        _owner = payable(0xf1bec418ebB008aa61f9f5102B9A50EF5c34D65b);
        _accountLimit = limitValue;
        _taxRate = taxValue;
        _price = priceValue * oneWei;
        _mint(_wallet, supplyValue);
    }

    modifier AllowanceEnough (address owner, address spender, uint256 amount) {
        require(allowance(owner, spender) >= amount, "AllowanceNotEnough");
        _;
    }

    modifier BalanceEnough (address owner, uint256 amount) {
        require(balanceOf(owner) >= amount, "BalanceNotEnough");
        _;
    }

    modifier AmountInRange (uint256 amount) {
        require(amount > 0 && amount <= balanceOf(_wallet), "AmountNotInRange");
        _;
    }

    modifier MaxBalance (address account, uint256 amount) {
        require(balanceOf(account) + amount <= _accountLimit, "MaxBalanceExceed");
        _;
    }

    modifier MinPrice (uint256 amount, uint256 minPrice) {
        require(amount >= minPrice, "LowerThanMinPrice");
        _;
    }
    
    function maxToken() public view returns (uint256) {
        return _accountLimit;
    }

    function price() public view returns (uint256) {
        return _price;
    }

    function taxRate() public view returns (uint256) {
        return _taxRate;
    }
    
    function transfer(address to, uint256 amount)  public override MaxBalance(to, amount) returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override MaxBalance(to, amount) returns (bool) {
        _spendAllowance(from, to, amount);
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        uint256 taxedAmount = _tax(_msgSender(), amount);
        _approve(_msgSender(), spender, allowance(_msgSender(), spender) + taxedAmount);
        return true;    }

    function addAllowance(address spender, uint256 amount) public BalanceEnough(_msgSender(), amount) returns (bool) {
        uint256 taxedAmount = _tax(_msgSender(), amount);
        _approve(_msgSender(), spender, allowance(_msgSender(), spender) + taxedAmount);
        return true;
    }

    function subAllowance(address spender, uint256 amount) public AllowanceEnough(_msgSender(), spender, amount) returns (bool){
        _approve(_msgSender(), spender, allowance(_msgSender(), spender) - amount);
        return true;
    }

    function destroy() public returns (bool) {
        _burn(_wallet, balanceOf(_wallet));
        return true;
    }

    function produce(uint256 amount) public returns (bool) {
        _mint(_wallet, amount);
        return true;
    }

    function buy(uint256 amount) public payable AmountInRange(amount) MinPrice(msg.value, caculateTotalPrice(amount)) MaxBalance(_msgSender(), amount) returns (bool)  {
        _transfer(_wallet, _msgSender(), amount);
        _share(msg.value);
        return true;
    }

    function caculateTotalPrice (uint256 amount) public view returns (uint256)  {
        return amount * price();
    }
    
    function _tax(address account, uint256 amount) private returns (uint256) {
        uint256 fee = amount * _taxRate / 100;
        _transfer(account, _owner, fee);
        return amount - fee;
    }

    function _share(uint256 amount) private returns (bool) {
        _price =  price() + amount / totalSupply();
        return true;
    }

    function withdraw() public payable {
        _owner.transfer(_wallet.balance);
    }
}

contract TestZoeCoin is ZoeCoin {
    constructor () ZoeCoin (20,100,1000,10000) {}
}
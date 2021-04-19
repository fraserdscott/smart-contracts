pragma solidity >=0.4.22 <0.7.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

contract Token {
    using SafeMath for uint256;
    
    uint256 public tokenPrice;
    uint256 private totalSupply;
    address private owner;
    mapping(address => uint256) private balances;

    event Purchase(address buyer, uint256 amount);
    event Transfer(address sender, address receiver, uint256 amount);
    event Sell(address seller, uint256 amount);
    event Price(uint256 price);

    constructor(uint256 price) public {
        owner = msg.sender;
        tokenPrice = price;
    }

    function buyToken(uint256 amount) public payable returns(bool success) {
        require(msg.value == tokenPrice.mul(amount));
       
        balances[msg.sender] = balances[msg.sender].add(amount);
        totalSupply = totalSupply.add(amount);
        
        emit Purchase(msg.sender, amount);
        
        return true;
    }

    function transfer(address recipient, uint256 amount) public returns(bool success) {
        require(balances[msg.sender] >= amount);
        
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        
        emit Transfer(msg.sender, recipient, amount);
        
        return true;
    }
    
    function sellToken(uint256 amount) public returns(bool success) {
        require(balances[msg.sender] >= amount);
       
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
        
        msg.sender.transfer(tokenPrice.mul(amount));
        
        emit Sell(msg.sender, amount);
        
        return true;
    }
    
    function changePrice(uint256 price) payable public returns(bool success) {
        require(msg.sender == owner); 
        
        if (price >= tokenPrice) {
            // The new balance should be exactly enough to sell all tokens
            require(address(this).balance - totalSupply.mul(price) == 0);
            
            tokenPrice = price;
        } else {
            // Don't top up the contract if decreasing the price
            require(msg.value == 0);
            
            tokenPrice = price;
            msg.sender.transfer(address(this).balance - totalSupply.mul(price));
        }
        
        emit Price(price);
        
        return true;
    }
    
    function getBalance() public view returns(uint256 balance) {
        return balances[msg.sender];
    }
}
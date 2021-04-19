pragma solidity >=0.4.22 <0.7.0;

abstract contract Token {
    function transfer(address recipient, uint256 amount) public virtual returns(bool success);
    function getBalance() public view virtual returns(uint256 balance);
}

contract FairSwap {
    uint constant refundLimit = 10 seconds;
    uint constant cancelLimit = 20 seconds;
    
    Token public token1;
    Token public token2;
    
    uint256 public amount1;
    uint256 public amount2;
    
    address public A;
    address public B;

    bool public withdrawA;
    bool public withdrawB;
    bool public refundA;
    bool public refundB;
    
    uint public startTime;

    constructor(address addressToken1, address addressToken2) public {
        token1 = Token(addressToken1);
        token2 = Token(addressToken2);
    }
    
    // Anyone can announce a new swap if both users have withdrawn or refunded, or sufficient time has passed
    function beginSwap(address a, address b, uint256 x, uint256 y) public returns(bool success) {
        require(withdrawA && withdrawB || refundA && refundB || block.timestamp >= startTime + cancelLimit);
        
        A = a;
        B = b;
        
        amount1 = x;
        amount2 = y;
        
        withdrawA = withdrawB = refundA = refundB = false;
        
        startTime = block.timestamp;

        return true;
    }
    
    // A gets a refund if no one has withdrawn and enough time has passed
    function refundToken1() public returns(bool success) {
        require(msg.sender == A && token1.getBalance() >= amount1 && !(withdrawA || withdrawB) && block.timestamp >= startTime + refundLimit);

        refundA = true;
        
        token1.transfer(A, amount1);
        
        return true;
    }
    
    // B gets a refund if they sent funds, and no one has withdrawn, and enough time has passed
    function refundToken2() public returns(bool success) {
        require(msg.sender == B && token2.getBalance() >= amount2 && !(withdrawA || withdrawB) && block.timestamp >= startTime + refundLimit);

        refundB = true;
        
        token2.transfer(B, amount2);
        
        return true;
    }
    
    // B can only withdraw when the contract has enough of both tokens
    function withdrawToken1() public returns(bool success) {
        require(!(refundA || refundB) && msg.sender == B && token1.getBalance() >= amount1 && (token2.getBalance() >= amount2 || withdrawA));

        withdrawB = true;
        
        token1.transfer(B, amount1);
        
        return true;
    }
    
    // A can withdraw if no one has refunded and the contract has enough of both tokens
    function withdrawToken2() public returns(bool success) {
        require(!(refundA || refundB) && msg.sender == A && (token1.getBalance() >= amount1 || withdrawB) && token2.getBalance() >= amount2);
        
        withdrawA = true;
        
        token2.transfer(A, amount2);

        return true;
    }
    
    function token1Balance() public view returns(uint256 balance) {
        return token1.getBalance();
    }
    
    function token2Balance() public view returns(uint256 balance) {
        return token2.getBalance();
    }
}
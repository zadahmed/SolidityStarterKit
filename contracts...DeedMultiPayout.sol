pragma solidity 0.8.0;

contract DeedMultiPayout {
    address public lawyer;
    address payable public beneificary;
    
    uint public earliest;
    uint public amount;
    
    uint constant public PAYOUTS = 10;
    uint constant public INTERVAL = 10;
    uint public paidPayouts;
    
    constructor(
    address _lawyer,
    address payable _beneficiary,
    uint fromNow)
    payable {
        lawyer = _lawyer;
        beneificary = _beneficiary;
        earliest = block.timestamp + fromNow;
        amount = msg.value / PAYOUTS;
    }
    
    function withdraw() public {
        require(msg.sender == beneificary, 'beneificary only');
        require(block.timestamp >= earliest, 'too early');
        require(paidPayouts < PAYOUTS, 'no payouts left');
        
    
        uint elligiblePayouts = (block.timestamp - earliest) / INTERVAL;
        uint duePayouts = elligiblePayouts - paidPayouts;
        duePayouts = duePayouts + paidPayouts > PAYOUTS ? PAYOUTS - paidPayouts : duePayouts;
        paidPayouts += duePayouts;
        beneificary.transfer(duePayouts * amount);
    }
}
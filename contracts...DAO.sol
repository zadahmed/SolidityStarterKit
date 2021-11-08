pragma solidity 0.8.0;

/**
 * DAO contract:
 * 1. Collects investors money (ether) & allocate shares
 * 2. Keep track of investor contributions with shares
 * 3. Allow investors to transfer shares
 * 4. allow investment proposals to be created and voted
 * 5. execute successful investment proposals (i.e send money)
 */
 
 
 contract DAO {
     
     struct Proposal {
         uint id;
         string name;
         uint amount;
         address payable recipent;
         uint votes;
         uint end;
         bool executed;
     }
     
     mapping(address => bool) public investors;
     mapping(address => uint) public shares;
     mapping(address => mapping(uint => bool)) public votes;
     mapping(uint => Proposal) public proposals;
     
     uint public totalShares;
     uint public availableFunds;
     uint public contributionEnd;
     uint public nextProposalId;
     uint public voteTime;
     uint public quorum;
     address public admin;
     
     constructor(
         uint contributionTime, uint _voteTime, uint _quorum){
             require(_quorum > 0 && _quorum < 100, 'quorum must be between 0 and 100');
             contributionEnd = block.timestamp + contributionTime;
             voteTime = _voteTime;
             quorum = _quorum;
             admin = msg.sender;
         }
         
         
         
        function contribute() payable external {
            require(block.timestamp < contributionEnd , 'cannot contribute after contributionEnd');
            investors[msg.sender] = true;
            shares[msg.sender] += msg.value;
            totalShares += msg.value;
            availableFunds += msg.value;
        }
        
        
        function redeemShare(uint amount) external {
            require(shares[msg.sender] >= amount,'not enough shares');
            require(availableFunds >= amount, 'not enough availableFunds');
            shares[msg.sender] -= amount;
            availableFunds -= amount;
            payable(msg.sender).transfer(amount);
        }
        
        function transferShare(uint amount, address to) external {
            require(shares[msg.sender] >= amount, 'not enough shares');
            shares[msg.sender] -=amount;
            shares[to] += amount;
            investors[to] = true;
        }
        
        function vote(uint proposalId) external onlyInvestors() {
            Proposal storage proposal = proposals[proposalId];
            require(votes[msg.sender][proposalId] == false , 'investor can only vote once for a proposal');
            require(block.timestamp < proposal.end, 'Voting period has ended');
            votes[msg.sender][proposalId] = true;
            proposal.votes += shares[msg.sender];
        }
        
        function executeProposal(uint proposalId) external onlyAdmin(){
            Proposal storage proposal = proposals[proposalId];
            require(block.timestamp >= proposal.end, 'Proposal has not ended');
            require(proposal.executed = false, 'Proposal has already been executed');
            require((proposal.votes / totalShares)   * 100 >= quorum, 'cannot execute proposals with vote number below quorum');
            _transferEther(proposal.amount, proposal.recipent);
        }
        
        function withdrawEther(uint amount, address payable to) external onlyAdmin(){
            _transferEther(amount, to);
        }
        
         function _transferEther(uint amount, address payable to) internal {
            require(amount <= availableFunds, 'not enough availableFunds');
            availableFunds -= amount;
            to.transfer(amount);
          }

        
        receive() external payable{
            availableFunds += msg.value;
        }
        
        modifier onlyInvestors(){
            require(investors[msg.sender] == true, 'only investors');
            _;
        }
        
        modifier onlyAdmin(){
            require(msg.sender == admin , 'only admin');
            _;
        }
        
        function createProposal(string memory name, uint amount, address payable recipent) public onlyInvestors() {
            require(availableFunds >= amount, 'not enough availableFunds');
            proposals[nextProposalId] = Proposal(nextProposalId, name, amount, recipent, 0, block.timestamp + voteTime, false);
            availableFunds -= amount;
            nextProposalId ++;
            
        }
 }
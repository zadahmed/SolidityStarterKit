pragma solidity 0.8.0;



interface ERC20Interface {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function totalSupply() external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ERC20Token is ERC20Interface {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupplyTokens;
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint _totalSupply)
        public {
            name = _name;
            symbol = _symbol;
            decimals = _decimals;
            totalSupplyTokens = _totalSupply;
            balances[msg.sender] = _totalSupply;
        }
        
        
        function  transfer(address to, uint value) public override returns(bool) {
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public override returns(bool) {
        uint allowance = allowed[from][msg.sender];
        require(balances[msg.sender] >= value && allowance >= value);
        allowed[from][msg.sender] -= value;
        balances[msg.sender] -= value;
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function approve(address spender, uint value) public override returns(bool) {
        require(spender != msg.sender);
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) public override view returns(uint) {
        return allowed[owner][spender];
    }
    
     function totalSupply() public view override returns(uint) {
        return totalSupplyTokens;
    }
    
    function balanceOf(address owner) public view override returns(uint) {
        return balances[owner];
    }
 
}

contract ICO {
   struct Sale {
       address investor;
       uint quantity;
   }  
   Sale[] public sales;
   mapping(address => bool) public investors;
   address public token;
   address public admin;
   uint public end;
   uint public price;
   uint public availableTokens;
   uint public minPurchase;
   uint public maxPurchase;
   bool public released;
   
   constructor( string memory _name, string memory _symbol, uint8 _decimals, uint _totalSupply) public {
       token = address(new ERC20Token(
           _name, _symbol, _decimals, _totalSupply));
           admin = msg.sender;
   }
   
   function start(
       uint duration, uint _price, uint _availableTokens, uint _minPurchase, uint _maxPurchase) external onlyAdmin() icoNotActive(){
           require(duration > 0, 'duration should be > 0');
           uint totalSupply = ERC20Token(token).totalSupply();
           require(_availableTokens > 0 && _availableTokens <= totalSupply, 'total Supply should be > availableTokens');
           require(_minPurchase > 0, '_minPurchase should > 0');
           
           end = duration + block.timestamp; 
        price = _price;
        availableTokens = _availableTokens;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
       }
       
       
       
       
        function whitelist(address investor)
        external
        onlyAdmin() {
        investors[investor] = true;    
    }
    
    function buy()
        payable
        external
        onlyInvestors()
        icoActive() {
        require(msg.value % price == 0, 'have to send a multiple of price');
        require(msg.value >= minPurchase && msg.value <= maxPurchase, 'have to send between minPurchase and maxPurchase');
        uint quantity = price * msg.value;
        require(quantity <= availableTokens, 'Not enough tokens left for sale');
        sales.push(Sale(
            msg.sender,
            quantity
        ));
    }
    
    
     function release()
        external
        onlyAdmin()
        icoEnded()
        tokensNotReleased() {
        ERC20Token tokenInstance = ERC20Token(token);
        for(uint i = 0; i < sales.length; i++) {
            Sale storage sale = sales[i];
            tokenInstance.transfer(sale.investor, sale.quantity);
        }
    }


modifier icoActive() {
        require(end > 0 && block.timestamp < end && availableTokens > 0, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(end == 0, 'ICO should not be active');
        _;
    }
    
    modifier icoEnded() {
        require(end > 0 && (block.timestamp >= end || availableTokens == 0), 'ICO must have ended');
        _;
    }
    
    modifier tokensNotReleased() {
        require(released == false, 'Tokens must NOT have been released');
        _;
    }
    
    modifier tokensReleased() {
        require(released == true, 'Tokens must have been released');
        _;
    }
    
    modifier onlyInvestors() {
        require(investors[msg.sender] == true, 'only investors');
        _;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
    
    function withdraw(
        address payable to,
        uint amount)
        external
        onlyAdmin()
        icoEnded()
        tokensReleased() {
        to.transfer(amount);    
    }
}
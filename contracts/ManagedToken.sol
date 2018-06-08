pragma solidity ^0.4.18;

contract ManagedToken{
    mapping(address=>uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping(address=>address) delegation;
    string public name;
    string public symbol;
    uint256 totalSupply_;
    address public owner;
    address public admin;
    bool public paused;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event Mint(address indexed _to,uint256 amount);
    event Burn(address indexed _from,uint256 amount);
    event Delegation(address indexed from, address indexed to);
    event ManagedTransfer(address indexed from, address indexed to, uint256 value);
    event TogglePause();

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin{
        require(msg.sender == admin);
        _;
    }

    modifier whenNotPaused{
        require(!paused);
        _;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }

    constructor(string _name, string _symbol, uint256 _supply, address _admin) public{
        owner = msg.sender;
        admin = _admin;
        name = _name;
        symbol = _symbol;
        totalSupply_ = _supply;
        balances[owner] = totalSupply_;
    }

    function totalSupply() public view returns (uint256) {
      return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
      require(_to != address(0));
      require(_value <= balances[msg.sender]);

      balances[msg.sender] = sub(balances[msg.sender],_value);
      balances[_to] = add(balances[_to],_value);
      emit Transfer(msg.sender, _to, _value);
      return true;
    }

    function balanceOf(address _owner) public view returns (uint256) {
      return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = sub(balances[_from],_value);
        balances[_to] = add(balances[_to],_value);
        allowed[_from][msg.sender] = sub(allowed[_from][msg.sender],_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

    function mint(address _to, uint256 _amount) onlyOwner whenNotPaused public returns (bool){
        totalSupply_ = add(totalSupply_,_amount);
        balances[_to] = add(balances[_to],_amount);
        emit Mint(_to,_amount);
        emit Transfer(address(0),_to,_amount);
        return true;
    }

    function burn(uint256 _amount) public returns (bool){
        require(_amount<=balances[msg.sender]);
        balances[msg.sender] = sub(balances[msg.sender],_amount);
        totalSupply_ = sub(totalSupply_,_amount);
        emit Burn(msg.sender,_amount);
        emit Transfer(msg.sender,address(0),_amount);
        return true;
    }

    function delegate(address _to) public returns (bool){
        delegation[msg.sender] = _to;
        emit Delegation(msg.sender,_to);
        return true;
    }

    function delegateOf(address _owner) public view returns (address){
        return delegation[_owner];
    }

    function managedTransfer(address _from, address _to, uint256 _value) public whenNotPaused returns (bool){
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(delegation[_from] == msg.sender);

        balances[_from] = sub(balances[_from],_value);
        balances[_to] = add(balances[_to],_value);
        emit ManagedTransfer(_from, _to, _value);
        return true;
    }

    function togglePause() onlyAdmin public returns (bool){
        paused = !paused;
        emit TogglePause();
        return true;
    }

    function changeOwner(address newOwner) onlyAdmin public returns (bool){
        owner = newOwner;
        return true;
    }

    function changeAdmin(address newAdmin) onlyAdmin public returns (bool){
        admin = newAdmin;
        return true;
    }

    function withdraw() onlyOwner whenNotPaused public returns (bool){
        msg.sender.transfer(address(this).balance);
        return true;
    }
}

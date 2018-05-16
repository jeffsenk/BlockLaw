pragma solidity ^0.4.18;

contract EquityToken{
    mapping(address => uint256) tokenBalances;
    mapping(address => uint256) ethBalances;
    address[] members;
    uint256 totalSupply_;

    address public administrator;
    mapping(address =>uint256) candidateVotes;
    mapping(address =>address) candidateSupport;

    uint256 public dividend;
    uint256 public dividendPeriod;
    uint256 public lastDividend;
    mapping(uint256 =>uint256) dividendVotes;
    mapping(address =>uint256) dividendSupport;

    uint256 public budget;
    uint256 public budgetPeriod;
    uint256 public lastBudget;
    mapping(uint256 =>uint256) budgetVotes;
    mapping(address =>uint256) budgetSupport;

    uint256 public quorum;

    uint256 public windDownVotes;

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event AdminElected(address newAdmin, uint256 votes);
    event DividendDistributed(uint256 dividend);
    event BudgetDistributed(address target,uint256 budget);
    event Log(uint256 share, uint256 balance);

    constructor(uint256 initSupply, uint256 _quorum, uint256 _dividendPeriod,
    uint256 _budgetPeriod) public{
        totalSupply_ = initSupply;
        quorum = _quorum;
        administrator = msg.sender;
        tokenBalances[administrator] = totalSupply_;
        members.push(administrator);
        /*to initialize elections must put sole ownership support behind defaults**/
        candidateSupport[administrator] = administrator;
        candidateVotes[administrator] = tokenBalances[administrator];
        dividendSupport[administrator] = 0;
        dividendVotes[0] = tokenBalances[administrator];
        budgetSupport[administrator] = 0;
        budgetVotes[0] = tokenBalances[administrator];
        lastDividend = now;
        lastBudget = now;
        dividendPeriod = _dividendPeriod;
        budgetPeriod = _budgetPeriod;
    }

    /* math functions from OpenZeppelin SafeMath.sol**/

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
        return 0;
      }
      uint256 c = a * b;
      assert(c / a == b);
      return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a / b;
      return c;
    }

    modifier onlyAdmin() {
      require(msg.sender == administrator);
      _;
    }

    function calcShare(uint256 memberBalance,uint256 payOut)internal view returns (uint256){
      uint256 percentage = div(memberBalance,totalSupply_);
      return mul(payOut,percentage);
    }

    function totalSupply() public view returns (uint256) {
      return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= tokenBalances[msg.sender]);
        tokenBalances[msg.sender] = sub(tokenBalances[msg.sender],_value);
        tokenBalances[_to] = add(tokenBalances[_to],_value);
        bool isMember = false;
        for(uint i=0;i<members.length;i++){
            if(members[i] == _to){
                isMember = true;
                break;
            }
        }
        if(!isMember){
            members.push(_to);
        }
        /**May also want to remove msg.sender if tokenBalances[msg.sender]<=0*/
        /**Preferences of msg.sender automatically transfer to _to**/
        dividendSupport[_to] = dividendSupport[msg.sender];
        budgetSupport[_to] = budgetSupport[msg.sender];
        candidateSupport[_to] = candidateSupport[msg.sender];

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address member) public view returns (uint256 balance) {
      return tokenBalances[member];
    }

    function electDividend(uint256 _dividend) public returns (bool){
      uint256 currentSupport = dividendSupport[msg.sender];
      dividendVotes[currentSupport] = sub(dividendVotes[currentSupport],tokenBalances[msg.sender]);
      dividendSupport[msg.sender] = _dividend;
      dividendVotes[_dividend] = add(dividendVotes[_dividend],tokenBalances[msg.sender]);
      if(dividendVotes[_dividend]>quorum){
          dividend = _dividend;
      }
      return true;
    }

    function distributeDividend() public onlyAdmin returns (bool){
        require(dividend < address(this).balance);
        require(now > add(lastDividend,dividendPeriod));
        lastDividend = now;
        for(uint i =0;i<members.length;i++){
            uint256 share = calcShare(tokenBalances[members[i]],dividend);
            ethBalances[members[i]] = add(ethBalances[members[i]],share);
            emit Log(share,ethBalances[members[i]]);
        }
        emit DividendDistributed(dividend);
        dividend = 0;
        return true;
    }

    function electBudget(uint256 _budget) public returns (bool){
        uint256 currentSupport = budgetSupport[msg.sender];
        budgetVotes[currentSupport] = sub(budgetVotes[currentSupport],tokenBalances[msg.sender]);
        budgetSupport[msg.sender] = _budget;
        budgetVotes[_budget] = add(budgetVotes[_budget],tokenBalances[msg.sender]);
        if(budgetVotes[_budget] > quorum){
            budget = _budget;
        }
        return true;
    }

    function distributeBudget(address _to) public onlyAdmin returns (bool){
        require(budget <= address(this).balance);
        require(now > add(lastBudget,budgetPeriod));
        lastBudget = now;
        ethBalances[_to] = add(ethBalances[_to],budget);
        emit BudgetDistributed(_to,budget);
        budget = 0;
        return true;
    }

    function electAdmin(address candidate) public returns (bool){
        address currentSupport = candidateSupport[msg.sender];
        candidateVotes[currentSupport] = sub(candidateVotes[currentSupport],tokenBalances[msg.sender]);
        candidateSupport[msg.sender] = candidate;
        candidateVotes[candidate] = add(candidateVotes[candidate],tokenBalances[msg.sender]);
        if(candidateVotes[candidate] > quorum){
            administrator = candidate;
            emit AdminElected(administrator,candidateVotes[candidate]);
        }
        return true;
    }

    function ethBalanceOf(address member) public view returns (uint256 balance) {
        return ethBalances[member];
    }

    function withdraw() public returns (bool){
       /*pay out full balance of calling member**/
       uint amountToWithdraw = ethBalances[msg.sender];
       ethBalances[msg.sender] = 0;
       msg.sender.transfer(amountToWithdraw);
       return true;
    }

    function windDown() public returns (bool){
        windDownVotes = add(windDownVotes,tokenBalances[msg.sender]);
        if(windDownVotes > quorum){
            for(uint i =0;i<members.length;i++){
              uint256 share = calcShare(tokenBalances[members[i]],address(this).balance);
              ethBalances[members[i]] = add(ethBalances[members[i]],share);
            }
        }
        return true;
    }

    function () external payable{
    }
}

pragma solidity ^0.4.18;

contract EquityToken{
    mapping(address => uint256) tokenBalances;
    mapping(address => uint256) ethBalances;
    address[] members;
    uint256 totalSupply_;

    address administrator;
    mapping(address =>uint256) candidateVotes;
    mapping(address =>address) candidateSupport;

    uint256 dividend;
    uint256 dividendPeriod;
    uint256 lastDividend;
    mapping(uint256 =>uint256) dividendVotes;
    mapping(address =>uint256) dividendSupport;

    uint256 budget;
    uint256 budgetPeriod;
    uint256 lastBudget;
    mapping(uint256 =>uint256) budgetVotes;
    mapping(address =>uint256) budgetSupport;

    uint256 quorum;

    uint256 windDownVotes;

    event Transfer(address indexed from, address indexed to, uint tokens);

    constructor(uint256 _totalSupply, uint256 _quorum, uint256 _dividendPeriod,
    uint256 _budgetPeriod) public{
        totalSupply_ = _totalSupply;
        quorum = _quorum;
        administrator = msg.sender;
        tokenBalances[administrator] = totalSupply_;
        lastDividend = now;
        lastBudget = now;
        dividendPeriod = _dividendPeriod;
        budgetPeriod = _budgetPeriod;
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

    modifier onlyAdmin() {
      require(msg.sender == administrator);
      _;
    }

    function totalSupply() public view returns (uint256) {
      return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= tokenBalances[msg.sender]);

        tokenBalances[msg.sender] = sub(tokenBalances[msg.sender],_value);
        tokenBalances[_to] = add(tokenBalances[_to],_value);

        /**Must check if _to is current member */
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
            dividend = dividendVotes[_dividend];
        }
        return true;
    }

    function distributeDividend() public onlyAdmin returns (bool){
        require(dividend< address(this).balance);
        require(now > add(lastDividend,dividendPeriod));
        lastDividend = now;
        for(uint i =0;i<members.length;i++){
            uint256 share = dividend * (tokenBalances[members[i]]/totalSupply_);
            /**rounding*/
            ethBalances[members[i]] = add(ethBalances[members[i]],share);
        }
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
        }
        return true;
    }

    function ethBalanceOf(address member) public view returns (uint256 balance) {
        return ethBalances[member];
    }

    function withdraw() public returns (bool){
      //pay out full balance of calling member
       uint amountToWithdraw = ethBalances[msg.sender];
       ethBalances[msg.sender] = 0;
       msg.sender.transfer(amountToWithdraw);
       return true;
    }

    function windDown() public returns (bool){
        windDownVotes = add(windDownVotes,tokenBalances[msg.sender]);
        if(windDownVotes > quorum){
            for(uint i =0;i<members.length;i++){
              uint256 share = address(this).balance * (tokenBalances[members[i]]/totalSupply_);
              /**rounding*/
              ethBalances[members[i]] = add(ethBalances[members[i]],share);
            }
        }
        return true;
    }

}

const EquityToken = artifacts.require('./EquityToken.sol');
contract('EquityToken', accounts =>{
  let token;
  const owner = accounts[0];
  const operations = accounts[1];
  const initSupply = 1000;
  const quorum = 51;
  const dividendPeriod = 0;
  const budgetPeriod = 0;
  const investment = 100000;

  beforeEach(async function(){
    token = await EquityToken.new(initSupply,quorum,dividendPeriod,budgetPeriod,{
      from:owner
    });
    assert(await token.send(investment,{from:owner}));
  });

  //param check
  it('assigns quorum', async function(){
    const quorum = await token.quorum();
    assert.equal(quorum,51);
  });

  it('receives funds',async function(){
    const balance = web3.eth.getBalance(token.address);
    assert.equal(investment,balance.toNumber())
  })

  it('elects correct dividend', async function(){
    const choice = 55;
    assert(await token.electDividend(choice,{
      from: owner
    }))
    const dividend = await token.dividend();
    assert.equal(choice,dividend.toNumber());
  })

  const delay = ms => new Promise(resolve => setTimeout(resolve, ms));

  it('distributes dividend to sole owner',async function(){
    const dividend = 20;
    const startingBalance = await token.ethBalanceOf(owner);
    assert(await token.electDividend(dividend,{
      from: owner
    }))
    await delay(3000);
    assert(await token.distributeDividend({from:owner}));
    const endingBalance = await token.ethBalanceOf(owner);
    assert.equal(endingBalance.toNumber(),startingBalance.toNumber() + dividend);
  })

  it('elects budget when sole owner votes',async function(){
    const choice = 20;
    assert(await token.electBudget(choice,{
      from: owner
    }))
    const budget = await token.budget();
    assert.equal(choice,budget.toNumber());
  })

  it('assigns budget to operations address',async function(){
    const choice = 50;
    assert(await token.electBudget(choice,{
      from: owner
    }))
    await delay(3000);
    assert(await token.distributeBudget(operations,{
      from: owner
    }))
    const operationsBalance = await token.ethBalanceOf(operations);
    assert.equal(operationsBalance.toNumber(),choice);
  })

  it('elects admin when sole owner votes',async function(){
    const choice = '0xd4335070909212f14fa9d32c163d9a4ca82f336f';
    assert(await token.electAdmin(choice,{
      from: owner
    }))
    const admin = await token.administrator();
    assert.equal(choice,admin);
  })

});

import React, { useState } from 'react';

import MYTOKEN_ABI from './MYTOKEN_ABI.json';

import { ethers } from 'ethers';

const zoeCoin = '0xC4Dd6c8d226F0b63961A996880ca75a8c84a36ED';
const provider = new ethers.providers.Web3Provider(window.ethereum);
const myContract = new ethers.Contract(zoeCoin, MYTOKEN_ABI, provider);

const buy = async (amount, price) => {
  const signer = provider.getSigner();
  const msg = { value: ethers.utils.parseEther(price) * amount };

  const contractWithSigner = myContract.connect(signer);
  try {
    await contractWithSigner.buy(amount, msg);
    alert('mint success');
  } catch (e) {
    console.log(e);
    let errMsg = e.error.message.replace('execution reverted: ', '');
    alert(errMsg);
  }
};

const getContractInfo = async (address) => {
  const tokenName = await myContract.name();
  const tokenBalance = await myContract.balanceOf(address);
  const tokenUnits = await myContract.decimals();
  const tokenPrice = ethers.utils.formatEther(await myContract.price());
  const tokenBalanceInEther = ethers.utils.formatUnits(tokenBalance, tokenUnits);
  return { tokenName, tokenBalanceInEther, tokenPrice };
};

const connectUserMetamask = async () => {
  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const accounts = await provider.send('eth_requestAccounts', []);
  const balance = await provider.getBalance(accounts[0]);
  const balanceInEther = ethers.utils.formatEther(balance);
  const block = await provider.getBlockNumber();
  return { address: accounts[0], balance: balanceInEther, block };
};

// provider.on('block', (block) => {
//   setUser((user) => ({ ...user, block }));
// });

const Metamask = () => {
  const [user, setUser] = useState(null);

  const [contract, setContract] = useState(null);
  const [amount, setAmount] = useState(1);

  const connect = async () => {
    const userInfo = await connectUserMetamask();
    const contractInfo = await getContractInfo(userInfo.address);
    setUser(userInfo);
    setContract(contractInfo);
  };

  return (
    <div>
      {user ? (
        <div>
          <p>Welcome {user.address}</p>
          <p>Your ETH Balance is: {user.balance}</p>
          <p>Current ETH Block is: {user.block}</p>
          <p>
            Balance of {contract.tokenName} is: {contract.tokenBalanceInEther}
          </p>
          <p>Token Price is: {contract.tokenPrice}</p>
          <input type='number' value={amount} onChange={({ target }) => setAmount(target.value)} />
          <button onClick={() => buy(amount, contract.tokenPrice)}>mint</button>
        </div>
      ) : (
        <button onClick={() => connect()}>Connect to Metamask</button>
      )}
    </div>
  );
};

export default Metamask;

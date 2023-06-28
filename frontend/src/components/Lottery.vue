<template>
    <div>
      <h2>Enter Lottery</h2>
      <input type="text" v-model="amount" placeholder="Amount of tokens to enter" />
      <button @click="enterLottery">Enter Lottery</button>
  
      <h2>Admin Only: Pick Winner</h2>
      <button @click="pickWinner">Pick Winner</button>
    </div>
  </template>
  
  <script>
  import Web3 from "web3";
  
  export default {
    data() {
      return {
        web3: null,
        lotteryContract: null,
        amount: ""
      };
    },
    async mounted() {
      if (window.ethereum) {
        this.web3 = new Web3(window.ethereum);
        await window.ethereum.request({ method: "eth_requestAccounts" });
  
        const contractABI = []; // Set your contract ABI here
        const contractAddress = ""; // Set your contract address here
  
        this.lotteryContract = new this.web3.eth.Contract(contractABI, contractAddress);
      }
    },
    methods: {
      async enterLottery() {
        const accounts = await this.web3.eth.getAccounts();
        await this.lotteryContract.methods.enter(this.amount).send({ from: accounts[0] });
      },
      async pickWinner() {
        const accounts = await this.web3.eth.getAccounts();
        await this.lotteryContract.methods.pickWinner().send({ from: accounts[0] });
      }
    }
  };
  </script>
  
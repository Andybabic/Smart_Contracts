
<script>
import Web3 from 'web3';
import axios from "axios";

export default {
  data() {
    return {
      contractAddress: '0xbbaa17F1a80B18d69Ae9070420699ecA96DAb01B',
      contractABI: [], // Contract ABI should be provided here
      web3: null,
      ticketPrice: 0,
      contractInstance: null,
      currentState: '',
      minimumPlayers: 0,
      players: [],
      ticketCount: 0,
      isManager: false,
      winner: null
    };
  },
  async mounted() {
    await this.initializeWeb3();
    await this.loadContract();
  },
  methods: {
    async initializeWeb3() {
      try {
          if (typeof window.ethereum !== 'undefined') {
          this.web3 = new Web3(window.ethereum);
          await window.ethereum.enable();
        } else if (typeof window.web3 !== 'undefined') {
          this.web3 = new Web3(window.web3.currentProvider);
        } else {
          this.web3 = new Web3('https://mainnet.infura.io/v3/84a017e2ca8b4a02b39ab4c41bdbb1a2'); // Update with your Ethereum node URL
      }
      } catch (error) {
        console.error('Error initializing web3:', error);
        throw error;
      }
  
    },
    async getContractABI(contractAddress) {
      try {
        const response = await axios.get(`https://api-goerli.etherscan.io/api?module=contract&action=getabi&address=${contractAddress}&apikey=UKPPPWAGDJFVPQ9DIU3EH157GPQ9132UDT`);
        const result = response.data;
        if (result.status === '1') {
          return JSON.parse(result.result);
        } else {
          console.log(result)
          throw new Error('Failed to fetch contract ABI');
        }
      } catch (error) {
        console.error('Error fetching contract ABI:', error);
        throw error;
      }
    },
    async loadContract() {
      const abi = require("../assets/abi.json")
      this.contractInstance = new this.web3.eth.Contract(abi, this.contractAddress);
      const currentState = await this.contractInstance.methods.getCurrentState().call();
      const ticketPrice = await this.contractInstance.methods.ticketPrice().call();
      const ticketPriceEth = this.web3.utils.fromWei(ticketPrice, "ether");
      const minimumPlayers = await this.contractInstance.methods.minimumPlayers().call();

      const players = await this.contractInstance.methods.getPlayers().call();
      const ticketCount = players.length;

      this.currentState = currentState;
      this.ticketPrice = ticketPriceEth
      this.minimumPlayers = minimumPlayers;
      this.players = players;
      this.ticketCount = ticketCount;
      this.isManager = false;
    },
    async enterLottery() {
      try {
        const accounts = await this.web3.eth.getAccounts();
        const ticketPriceWei = this.web3.utils.toWei(this.ticketPrice.toString(), "ether");
        this.contractInstance.methods.enter(ticketPriceWei).send({from: accounts[0], value: ticketPriceWei})
          .on('receipt', () => {
            console.log('Entered lottery successfully.');
            this.loadContract();
          })
          .on('error', error => {
            if (error.message.includes('User denied transaction signature')) {
              alert('You denied the transaction. Please approve it to enter the lottery.');
            } else {
              console.error('Error entering lottery:', error.message);
            }
          });
       
      } catch (error) {
        console.error('Error entering lottery:', error.message);
      }
    },
    async pickWinner() {
      try {
        this.contractInstance.methods.pickWinner().send()
            .on('receipt', receipt => {
              console.log('Winner picked successfully.');

              // Retrieve the winner event from the receipt
              const winnerEvent = receipt.events.WinnerPicked;
              if (winnerEvent) {
                const winnerAddress = winnerEvent.returnValues.winner;
                this.winner = winnerAddress;
              }

              this.loadContract();
            })
            .on('error', error => {
              console.error('Error picking winner:', error.message);
            });
      } catch (error) {
        console.error('Error picking winner:', error.message);
      }
    },
  }
}
</script>


<template>
  <div class="container">
    <div class="header">
      <h1>Lottery Contract</h1>
    </div>
    <div class="content">
      <p class="status-message" v-if="currentState === BigInt(0n)">Lottery is currently open for entries.</p>
      <p class="status-message" v-else-if="currentState === BigInt(1n)">Lottery is closed. Waiting for the winner to be picked.</p>
      <p class="status-message" v-else-if="currentState === BigInt(2n)">Lottery has finished. Winner: <span class="winner">{{ winner }}</span></p>
      <p class="loading" v-else>Loading...</p>

      <div v-if="currentState === BigInt(0n)">
        <p>Ticket Price: {{ ticketPrice }} ETH</p>
        <p>Minimum Players: {{ minimumPlayers }}</p>
        <p>Current Players: {{ players.length }}</p>
        <p>Total Tickets Sold: {{ ticketCount }}</p>
        <div class="input-group">
          <label for="customPrice">Custom Ticket Price (ETH):</label>
          <input type="number" id="customPrice" v-model="ticketPrice" step="0.01">
        </div>
        <button @click="enterLottery">Enter Lottery</button>
      </div>

      <div class="manager-actions">
        <button v-if="isManager" @click="pickWinner">Pick Winner</button>
      </div>
    </div>
    <div class="footer">
      <p>LOTTERY</p>
    </div>
  </div>
</template>

<style>

.content {
  margin-top: 20px;
}

.footer {
  background: linear-gradient(to right, #6dd5fa, #2980b9);
  color: #fff;
  padding: 10px;
  border-bottom-left-radius: 10px;
  border-bottom-right-radius: 10px;
  text-align: center;
}

h1 {
  font-size: 24px;
  margin-bottom: 20px;
}

p {
  margin-bottom: 10px;
}

.status-message {
  font-style: italic;
  margin-bottom: 10px;
}

.winner {
  font-weight: bold;
  color: #28a745;
}

.input-group {
  display: flex;
  flex-direction: column;
  margin-bottom: 10px;
}

.label {
  margin-bottom: 5px;
}

input[type="number"] {
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 14px;
  margin-bottom: 10px;
}

button {
  padding: 10px 20px;
  background-color: #007bff;
  color: #fff;
  border: none;
  border-radius: 4px;
  font-size: 16px;
  cursor: pointer;
}

button:hover {
  background-color: #0069d9;
}

.loading {
  text-align: center;
  margin-top: 20px;
}

.manager-actions {
  margin-top: 20px;
  text-align: right;
}

@media (max-width: 480px) {
  h1 {
    font-size: 20px;
  }
  
  .input-group {
    flex-direction: column;
  }
}
</style>

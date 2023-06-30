<script>
import Web3 from 'web3';
import axios from "axios";

export default {
  data() {
    return {
      contractAddress: '0x6fae85ec11b3001646f19f3ef94b4f08e0bc0117',
      contractABI: [], // Contract ABI should be provided here
      web3: null,
      ticketPrice: 0,
      contractInstance: null,
      currentState: '',
      minimumPlayers: 0,
      players: [],
      ticketCount: 0,
      isManager: false,
      winner: null,
      win: false,
      deniedTransaction: false,

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
                this.deniedTransaction = true;

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

                const accounts = this.web3.eth.getAccounts();
                if (this.winner === accounts[0]) {
                  this.win = true;

                  console.log("You are the winner!");

                } else {
                  this.win = false;

                  console.log("You are not the winner!");

                }
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
    <div class="overlay"></div>
    <video autoplay loop muted>
      <source src="../assets/gambling-background-casino-and-poker-concept-2023-04-14-17-11-37-utc.mp4" type="video/mp4">
    </video>
    <div class="content">
      <div v-if="currentState === BigInt(0n)">
        <div class="dot dot-green"></div>
        <p class="status-message">Lottery is currently open for entries.</p>
      </div>
      <div v-else-if="currentState === BigInt(1n)">
        <div class="dot dot-yellow"></div>
        <p class="status-message">Lottery is closed. Waiting for the winner to be picked.</p>
      </div>
      <div v-else-if="currentState === BigInt(2n)">
        <div class="dot dot-red"></div>
        <p class="status-message">Lottery has finished. Winner: <span class="winner">{{ winner }}</span></p>
      </div>
      <p class="loading" v-else>Connect your Wallet to the Lottery ...</p>

      <div v-if="currentState === BigInt(0n)" class="lottery-info">
        <p>Ticket Price: {{ ticketPrice }} ETH</p>
        <p>Minimum Players: {{ minimumPlayers }}</p>
        <p>Current Players: {{ players.length }}</p>
        <p>Total Tickets Sold: {{ ticketCount }}</p>
        <div class="input-group">
          <label for="customPrice">Custom Ticket Price (ETH):</label>
          <input type="number" id="customPrice" v-model="ticketPrice" step="0.01">
        </div>
        <div>
          <p> Press the Quokka to enter the lottery </p>
        </div>
        <button @click="enterLottery"></button>
      </div>

      <div v-if="win === true && currentState === BigInt(2n)" class="winning-message">
        <p>Congratulations you won the lottery!</p>
      </div>
      <div v-if="win === false && currentState === BigInt(2n)" class="losing-message">
        <p> Sorry you did not win the lottery!</p>
      </div>
      <div v-if="deniedTransaction" class="denied-transaction">
        <p>Transaction denied.</p>
      </div>
      <div class="manager-actions">
        <button v-if="isManager" @click="pickWinner">Pick Winner</button>
      </div>
    </div>

  </div>
</template>

<style>

.winning-message {
  background-color: green;
  color: white;
  padding: 10px;
  border-radius: 10px;
  margin-bottom: 20px;
}

.losing-message {
  background-color: red;
  color: white;
  padding: 10px;
  border-radius: 10px;
  margin-bottom: 20px;
}

.denied-transaction {
  background-color: red;
  color: white;
  padding: 10px;
  border-radius: 10px;
  margin-bottom: 20px;
}

.lottery-info {
  margin-bottom: 20px;
  font-size: 22px;


}


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
  margin-bottom: 15px;
  font-size: 22px;
}

.status-message {
  font-size: 25px;
  font-weight: bold;
  margin-bottom: 20px;
}

.dot {
  height: 25px;
  width: 25px;
  border-radius: 50%;
  margin-right: 5px;
}

.dot-green {
  background-color: lightgreen;
}

.dot-yellow {
  background-color: orange;
}

.dot-red {
  background-color: red;
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
  padding: 10px;
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 16px;
  width: 100%;
  box-sizing: border-box;
  margin: 5px 0;
}


button {
  padding: 10px 20px;
  background-color: #007bff;
  width: 200px;
  height: 200px;
  color: gold;
  border: none;
  border-radius: 4px;
  font-size: 30px;
  cursor: pointer;
  background-image: url("../assets/QuokkaDol.jpg");
  background-size: cover;
  background-repeat: no-repeat;
  background-position: center;
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

html,
body {
  height: 100%;
  margin: 0;
  padding: 0;
}

body {
  background-size: cover;
  background-repeat: no-repeat;
  background-position: center;
  position: relative;
}

.container {
  width: 180%;
  height: 60vh;
  margin: 0;
  padding: 0;
  background-color: #f2f2f2;
  color: #333;
  border: 1px solid #ccc;
  border-radius: 10px;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
}

video {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  z-index: -1;
}

</style>

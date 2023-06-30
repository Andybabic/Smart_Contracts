<script>
/* eslint-disable */
import Web3 from 'web3';
import axios from "axios";
import Swal from 'sweetalert2'

export default {
  name: 'LotteryComponent',
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
      updateInterval: null
    };
  },
  async mounted() {
    await this.initializeWeb3();
    await this.loadContract();
  },
  methods: {
    getSpinnerGif(){
      return require("../assets/spinner.gif");
    },
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
    async loadContract() {
      const abi = require("../assets/abi.json")
      this.contractInstance = await new this.web3.eth.Contract(abi, this.contractAddress);

      const currentState = await this.contractInstance.methods.getCurrentState().call();
      const ticketPrice = await this.contractInstance.methods.ticketPrice().call();
      const ticketPriceEth = await this.web3.utils.fromWei(ticketPrice, "ether");
      const minimumPlayers = await this.contractInstance.methods.minimumPlayers().call();

      const players = await this.contractInstance.methods.getPlayers().call();
      const ticketCount = players.length;

      this.currentState = currentState;
      this.ticketPrice = ticketPriceEth
      this.minimumPlayers = minimumPlayers;
      this.players = players;
      this.ticketCount = ticketCount;
      this.isManager = false;

      this.setIntervalCheckingContract();
    },
    async enterLottery() {
      try {
        const accounts = await this.web3.eth.getAccounts();
        const ticketPriceWei = this.web3.utils.toWei(this.ticketPrice.toString(), "ether");
        const playerAddress = accounts[0];
        const isPlayerEntered = await this.contractInstance.methods.hasPlayerEntered(playerAddress).call();

        if(isPlayerEntered){
          await this.showAlert("Already Entered", "You have already entered. Please wait until the winner is picked.", "info");
        } else {
          this.showLoading();
          // send coins
          const result = await this.contractInstance.methods.enter(ticketPriceWei).send({from: accounts[0], value: ticketPriceWei});
          
          // retrieve hash and check for completion
          const txHash = result.transactionHash;

          // wait until transaction is complete
          const transactionResult = await this.waitForTransactionCompletion();

          // check result
          if(transactionResult){
            Swal.close();
            await this.showAlert("Success", "Transaction finished successfully. You entered lottery!", "success");
          } else {
            Swal.close();
            await this.showAlert("Error", "Something went wrong during transaction. Please try again.", "error");
          }
        }
      } catch (error) {
        Swal.close();
        this.showAlert("Error occurred during Transaction.", error, "error");
      }
    },
    async showLoading(message){
      Swal.fire({
        showConfirmButton: false,
        showCancelButton: false,
        allowOutsideClick: false,
        allowEscapeKey: false,
        html: `
          <div class="loading-container">
            <div class="loading-indicator">
              <img src="${this.getSpinnerGif()}" alt="Loading">
            </div>
            <div class="loading-text">
              ${message}...
            </div>
          </div>
        `,
        customClass: {
          confirmButton: 'alert-ok-button', // Apply custom class to the confirm button
          cancelButton: 'alert-cancel-button', // Apply custom class to the cancel button
        },
      });
    },

    async showAlert(title, message, icon){
      Swal.fire({
        title,
        text: message,
        icon,
        customClass: {
          confirmButton: 'alert-ok-button', // Apply custom class to the confirm button
          cancelButton: 'alert-cancel-button', // Apply custom class to the cancel button
        },
      });
    },

    async waitForTransactionCompletion(transactionHash) {
      let receipt = null;
      while (receipt === null) {
        receipt = await this.web3.eth.getTransactionReceipt(transactionHash);
        if (receipt && receipt.status === false) {
          throw new Error("Transaction failed or reverted");
        }
        await new Promise((resolve) => setTimeout(resolve, 3000)); // Delay between each check (e.g., 3 seconds)
      }
      return receipt;
    },

    async setIntervalCheckingContract(){
      this.updateInterval = setInterval(async () => {
        const currentState = await this.contractInstance.methods.getCurrentState().call();
        this.players = await this.contractInstance.methods.getPlayers().call();

        if(this.currentState !== currentState){
          try{
            const isPlayerWinner = await this.contractInstance.methods.checkIfWinner().call();
            console.log("AM I WINNER?", isPlayerWinner);
          } catch(e) {}
        }

      }, 5000);
    }

  }
}
</script>


<template>
  <div class="container">

  <div class="meta-info">
  <img src="../assets/metamask.png" alt="MetaMask" class="metamask-logo">
    <p>You need a MetaMask-Wallet to join this lottery!</p>
  </div>


    <div class="overlay"></div>

    <div class="header">
      <div v-if="currentState === BigInt(0n)" class="status-open">
        <p class="status-message">Quokka is currently open for entries!</p>
      </div>
      <div v-else-if="currentState === BigInt(1n)" class="status-closed">
        <p class="status-message">Lottery is closed. Waiting for the winner to be picked!</p>
      </div>
      <div v-else-if="currentState === BigInt(2n)" class="status-finished">
        <p class="status-message">Lottery has finished. Winner: <span class="winner">{{ winner }}</span></p>
      </div>
      <p class="loading" v-else>Connect your Wallet to the Lottery ...</p>
    </div>


    <div class="content">
     
      

      <div v-if="currentState === BigInt(0n)" class="lottery-info">

      <div class="eth-ticket-container">
      
      <div class="eth-container">

        <p>{{ ticketPrice }} </p>
        <img src="../assets/ethereum.png" alt="eth" class="eth">
      
      </div>
        
        <div class="ticket-container">
          <p>{{ ticketCount }} / {{ minimumPlayers }}</p>
        <img src="../assets/fahrkarte.png" alt="ticket" class="ticket">
        
        </div>
        </div>

        

        <div>
          <p> Press the Quokka to enter!</p>
        </div>
        <button @click="enterLottery"></button>
      </div>

      <!-- <div v-if="win === true && currentState === BigInt(2n)" class="winning-message">
        <p>Congratulations you won the lottery!</p>
      </div>
      <div v-if="win === false && currentState === BigInt(2n)" class="losing-message">
        <p> Sorry you did not win the lottery!</p>
      </div> -->
      <div class="manager-actions">
        <button v-if="isManager" @click="pickWinner">Pick Winner</button>
      </div>
    </div>

  </div>
</template>

<style>

.meta-info {
  display: flex;
  flex-direction: row;
  align-items: center;
  justify-content: center;
  margin-bottom: 20px;
}

.meta-info p {
  margin-left: 10px;
}

.metamask-logo {
  width: 50px;
  height: 50px;
}

.header {
  font-weight: bold;
}


.status-open {
  background-color: rgba(0, 255, 0, 0.4);
  color: black;
  padding: 20px;
  border-radius: 5px;
  margin-bottom: 20px;
}

.status-closed {
  background-color: rgba(255, 255, 0, 0.4);
  color: black;
  padding: 20px;
  border-radius: 5px;
  margin-bottom: 20px;
}

.status-finished {
  background-color: rgba(255, 0, 0, 0.4);
  color: black;
  padding: 20px;
  border-radius: 5px;
  margin-bottom: 20px;
}

.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
}

.loading-indicator {
  margin-bottom: 10px;
}

.loading-text {
  font-size: 14px;
  color: #888;
}

.alert-ok-button, .alert-cancel-button{
  max-height: 50px;
}

.status {
  display: flex;
  align-items: center;
  justify-content: space-evenly;

  margin-bottom: 20px;
}

.eth-ticket-container {
  display: flex;
  align-items: center;
  justify-content: space-evenly;

  margin-bottom: 20px;
}

.eth-container {
  display: flex;
  align-items: center;
  justify-content: center;

  margin-bottom: 20px;
}

.eth-container p {
  margin-right: 10px;
  font-size: 22px;
}

.eth-container img {
  width: 50px;
  height: 50px;
}


.ticket-container {
  display: flex;
  align-items: center;
  justify-content: center;

  margin-bottom: 20px;
}

.ticket-container img {
  width: 50px;
  height: 50px;
}

.ticket-container p {
  margin-right: 10px;
  font-size: 22px;
}


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


p {
  margin-bottom: 15px;
  font-size: 22px;
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
  box-shadow: 0 5px 5px rgba(0, 0, 0, 0.5);
}


.loading {
  text-align: center;
  margin-top: 20px;
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
  max-width: 600px;
  margin-top: 25vh;
  padding: 50px;
  border-radius: 10px;
  box-shadow: 0 20px 20px rgba(0, 0, 0, 0.5);
  position: relative;
  overflow: hidden;
  background-image: linear-gradient(to bottom right, #FDFCFB, #E2D1C3);

  


}

@media screen and (max-width: 600px) {
  .container {
    margin: auto 20px;
    border-radius: 10px;
    box-shadow: 0 20px 20px rgba(0, 0, 0, 0.5);
    padding: 20px;
    font-size: 10px;

  }
  
}

</style>

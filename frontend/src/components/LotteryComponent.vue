<script>
/* eslint-disable */
import Web3 from "web3";
import axios from "axios";
import Swal from "sweetalert2";

export default {
  name: "LotteryComponent",
  data() {
    return {
      contractAddress: "0x059d3ada63528ec9c032aede7d0c0b8303f0ec97",
      contractABI: [], // Contract ABI should be provided here
      web3: null,
      ticketPrice: 0,
      contractInstance: null,
      currentState: "",
      minimumPlayers: 0,
      players: [],
      ticketCount: 0,
      isManager: false,
      winner: null,
      win: false,
      updateInterval: null,
      managerTicketPrice: 0,
      managerMinimumPlayer: 0,
      balance: 0,
      timeout: 0,
      moneyPotIcon: require("../assets/money-pot.svg"),
    };
  },
  async mounted() {
    await this.initializeWeb3();
    await this.loadContract();
  },
  methods: {
    getSpinnerGif() {
      return require("../assets/spinner.gif");
    },
    async initializeWeb3() {
      try {
        if (typeof window.ethereum !== "undefined") {
          this.web3 = new Web3(window.ethereum);
          await window.ethereum.enable();
        } else if (typeof window.web3 !== "undefined") {
          this.web3 = new Web3(window.web3.currentProvider);
        } else {
          this.web3 = new Web3(
            "https://mainnet.infura.io/v3/84a017e2ca8b4a02b39ab4c41bdbb1a2"
          ); // Update with your Ethereum node URL
        }
      } catch (error) {
        console.error("Error initializing web3:", error);
        throw error;
      }
    },
    async loadContract() {
      const abi = require("../assets/abi.json");
      this.contractInstance = await new this.web3.eth.Contract(
        abi,
        this.contractAddress
      );

      const accounts = await this.web3.eth.getAccounts();
      const isManager = await this.contractInstance.methods
        .isManager()
        .call({ from: accounts[0] });
      this.isManager = isManager;
      console.log("AM I MANAGER?", isManager);

      const currentState = await this.contractInstance.methods
        .getCurrentState()
        .call();
      const ticketPrice = await this.contractInstance.methods
        .ticketPrice()
        .call();
      const ticketPriceEth = await this.web3.utils.fromWei(
        ticketPrice,
        "ether"
      );
      const minimumPlayers = await this.contractInstance.methods
        .minimumPlayers()
        .call();

      const players = await this.contractInstance.methods.getPlayers().call();
      const ticketCount = players.length;

      const balance = await this.web3.eth.getBalance(this.contractAddress);

      if (balance) {
        this.balance = this.web3.utils.fromWei(Number(balance), "ether");
      } else {
        this.balance = 0;
      }

      const timeout = await this.contractInstance.methods
        .getTimoutStamp()
        .call();

      if (timeout) {
        this.timeout = Number(timeout);
      }

      this.currentState = Number(currentState);
      this.ticketPrice = Number(ticketPriceEth);
      this.minimumPlayers = minimumPlayers;
      this.players = players;
      this.ticketCount = Number(ticketCount);

      if (localStorage.getItem("txHash")) {
        this.showLoading(
          "Your last Transaction is still pending... Please wait until it is finished. Unfortunately it is not possible to participate until the transaction is finished."
        );
        await this.checkTransaction(localStorage.getItem("txHash"));
      } else {
        this.setIntervalCheckingContract();
      }
    },
    async enterLottery() {
      try {
        const accounts = await this.web3.eth.getAccounts();
        const ticketPriceWei = this.web3.utils.toWei(
          this.ticketPrice.toString(),
          "ether"
        );
        const playerAddress = accounts[0];
        const isPlayerEntered = await this.contractInstance.methods
          .hasPlayerEntered(playerAddress)
          .call();

        if (localStorage.getItem("txHash")) {
          try {
            Swal.close();
          } catch (e) {}
          this.showLoading(
            "Your Transaction is currently pending... Please wait until it is finished."
          );
          await this.checkTransaction(localStorage.getItem("txHash"));
        } else if (isPlayerEntered) {
          await this.showAlert(
            "Already Entered",
            "You have already entered. Please wait until the winner is picked.",
            "info"
          );
        } else {
          this.showLoading(
            "Please wait until the Transaction is complete. WARNING! Don't close this window until the process is finished!"
          );

          console.log("ACCOUNT", accounts);

            result = await this.contractInstance.methods
              .enter(ticketPriceWei)
              .send({ from: accounts[0], value: ticketPriceWei });

          // retrieve hash and check for completion
          const txHash = result.transactionHash;
          localStorage.setItem("txHash", "Tom");
          console.log("txHash", txHash);

          // wait until transaction is complete
          this.checkTransaction(txHash);
        }
      } catch (error) {
        Swal.close();
        this.setIntervalCheckingContract();
        try {
          localStorage.removeItem("txHash");
        } catch (e) {}
        this.showAlert("Error occurred during Transaction.", error, "error");
      }
    },
    async getCurrentGasPrice(){
      const gasPrice = await this.web3.eth.getGasPrice();
      console.log("RAW price", gasPrice);
      console.log('Current gas price:', this.web3.utils.fromWei(gasPrice, 'wei'), 'Gwei');
    },
    async showLoading(message) {
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
          confirmButton: "alert-ok-button", // Apply custom class to the confirm button
          cancelButton: "alert-cancel-button", // Apply custom class to the cancel button
        },
      });
    },

    async showAlert(title, message, icon) {
      Swal.fire({
        title,
        text: message,
        icon,
        customClass: {
          confirmButton: "alert-ok-button", // Apply custom class to the confirm button
          cancelButton: "alert-cancel-button", // Apply custom class to the cancel button
        },
      });
    },

    async waitForTransactionCompletion(transactionHash) {
      try {
        let receipt = null;
        while (receipt === null) {
          receipt = await this.web3.eth.getTransactionReceipt(transactionHash);
          console.log("RECEIPT", receipt);
          if (receipt && receipt.status == false) {
            throw new Error("Transaction failed or reverted");
          } else {
            await new Promise((resolve) => setTimeout(resolve, 3000)); // Delay between each check (e.g., 3 seconds)
          }
        }
        return receipt;
      } catch (e) {
        console.log(e);
        return null;
      }
    },

    async checkTransaction(txHash) {
      try {
        const transactionResult = await this.waitForTransactionCompletion(
          txHash
        );
        console.log("RESULT", transactionResult);
        // check result
        if (transactionResult) {
          Swal.close();
          await this.showAlert(
            "Success",
            "Transaction finished successfully. You entered lottery!",
            "success"
          );
        } else {
          Swal.close();
          await this.showAlert(
            "Error",
            "Something went wrong during transaction. Please try again.",
            "error"
          );
        }
        localStorage.removeItem("txHash");
      } catch (e) {
        Swal.close();
        this.showAlert("Error occurred during Transaction.", e, "error");
        localStorage.removeItem("txHash");
      }
    },

    async setIntervalCheckingContract() {
      this.updateInterval = setInterval(async () => {
        const currentState = await this.contractInstance.methods
          .getCurrentState()
          .call();

        this.players = await this.contractInstance.methods.getPlayers().call();
        const ticketPriceWei = await this.contractInstance.methods
          .ticketPrice()
          .call();

        this.ticketPrice = await this.web3.utils.fromWei(
          ticketPriceWei,
          "ether"
        );

        this.minimumPlayers = await this.contractInstance.methods
          .minimumPlayers()
          .call();

        this.ticketCount = (
          await this.contractInstance.methods.getPlayers().call()
        ).length;

        const balance = await this.web3.eth.getBalance(this.contractAddress);

        if (balance) {
          this.balance = this.web3.utils.fromWei(Number(balance), "ether");
        } else {
          this.balance = 0;
        }

        const timeout = await this.contractInstance.methods
          .getTimoutStamp()
          .call();

        if (timeout) {
          this.timeout = Number(timeout);
        }

        if (this.currentState !== Number(currentState)) {
          try {
            const accounts = await this.web3.eth.getAccounts();
            if (accounts && accounts.length) {
              const isPlayerWinner = await this.contractInstance.methods
                .checkIfWinner()
                .call({ from: address[0] });
              console.log("AM I WINNER?", isPlayerWinner);
            }
          } catch (e) {}
        }

        this.currentState = Number(currentState);
      }, 5000);
    },

    async changeTicketPrice() {
      try {
        const accounts = await this.web3.eth.getAccounts();
        await this.contractInstance.methods
          .changeTicketPrice(
            this.web3.utils.toWei(this.managerTicketPrice.toString(), "ether")
          )
          .send({ from: accounts[0] });
      } catch (error) {
        console.error("Failed to change ticket price", error);
      }
    },
    async changeMinimumPlayers() {
      try {
        const accounts = await this.web3.eth.getAccounts();
        await this.contractInstance.methods
          .changeMinimumPlayers(this.managerMinimumPlayer)
          .send({ from: accounts[0] });
      } catch (error) {
        console.error("Failed to change minimum players", error);
      }
    },
    async resetLottery() {
      try {
        const accounts = await this.web3.eth.getAccounts();
        await this.contractInstance.methods
          .resetLottery()
          .send({ from: accounts[0] });
      } catch (error) {
        console.error("Failed to reset lottery", error);
      }
    },
    async closeLotteryAndPickWinner() {
      try {
        const accounts = await this.web3.eth.getAccounts();
        const estimate = await this.contractInstance.methods.closeLotteryAndPickWinner().estimateGas({from: accounts[0]});
        console.log("ESTIMATE", estimate);
        const res = await this.contractInstance.methods
          .closeLotteryAndPickWinner()
          .send({ from: accounts[0] });
        const txHash = res.transactionHash;
        await this.checkTransaction(txHash);
      } catch (error) {
        console.error("Failed to close lottery and pick winner", error);
      }
    },
  },
};
</script>

<template>
  <div class="container">
    <div class="meta-info">
      <img src="../assets/metamask.png" alt="MetaMask" class="metamask-logo" />
      <p>You need a MetaMask-Wallet to join this lottery!</p>
    </div>

    <div class="overlay"></div>

    <div class="header">
      <div v-if="timeout > Date.now()">
        Timeout {{ timeout - Date.now() }} seconds!
      </div>
      <div
        v-if="
          currentState === 0 || (currentState === 3 && timeout < Date.now())
        "
        class="status-open"
      >
        <p class="status-message">Quokka is currently open for entries!</p>
      </div>
      <div v-else-if="currentState === 1" class="status-closed">
        <p class="status-message">
          Lottery is closed. Waiting for the winner to be picked!
        </p>
      </div>
      <p class="loading" v-else>Connect your Wallet to the Lottery ...</p>
      <!-- <div v-if="currentState === 3" class="status-finished">
        <p class="status-message">
          Lottery has finished. Latest Winner: <span class="winner">{{ winner }}</span>
        </p>
      </div> -->
    </div>

    <div class="content">
      <div v-if="this.balance">
        <div class="pot">POT currently: {{ this.balance }} ETH!</div>
        <div class="money-pot-container">
          <img
            :src="moneyPotIcon"
            alt="money-pot"
            class="money-pot"
            width="50"
            height="50"
          />
        </div>
      </div>
      <div
        v-if="
          currentState === 0 || (currentState === 3 && timeout < Date.now())
        "
        class="lottery-info"
      >
        <div class="eth-ticket-container">
          <div class="eth-container">
            <p>{{ ticketPrice }}</p>
            <img src="../assets/ethereum.png" alt="eth" class="eth" />
          </div>

          <div class="ticket-container">
            <p>{{ ticketCount }} / {{ minimumPlayers }}</p>
            <img src="../assets/fahrkarte.png" alt="ticket" class="ticket" />
          </div>
        </div>

        <div>
          <p>Press the Quokka to enter!</p>
        </div>
        <button class="entry-lottery-btn" @click="enterLottery"></button>
      </div>

      <!-- <div v-if="win === true && currentState === BigInt(2n)" class="winning-message">
        <p>Congratulations you won the lottery!</p>
      </div>
      <div v-if="win === false && currentState === BigInt(2n)" class="losing-message">
        <p> Sorry you did not win the lottery!</p>
      </div> -->
      <div class="manager-actions" v-if="this.isManager">
        <h2>Manager Functions</h2>
        <label>Ticket Price: </label>
        <input type="number" v-model="managerTicketPrice" />
        <button @click="changeTicketPrice">Change Ticket Price</button>

        <label>Minimum Players: </label>
        <input type="number" v-model="managerMinimumPlayer" />
        <button @click="changeMinimumPlayers">Change Minimum Players</button>

        <button @click="resetLottery">Reset Lottery</button>
        <button @click="closeLotteryAndPickWinner">
          Close Lottery and Pick Winner
        </button>
      </div>
    </div>
  </div>
</template>

<style>
.pot {
  padding: 15px;
}
.manager-actions {
  display: flex;
  flex-direction: column;
  align-items: center;
}

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

.alert-ok-button,
.alert-cancel-button {
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

.entry-lottery-btn {
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
  padding: 50px;
  border-radius: 10px;
  -webkit-box-shadow: 5px 5px 9px -1px rgba(255, 255, 255, 0.35);
  box-shadow: 5px 5px 9px -1px rgba(255, 255, 255, 0.35);
  position: relative;
  overflow: hidden;
  background-image: linear-gradient(to bottom right, #fdfcfb, #e2d1c3);
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

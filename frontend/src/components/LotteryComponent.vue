<template>
  <div class="lottery-container">
    <transition name="fade">
      <h2 v-if="showTitle">Enter Lottery</h2>
    </transition>

    <div class="input-group">
      <input type="text" v-model="amount" placeholder="Amount of tokens to enter" />
      <button @click="enterLottery" class="enter-button">Enter Lottery</button>
    </div>

    <transition name="slide-fade">
      <div v-if="showWinnerSection" class="winner-section">
        <h2>Admin Only: Pick Winner</h2>
        <button @click="pickWinner" class="pick-winner-button">Pick Winner</button>
      </div>
    </transition>

    <!-- Display error message if an error occurred -->
    <div v-if="errorMessage" class="error-message">
      {{ errorMessage }}
    </div>

    <!-- Display list of participants -->
    <div v-if="participants.length > 0" class="participant-list">
      <h3>Participants:</h3>
      <ul>
        <li v-for="participant in participants" :key="participant.id">{{ participant.name }}</li>
      </ul>
    </div>

    <!-- Show confetti if user is the winner -->
    <div v-if="isWinner" class="confetti">
      <!-- Confetti animation or celebration message -->
      Congratulations! You are the winner!
    </div>
  </div>
</template>

<script>
import Web3 from "web3";
// Import confetti library or component if available

export default {
  data() {
    return {
      web3: null,
      lotteryContract: null,
      amount: "",
      showTitle: true,
      showWinnerSection: false,
      errorMessage: "", // New data property for error message
      participants: [], // New data property for participant list
      isWinner: false, // New data property for winner flag
    };
  },
  async mounted() {
    try {
      if (window.ethereum) {
        this.web3 = new Web3(window.ethereum);
        await window.ethereum.request({ method: "eth_requestAccounts" });

        const contractABI = []; // Set your contract ABI here
        const contractAddress = ""; // Set your contract address here

        this.lotteryContract = new this.web3.eth.Contract(contractABI, contractAddress);
      }
      setTimeout(() => {
        this.showWinnerSection = true;
        this.participants = [ // Mock participant data, replace with actual logic to fetch participants
          { id: 1, name: "Participant 1" },
          { id: 2, name: "Participant 2" },
          { id: 3, name: "Participant 3" },
        ];
      }, 1000);
    } catch (error) {
      this.errorMessage = "An error occurred while initializing the app.";
      console.error(error);
    }
  },
  methods: {
    async enterLottery() {
      try {
        const accounts = await this.web3.eth.getAccounts();
        await this.lotteryContract.methods.enter(this.amount).send({ from: accounts[0] });
      } catch (error) {
        this.errorMessage = "An error occurred while entering the lottery.";
        console.error(error);
      }
    },
    async pickWinner() {
      try {
        const accounts = await this.web3.eth.getAccounts();
        await this.lotteryContract.methods.pickWinner().send({ from: accounts[0] });
        // Check if user's account is the winner and set isWinner flag accordingly
        // Replace the following logic with actual implementation based on your contract's winner selection mechanism
        const userAccount = accounts[0];
        const winnerAccount = ""; // Set the winner account here
        this.isWinner = userAccount.toLowerCase() === winnerAccount.toLowerCase();
      } catch (error) {
        this.errorMessage = "An error occurred while picking the winner.";
        console.error(error);
      }
    },
  },
};
</script>

<style scoped>
.lottery-container {
  text-align: center;
  max-width: 500px;
  margin: 0 auto;
  padding: 40px;
  background-color: #f9f9f9;
  border-radius: 8px;
}

.input-group {
  margin-bottom: 20px;
}

.enter-button,
.pick-winner-button {
  margin-left: 10px;
  background-color: #4caf50;
  color: white;
  border: none;
  padding: 10px 20px;
  text-align: center;
  text-decoration: none;
  display: inline-block;
  font-size: 16px;
  border-radius: 4px;
  cursor: pointer;
}

.pick-winner-button {
  background-color: #f44336;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 1s;
}
.fade-enter,
.fade-leave-to /* .fade-leave-active in <2.1.8 */ {
  opacity: 0;
}

.slide-fade-enter-active {
  transition: all 1s ease;
}
.slide-fade-leave-active {
  transition: all 0.5s cubic-bezier(1.0, 0.5, 0.8, 1.0);
}
.slide-fade-enter,
.slide-fade-leave-to {
  transform: translateY(10px);
  opacity: 0;
}

.error-message {
  color: red;
  margin-top: 10px;
}

.participant-list {
  margin-top: 20px;
}

.confetti {
  margin-top: 20px;
  font-weight: bold;
  color: #4caf50;
}
</style>

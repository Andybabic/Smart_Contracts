

<script>
import LotteryComponent from "./components/LotteryComponent.vue";
import {Countdown} from 'vue3-flip-countdown'

export default {
  name: "App",
  components: {
    LotteryComponent,
    Countdown,
  },
  data() {
    return {
      targetTimestamp: 0,
    };
  },
};
</script>


<template>
  <header class="header">
      <img src="./assets/QuokkaDol.jpg" class="logo" />
      <nav class="menu">
        <ul>
          <li><a href="#">Win</a></li>
          <li><a href="#">About</a></li>
          <li><a href="#">Contact</a></li>
        </ul>
      </nav>
    </header>
  <div id="app">

    



    <main class="content">


     <Countdown :targetTimestamp="targetTimestamp" />
 
      <LotteryComponent />
    </main>

    <footer class="footer">
      <p>&copy; 2023 Your App. All rights reserved.</p>
    </footer>
  </div>
</template>

<style>
#app {
  text-align: center;
  padding: 40px;
  background-color: gold;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  width: 100%;
  padding: 10px;
}

.logo {
  height: 100px;
  width: 100px;
}

.menu ul {
  list-style: none;
  display: flex;
  gap: 20px;
}

.menu ul li a {
  text-decoration: none;
  color: #333;
  font-weight: bold;
}

.content {
  flex-grow: 2;
}

.footer {
  margin-top: auto;
  padding: 20px;
  background-color: #f9f9f9;
  width: 100%;
  color: #333;
}
</style>

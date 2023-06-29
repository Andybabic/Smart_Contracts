<template>
  <div id="app">
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

    <lottery-component></lottery-component>

    <footer class="footer">
      <p>&copy; 2023 Your App. All rights reserved.</p>
    </footer>
  </div>
</template>

<script>
import LotteryComponent from "./components/LotteryComponent.vue";

export default {
  name: "App",
  components: {
    LotteryComponent
  }
};
</script>

<style>
#app {
  text-align: center;
  padding: 40px;
  background-color: #4b3927;
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
  color: #fff;
  font-weight: bold;
}

.footer {
  margin-top: auto;
  padding: 20px;
  background-color: #f9f9f9;
  width: 100%;
  color: #333;
}
</style>
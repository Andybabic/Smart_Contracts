<template>
  <div id="app">
    <lottery-component></lottery-component>
  </div>
</template>

<script>
import LotteryComponent from "./components/Lottery.vue";

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
}

</style>
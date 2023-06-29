

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

  <div id="app">

    <Countdown :targetTimestamp="targetTimestamp" />

    <LotteryComponent />



  </div>

</template>

<style>

#app {
  text-align: center;
  min-height: 100vh;  
  display: flex;
  flex-direction: column;
  align-items: center;
  font-family: "Avenir", Helvetica, Arial, sans-serif;
  color: #2c3e50;
  


}


.logo {
  height: 100px;
  width: 100px;
}


</style>

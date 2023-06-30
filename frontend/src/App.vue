

<script>
import LotteryComponent from "./components/LotteryComponent.vue";

export default {
  name: "App",
  components: {
    LotteryComponent,
  },
  data() {
    return {
      
    };
  },
};
</script>


<template>

  <div id="app">
    

    <LotteryComponent />

    <video autoplay loop muted>
      <source src="./assets/gambling-background-casino-and-poker-concept-2023-04-14-17-11-37-utc.mp4" type="video/mp4">
    </video>

  </div>

</template>

<style>

video {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  z-index: -1;
  filter: blur(3px);
}

#app {
  text-align: center;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-family: Arial, Helvetica, sans-serif;
}
.quokka-image {
  width: 300px; /* Adjust the width as needed */
  height: auto;
  margin-bottom: 20px; /* Add margin to create space between the image and other elements */
}

.logo {
  height: 100px;
  width: 100px;
}

@media screen and (max-width: 600px) {
  #app {
    font-size: 10px;
  }

  body{
    font-size: 10px;
  }
  
}


</style>

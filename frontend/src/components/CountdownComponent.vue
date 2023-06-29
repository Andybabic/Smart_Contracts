<template>
    <div class="flip-clock">
      <div class="flip-card">
        <div class="flip-card-inner" :class="flipAnimationClass">
          <div class="flip-card-front">
            <div class="flip-card-top">
              <span>{{ minutes }}</span>
            </div>
            <div class="flip-card-bottom">
              <span>{{ formattedMinutes }}</span>
            </div>
          </div>
          <div class="flip-card-back">
            <div class="flip-card-top">
              <span>{{ nextMinutes }}</span>
            </div>
            <div class="flip-card-bottom">
              <span>{{ formattedNextMinutes }}</span>
            </div>
          </div>
        </div>
      </div>
      <div class="flip-card">
        <div class="flip-card-inner" :class="flipAnimationClass">
          <div class="flip-card-front">
            <div class="flip-card-top">
              <span>{{ seconds }}</span>
            </div>
            <div class="flip-card-bottom">
              <span>{{ formattedSeconds }}</span>
            </div>
          </div>
          <div class="flip-card-back">
            <div class="flip-card-top">
              <span>{{ nextSeconds }}</span>
            </div>
            <div class="flip-card-bottom">
              <span>{{ formattedNextSeconds }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </template>
  
  <script>
  export default {
    data() {
      return {
        countdownInterval: null,
        targetTimestamp: 0,
        remainingTime: 0,
        flipAnimationClass: ''
      };
    },
    computed: {
      minutes() {
        return Math.floor(this.remainingTime / 60);
      },
      seconds() {
        return this.remainingTime % 60;
      },
      nextMinutes() {
        return Math.floor((this.remainingTime - 1) / 60);
      },
      nextSeconds() {
        return (this.remainingTime - 1) % 60;
      },
      formattedMinutes() {
        return this.minutes.toString().padStart(2, '0');
      },
      formattedSeconds() {
        return this.seconds.toString().padStart(2, '0');
      },
      formattedNextMinutes() {
        return this.nextMinutes.toString().padStart(2, '0');
      },
      formattedNextSeconds() {
        return this.nextSeconds.toString().padStart(2, '0');
      }
    },
    mounted() {
      this.startCountdown();
    },
    beforeUnmount() {
      this.stopCountdown();
    },
    methods: {
      startCountdown() {
        const now = Math.floor(Date.now() / 1000);
        const remainingTime = this.targetTimestamp - now;
        if (remainingTime <= 0) {
          this.remainingTime = 0;
        } else {
          this.remainingTime = remainingTime;
          this.countdownInterval = setInterval(() => {
            this.remainingTime--;
            if (this.remainingTime <= 0) {
              this.stopCountdown();
            }
          }, 1000);
        }
      },
      stopCountdown() {
        clearInterval(this.countdownInterval);
      },
      flipCard() {
        this.flipAnimationClass = 'flip-animation';
        setTimeout(() => {
          this.flipAnimationClass = '';
        }, 1000);
      }
    },
    props: {
      timestamp: {
        type: Number,
        required: true
      }
    },
    watch: {
      timestamp: {
        immediate: true,
        handler() {
          const now = Math.floor(Date.now() / 1000);
          this.targetTimestamp = this.timestamp;
          this.remainingTime = this.targetTimestamp - now;
          this.startCountdown();
        }
      },
      remainingTime() {
        this.flipCard();
        if (this.remainingTime <= 0) {
          this.stopCountdown();
        }
      }
    }
  };
  </script>
  
  <style>
  .flip-clock {
    display: flex;
    justify-content: center;
    align-items: center;
  }
  
  .flip-card {
    perspective: 1000px;
    margin: 0 5px;
  }
  
  .flip-card-inner {
    position: relative;
    width: 80px;
    height: 120px;
    transform-style: preserve-3d;
    transition: transform 0.5s;
  }
  
  .flip-card-front,
  .flip-card-back {
    position: absolute;
    width: 100%;
    height: 100%;
    backface-visibility: hidden;
  }
  
  .flip-card-front {
    background-color: #f1f1f1;
    color: #333;
    transform: rotateY(0deg);
  }
  
  .flip-card-back {
    background-color: #333;
    color: gold;
    transform: rotateY(180deg);
  }
  
  .flip-card-top {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 50%;
    font-size: 48px;
    font-weight: bold;
    transform: rotateX(0deg);
    transition: transform 0.5s;
    color: gold;
  }
  
  .flip-card-bottom {
    display: flex;
    justify-content: center;
    align-items: center;
    height: 50%;
    font-size: 24px;
    font-weight: bold;
    transform: rotateX(180deg);
    transition: transform 0.5s;
    color: gold;
  }
  
  .flip-card-inner.flip-animation .flip-card-top {
    transform: rotateX(-180deg);
  }
  
  .flip-card-inner.flip-animation .flip-card-bottom {
    transform: rotateX(0deg);
  }
  </style>
  
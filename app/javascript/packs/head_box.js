import Vue from 'vue/dist/vue.esm'
import HeadBox from '../head_box.vue'

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#header',
    components: { HeadBox }
  })
})

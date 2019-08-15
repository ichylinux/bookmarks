import Vue from 'vue/dist/vue.esm'
import VueMaterial from 'vue-material'
import 'vue-material/dist/vue-material.min.css'
import App from '../app.vue'

Vue.use(VueMaterial)

document.addEventListener('DOMContentLoaded', () => {
  const app = new Vue({
    el: '#app',
    components: { App }
  })
})

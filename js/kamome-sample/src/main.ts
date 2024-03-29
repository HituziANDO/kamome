import { createApp } from 'vue';

import './style.css';
import App from './App.vue';

import 'vuetify/styles';
import { createVuetify } from 'vuetify';
import * as components from 'vuetify/components';
import * as directives from 'vuetify/directives';
import colors from 'vuetify/util/colors';

const vuetify = createVuetify({
  components,
  directives,
  theme: {
    themes: {
      light: {
        dark: true,
        colors: {
          primary: colors.deepPurple.accent4,
        },
      },
    },
  },
});

createApp(App).use(vuetify).mount('#app');

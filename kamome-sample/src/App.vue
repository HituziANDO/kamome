<template>
  <v-app id="app">
    <v-app-bar app color="deep-purple accent-4" dark height="90">
      <v-toolbar-title>Kamome Sample App</v-toolbar-title>
    </v-app-bar>

    <v-main>
      <v-simple-table>
        <template v-slot:default>
          <thead>
          <tr>
            <th class="text-left">Message</th>
          </tr>
          </thead>
          <tbody>
          <tr v-for="(message, idx) in messages" :key="idx" @click="onClickMessage(idx)">
            <td>{{ message }}</td>
          </tr>
          </tbody>
        </template>
      </v-simple-table>

      <v-bottom-sheet v-model="sheet">
        <template v-slot:activator="{ on, attrs }">
          <v-btn
              color="deep-purple accent-4"
              dark
              v-bind="attrs"
              v-on="on"
              class="menu-button"
          >
            Menu
          </v-btn>
        </template>
        <v-list>
          <v-btn fab dark small color="pink" class="close-menu-button" @click="onCloseMenu">
            <v-icon>mdi-minus</v-icon>
          </v-btn>
          <v-subheader>Menu</v-subheader>
          <v-list-item v-for="tile in tiles" :key="tile.key" @click="onClickSheetItem(tile.key)" class="center">
            <v-list-item-title>{{ tile.title }}</v-list-item-title>
          </v-list-item>
        </v-list>
      </v-bottom-sheet>
    </v-main>
  </v-app>
</template>

<script>
import { KM } from "./kamome";

export default {
  name: 'App',
  components: {},
  data: () => ({
    sheet: false,
    tiles: [
      { key: 1, title: 'Send Data to Native' },
      { key: 2, title: 'Error from Native' },
      { key: 3, title: 'Timeout Sample' },
      { key: 4, title: 'Non-existent Command' },
    ],
    count: 0,
    messages: [],
  }),
  methods: {
    async onClickSheetItem(key) {
      if (key === 1) {
        const data = await KM.send('echo', {
          message: 'Hello World! [\'"+-._~\\@#$%^&*=,/?;:|{}] (' + (++this.count) + ')'
        })
        this.messages.push(data.message)
      } else if (key === 2) {
        try {
          await KM.send('echoError')
        } catch (error) {
          this.messages.push(error)
        }
      } else if (key === 3) {
        try {
          await KM.send('tooLong')
        } catch (error) {
          this.messages.push(error)
        }
      } else if (key === 4) {
        try {
          await KM.send('NO_EXISTENT_CMD')
        } catch (error) {
          this.messages.push(error)
        }
      }
    },
    onCloseMenu() {
      this.sheet = false
    },
    onClickMessage(idx) {
      window.console.log(`[${idx}] ${this.messages[idx]}`)
    },
  },
  created() {
    // Set default timeout in millisecond.
    KM.setDefaultRequestTimeout(3000)

    // Add a receiver that receives a message sent by the native client.
    KM.addReceiver('greeting', (data, resolve) => {
      // The data is the object sent by the native client.
      this.messages.push(data.greeting)

      // Run asynchronous something to do...
      setTimeout(() => {
        // Return a result as any object or null to the native client.
        resolve('OK!')
        // If the task is failed, call `reject()` function.
        //reject('Error message')
      }, 1000)
    })

    // When there is no Kamome's iOS/Android native client, that is, when you run with a browser alone,
    // you can register the processing of each command.
    KM.browser
        .addCommand("echo", (data, resolve) => {
          // Success
          resolve({ message: data["message"] })
        })
        .addCommand("echoError", (data, resolve, reject) => {
          // Failure
          reject("Echo Error! ['\"+-._~\\@#$%^&*=,/?;:|{}]")
        })
        .addCommand("tooLong", (data, resolve) => {
          // Too long process...
          setTimeout(() => {
            resolve()
          }, 30000)
        })
  }
}
</script>

<style>
html {
  -webkit-touch-callout: none;
  -webkit-text-size-adjust: none;
  -webkit-user-select: none;
  -webkit-tap-highlight-color: rgba(0, 0, 0, 0);
}

input {
  -webkit-user-select: text;
}

.center {
  text-align: center;
}

.menu-button {
  position: fixed;
  bottom: 64px;
  left: 20px;
  width: 100px;
}

.close-menu-button {
  float: right;
  top: 4px;
  right: 8px;
}
</style>

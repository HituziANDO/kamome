<script setup lang="ts">
import { onMounted, ref } from 'vue';

type ResolveFunc = (data?: any | null) => void;
type RejectFunc = (reason?: string) => void;

// @ts-ignore
const KM = window.Kamome.KM;

const APP_BAR_HEIGHT = 90;

const messages = ref<string[]>([]);

const menuItems: { key: number; title: string }[] = [
  { key: 1, title: 'Send Data to Native' },
  { key: 2, title: 'Return Error from Native' },
  { key: 3, title: 'Timeout Sample' },
  { key: 4, title: 'Non-existent Command' },
];

let count = 0;

const onMenuItemClicked = async (key: number) => {
  if (key === 1) {
    const data = await KM.send('echo', {
      message: 'Hello World! [\'"+-._~\\@#$%^&*=,/?;:|{}] (' + ++count + ')',
    });
    messages.value.push(data.message);
  } else if (key === 2) {
    try {
      await KM.send('echoError');
    } catch (error) {
      messages.value.push(error as string);
    }
  } else if (key === 3) {
    try {
      await KM.send('tooLong');
    } catch (error) {
      messages.value.push(error as string);
    }
  } else if (key === 4) {
    try {
      await KM.send('NO_EXISTENT_CMD');
    } catch (error) {
      messages.value.push(error as string);
    }
  }
};

onMounted(() => {
  // Set default timeout in millisecond.
  KM.setDefaultRequestTimeout(3000);

  // Add a receiver that receives a message sent by the native client.
  KM.addReceiver('greeting', (data: any, resolve: ResolveFunc, reject: RejectFunc) => {
    // The data is the object sent by the native client.
    messages.value.push(data.greeting);

    // Run asynchronous something to do...
    setTimeout(() => {
      // Return a result as any object or null to the native client.
      resolve('OK!');
      // If the task is failed, call `reject()` function.
      //reject('Error message')
    }, 1000);
  });

  // When there is no Kamome iOS, Android, or Flutter client, that is, when you run with a browser alone,
  // you can register the processing of each command.
  KM.browser
    .addCommand('echo', (data: any, resolve: ResolveFunc, reject: RejectFunc) => {
      // Success
      resolve({ message: data['message'] });
    })
    .addCommand('echoError', (data: any, resolve: ResolveFunc, reject: RejectFunc) => {
      // Failure
      reject('Echo Error! [\'"+-._~\\@#$%^&*=,/?;:|{}]');
    })
    .addCommand('tooLong', (data: any, resolve: ResolveFunc, reject: RejectFunc) => {
      // Too long process...
      setTimeout(() => {
        resolve();
      }, 30000);
    })
    .addCommand('testCommand', () => {})
    .removeCommand('testCommand');

  console.assert(!KM.browser.hasCommand('testCommand'), 'KM.browser should remove testCommand.');

  console.log('KM.VERSION_CODE=' + KM.VERSION_CODE);

  console.assert(KM.isReady(), 'The Kamome JS library is not ready.');

  // Set a ready event listener.
  // The listener is called when Kamome iOS, Android, or Flutter client goes ready state.
  KM.setReadyEventListener(() => {
    // KM.isReady() returns true.
    console.log('KM.isReady() is ' + KM.isReady());

    // If KM has no native clients...
    if (KM.hasNoClients()) {
      // Sends a message to the receiver added by KM.addReceiver method.
      KM.browser.send('greeting', { greeting: 'Hi!' }).then(console.log).catch(console.error);
    }
  });
});
</script>

<template>
  <v-app>
    <v-container>
      <v-app-bar color="primary" :height="APP_BAR_HEIGHT">
        <v-toolbar-title>Kamome Sample App</v-toolbar-title>
      </v-app-bar>

      <v-list lines="one" :style="{ marginTop: `${APP_BAR_HEIGHT}px` }">
        <v-list-item v-for="(message, idx) in messages" :key="idx" density="compact">
          <v-list-item-title style="font-size: 0.8rem">{{ message }}</v-list-item-title>
        </v-list-item>
      </v-list>

      <v-bottom-sheet>
        <template #activator="{ props }">
          <v-btn v-bind="props" class="menu-button" text="Menu" color="primary"> </v-btn>
        </template>
        <v-list lines="one">
          <v-list-item
            v-for="menuItem in menuItems"
            :key="menuItem.key"
            :title="menuItem.title"
            class="center"
            @click="onMenuItemClicked(menuItem.key)"
          >
          </v-list-item>
        </v-list>
      </v-bottom-sheet>
    </v-container>
  </v-app>
</template>

<style scoped>
.center {
  text-align: center;
}

.menu-button {
  position: fixed;
  bottom: 64px;
  right: 24px;
  width: 100px;
}
</style>

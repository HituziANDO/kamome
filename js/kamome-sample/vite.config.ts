// @ts-ignore
import { resolve } from 'path'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// @ts-ignore
const processEnv = process.env;

// https://vitejs.dev/config/
export default defineConfig({
  define: {
    'process.env': processEnv,
  },
  plugins: [vue()],
  build: {
    lib: {
      // @ts-ignore
      entry: resolve(__dirname, 'src/main.ts'),
      name: 'SampleApp',
      formats: ['umd'],
      fileName: (format) => 'main.js'
    },
  },
})

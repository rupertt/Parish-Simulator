import { defineConfig } from 'vite';

export default defineConfig({
  root: '.',
  build: {
    outDir: 'dist/client',
    emptyOutDir: true
  },
  server: {
    port: 5173,
    strictPort: false,
    proxy: {
      '/config': {
        target: 'http://localhost:3000'
      },
      '/socket.io': {
        target: 'http://localhost:3000',
        ws: true
      }
    }
  }
});

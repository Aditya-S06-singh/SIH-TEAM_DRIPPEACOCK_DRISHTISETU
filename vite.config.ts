import react from '@vitejs/plugin-react';
import basicSsl from '@vitejs/plugin-basic-ssl';
import { defineConfig } from 'vite';

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), basicSsl()],
  server: {
    host: true, // Exposes to LAN so your phone can open it
    port: 5173,
  },
  build: {
    chunkSizeWarningLimit: 1600,
  },
});

import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import fs from 'fs';
import path from 'path';

const DB_FOLDER = path.join(process.env.HOME || process.env.USERPROFILE || '', 'Desktop', 'CRM Data');
const DB_FILE = path.join(DB_FOLDER, 'database.db');

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  optimizeDeps: {
    exclude: ['lucide-react'],
  },
  server: {
    middleware: [
      // Database middleware
      async (req, res, next) => {
        if (req.url?.startsWith('/api/db')) {
          // Ensure folder exists
          if (!fs.existsSync(DB_FOLDER)) {
            fs.mkdirSync(DB_FOLDER, { recursive: true });
          }

          if (req.method === 'GET') {
            try {
              const data = fs.existsSync(DB_FILE) ? fs.readFileSync(DB_FILE) : null;
              res.setHeader('Content-Type', 'application/octet-stream');
              res.end(data);
            } catch (error) {
              res.statusCode = 500;
              res.end(JSON.stringify({ error: 'Failed to read database' }));
            }
          } else if (req.method === 'POST') {
            try {
              const chunks: Buffer[] = [];
              req.on('data', chunk => chunks.push(chunk));
              req.on('end', () => {
                const buffer = Buffer.concat(chunks);
                fs.writeFileSync(DB_FILE, buffer);
                res.end(JSON.stringify({ success: true }));
              });
            } catch (error) {
              res.statusCode = 500;
              res.end(JSON.stringify({ error: 'Failed to write database' }));
            }
          } else {
            next();
          }
        } else {
          next();
        }
      }
    ]
  }
});
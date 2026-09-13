import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

import creditsRoutes from './routes/credits.routes';
import circlesRoutes from './routes/circles.routes';
import moviscoreRoutes from './routes/moviscore.routes';
import marketplaceRoutes from './routes/marketplace.routes';
import profileRoutes from './routes/profile.routes';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (_req, res) => res.json({ ok: true, service: 'movicash-backend' }));

app.use('/api/creditos', creditsRoutes);
app.use('/api/circulos', circlesRoutes);
app.use('/api/moviscore', moviscoreRoutes);
app.use('/api/marketplace', marketplaceRoutes);
app.use('/api/perfil', profileRoutes);

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`✅ MoviCash backend corriendo en http://localhost:${PORT}`);
});

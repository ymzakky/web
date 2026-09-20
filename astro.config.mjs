import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
	site: 'https://www.musubi-kanaderu.net',
	integrations: [
		sitemap({
			filter: (page) => !page.includes('/seminar/'),
		}),
	],
	vite: {
		optimizeDeps: {
			noDiscovery: true,
			include: [],
		},
	},
});

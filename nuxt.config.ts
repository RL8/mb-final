// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-05-15',
  devtools: { enabled: true },

  modules: [
    '@nuxt/content',
    '@nuxt/ui',
    '@nuxt/test-utils',
    '@nuxt/scripts',
    '@nuxt/image',
    '@nuxt/icon',
    '@nuxt/fonts',
    '@nuxt/eslint',
    '@vite-pwa/nuxt'
  ],
  
  // PWA Configuration
  pwa: {
    registerType: 'autoUpdate',
    manifest: {
      name: 'MindBridge Chat',
      short_name: 'MindBridge',
      description: 'An AI-powered chat application with contextual input and sideboard features',
      theme_color: '#4F46E5',
      background_color: '#ffffff',
      icons: [
        {
          src: 'icons/icon-64x64.png',
          sizes: '64x64',
          type: 'image/png'
        },
        {
          src: 'icons/icon-144x144.png',
          sizes: '144x144',
          type: 'image/png'
        },
        {
          src: 'icons/icon-192x192.png',
          sizes: '192x192',
          type: 'image/png'
        },
        {
          src: 'icons/icon-512x512.png',
          sizes: '512x512',
          type: 'image/png'
        }
      ]
    },
    workbox: {
      navigateFallback: '/',
      globPatterns: ['**/*.{js,css,html,png,svg,ico}'],
      runtimeCaching: [
        {
          urlPattern: /^https:\/\/api\.mindbridge\.app\/.*$/,
          handler: 'NetworkFirst',
          options: {
            cacheName: 'api-cache',
            expiration: {
              maxEntries: 100,
              maxAgeSeconds: 60 * 60 * 24 // 1 day
            }
          }
        }
      ]
    },
    client: {
      installPrompt: true,
      periodicSyncForUpdates: 20 // check for updates every 20 minutes
    },
    devOptions: {
      enabled: true,
      suppressWarnings: false,
      type: 'module'
    }
  }
})
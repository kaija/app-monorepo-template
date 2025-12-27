/** @type {import('next').NextConfig} */

// Import configuration validation
const { config } = require('./lib/config-server')

const nextConfig = {
  // App Router is now stable in Next.js 15, no experimental flag needed
  
  // Environment variables (validated by config)
  env: {
    NEXT_PUBLIC_API_URL: config.apiUrl,
    NEXT_PUBLIC_APP_URL: config.appUrl,
    NEXT_PUBLIC_APP_NAME: config.appName,
  },

  // API proxy to backend
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: `${config.apiUrl}/api/:path*`,
      },
    ]
  },

  // Security headers
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          {
            key: 'X-Frame-Options',
            value: 'DENY',
          },
          {
            key: 'X-Content-Type-Options',
            value: 'nosniff',
          },
          {
            key: 'Referrer-Policy',
            value: 'strict-origin-when-cross-origin',
          },
          {
            key: 'X-XSS-Protection',
            value: '1; mode=block',
          },
          ...(config.isProduction ? [
            {
              key: 'Strict-Transport-Security',
              value: 'max-age=31536000; includeSubDomains',
            },
          ] : []),
        ],
      },
    ]
  },

  // Image optimization
  images: {
    domains: config.isDevelopment ? ['localhost'] : [],
    formats: ['image/webp', 'image/avif'],
  },

  // Compiler options
  compiler: {
    // Remove console logs in production
    removeConsole: config.isProduction,
  },

  // Output configuration for deployment
  output: 'standalone',
  
  // TypeScript configuration
  typescript: {
    // Type checking is handled by CI/CD pipeline
    ignoreBuildErrors: false,
  },

  // ESLint configuration
  eslint: {
    // Linting is handled by CI/CD pipeline
    ignoreDuringBuilds: false,
  },

  // Experimental features
  experimental: {
    // Enable server actions
    serverActions: true,
  },
}

module.exports = nextConfig
/** @type {import('next').NextConfig} */

const nextConfig = {
  // App Router is now stable in Next.js 15, no experimental flag needed

  // API proxy to backend (only if API URL is available)
  async rewrites() {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';
    return [
      {
        source: '/api/:path*',
        destination: `${apiUrl}/api/:path*`,
      },
    ]
  },

  // Security headers
  async headers() {
    const isProduction = process.env.NODE_ENV === 'production';
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
          ...(isProduction ? [
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
    domains: process.env.NODE_ENV === 'development' ? ['localhost'] : [],
    formats: ['image/webp', 'image/avif'],
  },

  // Compiler options
  compiler: {
    // Remove console logs in production
    removeConsole: process.env.NODE_ENV === 'production',
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
  // experimental: {
  //   // Server actions are now stable in Next.js 15
  // },
}

module.exports = nextConfig

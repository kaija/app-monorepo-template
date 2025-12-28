/**
 * Server-side configuration for Next.js
 * This file is used during build time and server-side rendering
 */

/**
 * Validate required environment variables
 */
function validateEnvironmentVariables() {
  const requiredVars = [
    'NEXT_PUBLIC_API_URL',
    'NEXT_PUBLIC_APP_URL',
    'NEXT_PUBLIC_APP_NAME'
  ];

  const missingVars = [];

  for (const varName of requiredVars) {
    if (!process.env[varName]) {
      missingVars.push(varName);
    }
  }

  if (missingVars.length > 0) {
    console.error('❌ Missing required environment variables:', missingVars.join(', '));
    console.error('Please check your .env.local file and ensure all required variables are set.');
    console.error('See .env.example for reference.');
    process.exit(1);
  }
}

/**
 * Validate production environment configuration
 */
function validateProductionConfig() {
  if (process.env.NODE_ENV !== 'production') {
    return;
  }

  const issues = [];

  // Check for HTTPS in production
  const apiUrl = process.env.NEXT_PUBLIC_API_URL;
  const appUrl = process.env.NEXT_PUBLIC_APP_URL;

  if (apiUrl && !apiUrl.startsWith('https://') && !apiUrl.includes('localhost')) {
    issues.push('API URL should use HTTPS in production');
  }

  if (appUrl && !appUrl.startsWith('https://') && !appUrl.includes('localhost')) {
    issues.push('App URL should use HTTPS in production');
  }

  // Check for development secrets
  const nextAuthSecret = process.env.NEXTAUTH_SECRET;
  if (nextAuthSecret && (
    nextAuthSecret.includes('dev') ||
    nextAuthSecret.includes('test') ||
    nextAuthSecret.length < 32
  )) {
    issues.push('NEXTAUTH_SECRET appears to be a development key or too short');
  }

  if (issues.length > 0) {
    console.error('❌ Production environment validation failed:');
    issues.forEach(issue => console.error(`  - ${issue}`));
    process.exit(1);
  }
}

/**
 * Create and validate application configuration
 */
function createConfig() {
  // Validate environment variables first
  validateEnvironmentVariables();
  validateProductionConfig();

  const config = {
    // Environment
    environment: process.env.NODE_ENV || 'development',
    isDevelopment: process.env.NODE_ENV === 'development',
    isProduction: process.env.NODE_ENV === 'production',

    // API Configuration
    apiUrl: process.env.NEXT_PUBLIC_API_URL,
    appUrl: process.env.NEXT_PUBLIC_APP_URL,
    appName: process.env.NEXT_PUBLIC_APP_NAME,

    // Feature Flags
    enableOAuth: process.env.NEXT_PUBLIC_ENABLE_OAUTH === 'true',
    enableRegistration: process.env.NEXT_PUBLIC_ENABLE_REGISTRATION === 'true',
    enableAnalytics: process.env.ENABLE_ANALYTICS === 'true',

    // Analytics
    googleAnalyticsId: process.env.NEXT_PUBLIC_GA_ID,

    // Timeouts
    apiTimeout: parseInt(process.env.API_TIMEOUT_MS || '10000', 10),
  };

  // Log configuration in development
  if (config.isDevelopment) {
    console.log('✅ Frontend configuration loaded successfully');
    console.log(`   Environment: ${config.environment}`);
    console.log(`   API URL: ${config.apiUrl}`);
    console.log(`   App URL: ${config.appUrl}`);
    console.log(`   OAuth enabled: ${config.enableOAuth}`);
  }

  return config;
}

// Export the configuration
const config = createConfig();

module.exports = { config };

/**
 * Frontend configuration with environment validation
 */

export interface AppConfig {
  // Environment
  environment: string;
  isDevelopment: boolean;
  isProduction: boolean;
  
  // API Configuration
  apiUrl: string;
  appUrl: string;
  appName: string;
  
  // Feature Flags
  enableOAuth: boolean;
  enableRegistration: boolean;
  enableAnalytics: boolean;
  
  // Analytics
  googleAnalyticsId?: string;
  
  // Timeouts
  apiTimeout: number;
}

/**
 * Validate required environment variables
 */
function validateEnvironmentVariables(): void {
  const requiredVars = [
    'NEXT_PUBLIC_API_URL',
    'NEXT_PUBLIC_APP_URL',
    'NEXT_PUBLIC_APP_NAME'
  ];
  
  const missingVars: string[] = [];
  
  for (const varName of requiredVars) {
    if (!process.env[varName]) {
      missingVars.push(varName);
    }
  }
  
  if (missingVars.length > 0) {
    console.error('❌ Missing required environment variables:', missingVars.join(', '));
    console.error('Please check your .env.local file and ensure all required variables are set.');
    console.error('See .env.example for reference.');
    
    if (typeof window === 'undefined') {
      // Server-side: exit process
      process.exit(1);
    } else {
      // Client-side: throw error
      throw new Error(`Missing required environment variables: ${missingVars.join(', ')}`);
    }
  }
}

/**
 * Validate production environment configuration
 */
function validateProductionConfig(): void {
  if (process.env.NODE_ENV !== 'production') {
    return;
  }
  
  const issues: string[] = [];
  
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
    
    if (typeof window === 'undefined') {
      process.exit(1);
    } else {
      throw new Error('Production configuration validation failed');
    }
  }
}

/**
 * Create and validate application configuration
 */
function createConfig(): AppConfig {
  // Validate environment variables first
  validateEnvironmentVariables();
  validateProductionConfig();
  
  const config: AppConfig = {
    // Environment
    environment: process.env.NODE_ENV || 'development',
    isDevelopment: process.env.NODE_ENV === 'development',
    isProduction: process.env.NODE_ENV === 'production',
    
    // API Configuration
    apiUrl: process.env.NEXT_PUBLIC_API_URL!,
    appUrl: process.env.NEXT_PUBLIC_APP_URL!,
    appName: process.env.NEXT_PUBLIC_APP_NAME!,
    
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
  if (config.isDevelopment && typeof window === 'undefined') {
    console.log('✅ Frontend configuration loaded successfully');
    console.log(`   Environment: ${config.environment}`);
    console.log(`   API URL: ${config.apiUrl}`);
    console.log(`   App URL: ${config.appUrl}`);
    console.log(`   OAuth enabled: ${config.enableOAuth}`);
  }
  
  return config;
}

// Export the configuration
export const config = createConfig();

// Helper functions
export const isServer = typeof window === 'undefined';
export const isClient = typeof window !== 'undefined';

/**
 * Get environment-specific configuration
 */
export function getEnvironmentConfig() {
  return {
    isDevelopment: config.isDevelopment,
    isProduction: config.isProduction,
    environment: config.environment,
  };
}

/**
 * Get API configuration
 */
export function getApiConfig() {
  return {
    baseUrl: config.apiUrl,
    timeout: config.apiTimeout,
  };
}

/**
 * Check if a feature is enabled
 */
export function isFeatureEnabled(feature: keyof Pick<AppConfig, 'enableOAuth' | 'enableRegistration' | 'enableAnalytics'>): boolean {
  return config[feature];
}
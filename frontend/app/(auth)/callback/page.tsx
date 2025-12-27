'use client'

import { useEffect, useState } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { ShoppingBag } from 'lucide-react'
import { apiClient } from '@/lib/api'

export default function CallbackPage() {
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>('loading')
  const [error, setError] = useState('')
  const router = useRouter()
  const searchParams = useSearchParams()

  useEffect(() => {
    const handleCallback = async () => {
      try {
        const code = searchParams.get('code')
        const provider = searchParams.get('provider')
        const redirect = searchParams.get('state') || '/console'

        if (!code || !provider) {
          throw new Error('Missing authorization code or provider')
        }

        // Handle OAuth callback
        await apiClient.handleOAuthCallback(provider, code)
        
        setStatus('success')
        
        // Redirect after a short delay
        setTimeout(() => {
          router.push(redirect)
        }, 2000)
        
      } catch (err) {
        console.error('OAuth callback error:', err)
        setError(err instanceof Error ? err.message : 'Authentication failed')
        setStatus('error')
        
        // Redirect to login after error
        setTimeout(() => {
          router.push('/login?error=OAuth authentication failed')
        }, 3000)
      }
    }

    handleCallback()
  }, [searchParams, router])

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-md w-full space-y-8">
        <div className="text-center">
          <ShoppingBag className="h-12 w-12 text-blue-600 mx-auto" />
          <span className="block mt-2 text-2xl font-bold text-gray-900">LINE Commerce</span>
          
          {status === 'loading' && (
            <div className="mt-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
              <h2 className="text-xl font-semibold text-gray-900">Completing sign in...</h2>
              <p className="text-gray-600 mt-2">Please wait while we authenticate your account.</p>
            </div>
          )}
          
          {status === 'success' && (
            <div className="mt-8">
              <div className="w-8 h-8 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                </svg>
              </div>
              <h2 className="text-xl font-semibold text-gray-900">Sign in successful!</h2>
              <p className="text-gray-600 mt-2">Redirecting you to your dashboard...</p>
            </div>
          )}
          
          {status === 'error' && (
            <div className="mt-8">
              <div className="w-8 h-8 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                <svg className="w-5 h-5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </div>
              <h2 className="text-xl font-semibold text-gray-900">Authentication failed</h2>
              <p className="text-gray-600 mt-2">{error}</p>
              <p className="text-sm text-gray-500 mt-4">Redirecting you back to sign in...</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
'use client'

import { useState, useEffect, createContext, useContext } from 'react'
import type { ReactNode } from 'react'

export interface User {
  id: string
  email: string
  display_name?: string
  avatar_url?: string
  oauth_provider?: string
  is_active: boolean
  created_at: string
}

export interface AuthContextType {
  user: User | null
  isLoading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
  refreshUser: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  // Check authentication status on mount
  useEffect(() => {
    checkAuthStatus()
  }, [])

  const checkAuthStatus = async () => {
    try {
      const response = await fetch('/api/auth/me', {
        credentials: 'include',
      })

      if (response.ok) {
        const userData = await response.json()
        setUser(userData)
      } else {
        setUser(null)
      }
    } catch (error) {
      console.error('Auth check failed:', error)
      setUser(null)
    } finally {
      setIsLoading(false)
    }
  }

  const login = async (email: string, password: string) => {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      credentials: 'include',
      body: JSON.stringify({ email, password }),
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.message || 'Login failed')
    }

    const userData = await response.json()
    setUser(userData.user)
  }

  const logout = async () => {
    try {
      await fetch('/api/auth/logout', {
        method: 'POST',
        credentials: 'include',
      })
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      setUser(null)
      // Redirect to login page
      window.location.href = '/login'
    }
  }

  const refreshUser = async () => {
    await checkAuthStatus()
  }

  const value: AuthContextType = {
    user,
    isLoading,
    login,
    logout,
    refreshUser,
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

// Utility functions for token management
export const getAuthToken = (): string | null => {
  if (typeof document === 'undefined') return null

  const cookies = document.cookie.split(';')
  const authCookie = cookies.find(cookie =>
    cookie.trim().startsWith('auth-token=')
  )

  return authCookie ? authCookie.split('=')[1] : null
}

export const isAuthenticated = (): boolean => {
  return getAuthToken() !== null
}

// OAuth helper functions
export const initiateOAuthLogin = (provider: 'google' | 'apple') => {
  window.location.href = `/api/auth/${provider}`
}

export const handleOAuthCallback = async (provider: string, code: string) => {
  const response = await fetch(`/api/auth/${provider}/callback`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    credentials: 'include',
    body: JSON.stringify({ code }),
  })

  if (!response.ok) {
    const error = await response.json()
    throw new Error(error.message || 'OAuth callback failed')
  }

  return response.json()
}

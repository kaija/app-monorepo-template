'use client'

import { getAuthToken } from './auth'
import { config, getApiConfig } from './config'

const apiConfig = getApiConfig()

export interface ApiResponse<T = any> {
  data?: T
  error?: string
  message?: string
}

export interface PaginatedResponse<T> {
  items: T[]
  total: number
  page: number
  per_page: number
  pages: number
}

export interface Item {
  id: string
  name: string
  description?: string
  price?: number
  user_id: string
  created_at: string
  updated_at: string
}

export interface CreateItemRequest {
  name: string
  description?: string
  price?: number
}

class ApiClient {
  private baseUrl: string
  private timeout: number

  constructor(baseUrl: string = '/api') {
    // Use environment-aware configuration
    this.baseUrl = config.isDevelopment ? baseUrl : apiConfig.baseUrl
    this.timeout = apiConfig.timeout
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`
    const token = getAuthToken()

    // Create abort controller for timeout
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), this.timeout)

    const config: RequestInit = {
      headers: {
        'Content-Type': 'application/json',
        ...(token && { Authorization: `Bearer ${token}` }),
        ...options.headers,
      },
      credentials: 'include',
      signal: controller.signal,
      ...options,
    }

    try {
      const response = await fetch(url, config)
      
      clearTimeout(timeoutId)
      
      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}))
        throw new ApiError(
          errorData.message || `HTTP ${response.status}: ${response.statusText}`,
          response.status,
          errorData
        )
      }

      // Handle empty responses
      const contentType = response.headers.get('content-type')
      if (contentType && contentType.includes('application/json')) {
        return await response.json()
      }
      
      return {} as T
    } catch (error) {
      clearTimeout(timeoutId)
      
      if (error instanceof ApiError) {
        throw error
      }
      
      if (error instanceof Error && error.name === 'AbortError') {
        throw new ApiError('Request timeout', 408)
      }
      
      if (error instanceof Error) {
        throw new ApiError(error.message, 0, error)
      }
      
      throw new ApiError('An unexpected error occurred', 0)
    }
  }

  // Health check
  async healthCheck(): Promise<{
    status: string;
    service: string;
    version: string;
    database: string;
  }> {
    return this.request('/healthz')
  }

  // Items API
  async getItems(params?: {
    page?: number
    per_page?: number
    search?: string
  }): Promise<PaginatedResponse<Item>> {
    const searchParams = new URLSearchParams()
    
    if (params?.page) searchParams.append('page', params.page.toString())
    if (params?.per_page) searchParams.append('per_page', params.per_page.toString())
    if (params?.search) searchParams.append('search', params.search)

    const query = searchParams.toString()
    const endpoint = `/items${query ? `?${query}` : ''}`
    
    return this.request<PaginatedResponse<Item>>(endpoint)
  }

  async getItem(id: string): Promise<Item> {
    return this.request<Item>(`/items/${id}`)
  }

  async createItem(data: CreateItemRequest): Promise<Item> {
    return this.request<Item>('/items', {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }

  async updateItem(id: string, data: Partial<CreateItemRequest>): Promise<Item> {
    return this.request<Item>(`/items/${id}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    })
  }

  async deleteItem(id: string): Promise<void> {
    return this.request<void>(`/items/${id}`, {
      method: 'DELETE',
    })
  }

  // Authentication API
  async login(email: string, password: string): Promise<{ user: any; token: string }> {
    return this.request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    })
  }

  async register(data: {
    email: string
    password: string
    display_name?: string
  }): Promise<{ user: any; token: string }> {
    return this.request('/auth/register', {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }

  async logout(): Promise<void> {
    return this.request('/auth/logout', {
      method: 'POST',
    })
  }

  async getCurrentUser(): Promise<any> {
    return this.request('/auth/me')
  }

  // OAuth methods
  getOAuthUrl(provider: 'google' | 'apple'): string {
    return `${this.baseUrl}/auth/${provider}`
  }

  async handleOAuthCallback(
    provider: string,
    code: string
  ): Promise<{ user: any; token: string }> {
    return this.request(`/auth/${provider}/callback`, {
      method: 'POST',
      body: JSON.stringify({ code }),
    })
  }
}

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public data?: any
  ) {
    super(message)
    this.name = 'ApiError'
  }

  isAuthError(): boolean {
    return this.status === 401 || this.status === 403
  }

  isNetworkError(): boolean {
    return this.status === 0
  }

  isTimeoutError(): boolean {
    return this.status === 408
  }
}

// Create and export a singleton instance
export const apiClient = new ApiClient()

// Export the class for testing or custom instances
export { ApiClient }

// Utility functions
export const handleApiError = (error: unknown): string => {
  if (error instanceof ApiError) {
    return error.message
  }
  if (error instanceof Error) {
    return error.message
  }
  return 'An unexpected error occurred'
}

export const isNetworkError = (error: unknown): boolean => {
  return error instanceof ApiError && error.isNetworkError()
}
'use client'

import Link from 'next/link'
import { FileQuestion, Home, ArrowLeft } from 'lucide-react'

export default function NotFound() {
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center px-4">
      <div className="max-w-md w-full text-center">
        <div className="card">
          <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <FileQuestion className="h-8 w-8 text-blue-600" />
          </div>

          <h1 className="text-2xl font-bold text-gray-900 mb-2">
            Page Not Found
          </h1>

          <p className="text-gray-600 mb-6">
            The page you're looking for doesn't exist or has been moved.
          </p>

          <div className="flex flex-col sm:flex-row gap-3 justify-center">
            <Link
              href="/"
              className="btn-primary flex items-center justify-center"
            >
              <Home className="h-4 w-4 mr-2" />
              Go Home
            </Link>

            <button
              onClick={() => window.history.back()}
              className="btn-secondary flex items-center justify-center"
            >
              <ArrowLeft className="h-4 w-4 mr-2" />
              Go Back
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

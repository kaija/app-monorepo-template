# Frontend Tests

This directory contains Jest unit tests for the frontend application.

## Test Setup

- **Jest**: Testing framework with Next.js integration
- **React Testing Library**: For testing React components
- **Jest DOM**: Additional Jest matchers for DOM testing
- **TypeScript**: Full TypeScript support for tests

## Running Tests

```bash
# Run all tests
npm run test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage

# Run E2E tests (Playwright)
npm run test:e2e
```

## Test Structure

- `example.test.tsx` - Basic example tests and configuration validation
- Add your component tests here following the same pattern

## Writing Tests

### Component Test Example

```tsx
import { render, screen } from '@testing-library/react'
import '@testing-library/jest-dom'
import MyComponent from '@/components/MyComponent'

describe('MyComponent', () => {
  it('should render correctly', () => {
    render(<MyComponent />)
    expect(screen.getByText('Expected Text')).toBeInTheDocument()
  })
})
```

### API Test Example

```tsx
import { apiClient } from '@/lib/api'

// Mock the API client
jest.mock('@/lib/api')
const mockApiClient = apiClient as jest.Mocked<typeof apiClient>

describe('API Integration', () => {
  it('should call API correctly', async () => {
    mockApiClient.getItems.mockResolvedValue({ items: [] })

    // Test your component that uses the API
  })
})
```

## Configuration

- `jest.config.js` - Jest configuration with Next.js integration
- `jest.setup.js` - Global test setup and mocks
- `tsconfig.json` - Includes Jest types for TypeScript support

## Mocks

The test setup includes automatic mocks for:
- Next.js router (`useRouter`, `useSearchParams`, `usePathname`)
- Environment variables (test values)

Add additional mocks in `jest.setup.js` as needed.

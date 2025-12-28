import { render, screen } from '@testing-library/react'
import '@testing-library/jest-dom'

// Simple example test to verify Jest setup
describe('Example Test', () => {
  it('should pass basic test', () => {
    expect(true).toBe(true)
  })

  it('should render a simple component', () => {
    const TestComponent = () => <div>Hello World</div>

    render(<TestComponent />)

    expect(screen.getByText('Hello World')).toBeInTheDocument()
  })
})

// Test for configuration values
describe('Configuration', () => {
  it('should have environment variables available', () => {
    expect(process.env.NEXT_PUBLIC_API_URL).toBe('http://localhost:8000')
    expect(process.env.NEXT_PUBLIC_APP_URL).toBe('http://localhost:3000')
    expect(process.env.NEXT_PUBLIC_APP_NAME).toBe('LINE Commerce')
  })
})

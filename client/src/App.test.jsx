import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import App from './App.jsx'

// Mock global fetch for session checking
beforeEach(() => {
  global.fetch = vi.fn().mockImplementation((url) => {
    if (url === '/api/v1/session') {
      return Promise.resolve({
        ok: false,
        status: 401,
        json: () => Promise.resolve({ error: 'Unauthorized' })
      })
    }
    return Promise.resolve({
      ok: true,
      status: 200,
      json: () => Promise.resolve({})
    })
  })
})

describe('App authentication workflow', () => {
  it('renders login screen when unauthenticated', async () => {
    render(<App />)

    await waitFor(() => {
      expect(screen.getByText('ACME HR Portal')).toBeInTheDocument()
      expect(screen.getByRole('button', { name: /Sign In as HR Manager/i })).toBeInTheDocument()
    })
  })

  it('submits credentials on sign in', async () => {
    render(<App />)

    await waitFor(() => {
      expect(screen.getByText('ACME HR Portal')).toBeInTheDocument()
    })

    const submitBtn = screen.getByRole('button', { name: /Sign In as HR Manager/i })
    fireEvent.click(submitBtn)

    expect(global.fetch).toHaveBeenCalledWith('/api/v1/session', expect.anything())
  })
})

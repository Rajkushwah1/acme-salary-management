// client/src/api.js
// Standard native Fetch client with cookie credentials and CSRF header handling

let csrfToken = null

export function setCsrfToken(token) {
  csrfToken = token
}

export function getCsrfToken() {
  return csrfToken
}

export async function apiRequest(endpoint, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...(csrfToken ? { 'X-CSRF-Token': csrfToken } : {}),
    ...(options.headers || {})
  }

  const response = await fetch(endpoint, {
    ...options,
    headers,
    credentials: 'include' // include HTTP-only session cookies
  })

  if (response.status === 204) {
    return null
  }

  const data = await response.json().catch(() => ({}))

  if (!response.ok) {
    const errorMsg = data.error || (data.errors ? data.errors.join(', ') : 'Request failed')
    const err = new Error(errorMsg)
    err.status = response.status
    err.data = data
    throw err
  }

  return data
}

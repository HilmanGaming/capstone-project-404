import { useState } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'

export default function Login() {
  const { status, signIn } = useAuth()
  const lokasi = useLocation()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  const tujuan = lokasi.state?.dari?.pathname ?? '/'
  if (status === 'in') return <Navigate to={tujuan} replace />

  async function kirim(e) {
    e.preventDefault()
    setBusy(true)
    setError('')
    const { error } = await signIn(email, password)
    if (error) setError('Email atau password salah.')
    setBusy(false)
  }

  return (
    <main style={{ maxWidth: 360, margin: '4rem auto', padding: '0 1rem' }}>
      <h1>Masuk</h1>
      <form onSubmit={kirim}>
        <p>
          <label>
            Email
            <br />
            <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} required autoFocus />
          </label>
        </p>
        <p>
          <label>
            Password
            <br />
            <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} required />
          </label>
        </p>
        {error && <p role="alert">{error}</p>}
        <button type="submit" disabled={busy}>
          {busy ? 'Memproses...' : 'Masuk'}
        </button>
      </form>
    </main>
  )
}
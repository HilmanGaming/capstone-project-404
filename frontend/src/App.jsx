import { Routes, Route, Link, Navigate } from 'react-router-dom'
import { useAuth, RequireRole } from './auth/AuthContext'
import Login from './pages/Login'

const SEMUA = ['admin', 'staff', 'owner']

// Placeholder: ganti satu per satu sesuai urutan halaman tahap 1.
const Halaman = ({ judul }) => <h1>{judul}</h1>

function Layout({ children }) {
  const { role, isLead, session, signOut } = useAuth()
  return (
    <>
      <nav style={{ display: 'flex', gap: '1rem', padding: '0.75rem 1rem', borderBottom: '1px solid #ccc' }}>
        <Link to="/vehicles">Kendaraan</Link>
        {role === 'admin' && <Link to="/vehicles/new">Tambah kendaraan</Link>}
        <span style={{ marginLeft: 'auto' }}>
          {session?.user?.email} ({role}
          {role === 'staff' && isLead ? ', ketua' : ''})
        </span>
        <button onClick={signOut}>Keluar</button>
      </nav>
      <main style={{ padding: '1rem' }}>{children}</main>
    </>
  )
}

export default function App() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        path="/vehicles"
        element={
          <RequireRole roles={SEMUA}>
            <Layout>
              <Halaman judul="Daftar kendaraan" />
            </Layout>
          </RequireRole>
        }
      />
      {/* Sesuaikan kalau di RLS staff juga boleh insert vehicles */}
      <Route
        path="/vehicles/new"
        element={
          <RequireRole roles={['admin']}>
            <Layout>
              <Halaman judul="Tambah kendaraan" />
            </Layout>
          </RequireRole>
        }
      />
      <Route path="*" element={<Navigate to="/vehicles" replace />} />
    </Routes>
  )
}
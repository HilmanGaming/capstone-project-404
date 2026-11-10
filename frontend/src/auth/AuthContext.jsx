import { createContext, useContext, useEffect, useState } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { supabase } from '../lib/supabase'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  // status: 'loading' | 'out' | 'in'
  const [state, setState] = useState({ status: 'loading', session: null, profile: null })

  useEffect(() => {
    let aktif = true

    async function muat(session) {
      if (!session) {
        if (aktif) setState({ status: 'out', session: null, profile: null })
        return
      }
      const { data } = await supabase
        .from('profiles')
        .select('role, is_lead')
        .eq('id', session.user.id)
        .single()
      if (aktif) setState({ status: 'in', session, profile: data ?? null })
    }

    // onAuthStateChange langsung mengirim sesi awal (INITIAL_SESSION), jadi getSession tidak perlu.
    const { data: sub } = supabase.auth.onAuthStateChange((_event, session) => {
      // Jangan memanggil query Supabase langsung di dalam callback ini (bisa menggantung).
      setTimeout(() => muat(session), 0)
    })

    return () => {
      aktif = false
      sub.subscription.unsubscribe()
    }
  }, [])

  const value = {
    ...state,
    role: state.profile?.role ?? null,
    isLead: state.profile?.is_lead ?? false,
    signIn: (email, password) => supabase.auth.signInWithPassword({ email, password }),
    signOut: () => supabase.auth.signOut(),
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth harus dipakai di dalam <AuthProvider>')
  return ctx
}

// Pembatasan di sini hanya untuk tampilan. Yang benar-benar menjaga data adalah RLS.
export function RequireRole({ roles, children }) {
  const { status, role } = useAuth()
  const lokasi = useLocation()

  if (status === 'loading') return <p>Memuat...</p>
  if (status === 'out') return <Navigate to="/login" replace state={{ dari: lokasi }} />
  if (!role) return <p>Akun ini belum punya profil atau role. Hubungi admin.</p>
  if (roles && !roles.includes(role)) return <p>Kamu tidak punya akses ke halaman ini.</p>
  return children
}
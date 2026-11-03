import React, { useState, useEffect } from 'react'
import { apiRequest, setCsrfToken } from './api.js'
import { 
  Users, DollarSign, BarChart3, History, LogOut, Search, Plus, 
  ChevronLeft, ChevronRight, AlertCircle, CheckCircle2, Shield, Calendar
} from 'lucide-react'

export default function App() {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState('dashboard') // 'dashboard' | 'employees' | 'analytics' | 'audit'

  // Global meta reference
  const [meta, setMeta] = useState({ countries: [], departments: [], currencies: [], pay_frequencies: [] })

  // Toast notifications
  const [toast, setToast] = useState(null)

  function showToast(message, type = 'success') {
    setToast({ message, type })
    setTimeout(() => setToast(null), 4000)
  }

  // Check initial session
  useEffect(() => {
    async function checkSession() {
      try {
        const res = await apiRequest('/api/v1/session')
        setUser(res.user)
        setCsrfToken(res.csrf_token)
      } catch (err) {
        setUser(null)
      } finally {
        setLoading(false)
      }
    }
    checkSession()
  }, [])

  // Load dropdown metadata once logged in
  useEffect(() => {
    if (user) {
      apiRequest('/api/v1/meta')
        .then(data => setMeta(data))
        .catch(err => console.error('Failed to load meta:', err))
    }
  }, [user])

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-slate-50 text-slate-500 font-medium">
        Loading ACME Salary Management...
      </div>
    )
  }

  if (!user) {
    return <LoginView onLogin={(userData, token) => {
      setUser(userData)
      setCsrfToken(token)
      showToast('Welcome back, ' + userData.first_name)
    }} />
  }

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
      {/* Toast Notification */}
      {toast && (
        <div className={`fixed top-4 right-4 z-50 flex items-center gap-2 px-4 py-3 rounded-lg shadow-lg text-sm text-white ${
          toast.type === 'error' ? 'bg-rose-600' : 'bg-emerald-600'
        }`}>
          {toast.type === 'error' ? <AlertCircle className="w-4 h-4" /> : <CheckCircle2 className="w-4 h-4" />}
          <span>{toast.message}</span>
        </div>
      )}

      {/* Top Navigation */}
      <header className="bg-white border-b border-slate-200 sticky top-0 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-6">
            <div className="flex items-center gap-2">
              <div className="w-9 h-9 rounded-lg bg-indigo-600 flex items-center justify-center text-white font-bold tracking-wider">
                AC
              </div>
              <div>
                <span className="font-bold text-slate-900 tracking-tight text-lg">ACME</span>
                <span className="text-xs uppercase ml-1.5 px-1.5 py-0.5 rounded bg-slate-100 text-slate-600 font-semibold border border-slate-200">
                  Compensation
                </span>
              </div>
            </div>

            <nav className="flex items-center gap-1">
              <button
                onClick={() => setActiveTab('dashboard')}
                className={`px-3 py-1.5 text-sm font-medium rounded-md flex items-center gap-1.5 transition-colors ${
                  activeTab === 'dashboard' ? 'bg-indigo-50 text-indigo-700 font-semibold' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
              >
                <BarChart3 className="w-4 h-4" />
                Dashboard
              </button>
              <button
                onClick={() => setActiveTab('employees')}
                className={`px-3 py-1.5 text-sm font-medium rounded-md flex items-center gap-1.5 transition-colors ${
                  activeTab === 'employees' ? 'bg-indigo-50 text-indigo-700 font-semibold' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
              >
                <Users className="w-4 h-4" />
                Employees
              </button>
              <button
                onClick={() => setActiveTab('analytics')}
                className={`px-3 py-1.5 text-sm font-medium rounded-md flex items-center gap-1.5 transition-colors ${
                  activeTab === 'analytics' ? 'bg-indigo-50 text-indigo-700 font-semibold' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
              >
                <DollarSign className="w-4 h-4" />
                Analytics
              </button>
              <button
                onClick={() => setActiveTab('audit')}
                className={`px-3 py-1.5 text-sm font-medium rounded-md flex items-center gap-1.5 transition-colors ${
                  activeTab === 'audit' ? 'bg-indigo-50 text-indigo-700 font-semibold' : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                }`}
              >
                <History className="w-4 h-4" />
                Audit Logs
              </button>
            </nav>
          </div>

          <div className="flex items-center gap-4">
            <div className="text-right hidden sm:block">
              <p className="text-sm font-medium text-slate-800">{user.first_name} {user.last_name}</p>
              <p className="text-xs text-slate-400 capitalize">{user.role.replace('_', ' ')}</p>
            </div>
            <button
              onClick={async () => {
                await apiRequest('/api/v1/session', { method: 'DELETE' })
                setUser(null)
                setCsrfToken(null)
              }}
              title="Sign Out"
              className="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 flex-1 w-full">
        {activeTab === 'dashboard' && <DashboardView onNavigate={setActiveTab} />}
        {activeTab === 'employees' && <EmployeesView meta={meta} showToast={showToast} />}
        {activeTab === 'analytics' && <AnalyticsView />}
        {activeTab === 'audit' && <AuditLogsView />}
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-200 bg-white py-4 text-center text-xs text-slate-400">
        ACME Salary Management System • Incubyte Craftsperson Assessment • 10,000 Employees Tested
      </footer>
    </div>
  )
}

// ---------------------------------------------------------
// 1. LOGIN VIEW
// ---------------------------------------------------------
function LoginView({ onLogin }) {
  const [email, setEmail] = useState('hr.manager@acme.com')
  const [password, setPassword] = useState('AcmeAdmin2026!')
  const [error, setError] = useState(null)
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setError(null)
    setSubmitting(true)
    try {
      const data = await apiRequest('/api/v1/session', {
        method: 'POST',
        body: JSON.stringify({ email, password })
      })
      onLogin(data.user, data.csrf_token)
    } catch (err) {
      setError(err.message || 'Invalid credentials')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-100 p-4">
      <div className="w-full max-w-md bg-white rounded-xl shadow-lg border border-slate-200 p-8">
        <div className="text-center mb-6">
          <div className="w-12 h-12 bg-indigo-600 rounded-xl mx-auto flex items-center justify-center text-white font-bold text-xl mb-3 shadow">
            AC
          </div>
          <h2 className="text-2xl font-bold text-slate-900">ACME HR Portal</h2>
          <p className="text-sm text-slate-500 mt-1">Sign in to manage global compensation and 10k employees</p>
        </div>

        {error && (
          <div className="mb-4 p-3 rounded-lg bg-rose-50 border border-rose-200 text-rose-700 text-sm flex items-center gap-2">
            <AlertCircle className="w-4 h-4 flex-shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-slate-700 mb-1">
              Email Address
            </label>
            <input
              type="email"
              required
              value={email}
              onChange={e => setEmail(e.target.value)}
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-slate-700 mb-1">
              Password
            </label>
            <input
              type="password"
              required
              value={password}
              onChange={e => setPassword(e.target.value)}
              className="w-full px-3 py-2 border border-slate-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
            />
          </div>

          <button
            type="submit"
            disabled={submitting}
            className="w-full py-2.5 px-4 bg-indigo-600 hover:bg-indigo-700 text-white font-medium text-sm rounded-lg shadow-sm transition duration-150 disabled:opacity-50"
          >
            {submitting ? 'Authenticating...' : 'Sign In as HR Manager'}
          </button>
        </form>

        <div className="mt-6 pt-4 border-t border-slate-100 text-xs text-slate-400 text-center">
          Default seed credentials pre-filled for convenience.
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------
// 2. DASHBOARD VIEW
// ---------------------------------------------------------
function DashboardView({ onNavigate }) {
  const [summary, setSummary] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    apiRequest('/api/v1/analytics/summary')
      .then(data => setSummary(data))
      .catch(err => console.error(err))
      .finally(() => setLoading(false))
  }, [])

  if (loading) {
    return <div className="p-8 text-center text-slate-400">Loading organization metrics...</div>
  }

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Organization Overview</h1>
        <p className="text-sm text-slate-500 mt-1">High-level snapshot of ACME compensation and workforce metrics</p>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase text-slate-500 tracking-wider">Total Headcount</span>
            <Users className="w-5 h-5 text-indigo-500" />
          </div>
          <p className="text-3xl font-extrabold text-slate-900 mt-2">{summary?.total_employees?.toLocaleString()}</p>
          <p className="text-xs text-slate-400 mt-1">Across 5 global subsidiaries</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase text-slate-500 tracking-wider">Active Employees</span>
            <CheckCircle2 className="w-5 h-5 text-emerald-500" />
          </div>
          <p className="text-3xl font-extrabold text-emerald-600 mt-2">{summary?.active_employees?.toLocaleString()}</p>
          <p className="text-xs text-slate-400 mt-1">Currently on active payroll</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase text-slate-500 tracking-wider">Inactive Records</span>
            <AlertCircle className="w-5 h-5 text-amber-500" />
          </div>
          <p className="text-3xl font-extrabold text-slate-700 mt-2">{summary?.inactive_employees?.toLocaleString()}</p>
          <p className="text-xs text-slate-400 mt-1">Preserved with full history</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase text-slate-500 tracking-wider">Currencies Supported</span>
            <DollarSign className="w-5 h-5 text-indigo-500" />
          </div>
          <div className="flex items-center gap-1.5 mt-2">
            {summary?.available_currencies?.map(curr => (
              <span key={curr} className="px-2 py-0.5 rounded text-xs font-bold bg-indigo-50 text-indigo-700 border border-indigo-100">
                {curr}
              </span>
            ))}
          </div>
          <p className="text-xs text-slate-400 mt-2">Zero cross-currency mixing</p>
        </div>
      </div>

      {/* Quick Navigation Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-4">
        <div 
          onClick={() => onNavigate('employees')}
          className="bg-white p-6 rounded-xl border border-slate-200 hover:border-indigo-300 hover:shadow-md transition cursor-pointer group"
        >
          <div className="w-10 h-10 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center mb-4 group-hover:bg-indigo-600 group-hover:text-white transition">
            <Users className="w-5 h-5" />
          </div>
          <h3 className="font-semibold text-slate-900 text-base">Employee Directory</h3>
          <p className="text-xs text-slate-500 mt-1">Search, filter, paginate, and inspect salary records across 10,000 employees.</p>
        </div>

        <div 
          onClick={() => onNavigate('analytics')}
          className="bg-white p-6 rounded-xl border border-slate-200 hover:border-indigo-300 hover:shadow-md transition cursor-pointer group"
        >
          <div className="w-10 h-10 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center mb-4 group-hover:bg-emerald-600 group-hover:text-white transition">
            <BarChart3 className="w-5 h-5" />
          </div>
          <h3 className="font-semibold text-slate-900 text-base">Compensation Analytics</h3>
          <p className="text-xs text-slate-500 mt-1">Deep-dive into annualized salary distributions, department averages, and country rollups.</p>
        </div>

        <div 
          onClick={() => onNavigate('audit')}
          className="bg-white p-6 rounded-xl border border-slate-200 hover:border-indigo-300 hover:shadow-md transition cursor-pointer group"
        >
          <div className="w-10 h-10 rounded-lg bg-slate-100 text-slate-700 flex items-center justify-center mb-4 group-hover:bg-slate-800 group-hover:text-white transition">
            <History className="w-5 h-5" />
          </div>
          <h3 className="font-semibold text-slate-900 text-base">Audit Trail</h3>
          <p className="text-xs text-slate-500 mt-1">Review append-only salary revisions, clerical corrections, and cancellation events.</p>
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------
// 3. EMPLOYEES VIEW
// ---------------------------------------------------------
function EmployeesView({ meta, showToast }) {
  const [employees, setEmployees] = useState([])
  const [pagination, setPagination] = useState({ current_page: 1, total_pages: 1, total_count: 0 })
  const [loading, setLoading] = useState(false)

  // Search & Filters
  const [search, setSearch] = useState('')
  const [countryId, setCountryId] = useState('')
  const [departmentId, setDepartmentId] = useState('')
  const [status, setStatus] = useState('')
  const [page, setPage] = useState(1)

  // Modals & Drawers
  const [selectedEmployee, setSelectedEmployee] = useState(null)
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [showRevisionModal, setShowRevisionModal] = useState(null)
  const [showCorrectionModal, setShowCorrectionModal] = useState(null)

  function fetchEmployees() {
    setLoading(true)
    const params = new URLSearchParams({
      page: page.toString(),
      per_page: '25',
      ...(search ? { search } : {}),
      ...(countryId ? { country_id: countryId } : {}),
      ...(departmentId ? { department_id: departmentId } : {}),
      ...(status ? { status } : {})
    })

    apiRequest(`/api/v1/employees?${params}`)
      .then(data => {
        setEmployees(data.employees)
        setPagination(data.pagination)
      })
      .catch(err => showToast(err.message, 'error'))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    fetchEmployees()
  }, [page, countryId, departmentId, status])

  function handleSearchSubmit(e) {
    e.preventDefault()
    setPage(1)
    fetchEmployees()
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Employee Directory</h1>
          <p className="text-sm text-slate-500 mt-1">
            Managing {pagination.total_count.toLocaleString()} employee records with server-side pagination
          </p>
        </div>
        <button
          onClick={() => setShowCreateModal(true)}
          className="inline-flex items-center gap-1.5 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-medium rounded-lg shadow-sm transition"
        >
          <Plus className="w-4 h-4" />
          Add Employee
        </button>
      </div>

      {/* Filter & Search Bar */}
      <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-xs flex flex-wrap items-center gap-3">
        <form onSubmit={handleSearchSubmit} className="flex-1 min-w-[240px] relative">
          <Search className="w-4 h-4 absolute left-3 top-2.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search name, code, or email..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-9 pr-3 py-1.5 text-sm border border-slate-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </form>

        <select
          value={countryId}
          onChange={e => { setCountryId(e.target.value); setPage(1) }}
          className="px-3 py-1.5 text-sm border border-slate-200 rounded-lg bg-white text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
        >
          <option value="">All Countries</option>
          {meta.countries.map(c => (
            <option key={c.id} value={c.id}>{c.name} ({c.code})</option>
          ))}
        </select>

        <select
          value={departmentId}
          onChange={e => { setDepartmentId(e.target.value); setPage(1) }}
          className="px-3 py-1.5 text-sm border border-slate-200 rounded-lg bg-white text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
        >
          <option value="">All Departments</option>
          {meta.departments.map(d => (
            <option key={d.id} value={d.id}>{d.name}</option>
          ))}
        </select>

        <select
          value={status}
          onChange={e => { setStatus(e.target.value); setPage(1) }}
          className="px-3 py-1.5 text-sm border border-slate-200 rounded-lg bg-white text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
        >
          <option value="">All Statuses</option>
          <option value="active">Active</option>
          <option value="inactive">Inactive</option>
        </select>

        {(search || countryId || departmentId || status) && (
          <button
            onClick={() => { setSearch(''); setCountryId(''); setDepartmentId(''); setStatus(''); setPage(1) }}
            className="text-xs text-indigo-600 hover:text-indigo-800 font-medium px-2 py-1.5"
          >
            Reset
          </button>
        )}
      </div>

      {/* Employee Table */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm border-collapse">
            <thead className="bg-slate-50 border-b border-slate-200 text-xs font-semibold text-slate-600 uppercase tracking-wider">
              <tr>
                <th className="py-3 px-4">Employee</th>
                <th className="py-3 px-4">Department</th>
                <th className="py-3 px-4">Country</th>
                <th className="py-3 px-4">Current Compensation</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan="6" className="py-12 text-center text-slate-400">Loading records...</td>
                </tr>
              ) : employees.length === 0 ? (
                <tr>
                  <td colSpan="6" className="py-12 text-center text-slate-400">No employees match the selected criteria.</td>
                </tr>
              ) : (
                employees.map(emp => (
                  <tr key={emp.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-3 px-4">
                      <div className="font-medium text-slate-900">{emp.full_name}</div>
                      <div className="text-xs text-slate-400 flex items-center gap-2 mt-0.5">
                        <span className="font-mono bg-slate-100 px-1 py-0.2 rounded text-slate-600 font-semibold">{emp.employee_code}</span>
                        <span>{emp.email}</span>
                      </div>
                    </td>
                    <td className="py-3 px-4 text-slate-700">
                      <div>{emp.department.name}</div>
                      <div className="text-xs text-slate-400">{emp.designation}</div>
                    </td>
                    <td className="py-3 px-4 text-slate-700">
                      <span className="font-semibold text-slate-800">{emp.country.code}</span>
                      <span className="text-xs text-slate-400 ml-1.5">{emp.country.name}</span>
                    </td>
                    <td className="py-3 px-4">
                      {emp.current_salary ? (
                        <div>
                          <span className="font-mono font-bold text-slate-900">
                            {Number(emp.current_salary.base_salary).toLocaleString()} {emp.current_salary.currency}
                          </span>
                          <span className="text-xs text-slate-400 ml-1">/ {emp.current_salary.pay_frequency}</span>
                        </div>
                      ) : (
                        <span className="text-xs text-slate-400 italic">No active salary</span>
                      )}
                    </td>
                    <td className="py-3 px-4">
                      <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold ${
                        emp.status === 'active' ? 'bg-emerald-50 text-emerald-700 border border-emerald-200' : 'bg-slate-100 text-slate-600 border border-slate-200'
                      }`}>
                        {emp.status}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right">
                      <button
                        onClick={() => setSelectedEmployee(emp)}
                        className="text-xs text-indigo-600 hover:text-indigo-900 font-semibold px-2 py-1 rounded hover:bg-indigo-50 transition"
                      >
                        View & Manage
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Bar */}
        <div className="bg-white px-4 py-3 border-t border-slate-200 flex items-center justify-between text-xs text-slate-500">
          <div>
            Page <span className="font-semibold text-slate-800">{pagination.current_page}</span> of{' '}
            <span className="font-semibold text-slate-800">{pagination.total_pages}</span>
          </div>
          <div className="flex items-center gap-2">
            <button
              disabled={page <= 1 || loading}
              onClick={() => setPage(p => p - 1)}
              className="p-1 rounded border border-slate-200 hover:bg-slate-50 disabled:opacity-40"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <button
              disabled={page >= pagination.total_pages || loading}
              onClick={() => setPage(p => p + 1)}
              className="p-1 rounded border border-slate-200 hover:bg-slate-50 disabled:opacity-40"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Employee Detail & Salary Timeline Drawer */}
      {selectedEmployee && (
        <EmployeeDetailDrawer
          employeeId={selectedEmployee.id}
          onClose={() => setSelectedEmployee(null)}
          onTriggerRevision={emp => setShowRevisionModal(emp)}
          onTriggerCorrection={(emp, sal) => setShowCorrectionModal({ employee: emp, salary: sal })}
          onEmployeeDeactivated={() => {
            fetchEmployees()
            showToast('Employee deactivated successfully')
          }}
          showToast={showToast}
        />
      )}

      {/* Create Employee Modal */}
      {showCreateModal && (
        <CreateEmployeeModal
          meta={meta}
          onClose={() => setShowCreateModal(false)}
          onSuccess={() => {
            setShowCreateModal(false)
            fetchEmployees()
            showToast('Employee created successfully')
          }}
          showToast={showToast}
        />
      )}

      {/* Revision Modal */}
      {showRevisionModal && (
        <SalaryRevisionModal
          employee={showRevisionModal}
          meta={meta}
          onClose={() => setShowRevisionModal(null)}
          onSuccess={() => {
            setShowRevisionModal(null)
            fetchEmployees()
            showToast('Salary revision created')
          }}
          showToast={showToast}
        />
      )}

      {/* Correction Modal */}
      {showCorrectionModal && (
        <SalaryCorrectionModal
          employee={showCorrectionModal.employee}
          salary={showCorrectionModal.salary}
          meta={meta}
          onClose={() => setShowCorrectionModal(null)}
          onSuccess={() => {
            setShowCorrectionModal(null)
            fetchEmployees()
            showToast('Salary record corrected')
          }}
          showToast={showToast}
        />
      )}
    </div>
  )
}

// ---------------------------------------------------------
// 4. EMPLOYEE DETAIL & TIMELINE DRAWER
// ---------------------------------------------------------
function EmployeeDetailDrawer({ employeeId, onClose, onTriggerRevision, onTriggerCorrection, onEmployeeDeactivated, showToast }) {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  function loadDetails() {
    setLoading(true)
    apiRequest(`/api/v1/employees/${employeeId}`)
      .then(res => setData(res.employee))
      .catch(err => showToast(err.message, 'error'))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    loadDetails()
  }, [employeeId])

  async function handleDeactivate() {
    if (!window.confirm('Are you sure you want to deactivate this employee? This will cap their current salary and cancel any future scheduled revisions.')) {
      return
    }

    try {
      await apiRequest(`/api/v1/employees/${employeeId}/deactivate`, {
        method: 'POST',
        body: JSON.stringify({ reason: 'HR Manager deactivation' })
      })
      loadDetails()
      onEmployeeDeactivated()
    } catch (err) {
      showToast(err.message, 'error')
    }
  }

  return (
    <div className="fixed inset-0 z-40 bg-slate-900/40 backdrop-blur-xs flex justify-end">
      <div className="w-full max-w-2xl bg-white h-full shadow-2xl flex flex-col overflow-hidden">
        {/* Header */}
        <div className="p-6 border-b border-slate-200 flex items-center justify-between bg-slate-50">
          <div>
            <h2 className="text-xl font-bold text-slate-900">{data?.full_name || 'Loading Employee...'}</h2>
            <div className="flex items-center gap-2 text-xs text-slate-500 mt-1">
              <span className="font-mono font-semibold bg-white px-1.5 py-0.5 rounded border border-slate-200">{data?.employee_code}</span>
              <span>{data?.designation}</span>
              <span>•</span>
              <span>{data?.department?.name}</span>
            </div>
          </div>
          <button onClick={onClose} className="p-2 text-slate-400 hover:text-slate-600 rounded-lg">✕</button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {loading ? (
            <div className="text-center py-12 text-slate-400">Loading details...</div>
          ) : (
            <>
              {/* Biographical Details */}
              <div className="grid grid-cols-2 gap-4 bg-slate-50 p-4 rounded-xl border border-slate-200 text-xs">
                <div>
                  <span className="text-slate-400 block">Email</span>
                  <span className="font-medium text-slate-800">{data?.email}</span>
                </div>
                <div>
                  <span className="text-slate-400 block">Country</span>
                  <span className="font-medium text-slate-800">{data?.country?.name} ({data?.country?.code})</span>
                </div>
                <div>
                  <span className="text-slate-400 block">Joined Organization</span>
                  <span className="font-medium text-slate-800">{data?.joined_at}</span>
                </div>
                <div>
                  <span className="text-slate-400 block">Employment Status</span>
                  <span className={`inline-block font-semibold capitalize ${data?.status === 'active' ? 'text-emerald-600' : 'text-slate-600'}`}>
                    {data?.status}
                  </span>
                </div>
              </div>

              {/* Action Toolbar */}
              <div className="flex items-center justify-between pt-2">
                <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider">Salary History & Timeline</h3>
                {data?.status === 'active' && (
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => onTriggerRevision(data)}
                      className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold rounded-lg shadow-xs"
                    >
                      + Revise Salary
                    </button>
                    <button
                      onClick={handleDeactivate}
                      className="px-3 py-1.5 bg-rose-50 hover:bg-rose-100 text-rose-700 text-xs font-semibold rounded-lg border border-rose-200"
                    >
                      Deactivate
                    </button>
                  </div>
                )}
              </div>

              {/* Chronological Timeline Cards */}
              <div className="space-y-3">
                {data?.salary_records?.map((record, index) => {
                  const isCurrent = !record.effective_to || new Date(record.effective_to) > new Date()
                  return (
                    <div 
                      key={record.id} 
                      className={`p-4 rounded-xl border transition ${
                        isCurrent 
                          ? 'border-indigo-200 bg-indigo-50/30' 
                          : 'border-slate-200 bg-white'
                      }`}
                    >
                      <div className="flex items-start justify-between">
                        <div>
                          <div className="flex items-center gap-2">
                            <span className="text-lg font-mono font-bold text-slate-900">
                              {Number(record.base_salary).toLocaleString()} {record.currency}
                            </span>
                            <span className="text-xs uppercase text-slate-400 font-medium">({record.pay_frequency})</span>
                            {isCurrent && (
                              <span className="px-2 py-0.5 rounded-full text-xs font-bold bg-indigo-100 text-indigo-700">
                                Current
                              </span>
                            )}
                          </div>
                          <div className="text-xs text-slate-500 mt-1 flex items-center gap-2">
                            <Calendar className="w-3.5 h-3.5 text-slate-400" />
                            <span>
                              Effective: <span className="font-medium text-slate-700">{record.effective_from}</span> to{' '}
                              <span className="font-medium text-slate-700">{record.effective_to || 'Present (Open-ended)'}</span>
                            </span>
                          </div>
                        </div>

                        <button
                          onClick={() => onTriggerCorrection(data, record)}
                          className="text-xs text-slate-500 hover:text-indigo-600 px-2 py-1 rounded hover:bg-slate-100"
                        >
                          Correct Typo
                        </button>
                      </div>

                      <div className="mt-2 text-xs text-slate-400">
                        Annualized compensation:{' '}
                        <span className="font-mono font-semibold text-slate-700">
                          {Number(record.annualized_salary).toLocaleString()} {record.currency}
                        </span>
                      </div>
                    </div>
                  )
                })}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  )
}

// ---------------------------------------------------------
// 5. SALARY REVISION MODAL
// ---------------------------------------------------------
function SalaryRevisionModal({ employee, meta, onClose, onSuccess, showToast }) {
  const [baseSalary, setBaseSalary] = useState('')
  const [currency, setCurrency] = useState(employee?.country?.default_currency || 'USD')
  const [payFrequency, setPayFrequency] = useState('annual')
  const [effectiveFrom, setEffectiveFrom] = useState(new Date().toISOString().split('T')[0])
  const [reason, setReason] = useState('')
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setSubmitting(true)
    try {
      await apiRequest(`/api/v1/employees/${employee.id}/salaries/revise`, {
        method: 'POST',
        body: JSON.stringify({
          salary: {
            base_salary: parseFloat(baseSalary),
            currency,
            pay_frequency: payFrequency,
            effective_from: effectiveFrom
          },
          reason
        })
      })
      onSuccess()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl shadow-xl border border-slate-200 max-w-md w-full p-6">
        <h3 className="text-lg font-bold text-slate-900">Salary Revision</h3>
        <p className="text-xs text-slate-500 mt-1">
          Promoting or revising compensation for <span className="font-semibold text-slate-800">{employee.full_name}</span>.
        </p>

        <form onSubmit={handleSubmit} className="space-y-4 mt-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">New Salary Amount</label>
              <input
                type="number"
                required
                min="1"
                value={baseSalary}
                onChange={e => setBaseSalary(e.target.value)}
                placeholder="e.g. 95000"
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Currency</label>
              <select
                value={currency}
                onChange={e => setCurrency(e.target.value)}
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg bg-white"
              >
                {meta.currencies.map(c => <option key={c} value={c}>{c}</option>)}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Pay Frequency</label>
              <select
                value={payFrequency}
                onChange={e => setPayFrequency(e.target.value)}
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg bg-white capitalize"
              >
                {meta.pay_frequencies.map(f => <option key={f} value={f}>{f}</option>)}
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Effective Date</label>
              <input
                type="date"
                required
                value={effectiveFrom}
                onChange={e => setEffectiveFrom(e.target.value)}
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Mandatory Business Reason</label>
            <textarea
              required
              rows="2"
              value={reason}
              onChange={e => setReason(e.target.value)}
              placeholder="e.g. Annual merit raise, market adjustment, promotion"
              className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button type="button" onClick={onClose} className="px-3 py-1.5 text-xs text-slate-600 hover:bg-slate-100 rounded-lg">Cancel</button>
            <button type="submit" disabled={submitting} className="px-4 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold rounded-lg shadow-xs">
              {submitting ? 'Recording...' : 'Apply Revision'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ---------------------------------------------------------
// 6. SALARY CORRECTION MODAL
// ---------------------------------------------------------
function SalaryCorrectionModal({ employee, salary, meta, onClose, onSuccess, showToast }) {
  const [baseSalary, setBaseSalary] = useState(salary.base_salary)
  const [reason, setReason] = useState('')
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setSubmitting(true)
    try {
      await apiRequest(`/api/v1/salaries/${salary.id}/correct`, {
        method: 'PATCH',
        body: JSON.stringify({
          salary: { base_salary: parseFloat(baseSalary) },
          reason
        })
      })
      onSuccess()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl shadow-xl border border-slate-200 max-w-md w-full p-6">
        <h3 className="text-lg font-bold text-slate-900">Correct Salary Record</h3>
        <p className="text-xs text-slate-500 mt-1">
          Fixing clerical data-entry error for <span className="font-semibold text-slate-800">{employee.full_name}</span>.
        </p>

        <form onSubmit={handleSubmit} className="space-y-4 mt-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Corrected Base Salary ({salary.currency})</label>
            <input
              type="number"
              required
              min="1"
              value={baseSalary}
              onChange={e => setBaseSalary(e.target.value)}
              className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">Mandatory Correction Rationale</label>
            <textarea
              required
              rows="2"
              value={reason}
              onChange={e => setReason(e.target.value)}
              placeholder="e.g. Correcting onboarding typographical error"
              className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg focus:ring-2 focus:ring-indigo-500"
            />
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button type="button" onClick={onClose} className="px-3 py-1.5 text-xs text-slate-600 hover:bg-slate-100 rounded-lg">Cancel</button>
            <button type="submit" disabled={submitting} className="px-4 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold rounded-lg shadow-xs">
              {submitting ? 'Correcting...' : 'Save Correction'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ---------------------------------------------------------
// 7. CREATE EMPLOYEE MODAL
// ---------------------------------------------------------
function CreateEmployeeModal({ meta, onClose, onSuccess, showToast }) {
  const [employeeCode, setEmployeeCode] = useState('EMP-' + Math.floor(10000 + Math.random() * 90000))
  const [firstName, setFirstName] = useState('')
  const [lastName, setLastName] = useState('')
  const [email, setEmail] = useState('')
  const [countryId, setCountryId] = useState(meta.countries[0]?.id || '')
  const [departmentId, setDepartmentId] = useState(meta.departments[0]?.id || '')
  const [designation, setDesignation] = useState('Associate Specialist')
  const [baseSalary, setBaseSalary] = useState('')
  const [payFrequency, setPayFrequency] = useState('annual')
  const [submitting, setSubmitting] = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setSubmitting(true)

    const selectedCountry = meta.countries.find(c => c.id === parseInt(countryId))

    try {
      await apiRequest('/api/v1/employees', {
        method: 'POST',
        body: JSON.stringify({
          employee: {
            employee_code: employeeCode,
            first_name: firstName,
            last_name: lastName,
            email,
            country_id: countryId,
            department_id: departmentId,
            designation,
            joined_at: new Date().toISOString().split('T')[0]
          },
          salary: {
            base_salary: parseFloat(baseSalary),
            currency: selectedCountry?.default_currency || 'USD',
            pay_frequency: payFrequency,
            effective_from: new Date().toISOString().split('T')[0]
          }
        })
      })
      onSuccess()
    } catch (err) {
      showToast(err.message, 'error')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl shadow-xl border border-slate-200 max-w-lg w-full p-6">
        <h3 className="text-lg font-bold text-slate-900">Add New Employee</h3>
        <p className="text-xs text-slate-500 mt-1">Creates employee record and initial salary agreement atomically.</p>

        <form onSubmit={handleSubmit} className="space-y-4 mt-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Employee Code</label>
              <input
                type="text"
                required
                value={employeeCode}
                onChange={e => setEmployeeCode(e.target.value)}
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg font-mono"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Work Email</label>
              <input
                type="email"
                required
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="name@acme.com"
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">First Name</label>
              <input
                type="text"
                required
                value={firstName}
                onChange={e => setFirstName(e.target.value)}
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Last Name</label>
              <input
                type="text"
                required
                value={lastName}
                onChange={e => setLastName(e.target.value)}
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Country</label>
              <select
                value={countryId}
                onChange={e => setCountryId(e.target.value)}
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg bg-white"
              >
                {meta.countries.map(c => <option key={c.id} value={c.id}>{c.name} ({c.default_currency})</option>)}
              </select>
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Department</label>
              <select
                value={departmentId}
                onChange={e => setDepartmentId(e.target.value)}
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg bg-white"
              >
                {meta.departments.map(d => <option key={d.id} value={d.id}>{d.name}</option>)}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div className="col-span-1">
              <label className="block text-xs font-semibold text-slate-700 mb-1">Designation</label>
              <input
                type="text"
                required
                value={designation}
                onChange={e => setDesignation(e.target.value)}
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Base Salary</label>
              <input
                type="number"
                required
                min="1"
                value={baseSalary}
                onChange={e => setBaseSalary(e.target.value)}
                placeholder="Amount"
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">Pay Frequency</label>
              <select
                value={payFrequency}
                onChange={e => setPayFrequency(e.target.value)}
                className="w-full px-3 py-1.5 text-sm border border-slate-300 rounded-lg bg-white capitalize"
              >
                {meta.pay_frequencies.map(f => <option key={f} value={f}>{f}</option>)}
              </select>
            </div>
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button type="button" onClick={onClose} className="px-3 py-1.5 text-xs text-slate-600 hover:bg-slate-100 rounded-lg">Cancel</button>
            <button type="submit" disabled={submitting} className="px-4 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold rounded-lg shadow-xs">
              {submitting ? 'Creating...' : 'Create Employee'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ---------------------------------------------------------
// 8. COMPENSATION ANALYTICS VIEW
// ---------------------------------------------------------
function AnalyticsView() {
  const [currency, setCurrency] = useState('USD')
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setLoading(true)
    apiRequest(`/api/v1/analytics/breakdown?currency=${currency}`)
      .then(res => setData(res))
      .catch(err => console.error(err))
      .finally(() => setLoading(false))
  }, [currency])

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Compensation Analytics</h1>
          <p className="text-sm text-slate-500 mt-1">
            Annualized statistics strictly scoped by contract currency
          </p>
        </div>

        {/* Currency Switcher */}
        <div className="flex items-center gap-2 bg-white p-1 rounded-xl border border-slate-200 shadow-xs">
          {['USD', 'INR', 'GBP', 'EUR', 'JPY'].map(c => (
            <button
              key={c}
              onClick={() => setCurrency(c)}
              className={`px-3 py-1 rounded-lg text-xs font-bold transition ${
                currency === c ? 'bg-indigo-600 text-white shadow-xs' : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              {c}
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="py-16 text-center text-slate-400">Computing PostgreSQL aggregations...</div>
      ) : (
        <>
          {/* Key Metric Tiles */}
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="bg-white p-5 rounded-xl border border-slate-200">
              <span className="text-xs font-semibold uppercase text-slate-500">Employees Paid in {currency}</span>
              <p className="text-2xl font-bold text-slate-900 mt-1">{data?.overall?.employee_count?.toLocaleString()}</p>
            </div>
            <div className="bg-white p-5 rounded-xl border border-slate-200">
              <span className="text-xs font-semibold uppercase text-slate-500">Average Annualized</span>
              <p className="text-2xl font-bold text-indigo-600 mt-1">
                {Number(data?.overall?.avg_annualized).toLocaleString()} {currency}
              </p>
            </div>
            <div className="bg-white p-5 rounded-xl border border-slate-200">
              <span className="text-xs font-semibold uppercase text-slate-500">Median Annualized</span>
              <p className="text-2xl font-bold text-slate-900 mt-1">
                {Number(data?.overall?.median_annualized).toLocaleString()} {currency}
              </p>
            </div>
            <div className="bg-white p-5 rounded-xl border border-slate-200">
              <span className="text-xs font-semibold uppercase text-slate-500">Compensation Spread</span>
              <p className="text-sm font-semibold text-slate-700 mt-1">
                Min: {Number(data?.overall?.min_annualized).toLocaleString()}
              </p>
              <p className="text-sm font-semibold text-slate-700">
                Max: {Number(data?.overall?.max_annualized).toLocaleString()}
              </p>
            </div>
          </div>

          {/* Department Breakdown */}
          <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-xs">
            <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4">Department Compensation Breakdown ({currency})</h3>
            <div className="overflow-x-auto">
              <table className="w-full text-left text-sm">
                <thead className="border-b border-slate-100 text-xs text-slate-400 uppercase">
                  <tr>
                    <th className="py-2">Department</th>
                    <th className="py-2">Employees</th>
                    <th className="py-2">Average Annualized</th>
                    <th className="py-2">Min - Max Range</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-50">
                  {data?.by_department?.map(dept => (
                    <tr key={dept.id}>
                      <td className="py-2.5 font-medium text-slate-800">{dept.name}</td>
                      <td className="py-2.5 text-slate-600">{dept.employee_count}</td>
                      <td className="py-2.5 font-mono font-semibold text-indigo-700">{Number(dept.avg_annualized).toLocaleString()} {currency}</td>
                      <td className="py-2.5 text-xs text-slate-500">
                        {Number(dept.min_annualized).toLocaleString()} – {Number(dept.max_annualized).toLocaleString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Salary Distribution Histogram */}
          <div className="bg-white rounded-xl border border-slate-200 p-6 shadow-xs">
            <h3 className="text-sm font-bold text-slate-900 uppercase tracking-wider mb-4">Distribution Buckets ({currency})</h3>
            <div className="space-y-3">
              {data?.distribution_buckets?.map((bucket, i) => {
                const total = data.overall.employee_count || 1
                const pct = Math.round((bucket.count / total) * 100)
                return (
                  <div key={i} className="text-xs">
                    <div className="flex justify-between text-slate-700 font-medium mb-1">
                      <span>{bucket.label} {currency}</span>
                      <span>{bucket.count} employees ({pct}%)</span>
                    </div>
                    <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                      <div className="bg-indigo-600 h-2 rounded-full" style={{ width: `${pct}%` }} />
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        </>
      )}
    </div>
  )
}

// ---------------------------------------------------------
// 9. AUDIT LOGS VIEW
// ---------------------------------------------------------
function AuditLogsView() {
  const [logs, setLogs] = useState([])
  const [pagination, setPagination] = useState({ current_page: 1, total_pages: 1, total_count: 0 })
  const [page, setPage] = useState(1)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    setLoading(true)
    apiRequest(`/api/v1/audit_logs?page=${page}&per_page=25`)
      .then(res => {
        setLogs(res.audit_logs)
        setPagination(res.pagination)
      })
      .catch(err => console.error(err))
      .finally(() => setLoading(false))
  }, [page])

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Salary Audit Trail</h1>
        <p className="text-sm text-slate-500 mt-1">
          Immutable historical log of all revisions, corrections, and cancellations ({pagination.total_count.toLocaleString()} entries)
        </p>
      </div>

      <div className="bg-white rounded-xl border border-slate-200 shadow-xs overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-slate-50 border-b border-slate-200 text-xs font-semibold text-slate-600 uppercase">
              <tr>
                <th className="py-3 px-4">Timestamp</th>
                <th className="py-3 px-4">Employee</th>
                <th className="py-3 px-4">Action</th>
                <th className="py-3 px-4">Previous Value</th>
                <th className="py-3 px-4">New Value</th>
                <th className="py-3 px-4">Actor</th>
                <th className="py-3 px-4">Reason</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-xs">
              {loading ? (
                <tr>
                  <td colSpan="7" className="py-12 text-center text-slate-400">Loading audit records...</td>
                </tr>
              ) : logs.length === 0 ? (
                <tr>
                  <td colSpan="7" className="py-12 text-center text-slate-400">No audit logs found.</td>
                </tr>
              ) : (
                logs.map(log => (
                  <tr key={log.id} className="hover:bg-slate-50">
                    <td className="py-3 px-4 text-slate-400 font-mono">
                      {new Date(log.created_at).toLocaleString()}
                    </td>
                    <td className="py-3 px-4 font-medium text-slate-900">
                      <div>{log.employee.full_name}</div>
                      <div className="text-slate-400 font-mono text-[10px]">{log.employee.employee_code}</div>
                    </td>
                    <td className="py-3 px-4">
                      <span className={`px-2 py-0.5 rounded font-semibold text-[10px] uppercase ${
                        log.action === 'revision' ? 'bg-indigo-50 text-indigo-700' :
                        log.action === 'correction' ? 'bg-amber-50 text-amber-700' :
                        log.action === 'deactivation' ? 'bg-rose-50 text-rose-700' :
                        'bg-slate-100 text-slate-700'
                      }`}>
                        {log.action}
                      </span>
                    </td>
                    <td className="py-3 px-4 font-mono text-slate-500">
                      {log.previous_salary ? `${Number(log.previous_salary).toLocaleString()} ${log.previous_currency}` : '—'}
                    </td>
                    <td className="py-3 px-4 font-mono font-bold text-slate-900">
                      {log.new_salary ? `${Number(log.new_salary).toLocaleString()} ${log.new_currency}` : '—'}
                    </td>
                    <td className="py-3 px-4 text-slate-600">
                      {log.actor.name}
                    </td>
                    <td className="py-3 px-4 text-slate-700 max-w-xs truncate" title={log.reason}>
                      {log.reason}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Bar */}
        <div className="bg-white px-4 py-3 border-t border-slate-200 flex items-center justify-between text-xs text-slate-500">
          <div>Page <span className="font-semibold text-slate-800">{pagination.current_page}</span> of {pagination.total_pages}</div>
          <div className="flex items-center gap-2">
            <button
              disabled={page <= 1 || loading}
              onClick={() => setPage(p => p - 1)}
              className="p-1 rounded border border-slate-200 hover:bg-slate-50 disabled:opacity-40"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <button
              disabled={page >= pagination.total_pages || loading}
              onClick={() => setPage(p => p + 1)}
              className="p-1 rounded border border-slate-200 hover:bg-slate-50 disabled:opacity-40"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

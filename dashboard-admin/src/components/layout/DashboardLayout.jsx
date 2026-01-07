import { Outlet } from 'react-router-dom'
import SidebarNav from './SidebarNav'
import Header from './Header'

export default function DashboardLayout({ onLogout }) {
  return (
    <div className="min-h-screen bg-coris-gray flex">
      {/* Sidebar avec navigation filtrée */}
      <SidebarNav />
      
      {/* Main Content */}
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <Header onLogout={onLogout} />
        
        {/* Page Content */}
        <main className="flex-1 overflow-y-auto p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}

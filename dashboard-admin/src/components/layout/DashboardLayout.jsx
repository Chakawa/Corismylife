import { Outlet } from 'react-router-dom'
import SidebarNav from './SidebarNav'
import Header from './Header'

export default function DashboardLayout({ onLogout }) {
  return (
    <div className="min-h-screen bg-coris-gray flex overflow-x-hidden">
      {/* Sidebar avec navigation filtrée */}
      <SidebarNav />
      
      {/* Main Content */}
      <div className="flex-1 flex flex-col min-w-0 md:ml-64">
        {/* Header */}
        <Header onLogout={onLogout} />
        
        {/* Page Content */}
        <main className="flex-1 overflow-y-auto overflow-x-hidden p-6 min-w-0">
          <Outlet />
        </main>
      </div>
    </div>
  )
}

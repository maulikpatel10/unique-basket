import React, { useState } from 'react';
import { Link, useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import {
  LayoutDashboard,
  Store,
  Users,
  FolderTree,
  Apple,
  PackageCheck,
  QrCode,
  CreditCard,
  Coins,
  Image as ImageIcon,
  ScrollText,
  LogOut,
  Menu,
  X,
  User as UserIcon,
  Sliders,
  MapPin
} from 'lucide-react';

export const DashboardLayout: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  if (!user) return null;

  // Define navigation rules based on Super Admin vs Store Manager role
  const menuItems = [
    {
      title: 'Dashboard',
      path: '/admin/dashboard',
      icon: LayoutDashboard,
      roles: ['SUPER_ADMIN', 'STORE_MANAGER'],
    },
    {
      title: 'Stores',
      path: '/admin/stores',
      icon: Store,
      roles: ['SUPER_ADMIN'],
    },
    {
      title: 'Store Managers',
      path: '/admin/managers',
      icon: Users,
      roles: ['SUPER_ADMIN'],
    },
    {
      title: 'Categories',
      path: '/admin/categories',
      icon: FolderTree,
      roles: ['SUPER_ADMIN'],
    },
    {
      title: 'Products',
      path: '/admin/products',
      icon: Apple,
      roles: ['SUPER_ADMIN'],
    },
    {
      title: 'Customers',
      path: '/admin/customers',
      icon: UserIcon,
      roles: ['SUPER_ADMIN'],
    },
    {
      title: 'Store Inventory',
      path: '/admin/inventory',
      icon: Sliders, // Swapped icon for custom control aesthetic
      roles: ['SUPER_ADMIN', 'STORE_MANAGER'],
    },
    {
      title: 'Orders',
      path: '/admin/orders',
      icon: PackageCheck,
      roles: ['SUPER_ADMIN', 'STORE_MANAGER'],
    },
    {
      title: 'Pickup Handover',
      path: '/admin/pickup-verify',
      icon: QrCode,
      roles: ['SUPER_ADMIN', 'STORE_MANAGER'],
    },
    {
      title: 'Payments',
      path: '/admin/payments',
      icon: CreditCard,
      roles: ['SUPER_ADMIN', 'STORE_MANAGER'],
    },
    {
      title: 'Fares & COD Settings',
      path: '/admin/settings',
      icon: Coins,
      roles: ['SUPER_ADMIN'],
    },
    {
      title: 'Delivery Pincodes',
      path: '/admin/pincodes',
      icon: MapPin,
      roles: ['SUPER_ADMIN'],
    },
    {
      title: 'Marketing Banners',
      path: '/admin/banners',
      icon: ImageIcon,
      roles: ['SUPER_ADMIN'],
    },
    {
      title: 'System Audit Logs',
      path: '/admin/audit-logs',
      icon: ScrollText,
      roles: ['SUPER_ADMIN'],
    },
  ];

  const filteredItems = menuItems.filter((item) => item.roles.includes(user.role));

  const SidebarContent = () => (
    <div className="flex h-full flex-col bg-darkbg-800 border-r border-slate-700 text-slate-100">
      {/* Brand Header */}
      <div className="flex h-16 items-center px-6 border-b border-slate-700">
        <div className="flex items-center gap-2">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-brand-500 text-white font-bold text-lg">
            UB
          </div>
          <div>
            <h1 className="font-extrabold text-sm leading-tight text-white tracking-wider uppercase">
              Unique Basket
            </h1>
            <span className="text-[10px] text-brand-400 font-semibold tracking-widest uppercase">
              Management Portal
            </span>
          </div>
        </div>
      </div>

      {/* Nav Links */}
      <nav className="flex-1 space-y-1 px-4 py-6 overflow-y-auto">
        {filteredItems.map((item) => {
          const isActive = location.pathname === item.path;
          const Icon = item.icon;
          return (
            <Link
              key={item.path}
              to={item.path}
              onClick={() => setMobileMenuOpen(false)}
              className={`flex items-center gap-3 px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200 ${
                isActive
                  ? 'bg-brand-500/10 text-brand-400 border border-brand-500/20 shadow-md shadow-brand-500/5'
                  : 'text-slate-400 hover:bg-slate-700/50 hover:text-white hover:pl-5'
              }`}
            >
              <Icon className={`h-5 w-5 ${isActive ? 'text-brand-400' : 'text-slate-400 group-hover:text-white'}`} />
              {item.title}
            </Link>
          );
        })}
      </nav>

      {/* User Footer block */}
      <div className="p-4 border-t border-slate-700 bg-slate-900/30">
        <div className="flex items-center gap-3 mb-4">
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-slate-700 text-brand-400">
            <UserIcon className="h-5 w-5" />
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-xs font-semibold text-white truncate">{user.name}</p>
            <p className="text-[10px] text-slate-400 truncate">{user.role.replace('_', ' ')}</p>
          </div>
        </div>
        <button
          onClick={handleLogout}
          className="flex w-full items-center justify-center gap-2 rounded-lg bg-slate-700/50 hover:bg-red-500/10 hover:text-red-400 text-slate-300 py-2.5 text-xs font-semibold border border-slate-600/30 transition-all duration-200"
        >
          <LogOut className="h-4 w-4" />
          Sign Out
        </button>
      </div>
    </div>
  );

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-darkbg-900 text-slate-200">
      {/* Desktop Sidebar */}
      <aside className="hidden md:flex md:w-64 md:flex-col md:fixed md:inset-y-0">
        <SidebarContent />
      </aside>

      {/* Main Container */}
      <div className="flex flex-col flex-1 md:pl-64">
        {/* Top Navbar */}
        <header className="flex h-16 items-center justify-between px-6 bg-darkbg-800 border-b border-slate-700 z-10">
          <button
            onClick={() => setMobileMenuOpen(true)}
            className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-700 hover:text-white md:hidden"
          >
            <Menu className="h-6 w-6" />
          </button>

          <div className="flex items-center gap-3 ml-auto">
            {user.storeId && (
              <span className="hidden sm:inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-brand-400 border border-brand-500/20">
                Assigned Store: {user.storeId.slice(0, 8)}...
              </span>
            )}
            <div className="text-right">
              <p className="text-xs font-bold text-white leading-none">{user.name}</p>
              <span className="text-[9px] text-brand-400 tracking-wider uppercase font-semibold">
                {user.role.replace('_', ' ')}
              </span>
            </div>
          </div>
        </header>

        {/* Dynamic Route Content */}
        <main className="flex-1 overflow-y-auto bg-darkbg-900 p-6">
          <Outlet />
        </main>
      </div>

      {/* Mobile Drawer Slide-over Overlay */}
      {mobileMenuOpen && (
        <div className="fixed inset-0 z-50 flex md:hidden">
          {/* Backdrop */}
          <div className="fixed inset-0 bg-black/60 backdrop-blur-xs" onClick={() => setMobileMenuOpen(false)} />

          {/* Sidebar container */}
          <div className="relative flex w-full max-w-xs flex-1 flex-col animate-slide-in">
            <div className="absolute right-4 top-4 z-10">
              <button
                onClick={() => setMobileMenuOpen(false)}
                className="rounded-lg p-1.5 text-slate-400 hover:bg-slate-700 hover:text-white"
              >
                <X className="h-6 w-6" />
              </button>
            </div>
            <SidebarContent />
          </div>
        </div>
      )}
    </div>
  );
};

import React, { Suspense, lazy } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { PrivateRoute } from './components/PrivateRoute';
import { DashboardLayout } from './layouts/DashboardLayout';

// Pages
import { Login } from './pages/Login';

// P2-07: route-level code splitting (pages load on demand)
const Dashboard = lazy(() => import('./pages/Dashboard').then((m) => ({ default: m.Dashboard })));
const Stores = lazy(() => import('./pages/Stores').then((m) => ({ default: m.Stores })));
const StoreDetails = lazy(() => import('./pages/StoreDetails').then((m) => ({ default: m.StoreDetails })));
const Managers = lazy(() => import('./pages/Managers').then((m) => ({ default: m.Managers })));
const ManagerDetails = lazy(() => import('./pages/ManagerDetails').then((m) => ({ default: m.ManagerDetails })));
const Categories = lazy(() => import('./pages/Categories').then((m) => ({ default: m.Categories })));
const Products = lazy(() => import('./pages/Products').then((m) => ({ default: m.Products })));
const Inventory = lazy(() => import('./pages/Inventory').then((m) => ({ default: m.Inventory })));
const Customers = lazy(() => import('./pages/Customers').then((m) => ({ default: m.Customers })));
const CustomerDetails = lazy(() => import('./pages/CustomerDetails').then((m) => ({ default: m.CustomerDetails })));
const Orders = lazy(() => import('./pages/Orders').then((m) => ({ default: m.Orders })));
const OrderDetails = lazy(() => import('./pages/OrderDetails').then((m) => ({ default: m.OrderDetails })));
const PickupVerification = lazy(() => import('./pages/PickupVerification').then((m) => ({ default: m.PickupVerification })));
const Payments = lazy(() => import('./pages/Payments').then((m) => ({ default: m.Payments })));
const PaymentDetails = lazy(() => import('./pages/PaymentDetails').then((m) => ({ default: m.PaymentDetails })));
const Settings = lazy(() => import('./pages/Settings').then((m) => ({ default: m.Settings })));
const Pincodes = lazy(() => import('./pages/Pincodes').then((m) => ({ default: m.Pincodes })));
const Banners = lazy(() => import('./pages/Banners').then((m) => ({ default: m.Banners })));
const AuditLogs = lazy(() => import('./pages/AuditLogs').then((m) => ({ default: m.AuditLogs })));

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Suspense
          fallback={
            <div className="flex h-screen items-center justify-center bg-darkbg-900">
              <div className="h-12 w-12 animate-spin rounded-full border-4 border-brand-500 border-t-transparent"></div>
            </div>
          }
        >
        <Routes>
          {/* Public Route */}
          <Route path="/login" element={<Login />} />

          {/* Protected Routes */}
          <Route
            path="/admin"
            element={
              <PrivateRoute>
                <DashboardLayout />
              </PrivateRoute>
            }
          >
            {/* Common Admin Views */}
            <Route path="dashboard" element={<Dashboard />} />

            {/* Super Admin & Store Manager Shared Views */}
            <Route
              path="orders"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN', 'STORE_MANAGER']}>
                  <Orders />
                </PrivateRoute>
              }
            />
            <Route
              path="orders/:id"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN', 'STORE_MANAGER']}>
                  <OrderDetails />
                </PrivateRoute>
              }
            />
            <Route
              path="pickup-verify"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN', 'STORE_MANAGER']}>
                  <PickupVerification />
                </PrivateRoute>
              }
            />
            <Route
              path="inventory"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN', 'STORE_MANAGER']}>
                  <Inventory />
                </PrivateRoute>
              }
            />
            <Route
              path="stores"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN', 'STORE_MANAGER']}>
                  <Stores />
                </PrivateRoute>
              }
            />
            <Route
              path="stores/:id"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN', 'STORE_MANAGER']}>
                  <StoreDetails />
                </PrivateRoute>
              }
            />
            <Route
              path="payments"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN', 'STORE_MANAGER']}>
                  <Payments />
                </PrivateRoute>
              }
            />
            <Route
              path="payments/:id"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN', 'STORE_MANAGER']}>
                  <PaymentDetails />
                </PrivateRoute>
              }
            />

            {/* Super Admin Only Views */}
            <Route
              path="managers"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN']}>
                  <Managers />
                </PrivateRoute>
              }
            />
            <Route
              path="managers/:id"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN']}>
                  <ManagerDetails />
                </PrivateRoute>
              }
            />
            <Route
              path="categories"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN']}>
                  <Categories />
                </PrivateRoute>
              }
            />
            <Route
              path="products"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN']}>
                  <Products />
                </PrivateRoute>
              }
            />
            <Route
              path="customers"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN']}>
                  <Customers />
                </PrivateRoute>
              }
            />
            <Route
              path="customers/:id"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN']}>
                  <CustomerDetails />
                </PrivateRoute>
              }
            />
            <Route
              path="settings"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN']}>
                  <Settings />
                </PrivateRoute>
              }
            />
            <Route
              path="pincodes"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN']}>
                  <Pincodes />
                </PrivateRoute>
              }
            />
            <Route
              path="banners"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN']}>
                  <Banners />
                </PrivateRoute>
              }
            />
            <Route
              path="marketing-banners"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN']}>
                  <Banners />
                </PrivateRoute>
              }
            />
            <Route
              path="audit-logs"
              element={
                <PrivateRoute allowedRoles={['SUPER_ADMIN']}>
                  <AuditLogs />
                </PrivateRoute>
              }
            />

            {/* Fallback Redirect */}
            <Route path="" element={<Navigate to="dashboard" replace />} />
          </Route>

          {/* Catch-all Fallback */}
          <Route path="*" element={<Navigate to="/admin/dashboard" replace />} />
        </Routes>
        </Suspense>
      </BrowserRouter>
    </AuthProvider>
  );
};

export default App;

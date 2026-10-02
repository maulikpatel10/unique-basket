import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { PrivateRoute } from './components/PrivateRoute';
import { DashboardLayout } from './layouts/DashboardLayout';

// Pages
import { Login } from './pages/Login';
import { Dashboard } from './pages/Dashboard';
import { Stores } from './pages/Stores';
import { StoreDetails } from './pages/StoreDetails';
import { Managers } from './pages/Managers';
import { ManagerDetails } from './pages/ManagerDetails';
import { Categories } from './pages/Categories';
import { Products } from './pages/Products';
import { Inventory } from './pages/Inventory';
import { Customers } from './pages/Customers';
import { CustomerDetails } from './pages/CustomerDetails';
import { Orders } from './pages/Orders';
import { OrderDetails } from './pages/OrderDetails';
import { PickupVerification } from './pages/PickupVerification';
import { Payments } from './pages/Payments';
import { PaymentDetails } from './pages/PaymentDetails';
import { Settings } from './pages/Settings';
import { Pincodes } from './pages/Pincodes';
import { Banners } from './pages/Banners';
import { AuditLogs } from './pages/AuditLogs';

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <BrowserRouter>
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
      </BrowserRouter>
    </AuthProvider>
  );
};

export default App;

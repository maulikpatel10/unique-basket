# UNIQUE BASKET — Admin Panel

The UNIQUE BASKET Admin Panel is a web dashboard for managing store operations, catalog inventory, orders, customers, store managers, banners, audit logs, and system settings across the UNIQUE BASKET platform.

## Tech Stack

- **Framework**: React 19 + TypeScript + Vite
- **Routing**: React Router v7
- **HTTP Client**: Axios
- **Styling & UI**: Tailwind CSS + Lucide React (Icons)
- **Linting**: ESLint + TypeScript ESLint

## Prerequisites

- **Node.js**: `v18+` (or active LTS)
- **Package Manager**: `npm` (v9+)
- **Backend API**: Running UNIQUE BASKET Backend API (default at `http://localhost:5001/api/v1`)

## Installation & Setup

1. **Navigate to the admin directory**:
   ```bash
   cd apps/admin
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Configure Environment (Optional)**:
   By default, the application connects to `http://localhost:5001/api/v1`. To override this, create a `.env` file:
   ```env
   VITE_API_URL=http://localhost:5001/api/v1
   ```

## Available Scripts

- `npm run dev`: Start the local Vite development server with HMR.
- `npm run build`: Type-check and build the production bundle in `dist/`.
- `npm run preview`: Locally preview the production build.
- `npm run lint`: Run ESLint across source files.

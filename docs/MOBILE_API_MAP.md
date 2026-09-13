# UNIQUE BASKET — Mobile API Map

**Base URL (Local/Dev)**: `http://<HOST_IP>:5001/api/v1`  
**Authorization Header**: `Authorization: Bearer <ACCESS_TOKEN>`

---

## 1. Authentication Endpoints (`/auth`)

### 1.1 Send Mobile OTP
- **Method**: `POST`
- **Path**: `/auth/send-otp`
- **Auth Required**: No
- **Request Body**:
  ```json
  {
    "phone": "+919999999999"
  }
  ```
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "OTP sent successfully."
  }
  ```
- **Error Codes**: `INVALID_PHONE_FORMAT`, `OTP_REQUEST_FAILED`

### 1.2 Verify Mobile OTP
- **Method**: `POST`
- **Path**: `/auth/verify-otp`
- **Auth Required**: No
- **Request Body**:
  ```json
  {
    "phone": "+919999999999",
    "otp": "123456"
  }
  ```
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "OTP verified successfully.",
    "data": {
      "user": {
        "id": "8beff4bf-a349-42e6-bfc6-cb2825c3588c",
        "phone": "+919999999999",
        "name": "Customer Name"
      },
      "isNewUser": false,
      "token": "eyJhbGciOi...",
      "refreshToken": "eyJhbGciOi..."
    }
  }
  ```
- **Error Codes**: `MISSING_PARAMETERS`, `OTP_VERIFICATION_FAILED`, `ACCOUNT_DEACTIVATED`

### 1.3 Refresh Session Token
- **Method**: `POST`
- **Path**: `/auth/refresh`
- **Auth Required**: No
- **Request Body**:
  ```json
  {
    "refreshToken": "eyJhbGciOi..."
  }
  ```
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": {
      "token": "eyJhbGciOi..."
    }
  }
  ```
- **Error Codes**: `MISSING_REFRESH_TOKEN`, `INVALID_REFRESH_TOKEN`, `USER_NOT_FOUND`

### 1.4 Logout
- **Method**: `POST`
- **Path**: `/auth/logout`
- **Auth Required**: No
- **Request Body**:
  ```json
  {
    "deviceToken": "fcm_token_optional"
  }
  ```
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Logged out successfully."
  }
  ```

---

## 2. Categories & Catalog Endpoints (`/categories`, `/products`)

### 2.1 List Categories
- **Method**: `GET`
- **Path**: `/categories`
- **Auth Required**: Yes (`Bearer`)
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "uuid",
        "name": "Fresh Vegetables",
        "description": "Farm fresh veggies",
        "imageUrl": "https://...",
        "displayOrder": 1,
        "isActive": true
      }
    ]
  }
  ```

### 2.2 List Global Products
- **Method**: `GET`
- **Path**: `/products?categoryId={uuid}&search={keyword}`
- **Auth Required**: Yes (`Bearer`)
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "uuid",
        "name": "Fresh Tomato",
        "description": "Organic ripe tomatoes",
        "imageUrl": "https://...",
        "categoryId": "uuid",
        "unit": "KG",
        "price": "40.00",
        "mrp": "50.00",
        "isActive": true,
        "category": { "name": "Fresh Vegetables" }
      }
    ]
  }
  ```

### 2.3 Get Product Details
- **Method**: `GET`
- **Path**: `/products/:id`
- **Auth Required**: Yes (`Bearer`)
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": {
      "id": "uuid",
      "name": "Fresh Tomato",
      "description": "Organic ripe tomatoes",
      "imageUrl": "https://...",
      "categoryId": "uuid",
      "unit": "KG",
      "price": "40.00",
      "mrp": "50.00",
      "isActive": true,
      "category": { "name": "Fresh Vegetables" }
    }
  }
  ```

### 2.4 List Products with Store Inventory
- **Method**: `GET`
- **Path**: `/products/store/:storeId?categoryId={uuid}`
- **Auth Required**: Yes (`Bearer`)
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "uuid",
        "name": "Fresh Tomato",
        "description": "Organic ripe tomatoes",
        "imageUrl": "https://...",
        "categoryId": "uuid",
        "categoryName": "Fresh Vegetables",
        "unit": "KG",
        "price": "40.00",
        "mrp": "50.00",
        "stockQuantity": 25.5,
        "lowStockThreshold": 5.0,
        "isAvailable": true
      }
    ]
  }
  ```

---

## 3. Store Endpoints (`/stores`)

### 3.1 List Stores with Eligibility Check
- **Method**: `GET`
- **Path**: `/stores?lat={lat}&lng={lng}&fulfillment=DELIVERY`
- **Auth Required**: Yes (`Bearer`)
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "id": "uuid",
        "storeId": "STORE-001",
        "name": "Central Supermarket",
        "address": "123 Main St",
        "city": "Rajkot",
        "state": "Gujarat",
        "pincode": "360001",
        "latitude": 22.303894,
        "longitude": 70.80216,
        "deliveryRadiusKm": 10.0,
        "phone": "+919876543210",
        "openingTime": "08:00",
        "closingTime": "22:00",
        "isActive": true,
        "distanceKm": 2.4,
        "isEligible": true
      }
    ]
  }
  ```

---

## 4. Server-Side Cart Endpoints (`/cart`)

### 4.1 Get Cart
- **Method**: `GET`
- **Path**: `/cart`
- **Auth Required**: Yes (`Bearer`)
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "data": {
      "items": [
        {
          "id": "cart_item_uuid",
          "productId": "product_uuid",
          "productName": "Fresh Tomato",
          "unit": "KG",
          "price": 40.0,
          "mrp": 50.0,
          "quantity": 1.5,
          "totalPrice": 60.0
        }
      ],
      "subtotal": 60.0
    }
  }
  ```

### 4.2 Add/Upsert Cart Item
- **Method**: `POST`
- **Path**: `/cart/items`
- **Auth Required**: Yes (`Bearer`)
- **Request Body**:
  ```json
  {
    "productId": "uuid",
    "quantity": 1.5
  }
  ```
- **Success Response (`201 Created`)**:
  ```json
  {
    "success": true,
    "message": "Product added to cart successfully.",
    "data": {
      "id": "cart_item_uuid",
      "productId": "product_uuid",
      "quantity": 1.5
    }
  }
  ```

### 4.3 Update Cart Item Quantity
- **Method**: `PUT`
- **Path**: `/cart/items/:id`
- **Auth Required**: Yes (`Bearer`)
- **Request Body**:
  ```json
  {
    "quantity": 2.0
  }
  ```

### 4.4 Remove Cart Item
- **Method**: `DELETE`
- **Path**: `/cart/items/:id`
- **Auth Required**: Yes (`Bearer`)

---

## 5. Orders & Checkout Endpoints (`/orders`)

### 5.1 Place Order
- **Method**: `POST`
- **Path**: `/orders`
- **Auth Required**: Yes (`Bearer`)
- **Request Body**:
  ```json
  {
    "fulfillmentType": "DELIVERY", // or "PICKUP"
    "addressId": "address_uuid", // required for DELIVERY
    "storeId": "store_uuid", // required for PICKUP
    "paymentMethod": "COD", // or "ONLINE"
    "items": [
      {
        "productId": "product_uuid",
        "quantity": 1.5
      }
    ]
  }
  ```
- **Success Response (`201 Created`)**:
  ```json
  {
    "success": true,
    "message": "Order created successfully.",
    "data": {
      "order": {
        "id": "order_uuid",
        "orderNumber": "UB-20260901-001",
        "fulfillmentType": "DELIVERY",
        "subtotal": 60.0,
        "deliveryFee": 30.0,
        "codCharge": 20.0,
        "total": 110.0,
        "paymentMethod": "COD",
        "paymentStatus": "PENDING",
        "orderStatus": "PLACED"
      },
      "razorpayOrder": null // Or { id: "order_rcptid_...", amount: 11000, currency: "INR" } for ONLINE
    }
  }
  ```
- **Error Codes**: `DELIVERY_DISABLED`, `MINIMUM_DELIVERY_AMOUNT_NOT_MET`, `COD_DISABLED`, `PICKUP_COD_DISABLED`, `MINIMUM_COD_AMOUNT_NOT_MET`, `MAXIMUM_COD_AMOUNT_EXCEEDED`, `NO_DELIVERY_AVAILABLE`, `INSUFFICIENT_STOCK`, `PAYMENT_GATEWAY_ERROR`

### 5.2 Get Customer Orders List
- **Method**: `GET`
- **Path**: `/orders`
- **Auth Required**: Yes (`Bearer`)

### 5.3 Get Order Details
- **Method**: `GET`
- **Path**: `/orders/:id`
- **Auth Required**: Yes (`Bearer`)

---

## 6. Payment Verification Endpoints (`/payments`)

### 6.1 Cryptographic Payment Verification
- **Method**: `POST`
- **Path**: `/payments/verify`
- **Auth Required**: Yes (`Bearer`)
- **Request Body**:
  ```json
  {
    "razorpay_order_id": "order_xxxx",
    "razorpay_payment_id": "pay_xxxx",
    "razorpay_signature": "signature_hex"
  }
  ```
- **Success Response (`200 OK`)**:
  ```json
  {
    "success": true,
    "message": "Payment verified and order confirmed successfully.",
    "data": {
      "orderId": "order_uuid",
      "orderNumber": "UB-20260901-001",
      "paymentStatus": "PAID",
      "orderStatus": "CONFIRMED"
    }
  }
  ```

---

## 7. Push Notifications Endpoints (`/notifications`)

### 7.1 Register Device Token
- **Method**: `POST`
- **Path**: `/notifications/tokens`
- **Auth Required**: Yes (`Bearer`)
- **Request Body**:
  ```json
  {
    "token": "fcm_token_string",
    "platform": "ANDROID" // or "IOS"
  }
  ```

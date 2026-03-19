# API
POST /auth/login        body: {email, password}  → {token, refreshToken}
POST /auth/refresh      body: {refreshToken}      → {token}
GET  /user/me           header: Authorization     → {id, name, email}


# FastAPI CRUD Frontend (Static)

A minimal, neutral-theme static site for Register, Login, and Item CRUD, split into separate files and ready for S3 + CloudFront.

## Structure

```
fastapi_frontend_split/
├── index.html
├── register.html
├── login.html
├── items.html
├── css/
│   └── style.css
└── js/
    ├── app.js
    ├── register.js
    ├── login.js
    └── items.js
```

- `index.html` redirects to `register.html` (landing).
- `items.html` is protected client-side: redirects to `login.html` if no JWT in `localStorage`.

## Configure

Edit `js/app.js`:
- Set `API_BASE` to your API Gateway base URL (e.g., `https://xxxx.execute-api.us-east-2.amazonaws.com`).
- Adjust endpoint paths if your FastAPI app differs.

> Ensure your FastAPI CORS allows your CloudFront domain and headers: `Authorization, Content-Type` with methods `GET, POST, PUT, DELETE, OPTIONS`.

## Deploy to S3 + CloudFront

1. Create S3 bucket and upload all files preserving folder structure.
2. (Recommended) Use CloudFront with an Origin Access Control for private bucket access.
3. Set default root object to `index.html` (or `register.html`) in CloudFront.
4. Invalidate cache after updates as needed.

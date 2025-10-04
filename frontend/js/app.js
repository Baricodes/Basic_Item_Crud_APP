/**
 * ======== CONFIG ========
 * Update API_BASE and paths below to match your FastAPI routes.
 */
export const API_BASE = "" // My API Gateway endpoint; // e.g. https://xxxx.execute-api.us-east-2.amazonaws.com
export const ENDPOINTS = {
  register: "/user/register/",   // POST {username, email, password}
  login: "/user/login/",         // POST {username, password} -> {access_token}
  items_list: "/item/read/",          // GET -> list items for current user (adjust if different)
  items_create: "/item/create/", // POST {name, description}
  items_update_id: (id) => `/item/update/${id}`, // PUT/PATCH {name?, description?}
  items_delete_id: (id) => `/item/delete/${id}`  // DELETE
};

// ======== UTIL ========
export const $ = (sel) => document.querySelector(sel);

export function setStatus(id, msg, ok = true) {
  const el = document.getElementById(id);
  if (!el) return;
  el.className = `status ${ok ? 'ok' : 'err'}`;
  el.textContent = msg;
}

export function clearStatus(id) {
  const el = document.getElementById(id);
  if (el) { el.className = 'status'; el.textContent = ''; }
}

export function token() { return localStorage.getItem('jwt') || ''; }
export function isAuthed() { return !!token(); }

export function authHeader() {
  const t = token();
  return t ? { 'Authorization': `Bearer ${t}` } : {};
}

export function applyAuthUI() {
  const indicator = document.getElementById('auth-indicator');
  const logoutBtn = document.getElementById('logout-btn');
  if (indicator) indicator.textContent = isAuthed() ? 'Logged in' : 'Logged out';
  if (logoutBtn) logoutBtn.style.display = isAuthed() ? '' : 'none';
}

export function activateTab(tabName) {
  document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t.dataset.tab === tabName));
}

export async function api(path, { method = 'GET', body, auth = false } = {}) {
  const headers = { 'Content-Type': 'application/json', ...(auth ? authHeader() : {}) };
  const resp = await fetch(API_BASE + path, { method, headers, body: body ? JSON.stringify(body) : undefined });
  let data = null;
  try { data = await resp.json(); } catch (e) {}
  return { ok: resp.ok, status: resp.status, data };
}

// Guard a page: if not authed, redirect to login
export function guardPage() {
  if (!isAuthed()) {
    try { setStatus('login-status', 'Please log in to access this page.', false); } catch (e) {}
    window.location.href = "login.html";
  }
}

// Navbar shared actions
export function setupNavbar(currentTab) {
  activateTab(currentTab);
  toggleChromeForAuth();

  // Also keep nav logout working when nav is visible
  const logoutBtn = document.getElementById('logout-btn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', () => {
      localStorage.removeItem('jwt');
      toggleChromeForAuth();
      window.location.href = "login.html";
    });
  }
}

// === Auth UI helpers (injected) ===
function ensureFloatingLogout() {
  let btn = document.getElementById('floating-logout');
  if (!btn) {
    btn = document.createElement('button');
    btn.id = 'floating-logout';
    btn.className = 'btn ghost';
    btn.textContent = 'Log out';
    btn.style.position = 'fixed';
    btn.style.top = '14px';
    btn.style.right = '16px';
    btn.style.zIndex = '9999';
    btn.style.display = 'none';
    document.body.appendChild(btn);
  }
  btn.onclick = () => {
    localStorage.removeItem('jwt');
    // show navbar again
    const nav = document.querySelector('.nav');
    if (nav) nav.style.display = '';
    btn.style.display = 'none';
    // also update any inline logout button in nav if present
    const navLogout = document.getElementById('logout-btn');
    if (navLogout) navLogout.style.display = 'none';
    window.location.href = 'login.html';
  };
  return btn;
}

function toggleChromeForAuth() {
  const authed = !!localStorage.getItem('jwt');
  const nav = document.querySelector('.nav');
  const floatBtn = ensureFloatingLogout();
  if (authed) {
    if (nav) nav.style.display = 'none';
    floatBtn.style.display = 'inline-block';
  } else {
    if (nav) nav.style.display = '';
    floatBtn.style.display = 'none';
  }
}


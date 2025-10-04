import { ENDPOINTS, api, clearStatus, setStatus, setupNavbar } from './app.js';

window.addEventListener('DOMContentLoaded', () => {
  setupNavbar('login');

  const submit = document.getElementById('login-btn');
  submit.addEventListener('click', async () => {
    clearStatus('login-status');
    const username = document.getElementById('login-username').value.trim();
    const password = document.getElementById('login-password').value;
    if (!username || !password) {
      return setStatus('login-status', 'Username and password required.', false);
    }
    const { ok, status, data } = await api(ENDPOINTS.login, { method: 'POST', body: { username, password } });
    if (ok) {
      const jwt = data?.access_token || data?.token || null;
      if (!jwt) return setStatus('login-status', 'No token returned by API. Check endpoint mapping.', false);
      localStorage.setItem('jwt', jwt);
      setStatus('login-status', 'Logged in! Redirecting…', true);
      window.location.href = 'items.html';
    } else {
      setStatus('login-status', `Error (${status}): ${data?.detail || 'Login failed.'}`, false);
    }
  });
});
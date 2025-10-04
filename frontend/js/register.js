import { ENDPOINTS, api, clearStatus, setStatus, setupNavbar } from './app.js';

window.addEventListener('DOMContentLoaded', () => {
  setupNavbar('register');

  const submit = document.getElementById('register-btn');
  submit.addEventListener('click', async () => {
    clearStatus('register-status');
    const username = document.getElementById('reg-username').value.trim();
    const email = document.getElementById('reg-email').value.trim();
    const password = document.getElementById('reg-password').value;
    if (!username || !email || !password) {
      return setStatus('register-status', 'All fields are required.', false);
    }
    const { ok, status, data } = await api(ENDPOINTS.register, { method: 'POST', body: { username, email, password } });
    if (ok) {
      setStatus('register-status', 'Success! You can now log in.', true);
      window.location.href = 'thankyou.html';
    } else {
      setStatus('register-status', `Error (${status}): ${data?.detail || 'Registration failed.'}`, false);
    }
  });
});
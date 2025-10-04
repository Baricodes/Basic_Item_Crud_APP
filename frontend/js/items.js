import { ENDPOINTS, api, setStatus, clearStatus, setupNavbar, guardPage } from './app.js';

async function loadItems() {
  clearStatus('items-status');
  const tbody = document.getElementById('items-tbody');
  tbody.innerHTML = `<tr><td colspan="4" class="hint" style="padding:14px;">Loading…</td></tr>`;
  const { ok, status, data } = await api(ENDPOINTS.items_list, { auth: true });
  if (!ok) {
    tbody.innerHTML = `<tr><td colspan="4" style="padding:14px; color:#ef9a9a;">Error (${status}). Check items_list path or authentication.</td></tr>`;
    return;
  }
  const items = Array.isArray(data) ? data : (data?.items || []);
  if (!items.length) {
    tbody.innerHTML = `<tr><td colspan="4" class="hint" style="padding:14px;">No items found.</td></tr>`;
    return;
  }
  tbody.innerHTML = '';
  for (const it of items) {
    const id = it.id ?? it.item_id ?? '';
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><code>${id}</code></td>
      <td><input value="${(it.name ?? '').toString().replaceAll('"','&quot;')}" data-field="name" style="width:100%;" /></td>
      <td><input value="${(it.description ?? '').toString().replaceAll('"','&quot;')}" data-field="description" style="width:100%;" /></td>
      <td>
        <div class="row-actions">
          <button class="btn" data-action="save">Save</button>
          <button class="btn" data-action="delete" style="border-color: rgba(239,68,68,0.35);">Delete</button>
        </div>
      </td>
    `;
    tr.querySelector('[data-action="save"]').addEventListener('click', async () => {
      const name = tr.querySelector('input[data-field="name"]').value.trim();
      const description = tr.querySelector('input[data-field="description"]').value.trim();
      const { ok, status, data } = await api(ENDPOINTS.items_update_id(id), { method: 'PUT', auth: true, body: { name, description } });
      setStatus('items-status', ok ? 'Saved.' : `Error (${status}): ${data?.detail || 'Update failed.'}`, ok);
      if (ok) loadItems();
    });
    tr.querySelector('[data-action="delete"]').addEventListener('click', async () => {
      if (!confirm('Delete this item?')) return;
      const { ok, status, data } = await api(ENDPOINTS.items_delete_id(id), { method: 'DELETE', auth: true });
      setStatus('items-status', ok ? 'Deleted.' : `Error (${status}): ${data?.detail || 'Delete failed.'}`, ok);
      if (ok) loadItems();
    });
    tbody.appendChild(tr);
  }
}

window.addEventListener('DOMContentLoaded', () => {
  guardPage();
  setupNavbar('items');

  document.getElementById('refresh-items').addEventListener('click', loadItems);
  document.getElementById('create-item').addEventListener('click', async () => {
    clearStatus('items-status');
    const name = document.getElementById('item-name').value.trim();
    const description = document.getElementById('item-desc').value.trim();
    if (!name) return setStatus('items-status', 'Name is required.', false);
    const { ok, status, data } = await api(ENDPOINTS.items_create, { method: 'POST', auth: true, body: { name, description } });
    setStatus('items-status', ok ? 'Created.' : `Error (${status}): ${data?.detail || 'Create failed.'}`, ok);
    if (ok) {
      document.getElementById('item-name').value = '';
      document.getElementById('item-desc').value = '';
      loadItems();
    }
  });

  loadItems();
});
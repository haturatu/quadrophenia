require 'cgi'

class HtmlGenerator
  def generate_html(query_params, network_utils)
    hosts = network_utils.parse_hosts_from_query(query_params)
    ports = network_utils.parse_ports_from_query(query_params)
    timeout = query_params['timeout']&.to_f || ServiceScanner::DEFAULT_TIMEOUT
    timeout = [timeout, 0.05].max

    hosts_str = CGI.escapeHTML(hosts.join(', '))
    timeout_str = CGI.escapeHTML(timeout.to_s)
    hosts_value = CGI.escapeHTML(hosts.join(','))

    <<~HTML
<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Quadrophenia - HTTP/HTTPS サービス スキャナー</title>
<link id="theme-link" href="https://cdn.jsdelivr.net/npm/bootswatch@5.3.3/dist/materia/bootstrap.min.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/notyf@3/notyf.min.css">
<style>
  :root {
    --bs-body-font-size: 16px !important;
    --bs-body-font-family: 'Segoe UI', 'ヒラギノ角ゴ ProN', 'Hiragino Kaku Gothic ProN', Arial, 'メイリオ', Meiryo, sans-serif !important;
    font-size: 16px !important;
  }
  html, body {
    font-size: 16px !important;
    font-family: 'Segoe UI', 'ヒラギノ角ゴ ProN', 'Hiragino Kaku Gothic ProN', Arial, 'メイリオ', Meiryo, sans-serif !important;
    line-height: 1.7;
    background: var(--bs-body-bg, #fff);
    color: var(--bs-body-color, #222);
  }
  h1, h2, h3, h4, h5, h6,
  .form-label, input, select, button, .table, .card, .badge, .notyf__message {
    font-size: 16px !important;
    font-family: 'Segoe UI', 'ヒラギノ角ゴ ProN', 'Hiragino Kaku Gothic ProN', Arial, 'メイリオ', Meiryo, sans-serif !important;
  }
  .btn, .form-control, .card-title, .card-body, .card-footer {
    font-size: 16px !important;
    font-family: 'Segoe UI', 'ヒラギノ角ゴ ProN', 'Hiragino Kaku Gothic ProN', Arial, 'メイリオ', Meiryo, sans-serif !important;
  }
  strong, em, code, pre, th, td, label, .form-check-label {
    font-size: 16px !important;
    font-family: 'Segoe UI', 'ヒラギノ角ゴ ProN', 'Hiragino Kaku Gothic ProN', Arial, 'メイリオ', Meiryo, sans-serif !important;
  }
  body { transition: background-color 0.2s ease-in-out; }
  .table { table-layout: fixed; }
  .table td, .table th { word-break: break-all; vertical-align: middle; }
  .form-label { font-weight: 500; }
  .table-overlay {
    position: absolute; top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(var(--bs-body-bg-rgb,255,255,255), 0.7);
    display: flex; justify-content: center; align-items: center; z-index: 10;
  }
  /* レスポンシブ: スマホはテーブル非表示・カード形式に */
  @media (max-width: 768px) {
    .table-responsive { display: none !important; }
    .card-list-responsive { display: block !important; }
  }
  .card-list-responsive { display: none; }
</style>
</head>
<body>
<div class="container py-4">
  <header class="d-flex flex-wrap align-items-center justify-content-between gap-3 pb-3 mb-4 border-bottom">
    <h1 class="h4 mb-0 d-flex align-items-center gap-2">
      Quadrophenia - HTTP/HTTPS サービス スキャナー
    </h1>
    <div class="form-check form-switch">
      <input class="form-check-input" type="checkbox" id="themeToggle">
      <label class="form-check-label" for="themeToggle"><i class="bi bi-moon-stars-fill"></i> ダークモード</label>
    </div>
  </header>

  <div class="card mb-4">
    <div class="card-body">
      <div class="row g-3 align-items-end">
        <div class="col-12 col-md-6 col-lg-3">
          <label class="form-label">ホスト</label>
          <input id="hostInput" type="text" class="form-control" placeholder="127.0.0.1, 10.0.0.0/24" value="#{hosts_value}">
        </div>
        <div class="col-12 col-sm-6 col-lg-2">
          <label class="form-label">ポート</label>
          <input id="portInput" type="text" class="form-control" placeholder="80, 443, 8080">
        </div>
        <div class="col-12 col-sm-6 col-lg-2">
          <label class="form-label">範囲</label>
          <input id="rangeInput" type="text" class="form-control" placeholder="3000-3010">
        </div>
        <div class="col-6 col-lg-2">
          <label class="form-label">タイムアウト(s)</label>
          <input id="timeoutInput" type="number" class="form-control" min="0.05" step="0.05" value="#{timeout_str}">
        </div>
        <div class="col-6 col-lg-3">
          <button class="btn btn-primary w-100" id="scanBtn">
            <i class="bi bi-search"></i> スキャン実行
          </button>
        </div>
      </div>
    </div>
  </div>
  
  <div class="d-flex flex-wrap align-items-center justify-content-between gap-2 mb-3">
    <input id="filterInput" type="search" class="form-control" style="max-width: 320px;" placeholder="結果をフィルタリング...">
    <div id="scanStatus" class="text-muted small">スキャン待機中</div>
  </div>
  <div class="card">
    <div class="position-relative">
      <div id="loadingOverlay" class="table-overlay d-none">
        <div class="spinner-border text-primary" role="status">
          <span class="visually-hidden">Loading...</span>
        </div>
      </div>
      <div class="table-responsive">
        <table id="resultTable" class="table table-hover table-striped mb-0">
          <thead>
            <tr>
              <th scope="col">ホスト</th>
              <th scope="col">ポート</th>
              <th scope="col">プロトコル</th>
              <th scope="col">ステータス</th>
              <th scope="col">タイトル / エラー</th>
              <th scope="col">サーバー</th>
              <th scope="col">URL / リダイレクト先</th>
              <th scope="col">操作</th>
            </tr>
          </thead>
          <tbody id="resultBody">
            <tr><td colspan="8" class="text-center text-muted p-5">スキャンを実行してください。</td></tr>
          </tbody>
        </table>
      </div>
      <!-- スマホ用: カードリスト -->
      <div class="card-list-responsive" id="resultCards" style="display: none;">
        <!-- JavaScriptで挿入 -->
      </div>
    </div>
  </div>
  <footer class="text-center text-muted small mt-4">
    <p>Quadrophenia - HTTP/HTTPS Service Scanner</p>
  </footer>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/notyf@3/notyf.min.js"></script>
<script>
document.addEventListener('DOMContentLoaded', () => {
  const $ = (s) => document.querySelector(s);

  const notyf = new Notyf({
    duration: 3000,
    position: { x: 'right', y: 'top' },
    dismissible: true
  });

  const THEMES = {
    light: "https://cdn.jsdelivr.net/npm/bootswatch@5.3.3/dist/materia/bootstrap.min.css",
    dark: "https://cdn.jsdelivr.net/npm/bootswatch@5.3.3/dist/cyborg/bootstrap.min.css"
  };
  const themeLink = $('#theme-link');
  const themeToggle = $('#themeToggle');
  const resultBody = $('#resultBody');
  const resultCards = $('#resultCards');
  const scanBtn = $('#scanBtn');
  const loadingOverlay = $('#loadingOverlay');
  // テーマ適用
  const setTheme = (theme) => {
    themeLink.href = THEMES[theme];
    document.documentElement.setAttribute('data-bs-theme', theme);
    themeToggle.checked = theme === 'dark';
    localStorage.setItem('theme', theme);
  };

  const savedTheme = localStorage.getItem('theme');
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  setTheme(savedTheme || (prefersDark ? 'dark' : 'light'));
  themeToggle.addEventListener('change', () => {
    setTheme(themeToggle.checked ? 'dark' : 'light');
  });

  const setLoading = (isLoading) => {
    scanBtn.disabled = isLoading;
    if (isLoading) {
      scanBtn.innerHTML = `<span class="spinner-border spinner-border-sm"></span> スキャン中...`;
      loadingOverlay.classList.remove('d-none');
    } else {
      scanBtn.innerHTML = `<i class="bi bi-search"></i> スキャン実行`;
      loadingOverlay.classList.add('d-none');
    }
  };

  const escapeHtml = (s) => String(s || '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const copyText = (text) => {
    navigator.clipboard.writeText(text).then(
      () => notyf.success('URLをコピーしました'),
      () => notyf.error('コピーに失敗しました')
    );
  };
  window.copyText = copyText;

  const buildQuery = () => {
    const params = {
      action: 'scan',
      hosts: $('#hostInput').value.trim(),
      ports: $('#portInput').value.trim(),
      range: $('#rangeInput').value.trim(),
      timeout: $('#timeoutInput').value.trim()
    };
    return new URLSearchParams(Object.entries(params).filter(([_, v]) => v)).toString();
  };

  // カード形式（スマホ表示用）
  const renderCards = (data) => {
    resultCards.innerHTML = '';
    if (!data.results || data.results.length === 0) {
      resultCards.innerHTML = '<div class="text-center text-muted p-5">オープンなHTTP/Sサービスは見つかりませんでした。</div>';
      return;
    }
    data.results.forEach(r => {
      const statusClass = r.status ? (r.status >= 200 && r.status < 400 ? 'success' : 'warning') : 'danger';
      const statusBadge = r.status ? `<span class="badge bg-${statusClass}">${r.status}</span>` : `<span class="badge bg-danger">ERROR</span>`;
      const title = r.title ? escapeHtml(r.title) : '<span class="text-muted small">（タイトルなし）</span>';
      const server = r.server ? escapeHtml(r.server) : '<span class="text-muted small">—</span>';
      const url = escapeHtml(r.url);
      const details = r.error ? `<span class="text-danger small">${escapeHtml(r.error_message)}</span>` : title;
      const locationInfo = r.location ? `<div class="small text-muted mt-1">→ ${escapeHtml(r.location)}</div>` : '';
      const card = document.createElement('div');
      card.className = 'card my-2 shadow-sm';
      card.innerHTML = `
        <div class="card-body py-3">
          <div class="d-flex align-items-center gap-2 mb-2">
            <span class="fw-bold">${escapeHtml(r.host)}</span>
            <span class="text-muted">:${r.port}</span>
            <span class="ms-auto">${statusBadge}</span>
          </div>
          <div class="mb-2 small">
            <span class="me-2">${r.scheme ? r.scheme.toUpperCase() : '—'}</span>
            <span class="me-2">${server}</span>
          </div>
          <div class="mb-2">${details}</div>
          <div>${!r.error ? `<a href="${url}" target="_blank" rel="noopener noreferrer">${url}</a>` : url}${locationInfo}</div>
          <div class="mt-3 d-flex gap-2">
            <a href="${url}" target="_blank" rel="noopener noreferrer" class="btn btn-outline-primary btn-sm${r.error ? ' disabled' : ''}"><i class="bi bi-box-arrow-up-right"></i></a>
            <button class="btn btn-outline-secondary btn-sm" onclick="copyText('${url}')"><i class="bi bi-clipboard"></i></button>
          </div>
        </div>`;
      card.dataset.search = [r.host, r.port, r.scheme, r.status, r.title, r.server, r.url, r.location].join(' ').toLowerCase();
      resultCards.appendChild(card);
    });
  };

  // テーブル（PC用）
  const renderRows = (data) => {
    resultBody.innerHTML = '';
    if (!data.results || data.results.length === 0) {
      resultBody.innerHTML = `<tr><td colspan="8" class="text-center text-muted p-5">オープンなHTTP/Sサービスは見つかりませんでした。</td></tr>`;
      return;
    }
    data.results.forEach(r => {
      const statusClass = r.status ? (r.status >= 200 && r.status < 400 ? 'text-success' : 'text-warning') : 'text-danger';
      const statusBadge = r.status ? `<span class="badge bg-${statusClass.replace('text-', '')}">${r.status}</span>` : `<span class="badge bg-danger">ERROR</span>`;
      const title = r.title ? escapeHtml(r.title) : '<span class="text-muted small">（タイトルなし）</span>';
      const server = r.server ? escapeHtml(r.server) : '<span class="text-muted small">—</span>';
      const url = escapeHtml(r.url);
      const details = r.error ? `<span class="text-danger small">${escapeHtml(r.error_message)}</span>` : title;
      const locationInfo = r.location ? `<div class="small text-muted mt-1">→ ${escapeHtml(r.location)}</div>` : '';
      const tr = document.createElement('tr');
      tr.dataset.search = [r.host, r.port, r.scheme, r.status, r.title, r.server, r.url, r.location].join(' ').toLowerCase();
      tr.innerHTML = `
        <td><strong>${escapeHtml(r.host)}</strong></td>
        <td>${r.port}</td>
        <td>${r.scheme ? r.scheme.toUpperCase() : '—'}</td>
        <td>${statusBadge}</td>
        <td>${details}</td>
        <td>${server}</td>
        <td>
          ${!r.error ? `<a href="${url}" target="_blank" rel="noopener noreferrer">${url}</a>` : url}
          ${locationInfo}
        </td>
        <td>
          <div class="btn-group btn-group-sm">
            <a href="${url}" target="_blank" rel="noopener noreferrer" class="btn btn-outline-primary ${r.error ? 'disabled' : ''}"><i class="bi bi-box-arrow-up-right"></i></a>
            <button class="btn btn-outline-secondary" onclick="copyText('${url}')"><i class="bi bi-clipboard"></i></button>
          </div>
        </td>
      `;
      resultBody.appendChild(tr);
    });
  };

  // メインスキャン
  const scan = async () => {
    setLoading(true);
    resultBody.innerHTML = '';
    resultCards.innerHTML = '';
    localStorage.removeItem('scan_results');
    try {
      const query = buildQuery();
      const response = await fetch(`${location.pathname}?${query}`, { headers: { 'Cache-Control': 'no-cache' } });
      if (!response.ok) throw new Error(`サーバーエラー: ${response.status}`);
      const data = await response.json();
      if (!data.ok) throw new Error(data.error || 'スキャンに失敗しました');
      renderRows(data);
      renderCards(data);
      localStorage.setItem('scan_results', JSON.stringify(data));
      $('#scanStatus').textContent = `完了 (${data.scan_time}秒) - ${data.found_services}件発見 / ${data.total_checks}件チェック`;
    } catch (err) {
      notyf.error(err.message);
      resultBody.innerHTML = `<tr><td colspan="8" class="text-center text-danger p-5">スキャン中にエラーが発生しました。<br><small>${escapeHtml(err.message)}</small></td></tr>`;
      resultCards.innerHTML = `<div class="text-center text-danger p-5">スキャン中にエラーが発生しました。<br><small>${escapeHtml(err.message)}</small></div>`;
      $('#scanStatus').textContent = 'エラー';
    } finally {
      setLoading(false);
    }
  };

  scanBtn.addEventListener('click', scan);

  // フィルタリング
  $('#filterInput').addEventListener('input', (e) => {
    const query = e.target.value.trim().toLowerCase();
    resultBody.querySelectorAll('tr').forEach(tr => {
      const searchData = tr.dataset.search || '';
      tr.style.display = searchData.includes(query) ? '' : 'none';
    });
    resultCards.querySelectorAll('.card').forEach(card => {
      const searchData = card.dataset.search || '';
      card.style.display = searchData.includes(query) ? '' : 'none';
    });
  });

  // キャッシュ反映
  const cachedData = localStorage.getItem('scan_results');
  if (cachedData) {
    try {
      const data = JSON.parse(cachedData);
      renderRows(data);
      renderCards(data);
    } catch {
      localStorage.removeItem('scan_results');
    }
  }
  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.has('hosts')) {
    $('#hostInput').value = urlParams.get('hosts') || '';
    $('#portInput').value = urlParams.get('ports') || '';
    $('#rangeInput').value = urlParams.get('range') || '';
    if (urlParams.has('timeout')) $('#timeoutInput').value = urlParams.get('timeout');
    if (urlParams.get('auto') === '1') {
      scan();
    }
  }
});
</script>
</body>
</html>
    HTML
  end
end


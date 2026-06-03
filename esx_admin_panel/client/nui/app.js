// ============================================
// ESX Admin Panel - NUI Application
// ============================================

const App = {
    permissions: {},
    players: [],
    bans: [],
    auditLogs: [],
    resources: [],
    config: {},
    refreshTimer: null,
};

// ============================================
// 初始化
// ============================================

window.addEventListener('message', function(event) {
    const data = event.data;

    switch (data.action) {
        case 'open':
            App.permissions = data.permissions || {};
            App.players = data.players || [];
            App.config = data.config || {};
            openPanel();
            renderPlayerList();
            updatePlayerCount();
            populateWeatherSelect();
            populateBanDurations();
            startAutoRefresh();
            break;
        case 'close':
            closePanel();
            break;
    }
});

// ============================================
// 面板控制
// ============================================

function openPanel() {
    document.getElementById('app').classList.remove('hidden');
}

function closePanel() {
    document.getElementById('app').classList.add('hidden');
    stopAutoRefresh();
    fetchNUI('closePanel', {});
}

function startAutoRefresh() {
    stopAutoRefresh();
    App.refreshTimer = setInterval(() => {
        refreshPlayers();
    }, 5000);
}

function stopAutoRefresh() {
    if (App.refreshTimer) {
        clearInterval(App.refreshTimer);
        App.refreshTimer = null;
    }
}

// ============================================
// NUI 通信
// ============================================

function fetchNUI(callback, data) {
    return fetch(`https://esx_admin_panel/${callback}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).then(resp => resp.json()).catch(err => console.error('NUI Error:', err));
}

// ============================================
// 标签切换
// ============================================

document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', function() {
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));

        this.classList.add('active');
        const tabName = this.dataset.tab;
        document.getElementById(`tab-${tabName}`).classList.add('active');

        // 切换标签时刷新数据
        switch (tabName) {
            case 'players': refreshPlayers(); break;
            case 'bans': refreshBans(); break;
            case 'audit': refreshAudit(); break;
            case 'resources': refreshResources(); break;
        }
    });
});

// ============================================
// 玩家列表
// ============================================

function renderPlayerList(filter = '') {
    const tbody = document.getElementById('player-list');
    const filtered = App.players.filter(p =>
        !filter || p.name.toLowerCase().includes(filter.toLowerCase()) ||
        String(p.id).includes(filter)
    );

    tbody.innerHTML = filtered.map(p => `
        <tr>
            <td>${p.id}</td>
            <td>${escapeHtml(p.name)}</td>
            <td>${escapeHtml(p.job)} - ${escapeHtml(p.jobGrade)}</td>
            <td>$${formatNumber(p.money)}</td>
            <td>$${formatNumber(p.bank)}</td>
            <td>${p.ping}ms</td>
            <td class="actions">
                <button class="btn btn-sm btn-primary" onclick="showPlayerDetail(${p.id})">详情</button>
                <button class="btn btn-sm btn-secondary" onclick="teleportToPlayer(${p.id})">传送</button>
                <button class="btn btn-sm btn-secondary" onclick="bringPlayer(${p.id})">召唤</button>
                <button class="btn btn-sm btn-danger" onclick="kickPlayer(${p.id})">踢出</button>
                <button class="btn btn-sm btn-danger" onclick="showBanModal(${p.id}, '${escapeHtml(p.name)}')">封禁</button>
            </td>
        </tr>
    `).join('');
}

function refreshPlayers() {
    fetchNUI('refreshPlayers', {}).then(players => {
        if (players) {
            App.players = players;
            const search = document.getElementById('player-search').value;
            renderPlayerList(search);
            updatePlayerCount();
        }
    });
}

function updatePlayerCount() {
    document.getElementById('player-count').textContent = `${App.players.length} 在线`;
}

// ============================================
// 玩家操作
// ============================================

function showPlayerDetail(targetId) {
    fetchNUI('getPlayerDetails', { targetId }).then(details => {
        if (!details) return;

        const body = document.getElementById('modal-player-body');
        const actions = document.getElementById('modal-player-actions');
        document.getElementById('modal-player-name').textContent = details.name;

        body.innerHTML = `
            <div class="detail-grid">
                <div class="detail-item">
                    <span class="detail-label">ID</span>
                    <span class="detail-value">${details.id}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">权限组</span>
                    <span class="detail-value">${details.group}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">职业</span>
                    <span class="detail-value">${details.job.label} - ${details.job.grade_label}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">Ping</span>
                    <span class="detail-value">${details.ping}ms</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">现金</span>
                    <span class="detail-value">$${formatNumber(details.money)}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">银行</span>
                    <span class="detail-value">$${formatNumber(details.bank)}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">黑钱</span>
                    <span class="detail-value">$${formatNumber(details.blackMoney)}</span>
                </div>
                <div class="detail-item">
                    <span class="detail-label">标识符</span>
                    <span class="detail-value" style="font-size:11px">${details.identifier}</span>
                </div>
            </div>
            ${details.inventory && details.inventory.length > 0 ? `
                <h4 style="margin-top:12px;font-size:13px;color:var(--accent)">背包</h4>
                <div style="display:flex;flex-wrap:wrap;gap:4px;margin-top:6px">
                    ${details.inventory.map(item => `<span class="status status-started">${item.label} x${item.count}</span>`).join('')}
                </div>
            ` : ''}
        `;

        actions.innerHTML = `
            <div class="detail-actions">
                <button class="btn btn-sm btn-secondary" onclick="teleportToPlayer(${details.id})">传送</button>
                <button class="btn btn-sm btn-secondary" onclick="bringPlayer(${details.id})">召唤</button>
                <button class="btn btn-sm btn-secondary" onclick="spectatePlayer(${details.id})">旁观</button>
                <button class="btn btn-sm btn-secondary" onclick="freezePlayer(${details.id}, true)">冻结</button>
                <button class="btn btn-sm btn-secondary" onclick="mutePlayer(${details.id}, true)">禁言</button>
                <button class="btn btn-sm btn-danger" onclick="kickPlayer(${details.id})">踢出</button>
                <button class="btn btn-sm btn-danger" onclick="showBanModal(${details.id}, '${escapeHtml(details.name)}')">封禁</button>
            </div>
        `;

        document.getElementById('player-modal').classList.remove('hidden');
    });
}

function kickPlayer(targetId) {
    showConfirm('踢出玩家', '确定要踢出该玩家吗？', () => {
        fetchNUI('kickPlayer', { targetId, reason: '管理员踢出' });
        refreshPlayers();
    });
}

function freezePlayer(targetId, toggle) {
    fetchNUI('freezePlayer', { targetId, toggle });
}

function teleportToPlayer(targetId) {
    fetchNUI('teleportToPlayer', { targetId });
}

function bringPlayer(targetId) {
    fetchNUI('bringPlayer', { targetId });
}

function mutePlayer(targetId, toggle) {
    fetchNUI('mutePlayer', { targetId, toggle });
}

function spectatePlayer(targetId) {
    fetchNUI('spectatePlayer', { targetId });
}

// ============================================
// 封禁系统
// ============================================

function populateBanDurations() {
    const select = document.getElementById('ban-duration');
    if (!App.config.banDurations) return;

    select.innerHTML = App.config.banDurations.map(d =>
        `<option value="${d.value}">${d.label}</option>`
    ).join('');
}

function showBanModal(targetId, playerName) {
    document.getElementById('ban-target-id').value = targetId;
    document.getElementById('ban-reason').value = '';
    document.getElementById('ban-modal').classList.remove('hidden');
}

function renderBanList() {
    const tbody = document.getElementById('ban-list');
    tbody.innerHTML = App.bans.map(b => `
        <tr>
            <td>${b.id}</td>
            <td>${escapeHtml(b.player_name)}</td>
            <td style="font-size:11px">${escapeHtml(b.identifier)}</td>
            <td>${escapeHtml(b.reason)}</td>
            <td>${escapeHtml(b.banned_by)}</td>
            <td>${b.expire_date || '永久'}</td>
            <td>
                <button class="btn btn-sm btn-success" onclick="unbanPlayer(${b.id})">解封</button>
            </td>
        </tr>
    `).join('');
}

function refreshBans() {
    fetchNUI('getBans', { filters: {} }).then(bans => {
        if (bans) {
            App.bans = bans;
            renderBanList();
        }
    });
}

function unbanPlayer(banId) {
    showConfirm('解封确认', '确定要解封该玩家吗？', () => {
        fetchNUI('unbanPlayer', { banId });
        refreshBans();
    });
}

// ============================================
// 审计日志
// ============================================

function renderAuditList() {
    const tbody = document.getElementById('audit-list');
    tbody.innerHTML = App.auditLogs.map(log => `
        <tr>
            <td style="font-size:11px">${formatDate(log.created_at)}</td>
            <td>${escapeHtml(log.admin_name)}</td>
            <td><span class="status status-started">${escapeHtml(log.action)}</span></td>
            <td style="font-size:12px">${escapeHtml(log.details)}</td>
            <td>${log.target_player ? escapeHtml(log.target_player) : '-'}</td>
        </tr>
    `).join('');
}

function refreshAudit() {
    fetchNUI('getAuditLogs', { filters: {} }).then(logs => {
        if (logs) {
            App.auditLogs = logs;
            renderAuditList();
        }
    });
}

// ============================================
// 世界控制
// ============================================

function populateWeatherSelect() {
    const select = document.getElementById('weather-select');
    if (!App.config.weatherTypes) return;

    select.innerHTML = '<option value="">选择天气...</option>' +
        App.config.weatherTypes.map(w =>
            `<option value="${w}">${w}</option>`
        ).join('');
}

// ============================================
// 资源监控
// ============================================

function renderResourceList(filter = '') {
    const tbody = document.getElementById('resource-list');
    const filtered = App.resources.filter(r =>
        !filter || r.name.toLowerCase().includes(filter.toLowerCase())
    );

    tbody.innerHTML = filtered.map(r => `
        <tr>
            <td>${escapeHtml(r.name)}</td>
            <td><span class="status status-${r.state}">${r.state}</span></td>
            <td class="actions">
                ${r.state === 'started' ? `
                    <button class="btn btn-sm btn-secondary" onclick="manageResource('restart', '${escapeHtml(r.name)}')">重启</button>
                    <button class="btn btn-sm btn-danger" onclick="manageResource('stop', '${escapeHtml(r.name)}')">停止</button>
                ` : `
                    <button class="btn btn-sm btn-success" onclick="manageResource('start', '${escapeHtml(r.name)}')">启动</button>
                `}
            </td>
        </tr>
    `).join('');
}

function refreshResources() {
    fetchNUI('getResourceStatus', {}).then(status => {
        if (status && status.resources) {
            App.resources = status.resources;
            const search = document.getElementById('resource-search').value;
            renderResourceList(search);
        }
    });
}

function manageResource(action, resourceName) {
    showConfirm('资源管理', `确定要${action === 'start' ? '启动' : action === 'stop' ? '停止' : '重启'}资源 ${resourceName} 吗？`, () => {
        fetchNUI('manageResource', { action, resource: resourceName });
        setTimeout(refreshResources, 1000);
    });
}

// ============================================
// 确认弹窗
// ============================================

let confirmCallback = null;

function showConfirm(title, message, callback) {
    document.getElementById('confirm-title').textContent = title;
    document.getElementById('confirm-message').textContent = message;
    confirmCallback = callback;
    document.getElementById('confirm-modal').classList.remove('hidden');
}

// ============================================
// 事件绑定
// ============================================

document.addEventListener('DOMContentLoaded', function() {
    // 关闭按钮
    document.getElementById('btn-close').addEventListener('click', closePanel);

    // 关闭弹窗
    document.querySelectorAll('.modal-close').forEach(btn => {
        btn.addEventListener('click', function() {
            this.closest('.modal').classList.add('hidden');
        });
    });

    // 弹窗遮罩关闭
    document.querySelectorAll('.modal-overlay').forEach(overlay => {
        overlay.addEventListener('click', function() {
            this.closest('.modal').classList.add('hidden');
        });
    });

    // 确认操作
    document.getElementById('btn-confirm-action').addEventListener('click', function() {
        if (confirmCallback) confirmCallback();
        document.getElementById('confirm-modal').classList.add('hidden');
        confirmCallback = null;
    });

    // 玩家搜索
    document.getElementById('player-search').addEventListener('input', function() {
        renderPlayerList(this.value);
    });

    // 刷新按钮
    document.getElementById('btn-refresh-players').addEventListener('click', refreshPlayers);
    document.getElementById('btn-refresh-bans').addEventListener('click', refreshBans);
    document.getElementById('btn-refresh-audit').addEventListener('click', refreshAudit);
    document.getElementById('btn-refresh-resources').addEventListener('click', refreshResources);

    // 封禁确认
    document.getElementById('btn-confirm-ban').addEventListener('click', function() {
        const targetId = parseInt(document.getElementById('ban-target-id').value);
        const duration = parseInt(document.getElementById('ban-duration').value);
        const reason = document.getElementById('ban-reason').value.trim();

        if (!reason) {
            document.getElementById('ban-reason').style.borderColor = 'var(--danger)';
            return;
        }

        fetchNUI('banPlayer', { targetId, duration, reason });
        document.getElementById('ban-modal').classList.add('hidden');
        refreshPlayers();
    });

    // 天气
    document.getElementById('btn-set-weather').addEventListener('click', function() {
        const weather = document.getElementById('weather-select').value;
        if (weather) fetchNUI('setWeather', { weatherType: weather });
    });

    // 时间
    document.getElementById('btn-set-time').addEventListener('click', function() {
        const hour = parseInt(document.getElementById('time-hour').value) || 12;
        const minute = parseInt(document.getElementById('time-minute').value) || 0;
        fetchNUI('setTime', { hour, minute });
    });

    // 穿墙
    document.getElementById('btn-noclip').addEventListener('click', function() {
        fetchNUI('toggleNoclip', {});
    });

    // 无敌
    document.getElementById('btn-godmode').addEventListener('click', function() {
        fetchNUI('toggleGodmode', {});
    });

    // 公告
    document.getElementById('btn-announce').addEventListener('click', function() {
        const message = document.getElementById('announce-message').value.trim();
        if (message) {
            fetchNUI('announce', { message });
            document.getElementById('announce-message').value = '';
        }
    });

    // 生成车辆
    document.getElementById('btn-spawn-vehicle').addEventListener('click', function() {
        const model = document.getElementById('vehicle-model').value.trim();
        if (model) {
            fetchNUI('spawnVehicle', { model });
            document.getElementById('vehicle-model').value = '';
        }
    });

    // 删除车辆
    document.getElementById('btn-delete-vehicle').addEventListener('click', function() {
        fetchNUI('deleteVehicle', {});
    });

    // 资源搜索
    document.getElementById('resource-search').addEventListener('input', function() {
        renderResourceList(this.value);
    });

    // 封禁搜索
    document.getElementById('ban-search').addEventListener('input', function() {
        const search = this.value;
        fetchNUI('getBans', { filters: { search } }).then(bans => {
            if (bans) {
                App.bans = bans;
                renderBanList();
            }
        });
    });

    // ESC 关闭
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            const modals = document.querySelectorAll('.modal:not(.hidden)');
            if (modals.length > 0) {
                modals[modals.length - 1].classList.add('hidden');
            } else if (!document.getElementById('app').classList.contains('hidden')) {
                closePanel();
            }
        }
    });
});

// ============================================
// 工具函数
// ============================================

function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatNumber(num) {
    if (num === undefined || num === null) return '0';
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
}

function formatDate(dateStr) {
    if (!dateStr) return '-';
    const d = new Date(dateStr);
    return d.toLocaleString('zh-CN', {
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
    });
}

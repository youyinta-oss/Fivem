let config = null;

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openUI') {
        config = data.config;
        document.getElementById('app').classList.remove('hidden');
        loadPlayers();
        loadRedPackets();
        loadHistory();
    }
});

document.getElementById('closeBtn').addEventListener('click', function() {
    closeUI();
});

function closeUI() {
    document.getElementById('app').classList.add('hidden');
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    });
}

document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', function() {
        const tabName = this.dataset.tab;
        document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
        document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
        this.classList.add('active');
        document.getElementById(tabName).classList.add('active');
    });
});

document.getElementById('targetType').addEventListener('change', function() {
    document.getElementById('playerSelectGroup').classList.toggle('hidden', this.value === 'all');
});

function loadPlayers() {
    fetch(`https://${GetParentResourceName()}/getPlayers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(players => {
        const select = document.getElementById('playerSelect');
        select.innerHTML = players.map(p => `<option value="${p.identifier}" data-name="${p.name}">${p.name}</option>`).join('');
    });
}

function loadRedPackets() {
    fetch(`https://${GetParentResourceName()}/getActiveRedPackets`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(packets => {
        const container = document.getElementById('redpacketList');
        if (packets.length === 0) {
            container.innerHTML = '<p class="empty">暂无红包</p>';
        } else {
            container.innerHTML = packets.map(p => `
                <div class="list-item redpacket-item">
                    <div class="redpacket-info">
                        <h4>🧧 ${p.creator_name} 的红包</h4>
                        <p>类型: ${getPacketTypeName(p.packet_type)}</p>
                        <p>模式: ${getModeName(p.mode)}</p>
                        <p>已抢: ${p.opened_count}/${p.count}</p>
                        <p>剩余: ${p.remain_amount}</p>
                    </div>
                    <button class="btn btn-redpacket" onclick="openRedPacket(${p.id})">抢</button>
                </div>
            `).join('');
        }
    });
}

function loadHistory() {
    fetch(`https://${GetParentResourceName()}/getPlayerHistory`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ limit: 50 })
    }).then(resp => resp.json()).then(history => {
        const container = document.getElementById('historyList');
        if (history.length === 0) {
            container.innerHTML = '<p class="empty">暂无记录</p>';
        } else {
            container.innerHTML = history.map(h => `
                <div class="list-item">
                    <h4>🎁 来自 ${h.sender_name}</h4>
                    <p>类型: ${getGiftTypeName(h.gift_type)}</p>
                    <p>时间: ${new Date(h.created_at)}</p>
                    ${h.message ? `<p>留言: ${h.message}</p>` : ''}
                </div>
            `).join('');
        }
    });
}

document.getElementById('sendGiftBtn').addEventListener('click', function() {
    const targetType = document.getElementById('targetType').value;
    const giftType = document.getElementById('giftType').value;
    let giftData = {};
    let targetId = null;
    let targetName = null;
    
    if (targetType === 'player') {
        const select = document.getElementById('playerSelect');
        targetId = select.value;
        targetName = select.options[select.selectedIndex].dataset.name;
    }
    
    if (giftType === 'money') {
        giftData = {
            account: document.getElementById('moneyType').value,
            amount: parseInt(document.getElementById('moneyAmount').value)
        };
    }
    
    fetch(`https://${GetParentResourceName()}/sendGift`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({
            targetType: targetType,
            targetId: targetId,
            targetName: targetName,
            giftType: giftType,
            giftData: giftData,
            message: document.getElementById('giftMessage').value
        })
    }).then(resp => resp.json()).then(result => {
        showNotification(result.msg, result.success ? 'success' : 'error');
        if (result.success) {
            loadHistory();
        }
    });
});

document.getElementById('createRedPacketBtn').addEventListener('click', function() {
    const packetType = document.getElementById('packetType').value;
    let packetData = {};
    let totalAmount = 0;
    
    if (packetType === 'money') {
        packetData = {
            account: document.getElementById('packetMoneyType').value
        };
        totalAmount = parseInt(document.getElementById('packetTotalMoney').value);
    }
    
    fetch(`https://${GetParentResourceName()}/createRedPacket`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({
            packetType: packetType,
            packetData: packetData,
            mode: document.getElementById('packetMode').value,
            totalAmount: totalAmount,
            count: parseInt(document.getElementById('packetCount').value),
            timeout: parseInt(document.getElementById('packetTimeout').value) || null
        })
    }).then(resp => resp.json()).then(result => {
        showNotification(result.msg, result.success ? 'success' : 'error');
        if (result.success) {
            loadRedPackets();
        }
    });
});

function openRedPacket(packetId) {
    fetch(`https://${GetParentResourceName()}/openRedPacket`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({ packetId: packetId })
    }).then(resp => resp.json()).then(result => {
        showNotification(result.msg, result.success ? 'success' : 'error');
        if (result.success) {
            loadRedPackets();
        }
    });
}

function getGiftTypeName(type) {
    const names = {
        money: '货币'
    };
    return names[type] || type;
}

function getPacketTypeName(type) {
    return getGiftTypeName(type);
}

function getModeName(mode) {
    const names = {
        random: '随机分配',
        equal: '平均分配',
        first_come: '先到先得'
    };
    return names[mode] || mode;
}

function showNotification(message, type) {
    const notification = document.getElementById('notification');
    notification.textContent = message;
    notification.className = 'notification ' + type;
    setTimeout(() => {
        notification.classList.add('hidden');
    }, 3000);
}

let config = null;

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openUI') {
        config = data.config;
        document.getElementById('app').classList.remove('hidden');
        initWeaponSelect();
        initVehicleSelect();
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

document.getElementById('giftType').addEventListener('change', function() {
    document.querySelectorAll('.gift-settings').forEach(el => el.classList.add('hidden'));
    document.getElementById(this.value + 'Settings').classList.remove('hidden');
});

document.getElementById('packetType').addEventListener('change', function() {
    document.querySelectorAll('.packet-settings').forEach(el => el.classList.add('hidden'));
    document.getElementById('packet' + this.value.charAt(0).toUpperCase() + this.value.slice(1) + 'Settings').classList.remove('hidden');
});

function initWeaponSelect() {
    const selects = ['weaponSelect', 'packetWeaponSelect'];
    selects.forEach(id => {
        const select = document.getElementById(id);
        if (select && config && config.Weapons) {
            select.innerHTML = config.Weapons.map(w => `<option value="${w}">${w}</option>').join('');
        }
    });
}

function initVehicleSelect() {
    const selects = ['vehicleSelect', 'packetVehicleSelect'];
    selects.forEach(id => {
        const select = document.getElementById(id);
        if (select && config && config.Vehicles) {
            select.innerHTML = config.Vehicles.map(v => `<option value="${v}">${v}</option>').join('');
        }
    });
}

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
    
    if (giftType === 'item') {
        giftData = {
            item: document.getElementById('itemName').value,
            amount: parseInt(document.getElementById('itemAmount').value)
        };
    } else if (giftType === 'money') {
        giftData = {
            account: document.getElementById('moneyType').value,
            amount: parseInt(document.getElementById('moneyAmount').value)
        };
    } else if (giftType === 'weapon') {
        giftData = {
            weapon: document.getElementById('weaponSelect').value,
            ammo: parseInt(document.getElementById('weaponAmmo').value)
        };
    } else if (giftType === 'vehicle') {
        giftData = {
            vehicle: document.getElementById('vehicleSelect').value
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
    
    if (packetType === 'item') {
        packetData = {
            item: document.getElementById('packetItemName').value
        };
        totalAmount = parseInt(document.getElementById('packetTotalAmount').value);
    } else if (packetType === 'money') {
        packetData = {
            account: document.getElementById('packetMoneyType').value,
            amount: parseInt(document.getElementById('packetTotalMoney').value)
        };
        totalAmount = parseInt(document.getElementById('packetTotalMoney').value);
    } else if (packetType === 'weapon') {
        packetData = {
            weapon: document.getElementById('packetWeaponSelect').value,
            ammo: parseInt(document.getElementById('packetWeaponAmmo').value)
        };
        totalAmount = parseInt(document.getElementById('packetCount').value);
    } else if (packetType === 'vehicle') {
        packetData = {
            vehicle: document.getElementById('packetVehicleSelect').value
        };
        totalAmount = parseInt(document.getElementById('packetCount').value);
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
        item: '物品',
        money: '货币',
        weapon: '武器',
        vehicle: '车辆'
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

let config = null;

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openAdminUI') {
        config = data.config;
        document.getElementById('app').classList.remove('hidden');
        initWeaponSelect();
        initVehicleSelect();
        loadPlayers();
        loadAllGifts();
        loadAllRedPackets();
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

document.getElementById('adminTargetType').addEventListener('change', function() {
    document.getElementById('adminPlayerSelectGroup').classList.toggle('hidden', this.value === 'all');
});

document.getElementById('adminGiftType').addEventListener('change', function() {
    document.querySelectorAll('.gift-settings').forEach(el => el.classList.add('hidden'));
    document.getElementById('admin' + this.value.charAt(0).toUpperCase() + this.value.slice(1) + 'Settings').classList.remove('hidden');
});

document.getElementById('adminPacketType').addEventListener('change', function() {
    document.querySelectorAll('.packet-settings').forEach(el => el.classList.add('hidden'));
    document.getElementById('adminPacket' + this.value.charAt(0).toUpperCase() + this.value.slice(1) + 'Settings').classList.remove('hidden');
});

function initWeaponSelect() {
    const selects = ['adminWeaponSelect', 'adminPacketWeaponSelect'];
    selects.forEach(id => {
        const select = document.getElementById(id);
        if (select && config && config.Weapons) {
            select.innerHTML = config.Weapons.map(w => `<option value="${w}">${w}</option>').join('');
        }
    });
}

function initVehicleSelect() {
    const selects = ['adminVehicleSelect', 'adminPacketVehicleSelect'];
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
        const select = document.getElementById('adminPlayerSelect');
        select.innerHTML = players.map(p => `<option value="${p.identifier}" data-name="${p.name}">${p.name}</option>`).join('');
    });
}

function loadAllGifts() {
    fetch(`https://${GetParentResourceName()}/getAllGifts`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(gifts => {
        const container = document.getElementById('allGiftsList');
        if (gifts.length === 0) {
            container.innerHTML = '<p class="empty">暂无记录</p>';
        } else {
            container.innerHTML = gifts.map(g => `
                <div class="list-item">
                    <h4>🎁 ${g.sender_name} → ${g.is_global ? '全服' : g.receiver_name}</h4>
                    <p>类型: ${getGiftTypeName(g.gift_type)}</p>
                    <p>时间: ${new Date(g.created_at)}</p>
                    ${g.message ? `<p>留言: ${g.message}</p>` : ''}
                </div>
            `).join('');
        }
    });
}

function loadAllRedPackets() {
    fetch(`https://${GetParentResourceName()}/getAllRedPackets`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(packets => {
        const container = document.getElementById('allRedPacketsList');
        if (packets.length === 0) {
            container.innerHTML = '<p class="empty">暂无记录</p>';
        } else {
            container.innerHTML = packets.map(p => `
                <div class="list-item redpacket-item">
                    <div class="redpacket-info">
                        <h4>🧧 ${p.creator_name} 的红包</h4>
                        <p>类型: ${getGiftTypeName(p.packet_type)}</p>
                        <p>模式: ${getModeName(p.mode)}</p>
                        <p>已抢: ${p.opened_count}/${p.count}</p>
                        <p>时间: ${new Date(p.created_at)}</p>
                    </div>
                </div>
            `).join('');
        }
    });
}

document.getElementById('adminSendGiftBtn').addEventListener('click', function() {
    const targetType = document.getElementById('adminTargetType').value;
    const giftType = document.getElementById('adminGiftType').value;
    let giftData = {};
    let targetId = null;
    let targetName = null;
    
    if (targetType === 'player') {
        const select = document.getElementById('adminPlayerSelect');
        targetId = select.value;
        targetName = select.options[select.selectedIndex].dataset.name;
    }
    
    if (giftType === 'item') {
        giftData = {
            item: document.getElementById('adminItemName').value,
            amount: parseInt(document.getElementById('adminItemAmount').value)
        };
    } else if (giftType === 'money') {
        giftData = {
            account: document.getElementById('adminMoneyType').value,
            amount: parseInt(document.getElementById('adminMoneyAmount').value)
        };
    } else if (giftType === 'weapon') {
        giftData = {
            weapon: document.getElementById('adminWeaponSelect').value,
            ammo: parseInt(document.getElementById('adminWeaponAmmo').value)
        };
    } else if (giftType === 'vehicle') {
        giftData = {
            vehicle: document.getElementById('adminVehicleSelect').value
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
            message: document.getElementById('adminGiftMessage').value
        })
    }).then(resp => resp.json()).then(result => {
        showNotification(result.msg, result.success ? 'success' : 'error');
        if (result.success) {
            loadAllGifts();
        }
    });
});

document.getElementById('adminCreateRedPacketBtn').addEventListener('click', function() {
    const packetType = document.getElementById('adminPacketType').value;
    let packetData = {};
    let totalAmount = 0;
    
    if (packetType === 'item') {
        packetData = {
            item: document.getElementById('adminPacketItemName').value
        };
        totalAmount = parseInt(document.getElementById('adminPacketTotalAmount').value);
    } else if (packetType === 'money') {
        packetData = {
            account: document.getElementById('adminPacketMoneyType').value,
            amount: parseInt(document.getElementById('adminPacketTotalMoney').value)
        };
        totalAmount = parseInt(document.getElementById('adminPacketTotalMoney').value);
    } else if (packetType === 'weapon') {
        packetData = {
            weapon: document.getElementById('adminPacketWeaponSelect').value,
            ammo: parseInt(document.getElementById('adminPacketWeaponAmmo').value)
        };
        totalAmount = parseInt(document.getElementById('adminPacketCount').value);
    } else if (packetType === 'vehicle') {
        packetData = {
            vehicle: document.getElementById('adminPacketVehicleSelect').value
        };
        totalAmount = parseInt(document.getElementById('adminPacketCount').value);
    }
    
    fetch(`https://${GetParentResourceName()}/createRedPacket`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify({
            packetType: packetType,
            packetData: packetData,
            mode: document.getElementById('adminPacketMode').value,
            totalAmount: totalAmount,
            count: parseInt(document.getElementById('adminPacketCount').value),
            timeout: parseInt(document.getElementById('adminPacketTimeout').value) || null
        })
    }).then(resp => resp.json()).then(result => {
        showNotification(result.msg, result.success ? 'success' : 'error');
        if (result.success) {
            loadAllRedPackets();
        }
    });
});

function getGiftTypeName(type) {
    const names = {
        item: '物品',
        money: '货币',
        weapon: '武器',
        vehicle: '车辆'
    };
    return names[type] || type;
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

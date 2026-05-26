let config = null;

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'openAdminUI') {
        config = data.config;
        document.getElementById('app').classList.remove('hidden');
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
                        <p>剩余: ${p.remain_amount}</p>
                        <p>时间: ${new Date(p.created_at)}</p>
                        <p>状态: ${p.is_active ? '进行中' : '已结束'}</p>
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
    
    if (giftType === 'money') {
        giftData = {
            account: document.getElementById('adminMoneyType').value,
            amount: parseInt(document.getElementById('adminMoneyAmount').value)
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
    
    if (packetType === 'money') {
        packetData = {
            account: document.getElementById('adminPacketMoneyType').value
        };
        totalAmount = parseInt(document.getElementById('adminPacketTotalMoney').value);
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
        money: '货币'
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

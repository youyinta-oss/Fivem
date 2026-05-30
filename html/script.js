let currentTunes = [];
let activeTuneId = null;
let vehicleHash = null;

document.addEventListener('DOMContentLoaded', function() {
    const closeBtn = document.getElementById('closeBtn');
    const saveBtn = document.getElementById('saveBtn');
    const resetBtn = document.getElementById('resetBtn');
    const deleteTuneBtn = document.getElementById('deleteTuneBtn');
    const saveModal = document.getElementById('saveModal');
    const confirmSaveBtn = document.getElementById('confirmSaveBtn');
    const modalClose = document.querySelector('.close');
    const tuneNameInput = document.getElementById('tuneNameInput');
    
    closeBtn.addEventListener('click', closeUI);
    saveBtn.addEventListener('click', openSaveModal);
    resetBtn.addEventListener('click', resetTune);
    deleteTuneBtn.addEventListener('click', deleteTune);
    confirmSaveBtn.addEventListener('click', saveTune);
    modalClose.addEventListener('click', closeModal);
    
    const sliders = [
        'mass', 'acceleration', 'brakeForce', 'brakeBiasFront',
        'steeringLock', 'tractionCurveMax', 'suspensionForce',
        'antiRollBarForce', 'initialDragCoeff', 'driveBiasFront'
    ];
    
    sliders.forEach(sliderId => {
        const slider = document.getElementById(sliderId);
        slider.addEventListener('input', function() {
            updateValueDisplay(sliderId);
            applyTune();
        });
    });
    
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        switch(data.type) {
            case 'open':
                vehicleHash = data.vehicleModel;
                document.querySelector('.container').style.display = 'flex';
                saveModal.style.display = 'none';
                break;
            case 'close':
                document.querySelector('.container').style.display = 'none';
                break;
            case 'loadTunes':
                currentTunes = data.tunes;
                renderTunesList();
                break;
        }
    });
});

function closeUI() {
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

function updateValueDisplay(sliderId) {
    const slider = document.getElementById(sliderId);
    const valueSpan = document.getElementById(sliderId + 'Value');
    valueSpan.textContent = slider.value;
}

function applyTune() {
    const tune = {
        mass: parseFloat(document.getElementById('mass').value),
        acceleration: parseFloat(document.getElementById('acceleration').value),
        brakeForce: parseFloat(document.getElementById('brakeForce').value),
        brakeBiasFront: parseFloat(document.getElementById('brakeBiasFront').value),
        steeringLock: parseFloat(document.getElementById('steeringLock').value),
        tractionCurveMax: parseFloat(document.getElementById('tractionCurveMax').value),
        suspensionForce: parseFloat(document.getElementById('suspensionForce').value),
        antiRollBarForce: parseFloat(document.getElementById('antiRollBarForce').value),
        initialDragCoeff: parseFloat(document.getElementById('initialDragCoeff').value),
        driveBiasFront: parseFloat(document.getElementById('driveBiasFront').value)
    };
    
    fetch(`https://${GetParentResourceName()}/applyTune`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ tune: tune })
    });
}

function resetTune() {
    fetch(`https://${GetParentResourceName()}/resetTune`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

function openSaveModal() {
    document.getElementById('saveModal').style.display = 'block';
    document.getElementById('tuneNameInput').value = '';
    document.getElementById('tuneNameInput').focus();
}

function closeModal() {
    document.getElementById('saveModal').style.display = 'none';
}

function saveTune() {
    const tuneName = document.getElementById('tuneNameInput').value.trim();
    
    if (!tuneName) {
        alert('请输入方案名称');
        return;
    }
    
    const tune = {
        mass: parseFloat(document.getElementById('mass').value),
        acceleration: parseFloat(document.getElementById('acceleration').value),
        brakeForce: parseFloat(document.getElementById('brakeForce').value),
        brakeBiasFront: parseFloat(document.getElementById('brakeBiasFront').value),
        steeringLock: parseFloat(document.getElementById('steeringLock').value),
        tractionCurveMax: parseFloat(document.getElementById('tractionCurveMax').value),
        suspensionForce: parseFloat(document.getElementById('suspensionForce').value),
        antiRollBarForce: parseFloat(document.getElementById('antiRollBarForce').value),
        initialDragCoeff: parseFloat(document.getElementById('initialDragCoeff').value),
        driveBiasFront: parseFloat(document.getElementById('driveBiasFront').value)
    };
    
    fetch(`https://${GetParentResourceName()}/saveTune`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            name: tuneName,
            vehicleHash: vehicleHash,
            tune: tune
        })
    });
    
    closeModal();
}

function deleteTune() {
    if (!activeTuneId) {
        alert('请先选择要删除的方案');
        return;
    }
    
    if (confirm('确定要删除此调车方案吗？')) {
        fetch(`https://${GetParentResourceName()}/deleteTune`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                id: activeTuneId
            })
        });
        
        activeTuneId = null;
        renderTunesList();
    }
}

function renderTunesList() {
    const listContainer = document.getElementById('tunesList');
    listContainer.innerHTML = '';
    
    currentTunes.forEach(tune => {
        const item = document.createElement('div');
        item.className = 'tune-item';
        item.innerHTML = `<span>${tune.name}</span>`;
        item.addEventListener('click', function() {
            selectTune(tune);
        });
        listContainer.appendChild(item);
    });
}

function selectTune(tune) {
    activeTuneId = tune.id;
    
    document.querySelectorAll('.tune-item').forEach((item, index) => {
        item.classList.remove('active');
        if (currentTunes[index].id === tune.id) {
            item.classList.add('active');
        }
    });
    
    loadTuneToSliders(tune.data);
    applyTune();
}

function loadTuneToSliders(tuneData) {
    if (tuneData.mass) {
        document.getElementById('mass').value = tuneData.mass;
        document.getElementById('massValue').textContent = tuneData.mass;
    }
    
    if (tuneData.acceleration) {
        document.getElementById('acceleration').value = tuneData.acceleration;
        document.getElementById('accelerationValue').textContent = tuneData.acceleration;
    }
    
    if (tuneData.brakeForce) {
        document.getElementById('brakeForce').value = tuneData.brakeForce;
        document.getElementById('brakeForceValue').textContent = tuneData.brakeForce;
    }
    
    if (tuneData.brakeBiasFront) {
        document.getElementById('brakeBiasFront').value = tuneData.brakeBiasFront;
        document.getElementById('brakeBiasFrontValue').textContent = tuneData.brakeBiasFront;
    }
    
    if (tuneData.steeringLock) {
        document.getElementById('steeringLock').value = tuneData.steeringLock;
        document.getElementById('steeringLockValue').textContent = tuneData.steeringLock;
    }
    
    if (tuneData.tractionCurveMax) {
        document.getElementById('tractionCurveMax').value = tuneData.tractionCurveMax;
        document.getElementById('tractionCurveMaxValue').textContent = tuneData.tractionCurveMax;
    }
    
    if (tuneData.suspensionForce) {
        document.getElementById('suspensionForce').value = tuneData.suspensionForce;
        document.getElementById('suspensionForceValue').textContent = tuneData.suspensionForce;
    }
    
    if (tuneData.antiRollBarForce) {
        document.getElementById('antiRollBarForce').value = tuneData.antiRollBarForce;
        document.getElementById('antiRollBarForceValue').textContent = tuneData.antiRollBarForce;
    }
    
    if (tuneData.initialDragCoeff) {
        document.getElementById('initialDragCoeff').value = tuneData.initialDragCoeff;
        document.getElementById('initialDragCoeffValue').textContent = tuneData.initialDragCoeff;
    }
    
    if (tuneData.driveBiasFront) {
        document.getElementById('driveBiasFront').value = tuneData.driveBiasFront;
        document.getElementById('driveBiasFrontValue').textContent = tuneData.driveBiasFront;
    }
}

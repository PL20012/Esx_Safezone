

let centerTimeout   = null;
let isInSafeZone    = false;
let currentZoneName = "";

function playSound(soundFile) {
    try {
        const audio = new Audio('./sound/' + soundFile);
        audio.volume = 0.4;
        audio.play().catch(e => console.log('Sound error:', e));
    } catch (e) {
        console.log('Audio error:', e);
    }
}


function setTextContent(element, text, highlightWord) {
    if (!element) return;

    let html = '';
    if (highlightWord && text.includes(highlightWord)) {
        const parts = text.split(highlightWord);
        parts.forEach((part, idx) => {
            html += part;
            if (idx < parts.length - 1) {
                html += `<span class="highlight">${highlightWord}</span>`;
            }
        });
    } else {
        html = text;
    }
    element.innerHTML = html;
}

function setSubTextContent(element, text) {
    if (!element) return;
    element.innerHTML = text;
}


function updateZoneName(name) {
    currentZoneName = name;

    const centerEl = document.getElementById('zone-name-center');
    const subEl    = document.getElementById('sub-text-center');
    const topEl    = document.getElementById('zone-name-top');

    setTextContent(centerEl, 'เข้าสู่ ' + name, name);
    setSubTextContent(subEl, 'คุณอยู่ในเขตปลอดภัย');
    setTextContent(topEl, name + ' ปลอดภัย', name);
}


function showCenterUI(zoneName, soundFile) {
    const centerEl = document.getElementById('center-ui');
    const topEl    = document.getElementById('top-ui');
    if (!centerEl) return;

    updateZoneName(zoneName);

    if (topEl) {
        topEl.classList.remove('show');
        topEl.classList.add('hide');
    }

    if (centerTimeout) clearTimeout(centerTimeout);

    centerEl.classList.remove('show', 'hide');
    centerEl.offsetHeight; // force reflow

    if (soundFile) playSound(soundFile);

    centerEl.classList.add('show');

    centerTimeout = setTimeout(() => {
        centerEl.classList.add('hide');
        centerEl.classList.remove('show');

        setTimeout(() => {
            if (isInSafeZone) {
                topEl.classList.remove('hide');
                topEl.classList.add('show');
            }
        }, 800);
    }, 5000);
}


function resetUI() {
    const centerEl = document.getElementById('center-ui');
    const topEl    = document.getElementById('top-ui');

    if (topEl) {
        topEl.classList.remove('show');
        topEl.classList.add('hide');
    }
    if (centerEl) {
        centerEl.classList.remove('show');
        centerEl.classList.add('hide');
    }
    if (centerTimeout) clearTimeout(centerTimeout);
    isInSafeZone = false;
}


window.addEventListener('message', function (event) {
    const data = event.data;
    if (!data) return;

    if (data.type === 'safezone') {
        if (data.status === true) {
            isInSafeZone = true;
            showCenterUI(data.zoneName, data.file);
        } else {
            isInSafeZone = false;
            resetUI();
        }
    }
});


resetUI();
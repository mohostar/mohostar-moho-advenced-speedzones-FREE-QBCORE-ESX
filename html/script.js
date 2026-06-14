
let zonesData = {};
let isDebug = false;
let currentLang = 'hu';
let editingZoneId = null;

const translations = {
    hu: {
        dashboard: "Áttekintés", create_zone: "Zóna Létrehozása", manage_zones: "Zónák Kezelése", debug_toggle: "Debug Váltás", close: "Bezárás",
        overview: "Áttekintés", total_zones: "Összes Zóna", active_zones: "Aktív Zóna", debug_status: "Debug Állapot",
        new_zone: "Új Zóna Kialakítása", zone_name: "Zóna Neve", speed_limit: "Sebesség Korlát (km/h)", duration: "Büntetés Ideje (Másodperc)",
        zone_type: "Zóna Típusa", fetch_coords: "Jelenlegi Helyzetem Betöltése", radius: "Sugár (Radius)", width: "Szélesség", length: "Hosszúság", height: "Magasság",
        create_btn: "Létrehozás", edit_btn: "Mentés", zone_manage: "Zónák Kezelése", slow_down: "LASSÍTS!",
        status_active: "Aktív", status_inactive: "Inaktív", limit: "Korlát", status: "Státusz",
        no_zones: "Nincsenek létrehozott zónák.", sphere: "Gömb (Sphere)", box: "Doboz (Box - Utakra)", on: "Bekapcsolva", off: "Kikapcsolva",
        import_export: "Zónák Biztonsági Mentése (Import / Export)", export: "Exportálás", import: "Importálás",
        edit: "Szerkesztés",
        import_placeholder: "Itt jelenik meg a kód, vagy ide illeszd be...",
        zone_name_placeholder: "pl. Iskola zóna"
    },
    en: {
        dashboard: "Dashboard", create_zone: "Create Zone", manage_zones: "Manage Zones", debug_toggle: "Toggle Debug", close: "Close",
        overview: "Overview", total_zones: "Total Zones", active_zones: "Active Zones", debug_status: "Debug Status",
        new_zone: "Create New Zone", zone_name: "Zone Name", speed_limit: "Speed Limit (km/h)", duration: "Slowdown Duration (Seconds)",
        zone_type: "Zone Type", fetch_coords: "Fetch Current Coords", radius: "Radius", width: "Width", length: "Length", height: "Height",
        create_btn: "Create", edit_btn: "Save", zone_manage: "Manage Zones", slow_down: "SLOW DOWN!",
        status_active: "Active", status_inactive: "Inactive", limit: "Limit", status: "Status",
        no_zones: "No zones created.", sphere: "Sphere", box: "Box (For roads)", on: "On", off: "Off",
        import_export: "Backup Zones (Import / Export)", export: "Export", import: "Import",
        edit: "Edit",
        import_placeholder: "The code appears here, or paste it here...",
        zone_name_placeholder: "e.g. School zone"
    }
};

function updateLanguage() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
        let key = el.getAttribute('data-i18n');
        if (translations[currentLang][key]) {
            el.innerHTML = translations[currentLang][key];
        }
    });

    let ioData = document.getElementById('ioData');
    if (ioData) ioData.placeholder = translations[currentLang].import_placeholder;
    
    let zName = document.getElementById('zName');
    if (zName) zName.placeholder = translations[currentLang].zone_name_placeholder;
    
    let submitBtn = document.querySelector('#createZoneForm button[type="submit"]');
    if (submitBtn) {
        if (editingZoneId) submitBtn.innerHTML = translations[currentLang].edit_btn;
        else submitBtn.innerHTML = translations[currentLang].create_btn;
    }
}

function postData(event, data = {}) {
    const resourceName = window.GetParentResourceName ? GetParentResourceName() : 'thehood_antispeed';
    return fetch(`https://${resourceName}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data)
    }).catch(err => console.error("Fetch hiba:", err));
}

window.addEventListener('message', function(e) {
    try {
        let item = e.data;
        if (item.action === "open") {
            document.getElementById("app").style.display = "flex";
            zonesData = item.zones || {};
            isDebug = item.debug || false;
            if (item.defaultSpeed) document.getElementById("zSpeed").value = item.defaultSpeed;
            updateUI();
        } else if (item.action === "close") {
            document.getElementById("app").style.display = "none";
        } else if (item.action === "updateZones") {
            zonesData = item.zones || {};
            updateUI();
        } else if (item.action === "showWarning") {
            if (item.lang) {
                currentLang = item.lang;
                updateLanguage();
            }
            document.getElementById("warning-container").style.display = "flex";
        } else if (item.action === "hideWarning") {
            document.getElementById("warning-container").style.display = "none";
        }
    } catch (error) {
        console.error("NUI Message Hiba:", error);
    }
});

document.querySelectorAll('.lang-btn').forEach(btn => {
    btn.addEventListener('click', function() {
        document.querySelectorAll('.lang-btn').forEach(b => b.classList.remove('active'));
        this.classList.add('active');
        currentLang = this.getAttribute('data-lang');
        updateLanguage();
        updateUI();
    });
});

document.querySelectorAll('.nav li').forEach(li => {
    li.addEventListener('click', () => {
        document.querySelectorAll('.nav li').forEach(el => el.classList.remove('active'));
        document.querySelectorAll('.page').forEach(el => el.classList.remove('active'));
        li.classList.add('active');
        document.getElementById('page-' + li.dataset.page).classList.add('active');
    });
});

document.getElementById('zType').addEventListener('change', function() {
    document.getElementById('sphereOptions').classList.remove('active');
    document.getElementById('boxOptions').classList.remove('active');
    if(this.value === 'sphere') document.getElementById('sphereOptions').classList.add('active');
    if(this.value === 'box') document.getElementById('boxOptions').classList.add('active');
});

document.getElementById('fetchCoordsBtn').addEventListener('click', () => {
    postData('getCurrentCoords').then(resp => resp.json()).then(data => {
        document.getElementById('zX').value = data.x.toFixed(2);
        document.getElementById('zY').value = data.y.toFixed(2);
        document.getElementById('zZ').value = data.z.toFixed(2);
        document.getElementById('zH').value = data.h.toFixed(2);
    });
});

document.getElementById('exportBtn').addEventListener('click', () => {
    document.getElementById('ioData').value = JSON.stringify(zonesData, null, 4);
});

document.getElementById('importBtn').addEventListener('click', () => {
    try {
        let parsed = JSON.parse(document.getElementById('ioData').value);
        postData('importZones', parsed);
    } catch (e) {
        postData('sendNotify', { msg: "Hibás JSON formátum!", type: "error" });
    }
});

document.getElementById('createZoneForm').addEventListener('submit', (e) => {
    e.preventDefault();
    let type = document.getElementById('zType').value;
    let data = {
        name: document.getElementById('zName').value,
        speedLimit: parseFloat(document.getElementById('zSpeed').value),
        duration: parseFloat(document.getElementById('zDuration').value),
        type: type,
        isActive: editingZoneId ? zonesData[editingZoneId].isActive : true,
        coords: {
            x: parseFloat(document.getElementById('zX').value),
            y: parseFloat(document.getElementById('zY').value),
            z: parseFloat(document.getElementById('zZ').value)
        }
    };
    
    if (isNaN(data.coords.x)) {
        postData('sendNotify', { msg: "Kérlek előbb töltsd be a koordinátákat a gombbal!", type: "error" });
        return;
    }

    if (type === 'sphere') {
        data.radius = parseFloat(document.getElementById('zRadius').value);
    } else {
        data.width = parseFloat(document.getElementById('zWidth').value);
        data.length = parseFloat(document.getElementById('zLength').value);
        data.height = parseFloat(document.getElementById('zHeight').value);
        data.heading = parseFloat(document.getElementById('zH').value);
    }

    if (editingZoneId) {
        postData('editZone', { id: editingZoneId, data: data });
        editingZoneId = null;
    } else {
        postData('createZone', data);
    }
    document.getElementById('createZoneForm').reset();
    document.getElementById('zSpeed').value = "15";
    updateLanguage();
});

window.editZone = function(id) {
    let z = zonesData[id];
    if (!z) return;

    editingZoneId = id;
    
    let navs = document.querySelectorAll('.nav li');
    for (let li of navs) {
        if (li.dataset.page === 'create' || li.innerText.includes('Zóna') || li.innerText.includes('Zone')) {
            li.click();
            break;
        }
    }

    let zName = document.getElementById('zName'); if(zName) zName.value = z.name;
    let zSpeed = document.getElementById('zSpeed'); if(zSpeed) zSpeed.value = z.speedLimit;
    let zDuration = document.getElementById('zDuration'); if(zDuration) zDuration.value = z.duration || 2;
    let zType = document.getElementById('zType'); 
    if(zType) { zType.value = z.type; zType.dispatchEvent(new Event('change')); }
    
    let zX = document.getElementById('zX'); if(zX) zX.value = z.coords.x;
    let zY = document.getElementById('zY'); if(zY) zY.value = z.coords.y;
    let zZ = document.getElementById('zZ'); if(zZ) zZ.value = z.coords.z;
    let zH = document.getElementById('zH'); if(zH) zH.value = z.heading || 0;
    
    if (z.type === 'sphere') {
        let zRadius = document.getElementById('zRadius'); if(zRadius) zRadius.value = z.radius || 150;
    } else {
        let zWidth = document.getElementById('zWidth'); if(zWidth) zWidth.value = z.width || 10;
        let zLength = document.getElementById('zLength'); if(zLength) zLength.value = z.length || 10;
        let zHeight = document.getElementById('zHeight'); if(zHeight) zHeight.value = z.height || 10;
    }

    updateLanguage();
};

function updateUI() {
    let total = 0; let active = 0;
    let listHTML = '';

    for (let id in zonesData) {
        let z = zonesData[id];
        total++;
        if(z.isActive !== false) active++;
        
        let icon = z.type === 'sphere' ? 'fa-circle' : 'fa-square';
        let statusText = z.isActive !== false 
            ? `<span style="color:var(--success)">${translations[currentLang].status_active}</span>` 
            : `<span style="color:var(--danger)">${translations[currentLang].status_inactive}</span>`;
        let toggleClass = z.isActive !== false ? '' : 'off';
        
        listHTML += `
            <div class="zone-card">
                <div class="zone-info">
                    <h4><i class="fa-solid ${icon} ${toggleClass ? 'text-danger' : 'text-primary'}"></i> ${z.name}</h4>
                    <p>${translations[currentLang].limit}: ${z.speedLimit} km/h | ${translations[currentLang].status}: ${statusText}</p>
                </div>
                <div class="zone-actions">
                    <button class="icon-btn" title="${translations[currentLang].edit}" onclick="editZone('${id}')"><i class="fa-solid fa-pen"></i></button>
                    <button class="icon-btn toggle ${toggleClass}" title="Ki/Be Kapcsolás" onclick="postData('toggleZoneActive', {id: '${id}', state: ${z.isActive === false ? true : false}})"><i class="fa-solid fa-power-off"></i></button>
                    <button class="icon-btn" title="Teleport" onclick="postData('teleportZone', {id: '${id}'})"><i class="fa-solid fa-location-arrow"></i></button>
                    <button class="icon-btn del" title="Törlés" onclick="postData('deleteZone', {id: '${id}'})"><i class="fa-solid fa-trash"></i></button>
                </div>
            </div>
        `;
    }
    document.getElementById('zonesList').innerHTML = listHTML || `<p style="color: var(--text-muted); text-align: center; padding: 20px;">${translations[currentLang].no_zones}</p>`;
    document.getElementById('statTotal').innerText = total;
    document.getElementById('statActive').innerText = active;
    document.getElementById('statDebug').innerText = isDebug ? translations[currentLang].on : translations[currentLang].off;
    document.getElementById('statDebug').style.color = isDebug ? "var(--success)" : "var(--danger)";
}

updateLanguage();
document.getElementById('closeBtn').addEventListener('click', () => { 
    document.getElementById("app").style.display = "none"; 
    postData('close'); 
});
document.getElementById('toggleDebugBtn').addEventListener('click', () => { postData('toggleDebug').then(r => r.json()).then(d => { isDebug = d; updateUI(); }); });

window.addEventListener('DOMContentLoaded', () => {
    let dashboard = document.getElementById("page-dashboard");
    if (dashboard) {
        dashboard.style.paddingBottom = "0px"; 
    }
        
    let nav = document.querySelector(".nav");
    if (nav) {
        let creditBadge = document.createElement('a');
        creditBadge.id = "moho-credit-badge";
        creditBadge.href = "https://github.com/mohostar";
        creditBadge.style.position = "relative";
        creditBadge.style.marginTop = "auto";
        creditBadge.style.marginBottom = "15px";
        creditBadge.style.marginLeft = "15px";
        creditBadge.style.marginRight = "15px";
        creditBadge.style.display = "flex";
        creditBadge.style.alignItems = "center";
        creditBadge.style.gap = "12px";
        creditBadge.style.textDecoration = "none";
        creditBadge.style.background = "rgba(20, 20, 25, 0.9)";
        creditBadge.style.padding = "10px 15px";
        creditBadge.style.borderRadius = "12px";
        creditBadge.style.border = "1px solid rgba(255, 255, 255, 0.1)";
        creditBadge.style.boxShadow = "0 4px 15px rgba(0, 0, 0, 0.5)";
        creditBadge.style.transition = "all 0.3s ease";
        creditBadge.style.zIndex = "100";
        creditBadge.style.cursor = "pointer";

        creditBadge.innerHTML = `
            <img src="https://avatars.githubusercontent.com/u/111076071?s=400&u=b33259319e24ae544ea16d109417bf9cbaa1d025&v=4" alt="Moho" style="width: 40px; height: 40px; border-radius: 50%; border: 2px solid #fff; object-fit: cover;">
            <div style="display: flex; flex-direction: column; justify-content: center;">
                <span style="font-size: 10px; color: #aaa; text-transform: uppercase; letter-spacing: 1px; font-weight: 600;">Developed by</span>
                <span style="font-size: 15px; font-weight: bold; color: #fff; display: flex; align-items: center; gap: 5px;">
                    MOHO <i class="fa-brands fa-github" style="font-size: 14px;"></i>
                </span>
            </div>
        `;

        creditBadge.addEventListener('mouseenter', () => { creditBadge.style.transform = "translateY(-3px)"; creditBadge.style.boxShadow = "0 8px 20px rgba(0, 0, 0, 0.7)"; creditBadge.style.background = "rgba(30, 30, 35, 0.9)"; });
        creditBadge.addEventListener('mouseleave', () => { creditBadge.style.transform = "translateY(0)"; creditBadge.style.boxShadow = "0 4px 15px rgba(0, 0, 0, 0.5)"; creditBadge.style.background = "rgba(20, 20, 25, 0.9)"; });
        creditBadge.addEventListener('click', (e) => { e.preventDefault(); if (window.invokeNative) { window.invokeNative("openUrl", "https://github.com/mohowhok"); } else { window.open("https://github.com/mohowhok", "_blank"); } });

        nav.insertAdjacentElement('afterend', creditBadge);
    }
});

document.onkeyup = function(data) { 
    if (data.which == 27 || data.key === "Escape") { 
        document.getElementById("app").style.display = "none"; 
        postData('close'); 
    } 
};      
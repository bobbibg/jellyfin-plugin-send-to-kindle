/* Send to Kindle - injected client script.
 *
 * Three responsibilities:
 *   1. Add a "Send to Kindle" entry to the user settings sidebar (#myPreferencesMenuPage),
 *      so each user can self-serve their Kindle email address.
 *   2. Add a "Send to Kindle" button to book detail pages.
 *   3. Provide a modal for entering the Kindle email - opened either from the
 *      sidebar entry, or automatically when a user clicks "Send to Kindle" on
 *      a book before they've set an address.
 *
 * Strategy: MutationObserver on document.body, debounced via requestAnimationFrame.
 * We re-check on every mutation tick because Jellyfin's web UI is a single-page
 * app that destroys and rebuilds DOM on navigation.
 *
 * Selectors confirmed stable since Jellyfin 10.7:
 *   #myPreferencesMenuPage  - user settings page wrapper
 *   .readOnlyContent > .verticalSection - top section of the sidebar
 *   .lnk{Name}.listItem-border - link entries
 *   .listItem > .listItemIcon + .listItemBody > .listItemBodyText - entry layout
 */

(function () {
    'use strict';

    const SIDEBAR_ENTRY_CLASS = 'lnkSendToKindle';
    const BOOK_BUTTON_ID = 'sendToKindleButton';
    const MODAL_ID = 'sendToKindleModal';

    // ----- ApiClient helpers -----------------------------------------------

    function getApiClient() {
        if (typeof window.ApiClient !== 'undefined' && window.ApiClient) {
            return window.ApiClient;
        }
        if (typeof window.ApiClientFactory !== 'undefined') {
            try { return window.ApiClientFactory.getApiClient(); } catch (e) { /* ignore */ }
        }
        return null;
    }

    function fetchUserConfig() {
        const api = getApiClient();
        if (!api) return Promise.reject('no api client');
        return api.ajax({
            type: 'GET',
            url: api.getUrl('SendToKindle/UserConfig'),
            dataType: 'json'
        });
    }

    function saveUserConfig(kindleEmail) {
        const api = getApiClient();
        if (!api) return Promise.reject('no api client');
        return api.ajax({
            type: 'POST',
            url: api.getUrl('SendToKindle/UserConfig'),
            contentType: 'application/json',
            data: JSON.stringify({ KindleEmail: kindleEmail })
        });
    }

    function sendBook(itemId) {
        const api = getApiClient();
        if (!api) return Promise.reject('no api client');
        return api.ajax({
            type: 'POST',
            url: api.getUrl('SendToKindle/Send/' + itemId)
        });
    }

    // ----- Modal -----------------------------------------------------------

    function ensureModalStyles() {
        if (document.getElementById('sendToKindleModalStyles')) return;
        const css = `
        #${MODAL_ID}-backdrop {
            position: fixed; inset: 0; background: rgba(0,0,0,0.6);
            display: flex; align-items: center; justify-content: center;
            z-index: 9999;
        }
        #${MODAL_ID} {
            background: #1c1c1c; color: #fff; border-radius: 8px;
            min-width: 320px; max-width: 90vw; padding: 1.5em 1.5em 1em;
            box-shadow: 0 8px 32px rgba(0,0,0,0.4);
            font-family: inherit;
        }
        #${MODAL_ID} h2 { margin: 0 0 0.4em; font-size: 1.2em; }
        #${MODAL_ID} p { margin: 0 0 1em; opacity: 0.85; font-size: 0.9em; line-height: 1.4; }
        #${MODAL_ID} label { display: block; margin-bottom: 0.4em; font-size: 0.85em; opacity: 0.9; }
        #${MODAL_ID} input[type="email"] {
            width: 100%; box-sizing: border-box; padding: 0.5em 0.7em;
            background: #2a2a2a; color: #fff; border: 1px solid #444;
            border-radius: 4px; font-size: 1em;
        }
        #${MODAL_ID} input[type="email"]:focus { outline: none; border-color: #00a4dc; }
        #${MODAL_ID} .stk-actions {
            display: flex; gap: 0.6em; justify-content: flex-end; margin-top: 1.2em;
        }
        #${MODAL_ID} button {
            padding: 0.5em 1em; border: none; border-radius: 4px;
            background: #444; color: #fff; cursor: pointer; font-size: 0.9em;
        }
        #${MODAL_ID} button.primary { background: #00a4dc; }
        #${MODAL_ID} button:hover { filter: brightness(1.15); }
        #${MODAL_ID} .stk-status { font-size: 0.85em; min-height: 1.2em; margin-top: 0.6em; }
        #${MODAL_ID} .stk-status.error { color: #ff6b6b; }
        #${MODAL_ID} .stk-status.ok { color: #4caf50; }
        `;
        const style = document.createElement('style');
        style.id = 'sendToKindleModalStyles';
        style.textContent = css;
        document.head.appendChild(style);
    }

    /**
     * Open the email-entry modal. Returns a Promise that resolves with the saved
     * address (or rejects if the user cancels).
     */
    function openModal(currentValue) {
        ensureModalStyles();

        const existing = document.getElementById(MODAL_ID + '-backdrop');
        if (existing) existing.remove();

        return new Promise((resolve, reject) => {
            const backdrop = document.createElement('div');
            backdrop.id = MODAL_ID + '-backdrop';
            backdrop.innerHTML = `
                <div id="${MODAL_ID}" role="dialog" aria-labelledby="${MODAL_ID}-title">
                    <h2 id="${MODAL_ID}-title">Send to Kindle</h2>
                    <p>
                        Enter your personal Kindle email address. Find it on Amazon at
                        <em>Manage Your Content and Devices &rarr; Preferences &rarr; Personal Document Settings</em>.
                        It looks like <code>your-name_abc123@kindle.com</code>.
                    </p>
                    <label for="${MODAL_ID}-input">Kindle email</label>
                    <input id="${MODAL_ID}-input" type="email"
                           placeholder="you_xyz@kindle.com"
                           pattern=".+@(kindle\\.com|free\\.kindle\\.com)$"
                           autocomplete="off" />
                    <div class="stk-status" id="${MODAL_ID}-status"></div>
                    <div class="stk-actions">
                        <button type="button" id="${MODAL_ID}-cancel">Cancel</button>
                        <button type="button" class="primary" id="${MODAL_ID}-save">Save</button>
                    </div>
                </div>
            `;
            document.body.appendChild(backdrop);

            const input = backdrop.querySelector('#' + MODAL_ID + '-input');
            const status = backdrop.querySelector('#' + MODAL_ID + '-status');
            const saveBtn = backdrop.querySelector('#' + MODAL_ID + '-save');
            const cancelBtn = backdrop.querySelector('#' + MODAL_ID + '-cancel');

            input.value = currentValue || '';
            window.setTimeout(() => input.focus(), 50);

            const close = () => backdrop.remove();

            cancelBtn.addEventListener('click', () => { close(); reject('cancelled'); });
            backdrop.addEventListener('click', (e) => {
                if (e.target === backdrop) { close(); reject('cancelled'); }
            });

            saveBtn.addEventListener('click', async () => {
                const value = (input.value || '').trim();
                if (!/.+@(kindle\.com|free\.kindle\.com)$/i.test(value)) {
                    status.className = 'stk-status error';
                    status.textContent = 'Address must end in @kindle.com or @free.kindle.com';
                    return;
                }
                saveBtn.disabled = true;
                cancelBtn.disabled = true;
                status.className = 'stk-status';
                status.textContent = 'Saving...';
                try {
                    await saveUserConfig(value);
                    status.className = 'stk-status ok';
                    status.textContent = 'Saved.';
                    window.setTimeout(() => { close(); resolve(value); }, 600);
                } catch (err) {
                    status.className = 'stk-status error';
                    let message = 'Save failed.';
                    try {
                        if (err && err.response) message = (await err.response.text()) || message;
                        else if (err && err.statusText) message = err.statusText;
                    } catch (e) { /* ignore */ }
                    status.textContent = message;
                    saveBtn.disabled = false;
                    cancelBtn.disabled = false;
                }
            });

            input.addEventListener('keydown', (e) => {
                if (e.key === 'Enter') saveBtn.click();
                else if (e.key === 'Escape') cancelBtn.click();
            });
        });
    }

    /**
     * Open the modal pre-filled with the user's current address (if any).
     */
    async function openModalForCurrentUser() {
        let current = '';
        try {
            const data = await fetchUserConfig();
            current = (data && data.KindleEmail) || '';
        } catch (e) { /* user might not have one set yet */ }
        return openModal(current);
    }

    // ----- User settings sidebar entry -------------------------------------

    function injectUserMenuEntry() {
        const page = document.querySelector('#myPreferencesMenuPage');
        if (!page) return;
        const topSection = page.querySelector('.readOnlyContent > .verticalSection');
        if (!topSection) return;
        if (topSection.querySelector('.' + SIDEBAR_ENTRY_CLASS)) return;

        const link = document.createElement('a');
        link.setAttribute('is', 'emby-linkbutton');
        link.setAttribute('data-ripple', 'false');
        link.href = '#';
        link.style.cssText = 'display:block;padding:0;margin:0;';
        link.className = SIDEBAR_ENTRY_CLASS + ' listItem-border';
        link.innerHTML = `
            <div class="listItem">
                <span class="material-icons listItemIcon listItemIcon-transparent" aria-hidden="true">tablet_android</span>
                <div class="listItemBody">
                    <div class="listItemBodyText">Send to Kindle</div>
                </div>
            </div>`;
        link.addEventListener('click', (e) => {
            e.preventDefault();
            openModalForCurrentUser().catch(() => { /* user cancelled */ });
        });

        const controls = topSection.querySelector('.lnkControlsPreferences');
        if (controls && controls.nextSibling) {
            topSection.insertBefore(link, controls.nextSibling);
        } else {
            topSection.appendChild(link);
        }
    }

    // ----- Book detail button ----------------------------------------------

    function getItemIdFromHash() {
        const hash = window.location.hash || '';
        const match = hash.match(/[?&#]id=([0-9a-fA-F-]{32,36})/);
        return match ? match[1] : null;
    }

    function findActionsContainer() {
        return document.querySelector('.mainDetailButtons')
            || document.querySelector('.detailButton-container')
            || document.querySelector('.itemDetailPage:not(.hide) .detailButton-container');
    }

    function buildBookButton(itemId) {
        const button = document.createElement('button');
        button.id = BOOK_BUTTON_ID;
        button.type = 'button';
        button.className = 'button-flat detailButton emby-button';
        button.title = 'Send to Kindle';
        button.innerHTML =
            '<div class="detailButton-content">' +
              '<span class="material-icons detailButton-icon" aria-hidden="true">tablet_android</span>' +
              '<span class="detailButton-text">Send to Kindle</span>' +
            '</div>';

        button.addEventListener('click', async function () {
            const textEl = button.querySelector('.detailButton-text');
            const original = textEl.textContent;
            const setText = (t) => { textEl.textContent = t; };

            // If the user has no Kindle address set, prompt before sending.
            try {
                const cfg = await fetchUserConfig();
                if (!cfg || !cfg.KindleEmail) {
                    try {
                        await openModalForCurrentUser();
                    } catch (e) {
                        return; // user cancelled
                    }
                }
            } catch (e) {
                // Couldn't check — try send anyway, server returns 400 if unset
            }

            button.disabled = true;
            setText('Sending...');
            try {
                await sendBook(itemId);
                setText('Sent ✓');
                window.setTimeout(() => { setText(original); button.disabled = false; }, 2500);
            } catch (err) {
                let message = 'Send failed';
                try {
                    if (err && err.response) message = (await err.response.text()) || message;
                    else if (err && err.statusText) message = err.statusText;
                } catch (e) { /* ignore */ }
                window.alert('Send to Kindle: ' + message);
                setText(original);
                button.disabled = false;
            }
        });
        return button;
    }

    async function maybeInjectBookButton() {
        if (document.getElementById(BOOK_BUTTON_ID)) return;
        const itemId = getItemIdFromHash();
        if (!itemId) return;
        const api = getApiClient();
        if (!api) return;
        const container = findActionsContainer();
        if (!container) return;

        let item;
        try {
            item = await api.getItem(api.getCurrentUserId(), itemId);
        } catch (e) { return; }
        if (!item || item.Type !== 'Book') return;

        container.appendChild(buildBookButton(item.Id));
    }

    // ----- Observer + bootstrap --------------------------------------------

    function tick() {
        try { injectUserMenuEntry(); } catch (e) { /* swallow */ }
        try { maybeInjectBookButton(); } catch (e) { /* swallow */ }
        if (!getItemIdFromHash()) {
            const stale = document.getElementById(BOOK_BUTTON_ID);
            if (stale) stale.remove();
        }
    }

    let pending = false;
    function scheduleTick() {
        if (pending) return;
        pending = true;
        window.requestAnimationFrame(() => { pending = false; tick(); });
    }

    const observer = new MutationObserver(scheduleTick);
    observer.observe(document.body, { childList: true, subtree: true });

    window.addEventListener('hashchange', () => {
        const stale = document.getElementById(BOOK_BUTTON_ID);
        if (stale) stale.remove();
        window.setTimeout(scheduleTick, 200);
    });

    tick();
})();

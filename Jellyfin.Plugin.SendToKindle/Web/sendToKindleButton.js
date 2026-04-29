/* Send to Kindle - injected button for the book detail page.
 *
 * Strategy:
 *   1. Watch for the URL to change to a book item detail page.
 *   2. When we see one, look up the item via the Jellyfin API.
 *   3. If it's a Book, inject a "Send to Kindle" button into the actions row.
 *   4. Click handler POSTs to /SendToKindle/Send/{itemId} with the user's auth header.
 */

(function () {
    'use strict';

    const BUTTON_ID = 'sendToKindleButton';
    const POLL_INTERVAL = 500;

    // Detect a Jellyfin item details URL of the shape ".../#/details?id=GUID..."
    function getItemIdFromHash() {
        const hash = window.location.hash || '';
        const match = hash.match(/[?&#]id=([0-9a-fA-F-]{32,36})/);
        return match ? match[1] : null;
    }

    // ApiClient is the auth-aware client Jellyfin's web app exposes globally.
    function getApiClient() {
        if (typeof window.ApiClient !== 'undefined' && window.ApiClient) {
            return window.ApiClient;
        }
        if (typeof window.ApiClientFactory !== 'undefined') {
            try { return window.ApiClientFactory.getApiClient(); } catch (e) { /* ignore */ }
        }
        return null;
    }

    function fetchItem(apiClient, itemId) {
        const userId = apiClient.getCurrentUserId();
        return apiClient.getItem(userId, itemId);
    }

    function findActionsContainer() {
        // Jellyfin renders the detail page actions in a div with class "mainDetailButtons"
        // (with variants across themes). Match the most reliable selector first.
        return document.querySelector('.mainDetailButtons')
            || document.querySelector('.detailButton-container')
            || document.querySelector('.itemDetailPage:not(.hide) .detailButton-container');
    }

    function buildButton(itemId, itemName) {
        const button = document.createElement('button');
        button.id = BUTTON_ID;
        button.type = 'button';
        button.className = 'button-flat detailButton emby-button';
        button.title = 'Send to Kindle';
        button.innerHTML =
            '<div class="detailButton-content">' +
              '<span class="material-icons detailButton-icon" aria-hidden="true">tablet</span>' +
              '<span class="detailButton-text">Send to Kindle</span>' +
            '</div>';

        button.addEventListener('click', async function () {
            const apiClient = getApiClient();
            if (!apiClient) {
                window.alert('Could not reach Jellyfin API.');
                return;
            }
            button.disabled = true;
            const originalText = button.querySelector('.detailButton-text').textContent;
            button.querySelector('.detailButton-text').textContent = 'Sending...';
            try {
                await apiClient.ajax({
                    type: 'POST',
                    url: apiClient.getUrl('SendToKindle/Send/' + itemId)
                });
                button.querySelector('.detailButton-text').textContent = 'Sent ✓';
                window.setTimeout(() => {
                    button.querySelector('.detailButton-text').textContent = originalText;
                    button.disabled = false;
                }, 2500);
            } catch (err) {
                let message = 'Send to Kindle failed.';
                try {
                    if (err && err.response) {
                        message += ' ' + (await err.response.text());
                    } else if (err && err.statusText) {
                        message += ' ' + err.statusText;
                    }
                } catch (e) { /* ignore */ }
                window.alert(message);
                button.querySelector('.detailButton-text').textContent = originalText;
                button.disabled = false;
            }
        });

        return button;
    }

    async function maybeInject() {
        if (document.getElementById(BUTTON_ID)) {
            return; // already there
        }

        const itemId = getItemIdFromHash();
        if (!itemId) return;

        const apiClient = getApiClient();
        if (!apiClient) return;

        const container = findActionsContainer();
        if (!container) return;

        let item;
        try {
            item = await fetchItem(apiClient, itemId);
        } catch (e) {
            return;
        }

        if (!item || item.Type !== 'Book') return;

        const button = buildButton(item.Id, item.Name);
        container.appendChild(button);
    }

    // The Jellyfin web app is a single-page app; route changes don't fire load events,
    // so we poll on a low frequency. Cheap, resilient to theme/layout differences.
    function loop() {
        try { maybeInject(); } catch (e) { /* swallow */ }
        // Remove our button if the user navigated away from a book page
        const itemId = getItemIdFromHash();
        if (!itemId) {
            const existing = document.getElementById(BUTTON_ID);
            if (existing) existing.remove();
        }
    }

    window.setInterval(loop, POLL_INTERVAL);
    window.addEventListener('hashchange', () => {
        const existing = document.getElementById(BUTTON_ID);
        if (existing) existing.remove();
        // give the new view time to render, then try to inject
        window.setTimeout(maybeInject, 200);
    });
})();

// Progressive enhancement: without JS, gallery links open the full image directly.
(function () {
  const dialog = document.getElementById('lightbox');
  const pieces = Array.from(document.querySelectorAll('.piece'));
  if (!dialog || !pieces.length || typeof dialog.showModal !== 'function') return;

  const imgEl = document.getElementById('lb-img');
  const titleEl = document.getElementById('lb-title');
  const metaEl = document.getElementById('lb-meta');
  let current = 0;

  const items = pieces.map(function (piece) {
    const link = piece.querySelector('a');
    const thumb = piece.querySelector('img');
    return {
      full: link.dataset.full || link.getAttribute('href'),
      alt: thumb ? thumb.getAttribute('alt') || '' : '',
      title: (piece.querySelector('h2') || {}).textContent || '',
      meta: (piece.querySelector('.meta') || {}).textContent || ''
    };
  });

  function show(i) {
    current = (i + items.length) % items.length;
    const item = items[current];
    imgEl.src = item.full;
    imgEl.alt = item.alt;
    titleEl.textContent = item.title;
    metaEl.textContent = item.meta;
    preload(current + 1);
    preload(current - 1);
  }

  function preload(i) {
    const item = items[(i + items.length) % items.length];
    if (item) new Image().src = item.full;
  }

  pieces.forEach(function (piece, i) {
    piece.querySelector('a').addEventListener('click', function (event) {
      event.preventDefault();
      show(i);
      dialog.showModal();
    });
  });

  dialog.addEventListener('click', function (event) {
    const action = event.target.dataset.lb;
    if (action === 'close') { dialog.close(); return; }
    if (action === 'prev') { show(current - 1); return; }
    if (action === 'next') { show(current + 1); return; }
    // The figure fills the viewport, so test for the artwork itself rather than
    // relying on the click landing on the dialog element.
    if (!event.target.closest('#lb-img, figcaption')) dialog.close();
  });

  dialog.addEventListener('keydown', function (event) {
    if (event.key === 'ArrowRight') { event.preventDefault(); show(current + 1); }
    else if (event.key === 'ArrowLeft') { event.preventDefault(); show(current - 1); }
    // Not all engines fire the native close request reliably; close explicitly.
    else if (event.key === 'Escape') { event.preventDefault(); dialog.close(); }
  });

  // Free the decoded image from memory when the viewer is dismissed.
  dialog.addEventListener('close', function () {
    imgEl.removeAttribute('src');
  });
})();

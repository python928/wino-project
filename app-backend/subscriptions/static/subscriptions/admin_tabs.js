(function () {
  function initTabs() {
    const form = document.querySelector('#content-main');
    if (!form) return;

    const fieldsets = Array.from(form.querySelectorAll('fieldset.tab'));
    if (fieldsets.length === 0) return;

    const tabs = document.createElement('ul');
    tabs.className = 'subscription-admin-tabs';

    fieldsets.forEach((fs, index) => {
      const titleEl = fs.querySelector('h2');
      const title = titleEl ? titleEl.textContent.trim() : `Tab ${index + 1}`;

      const li = document.createElement('li');
      const btn = document.createElement('button');
      btn.type = 'button';
      btn.textContent = title;
      btn.addEventListener('click', () => {
        fieldsets.forEach((other, i) => {
          other.classList.toggle('subscription-admin-fieldset-hidden', i !== index);
        });
        const buttons = tabs.querySelectorAll('button');
        buttons.forEach((b, i) => b.classList.toggle('active', i === index));
      });

      li.appendChild(btn);
      tabs.appendChild(li);
    });

    fieldsets[0].parentNode.insertBefore(tabs, fieldsets[0]);

    fieldsets.forEach((fs, i) => {
      fs.classList.toggle('subscription-admin-fieldset-hidden', i !== 0);
    });
    const firstButton = tabs.querySelector('button');
    if (firstButton) firstButton.classList.add('active');
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initTabs);
  } else {
    initTabs();
  }
})();

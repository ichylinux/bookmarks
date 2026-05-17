// Preferences: linked portal column width ratio sliders (sum = 100).
(function () {
  const MIN_WIDTH = 10;
  const MAX_WIDTH = 80;

  function clamp(value) {
    return Math.max(MIN_WIDTH, Math.min(MAX_WIDTH, value));
  }

  function fixSum(sliders) {
    let guard = 0;
    while (guard < 200) {
      const values = sliders.map((slider) => parseInt(slider.value, 10));
      const sum = values.reduce((total, value) => total + value, 0);
      const diff = 100 - sum;
      if (diff === 0) {
        return values;
      }

      const index = guard % sliders.length;
      const next = clamp(values[index] + (diff > 0 ? 1 : -1));
      sliders[index].value = String(next);
      guard += 1;
    }

    return sliders.map((slider) => parseInt(slider.value, 10));
  }

  function redistribute(sliders, changedIndex, rawValue) {
    const newValue = clamp(parseInt(rawValue, 10));
    sliders[changedIndex].value = String(newValue);

    const others = sliders
      .map((slider, index) => ({ slider, index }))
      .filter((entry) => entry.index !== changedIndex);

    if (others.length === 0) {
      return fixSum(sliders);
    }

    const remaining = 100 - newValue;
    const oldOthersSum = others.reduce(
      (sum, entry) => sum + parseInt(entry.slider.value, 10),
      0
    );

    if (oldOthersSum <= 0) {
      const base = Math.floor(remaining / others.length);
      let leftover = remaining - base * others.length;
      others.forEach((entry) => {
        const extra = leftover > 0 ? 1 : 0;
        if (leftover > 0) {
          leftover -= 1;
        }
        entry.slider.value = String(clamp(base + extra));
      });
    } else {
      let distributed = 0;
      others.forEach((entry, position) => {
        const share =
          position === others.length - 1
            ? remaining - distributed
            : Math.round(
                (remaining * parseInt(entry.slider.value, 10)) / oldOthersSum
              );
        distributed += share;
        entry.slider.value = String(clamp(share));
      });
    }

    return fixSum(sliders);
  }

  function syncDisplay(root, values) {
    const labels = root.querySelectorAll('[data-portal-width-label]');
    const hiddens = root.querySelectorAll('[data-portal-width-hidden]');
    const sliders = root.querySelectorAll('[data-portal-width-slider]');

    values.forEach((value, index) => {
      if (labels[index]) {
        labels[index].textContent = `${value}%`;
      }
      if (hiddens[index]) {
        hiddens[index].value = String(value);
      }
      if (sliders[index]) {
        sliders[index].value = String(value);
      }
    });
  }

  function bindRoot(root) {
    const sliders = Array.from(root.querySelectorAll('[data-portal-width-slider]'));
    if (sliders.length === 0) {
      return;
    }

    sliders.forEach((slider, index) => {
      slider.addEventListener('input', () => {
        const values = redistribute(sliders, index, slider.value);
        syncDisplay(root, values);
      });
    });
  }

  function equalWidths(count) {
    if (count === 3) {
      return [34, 33, 33];
    }
    return [25, 25, 25, 25];
  }

  function rebuildControls(root, count) {
    const template = root.querySelector('[data-portal-width-row-template]');
    const list = root.querySelector('[data-portal-width-list]');
    if (!template || !list) {
      return;
    }

    list.innerHTML = '';
    const widths = equalWidths(count);
    const columnLabel = root.getAttribute('data-column-label') || 'Column';

    widths.forEach((width, index) => {
      const row = template.content.cloneNode(true);
      const label = row.querySelector('[data-portal-width-heading]');
      if (label) {
        label.textContent = `${columnLabel} ${index + 1}`;
      }
      const slider = row.querySelector('[data-portal-width-slider]');
      const hidden = row.querySelector('[data-portal-width-hidden]');
      const valueLabel = row.querySelector('[data-portal-width-label]');
      if (slider) {
        slider.value = String(width);
        slider.setAttribute('aria-valuenow', String(width));
      }
      if (hidden) {
        hidden.value = String(width);
      }
      if (valueLabel) {
        valueLabel.textContent = `${width}%`;
      }
      list.appendChild(row);
    });

    bindRoot(root);
  }

  function init() {
    const root = document.querySelector('[data-portal-column-widths-root]');
    if (!root) {
      return;
    }

    bindRoot(root);

    const countSelect = document.querySelector(
      'select[name="user[preference_attributes][portal_column_count]"]'
    );
    if (countSelect) {
      countSelect.addEventListener('change', () => {
        const count = parseInt(countSelect.value, 10);
        if (count === 3 || count === 4) {
          rebuildControls(root, count);
        }
      });
    }
  }

  $(document).ready(init);
})();

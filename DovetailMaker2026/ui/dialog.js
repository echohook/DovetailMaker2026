(() => {
  const $ = id => document.getElementById(id);
  const fields = ['thickness', 'tail_count', 'slope', 'left_pin', 'right_pin'];
  let phase = 'tail';
  let initialized = false;
  let updateTimer = null;

  $('about').onclick = () => { $('workflow').hidden = true; $('about_page').hidden = false; };
  $('about_back').onclick = () => { $('about_page').hidden = true; $('workflow').hidden = false; };

  function payload() { return Object.fromEntries(fields.map(id => [id, $(id).value])); }
  function update() {
    clearTimeout(updateTimer);
    const values = payload();
    const editing = fields.some(id => String(values[id]).trim() === '');
    if (editing) {
      setMetrics(null);
      $('create').disabled = true;
      setNotice('輸入中…');
      return;
    }
    updateTimer = setTimeout(() => window.sketchup.update(JSON.stringify(values)), 250);
  }
  function setNotice(message, error = false) {
    $('notice').textContent = message || '';
    $('notice').classList.toggle('error', error);
  }
  function setMetrics(metrics) {
    ['width', 'full_pin', 'tail_width', 'narrow_width'].forEach(id => $(id).value = metrics?.[id] || '—');
  }
  function latestPayload() {
    clearTimeout(updateTimer);
    return JSON.stringify(payload());
  }
  fields.forEach(id => $(id).addEventListener('input', update));
  $('flip').onclick = () => window.sketchup.flip(latestPayload());
  $('other_tail').onchange = () => window.sketchup.set_create_other_tail($('other_tail').checked);
  $('create').onclick = () => {
    if (phase === 'complete') window.sketchup.finish();
    else if (phase === 'pin') window.sketchup.create_pin();
    else window.sketchup.create_tail(latestPayload());
  };

  window.DovetailMaker = {
    receive(state) {
      // Only populate defaults on initial load. Later Ruby validation responses
      // must never overwrite a field that the user is actively editing.
      if (state.values && !initialized) {
        fields.forEach(id => { if (state.values[id] !== undefined) $(id).value = state.values[id]; });
        initialized = true;
      }
      if (state.about) {
        $('about_creator').textContent = state.about.creator;
        $('about_email').textContent = state.about.email;
        $('about_email').href = `mailto:${state.about.email}`;
        $('about_version').textContent = state.about.version;
        $('about_date').textContent = state.about.release_date;
      }
      if (state.phase) phase = state.phase;
      if (state.create_other_tail !== undefined) $('other_tail').checked = !!state.create_other_tail;
      $('other_tail').disabled = !!state.other_tail_created;
      setMetrics(state.metrics);
      if (state.error) { setNotice(state.error, true); $('create').disabled = true; return; }
      if (phase === 'select_pin') {
        $('parameters').hidden = true; $('flip').hidden = true;
        $('other_tail_option').hidden = false;
        $('create').disabled = true;
        setNotice(state.message || '請直接點選 Pin Board 的對應端面。');
      } else if (phase === 'pin') {
        $('parameters').hidden = true; $('flip').hidden = true; $('other_tail_option').hidden = false; $('create').textContent = '建立 Pin'; $('create').disabled = false;
        setNotice('已取得 Tail 實際輪廓。確認後建立互補 Pin。');
      } else if (phase === 'complete') {
        $('parameters').hidden = true; $('create').textContent = '完成'; $('create').disabled = false;
        $('flip').hidden = true; $('other_tail_option').hidden = false; setNotice(state.message || 'Tail 與 Pin 已完成。');
      } else {
        $('parameters').hidden = false; $('flip').hidden = false; $('other_tail_option').hidden = true;
        $('create').textContent = '建立 Tail'; $('create').disabled = !state.metrics;
        $('direction').textContent = state.values?.flipped ? '排列方向：RIGHT → LEFT' : '排列方向：LEFT → RIGHT';
        setNotice('調整參數後，模型視窗會即時更新預覽。');
      }
    }
  };
  window.sketchup.ready();
})();

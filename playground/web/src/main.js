const RARITY_LABELS = {
  common: 'Common',
  uncommon: 'Uncommon',
  rare: 'Rare',
  epic: 'Epic',
  legendary: 'Legendary',
};

const RARITY_ORDER = ['common', 'uncommon', 'rare', 'epic', 'legendary'];

const state = {
  screen: 'loading',
  money: 300,
  boxesOpened: 0,
  packsOpened: 0,
  cardsSeen: 0,
  packsRemaining: 0,
  currentBox: null,
  currentPack: [],
  inventory: [],
  log: [],
  data: {
    boxes: [],
    cards: [],
  },
};

const el = {
  stage: document.querySelector('#stage'),
  money: document.querySelector('#money'),
  boxCount: document.querySelector('#boxCount'),
  packCount: document.querySelector('#packCount'),
  inventoryCount: document.querySelector('#inventoryCount'),
  sessionLog: document.querySelector('#sessionLog'),
};

async function init() {
  const [boxes, cards] = await Promise.all([
    fetchJson('./data/boxes.json'),
    fetchJson('./data/cards.json'),
  ]);

  state.data.boxes = boxes;
  state.data.cards = cards;
  addLog('Buy the first box.');
  showBoxShop();
  bindKeyboard();
}

async function fetchJson(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`Failed to load ${url}`);
  }

  return response.json();
}

function bindKeyboard() {
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      const primary = document.querySelector('[data-primary="true"]');
      primary?.click();
    }

    if (event.key.toLowerCase() === 'i') {
      showInventory();
    }
  });
}

function showBoxShop() {
  state.screen = 'box_shop';
  const box = state.data.boxes[0];
  render(`
    <section class="shop panel">
      <div>
        <p class="eyebrow">Box Shop</p>
        <h1>${box.name}</h1>
        <p class="copy">${box.pack_count} packs. Each pack reveals ${box.pack.card_count} cards from the Genesis set.</p>
      </div>
      <div class="price">$${box.price}</div>
      <div class="actions">
        <button class="primary" data-primary="true" id="buyBox">Buy Box</button>
        <button class="secondary" id="openInventory">Inventory</button>
      </div>
    </section>
  `);

  document.querySelector('#buyBox').addEventListener('click', () => buyBox(box));
  document.querySelector('#openInventory').addEventListener('click', showInventory);
}

function buyBox(box) {
  if (state.money < box.price) {
    addLog('Not enough money for the next box.');
    return;
  }

  state.money -= box.price;
  state.currentBox = box;
  state.packsRemaining = box.pack_count;
  state.boxesOpened += 1;
  addLog(`Opened ${box.name}.`);
  showBoxOpening();
}

function showBoxOpening() {
  state.screen = 'box_opening';
  render(`
    <section class="box-opening panel">
      <p class="eyebrow">Box Opening</p>
      <div class="box-visual" aria-hidden="true">
        <span>Genesis</span>
        <strong>3 Packs</strong>
      </div>
    </section>
  `);

  window.setTimeout(showPackSelect, 650);
}

function showPackSelect() {
  state.screen = 'pack_select';
  render(`
    <section class="panel">
      <p class="eyebrow">Pack Select</p>
      <h1>${state.currentBox.pack.name}</h1>
      <p class="copy">${state.packsRemaining} packs remaining in this box.</p>
      <div class="actions">
        <button class="primary" data-primary="true" id="openPack">Open Pack</button>
        <button class="secondary" id="openInventory">Inventory</button>
      </div>
    </section>
  `);

  document.querySelector('#openPack').addEventListener('click', openPack);
  document.querySelector('#openInventory').addEventListener('click', showInventory);
}

function openPack() {
  if (state.packsRemaining <= 0) {
    showBoxShop();
    return;
  }

  state.packsRemaining -= 1;
  state.packsOpened += 1;
  state.currentPack = generatePack(state.currentBox.pack);
  state.cardsSeen += state.currentPack.length;
  addLog(`Ripped ${state.currentBox.pack.name}.`);
  showPackReveal(0);
}

function showPackReveal(index) {
  state.screen = 'pack_reveal';
  const revealed = state.currentPack.slice(0, index);
  const upcoming = state.currentPack.length - revealed.length;
  const total = packValue(state.currentPack);

  render(`
    <section class="reveal">
      <div class="reveal-header">
        <p class="eyebrow">Pack Reveal</p>
        <strong>$${total}</strong>
      </div>
      <div class="cards">
        ${revealed.map((card, cardIndex) => renderCard(card, cardIndex === revealed.length - 1)).join('')}
        ${Array.from({ length: upcoming }, () => renderCardBack()).join('')}
      </div>
    </section>
  `);

  if (index < state.currentPack.length) {
    const nextCard = state.currentPack[index];
    window.setTimeout(() => showPackReveal(index + 1), revealDelay(nextCard));
    return;
  }

  window.setTimeout(showResultSummary, 500);
}

function showResultSummary() {
  state.screen = 'result_summary';
  const total = packValue(state.currentPack);
  const best = [...state.currentPack].sort(compareRarity).at(-1);

  render(`
    <section class="summary panel">
      <p class="eyebrow">Pack Result</p>
      <h1>$${total}</h1>
      <p class="copy">Best pull: <span class="rarity ${best.rarity}">${RARITY_LABELS[best.rarity]}</span> ${best.name}</p>
      <div class="cards compact">
        ${state.currentPack.map((card) => renderCard(card, false)).join('')}
      </div>
      <div class="actions">
        <button class="primary" data-primary="true" id="sellAll">Sell All</button>
        <button class="secondary" id="keepAll">Keep All</button>
      </div>
    </section>
  `);

  document.querySelector('#sellAll').addEventListener('click', sellAll);
  document.querySelector('#keepAll').addEventListener('click', keepAll);
}

function sellAll() {
  const total = packValue(state.currentPack);
  state.money += total;
  state.currentPack = [];
  addLog(`Sold pack for $${total}.`);
  afterPackDecision();
}

function keepAll() {
  state.inventory.push(...state.currentPack);
  addLog(`Kept ${state.currentPack.length} cards.`);
  state.currentPack = [];
  afterPackDecision();
}

function afterPackDecision() {
  if (state.packsRemaining > 0) {
    showPackSelect();
    return;
  }

  showBoxShop();
}

function showInventory() {
  state.screen = 'inventory';
  const rows = state.inventory.slice(-8).reverse();
  render(`
    <section class="inventory panel">
      <p class="eyebrow">Inventory</p>
      <h1>${state.inventory.length} kept cards</h1>
      <div class="inventory-list">
        ${
          rows.length === 0
            ? '<p class="copy">No kept cards yet.</p>'
            : rows.map((card) => `
                <div class="inventory-row">
                  <span>${card.name}</span>
                  <span class="rarity ${card.rarity}">${RARITY_LABELS[card.rarity]}</span>
                  <strong>$${card.base_value}</strong>
                </div>
              `).join('')
        }
      </div>
      <div class="actions">
        <button class="primary" data-primary="true" id="back">Back</button>
      </div>
    </section>
  `);

  document.querySelector('#back').addEventListener('click', () => {
    if (state.packsRemaining > 0) {
      showPackSelect();
      return;
    }

    showBoxShop();
  });
}

function generatePack(pack) {
  return Array.from({ length: pack.card_count }, () => {
    const rarity = rollRarity(pack.rarity_table);
    const pool = state.data.cards.filter((card) => card.rarity === rarity);
    const template = pool[Math.floor(Math.random() * pool.length)];

    return {
      ...template,
      base_value: randomInt(template.value_min, template.value_max),
    };
  });
}

function rollRarity(table) {
  const roll = Math.random();
  let cursor = 0;

  for (const entry of table) {
    cursor += entry.weight;
    if (roll <= cursor) {
      return entry.rarity;
    }
  }

  return table.at(-1).rarity;
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function packValue(cards) {
  return cards.reduce((sum, card) => sum + card.base_value, 0);
}

function revealDelay(card) {
  if (card.rarity === 'legendary') return 1200;
  if (card.rarity === 'epic') return 950;
  if (card.rarity === 'rare') return 760;
  return 520;
}

function compareRarity(a, b) {
  return RARITY_ORDER.indexOf(a.rarity) - RARITY_ORDER.indexOf(b.rarity);
}

function renderCard(card, active) {
  return `
    <article class="card ${card.rarity} ${active ? 'active' : ''}">
      <span>${card.name}</span>
      <strong>${RARITY_LABELS[card.rarity]}</strong>
      <em>$${card.base_value}</em>
    </article>
  `;
}

function renderCardBack() {
  return `
    <article class="card back">
      <span>Ripverse</span>
      <strong>Card</strong>
      <em>?</em>
    </article>
  `;
}

function render(html) {
  el.stage.innerHTML = html;
  updateStats();
  updateLog();
}

function updateStats() {
  el.money.textContent = `$${state.money}`;
  el.boxCount.textContent = `Boxes ${state.boxesOpened}`;
  el.packCount.textContent = `Packs ${state.packsOpened}`;
  el.inventoryCount.textContent = `Kept ${state.inventory.length}`;
}

function addLog(message) {
  state.log.unshift(message);
  state.log = state.log.slice(0, 5);
}

function updateLog() {
  el.sessionLog.innerHTML = state.log.map((item) => `<li>${item}</li>`).join('');
}

init().catch((error) => {
  el.stage.innerHTML = `<section class="panel"><h1>Load failed</h1><p class="copy">${error.message}</p></section>`;
});

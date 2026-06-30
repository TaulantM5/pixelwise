// frontend/app.js
const API_KEY = "REPLACE_ME"; // wird beim Deploy überschrieben
const N = 28; // Eingangsgröße des Modells
const SCALE = 10; // 10 Bildschirm-Pixel pro Rasterzelle (280x280 Canvas)
const pad = document.getElementById("pad");
const view = pad.getContext("2d");
view.imageSmoothingEnabled = false; // Knackige Pixel-Blöcke zeichnen

// Gezeichnet wird auf einem versteckten 28x28 Raster
const grid = document.createElement("canvas");
grid.width = N; grid.height = N;
const gctx = grid.getContext("2d");
gctx.lineWidth = 2.5;
gctx.lineCap = "round"; gctx.lineJoin = "round";
let drawing = false;

function render() {
  // Das 28x28 Raster vergrößert auf das sichtbare Canvas zeichnen
  view.drawImage(grid, 0, 0, pad.width, pad.height);
}

function clearPad() {
  gctx.fillStyle = "#fff";
  gctx.fillRect(0, 0, N, N);
  render();
}
clearPad();

// Mausevents auf das 28x28 Raster skalieren
pad.onmousedown = e => {
  drawing = true; gctx.beginPath();
  gctx.moveTo(e.offsetX / SCALE, e.offsetY / SCALE);
};
pad.onmousemove = e => {
  if (!drawing) return;
  gctx.lineTo(e.offsetX / SCALE, e.offsetY / SCALE);
  gctx.stroke(); render();
};
pad.onmouseup = pad.onmouseleave = () => { drawing = false; };

function getPixels() {
  const data = gctx.getImageData(0, 0, N, N).data;
  const pixels = [];
  for (let y = 0; y < N; y++) {
    const row = [];
    for (let x = 0; x < N; x++)
      // Invertieren: 255 - RGB-Wert, da MNIST hell auf dunkel erwartet
      row.push(255 - data[(y * N + x) * 4]);
    pixels.push(row);
  }
  return pixels;
}

async function classify() {
  const r = await fetch("/api/classify", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-API-Key": API_KEY
    },
    body: JSON.stringify({ pixels: getPixels() })
  });
  const out = document.getElementById("result");
  if (!r.ok) { out.textContent = "Error " + r.status; return; }
  const d = await r.json();
  out.textContent = `Prediction: ${d.prediction} (${(d.confidence * 100).toFixed(1)}%)`;
  refresh();
}

async function refresh() {
  const r = await fetch("/api/results");
  if (!r.ok) return;
  const ul = document.getElementById("history");
  ul.innerHTML = "";
  for (const row of (await r.json()).results) {
    const li = document.createElement("li");
    li.textContent = `${row.prediction} ${row.confidence.toFixed(2)} ${row.created_at}`;
    ul.appendChild(li);
  }
}

document.getElementById("classify").onclick = classify;
document.getElementById("clear").onclick = () => {
  clearPad();
  document.getElementById("result").textContent = "";
};
refresh();

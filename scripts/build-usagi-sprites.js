#!/usr/bin/env node
const fs = require("fs");
const zlib = require("zlib");

const W = 256;
const H = 256;
const data = Buffer.alloc((W * 4 + 1) * H);

const C = {
  clear: [0, 0, 0, 0],
  ink: [255, 255, 255, 255],
  muted: [170, 170, 170, 255],
  dark: [29, 43, 83, 255],
  deep: [41, 24, 60, 255],
  blue: [41, 173, 255, 255],
  green: [0, 228, 54, 255],
  pink: [255, 119, 168, 255],
  orange: [255, 163, 0, 255],
  yellow: [255, 236, 39, 255],
};

function px(x, y, color) {
  if (x < 0 || y < 0 || x >= W || y >= H) return;
  const row = y * (W * 4 + 1);
  const i = row + 1 + x * 4;
  data[i] = color[0];
  data[i + 1] = color[1];
  data[i + 2] = color[2];
  data[i + 3] = color[3];
}

function fill(x, y, w, h, color) {
  for (let yy = y; yy < y + h; yy++) {
    for (let xx = x; xx < x + w; xx++) px(xx, yy, color);
  }
}

function rect(x, y, w, h, color) {
  fill(x, y, w, 1, color);
  fill(x, y + h - 1, w, 1, color);
  fill(x, y, 1, h, color);
  fill(x + w - 1, y, 1, h, color);
}

function line(x0, y0, x1, y1, color) {
  const dx = Math.abs(x1 - x0);
  const sx = x0 < x1 ? 1 : -1;
  const dy = -Math.abs(y1 - y0);
  const sy = y0 < y1 ? 1 : -1;
  let err = dx + dy;
  while (true) {
    px(x0, y0, color);
    if (x0 === x1 && y0 === y1) break;
    const e2 = 2 * err;
    if (e2 >= dy) {
      err += dy;
      x0 += sx;
    }
    if (e2 <= dx) {
      err += dx;
      y0 += sy;
    }
  }
}

function card(x, y, border, accent) {
  fill(x, y, 64, 88, C.dark);
  rect(x, y, 64, 88, border);
  rect(x + 3, y + 3, 58, 82, accent);
  fill(x + 7, y + 8, 50, 26, C.deep);
  fill(x + 7, y + 39, 50, 7, accent);
  fill(x + 7, y + 54, 23, 5, C.muted);
  fill(x + 34, y + 54, 23, 5, C.muted);
  fill(x + 7, y + 70, 50, 7, C.deep);
  for (let i = 0; i < 8; i++) line(x + 9 + i * 6, y + 32, x + 2 + i * 6, y + 7, border);
}

function packFront(x, y) {
  fill(x, y, 80, 104, C.dark);
  rect(x, y, 80, 104, C.blue);
  fill(x + 5, y + 5, 70, 13, C.deep);
  fill(x + 5, y + 19, 70, 2, C.muted);
  fill(x + 13, y + 31, 54, 26, C.deep);
  fill(x + 17, y + 65, 46, 8, C.blue);
  for (let i = 0; i < 12; i++) line(x + i * 7, y + 103, x + i * 7 + 9, y + 87, C.blue);
}

function packBack(x, y) {
  fill(x, y, 80, 104, C.deep);
  rect(x, y, 80, 104, C.pink);
  fill(x + 34, y + 7, 12, 90, C.dark);
  rect(x + 36, y + 7, 8, 90, C.muted);
  fill(x + 12, y + 23, 56, 10, C.dark);
  fill(x + 12, y + 70, 56, 8, C.pink);
}

function pngChunk(type, payload) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(payload.length);
  const name = Buffer.from(type, "ascii");
  const crcInput = Buffer.concat([name, payload]);
  let crc = 0xffffffff;
  for (const b of crcInput) {
    crc ^= b;
    for (let k = 0; k < 8; k++) crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
  }
  const crcBuf = Buffer.alloc(4);
  crcBuf.writeUInt32BE((crc ^ 0xffffffff) >>> 0);
  return Buffer.concat([len, name, payload, crcBuf]);
}

for (let y = 0; y < H; y++) data[y * (W * 4 + 1)] = 0;
packFront(0, 0);
packBack(80, 0);
card(0, 112, C.muted, C.deep);
card(64, 112, C.blue, C.blue);
card(128, 112, C.pink, C.pink);
card(192, 112, C.orange, C.yellow);
fill(0, 220, 256, 1, C.yellow);
for (let i = 0; i < 24; i++) line(i * 11, 236, i * 11 + 15, 220, C.yellow);

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(W, 0);
ihdr.writeUInt32BE(H, 4);
ihdr[8] = 8;
ihdr[9] = 6;
ihdr[10] = 0;
ihdr[11] = 0;
ihdr[12] = 0;

const out = Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  pngChunk("IHDR", ihdr),
  pngChunk("IDAT", zlib.deflateSync(data)),
  pngChunk("IEND", Buffer.alloc(0)),
]);

fs.writeFileSync("playground/usagi/sprites.png", out);

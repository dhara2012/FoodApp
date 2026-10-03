// Mock orders API (memory માં). Status સમય પ્રમાણે આપોઆપ આગળ વધે:
// placed -> confirmed (20s) -> preparing (40s) -> out_for_delivery (70s) -> delivered (100s)
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

// Orders orders.json માં સચવાય છે (restart પછી પણ history રહે)
const FILE = path.join(__dirname, "orders.json");
const orders = (() => { try { return JSON.parse(fs.readFileSync(FILE, "utf8")); } catch (e) { return []; } })();
const save = () => fs.writeFileSync(FILE, JSON.stringify(orders, null, 2));
const byKey = {};   // Idempotency-Key -> order  (duplicate order અટકાવવા)
orders.forEach((o) => { if (o.idempotencyKey) byKey[o.idempotencyKey] = o; });
const STAGES = [["placed", 0], ["confirmed", 20], ["preparing", 40], ["out_for_delivery", 70], ["delivered", 100]];

const statusOf = (o) => {
  if (o.cancelled) return "cancelled";
  const seconds = (Date.now() - o.createdMs) / 1000;
  let current = "placed";
  for (const [name, after] of STAGES) if (seconds >= after) current = name;
  return current;
};
const view = ({ createdMs, cancelled, idempotencyKey, ...rest }) => ({ ...rest, status: statusOf({ createdMs, cancelled }) });
const fail = (res, code, message) => res.status(code).json({ message });

module.exports = (req, res, next) => {
  if (!req.path.startsWith("/orders")) return next();

  if (req.method === "POST" && req.path === "/orders") {
    const key = req.get("Idempotency-Key");
    if (!key) return fail(res, 400, "Idempotency-Key header is required");
    if (byKey[key]) return res.status(200).json(view(byKey[key]));   // એ જ order પાછો

    const b = req.body || {};
    if (!Array.isArray(b.items) || b.items.length === 0) return fail(res, 400, "Order has no items");
    if (!b.address || !(Number(b.grand_total) > 0)) return fail(res, 400, "Invalid order");

    const id = "ORD" + Date.now().toString(36).toUpperCase() + crypto.randomBytes(2).toString("hex").toUpperCase();
    const order = {
      ...b, id,
      payment_status: b.payment_method === "cod" ? "pending" : "paid",
      created_at: new Date().toISOString().split(".")[0] + "Z",
      createdMs: Date.now(), cancelled: false, idempotencyKey: key
    };
    orders.unshift(order);
    byKey[key] = order;
    save();
    return res.status(201).json(view(order));
  }

  if (req.method === "GET" && req.path === "/orders") return res.json(orders.map(view));

  const match = req.path.match(/^\/orders\/([^/]+)(\/cancel)?$/);
  if (match) {
    const order = orders.find((o) => o.id === match[1]);
    if (!order) return fail(res, 404, "Order not found");
    if (req.method === "GET" && !match[2]) return res.json(view(order));
    if (req.method === "POST" && match[2]) {
      if (!["placed", "confirmed"].includes(statusOf(order))) return fail(res, 400, "This order can no longer be cancelled");
      order.cancelled = true;
      if (order.payment_status === "paid") order.payment_status = "refunded";
      save();
      return res.json(view(order));
    }
  }
  return next();
};

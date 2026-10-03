// Mock auth routes for json-server, ખરા email OTP સાથે.
require("dotenv").config({ path: __dirname + "/.env" });
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const nodemailer = require("nodemailer");

const OTP_TTL_MS = 5 * 60 * 1000;        // OTP 5 મિનિટ માન્ય
const RESEND_COOLDOWN_MS = 30 * 1000;    // 30 સેકન્ડ પહેલાં resend નહીં
const MAX_ATTEMPTS = 5;                  // 5 ખોટા પ્રયાસ પછી નવો OTP જોઈએ

// ---------- Users (users.json માં સચવાય; restart પર જતા નથી) ----------
const USERS_FILE = path.join(__dirname, "users.json");

// Password ક્યારેય સાદા અક્ષરોમાં સાચવતા નથી: salt + scrypt hash
const hashPassword = (password) => {
  const salt = crypto.randomBytes(16).toString("hex");
  return `${salt}:${crypto.scryptSync(String(password), salt, 32).toString("hex")}`;
};
const verifyPassword = (password, stored) => {
  const [salt, hash] = String(stored || "").split(":");
  if (!salt || !hash) return false;
  const attempt = crypto.scryptSync(String(password || ""), salt, 32);
  const expected = Buffer.from(hash, "hex");
  return attempt.length === expected.length && crypto.timingSafeEqual(attempt, expected);
};

const seedUsers = () => [
  { id: 1, name: "Test User", email: "test@example.com", mobile: "9876543210", password: hashPassword("Test1234") },
  { id: 2, name: "Dharu", email: "dharu@mailinator.com", mobile: "9876500000", password: hashPassword("Test1234") }
];
const saveUsers = () => fs.writeFileSync(USERS_FILE, JSON.stringify(users, null, 2));
const loadUsers = () => {
  try {
    const data = JSON.parse(fs.readFileSync(USERS_FILE, "utf8"));
    if (Array.isArray(data) && data.length) return data;
  } catch (e) { /* file નથી કે બગડેલી છે → seed */ }
  return null;
};

const users = loadUsers() || seedUsers();
if (!fs.existsSync(USERS_FILE)) saveUsers();
let nextId = users.reduce((max, u) => Math.max(max, u.id), 0) + 1;
const pending = {};   // email -> { user, otp }   (signup OTP બાકી)
const resets = {};    // email -> { otp }         (forgot password OTP)

const lower = (s) => String(s || "").toLowerCase().trim();
const strip = ({ password, ...u }) => u;
const issue = (u) => ({
  user: strip(u),
  access_token: `access-${u.id}-${Date.now()}`,
  refresh_token: `refresh-${u.id}-${Date.now()}`
});
const fail = (res, code, message) => res.status(code).json({ message });

// ---------- OTP ----------
const transporter = process.env.SMTP_USER && process.env.SMTP_PASS
  ? nodemailer.createTransport({ service: "gmail", auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS } })
  : null;

const newOtp = () => ({
  code: String(crypto.randomInt(100000, 1000000)),   // સુરક્ષિત random 6 અંક
  expires: Date.now() + OTP_TTL_MS,
  sentAt: Date.now(),
  attempts: 0
});

/** OTP પહોંચાડવાની એક જ જગ્યા. આગળ SMS જોઈએ તો અહીં જ ઉમેરો. */
async function deliverOtp(email, name, code, purpose) {
  if (!transporter) {
    console.log(`[DEV – email configure નથી] OTP for ${email}: ${code}`);
    return;
  }
  await transporter.sendMail({
    from: `"FoodApp" <${process.env.SMTP_USER}>`,
    to: email,
    subject: purpose === "reset" ? "FoodApp password reset code" : "FoodApp verification code",
    text: `Hi ${name || ""},\n\nYour FoodApp OTP is ${code}.\nIt is valid for 5 minutes. Do not share it with anyone.\n\nIf you did not request this, you can ignore this email.`
  });
}

/** સાચો હોય તો null, નહીંતર user ને બતાવવાનો error message */
function checkOtp(entry, otp) {
  if (!entry) return "Please request a new OTP";
  if (Date.now() > entry.otp.expires) return "OTP expired. Please request a new one.";
  if (entry.otp.attempts >= MAX_ATTEMPTS) return "Too many attempts. Please request a new OTP.";
  entry.otp.attempts += 1;
  if (entry.otp.code !== String(otp)) return "Invalid OTP. Please try again.";
  return null;
}

module.exports = async (req, res, next) => {
  if (req.method !== "POST") return next();
  const b = req.body || {};
  const email = lower(b.email);

  try {
    switch (req.path) {
      case "/auth/login": {
        const u = users.find((x) => lower(x.email) === email && verifyPassword(b.password, x.password));
        return u ? res.json(issue(u)) : fail(res, 401, "Invalid email or password");
      }

      case "/auth/signup": {
        if (!b.name || !email || !b.mobile || !b.password) return fail(res, 400, "All fields are required");
        if (users.some((x) => lower(x.email) === email)) return fail(res, 409, "Email already registered");
        const otp = newOtp();
        pending[email] = { user: { id: nextId++, name: b.name, email, mobile: b.mobile, password: hashPassword(b.password) }, otp };
        await deliverOtp(email, b.name, otp.code, "signup");
        return res.status(201).json({ message: "OTP sent to your email" });
      }

      case "/auth/verify-otp": {
        const p = pending[email];
        if (!p) return fail(res, 404, "No signup request found for this email");
        const err = checkOtp(p, b.otp);
        if (err) return fail(res, 400, err);
        users.push(p.user); delete pending[email]; saveUsers();
        return res.json(issue(p.user));
      }

      case "/auth/resend-otp": {
        const p = pending[email];
        if (!p) return fail(res, 404, "No signup request found for this email");
        if (Date.now() - p.otp.sentAt < RESEND_COOLDOWN_MS) return fail(res, 429, "Please wait before requesting another OTP");
        p.otp = newOtp();
        await deliverOtp(email, p.user.name, p.otp.code, "signup");
        return res.json({ message: "A new OTP has been sent" });
      }

      case "/auth/forgot-password": {
        const u = users.find((x) => lower(x.email) === email);
        if (u) {
          resets[email] = { otp: newOtp() };
          await deliverOtp(email, u.name, resets[email].otp.code, "reset");
        }
        // account છે કે નહીં તે જાહેર ન કરવા હંમેશા સરખો જવાબ
        return res.json({ message: "If this email is registered, an OTP has been sent." });
      }

      case "/auth/reset-password": {
        const err = checkOtp(resets[email], b.otp);
        if (err) return fail(res, 400, err);
        users.find((x) => lower(x.email) === email).password = hashPassword(b.new_password);
        saveUsers();
        delete resets[email];
        return res.json({ message: "Password changed successfully" });
      }

      case "/auth/refresh": {
        if (!String(b.refresh_token || "").startsWith("refresh-")) return fail(res, 401, "Session expired");
        return res.json({ access_token: `access-r-${Date.now()}`, refresh_token: `refresh-r-${Date.now()}` });
      }

      default:
        return next();
    }
  } catch (e) {
    console.error("auth error:", e.message);
    return fail(res, 500, "Could not send OTP. Please try again later.");
  }
};

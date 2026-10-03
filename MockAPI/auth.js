const users = [
  { id: 1, name: "Test User", email: "test@example.com", mobile: "9876543210", password: "Test1234" },
  { id: 2, name: "Dharu", email: "dharu@mailinator.com", mobile: "9876500000", password: "Test1234" }
];

const publicUser = ({ password, ...rest }) => rest;

const tokens = (user) => ({
  user: publicUser(user),
  access_token: `access-${user.id}-${Date.now()}`,
  refresh_token: `refresh-${user.id}-${Date.now()}`
});

module.exports = (req, res, next) => {
  if (req.method !== "POST") return next();

  if (req.path === "/auth/login") {
    const { email, password } = req.body || {};
    const user = users.find(
      (u) => u.email.toLowerCase() === String(email).toLowerCase() && u.password === password
    );
    if (!user) return res.status(401).json({ message: "Invalid email or password" });
    return res.status(200).json(tokens(user));
  }

  if (req.path === "/auth/signup") {
    const { name, email, mobile, password } = req.body || {};
    if (users.some((u) => u.email.toLowerCase() === String(email).toLowerCase())) {
      return res.status(409).json({ message: "Email already registered" });
    }
    const user = { id: users.length + 1, name, email, mobile, password };
    users.push(user);
    return res.status(201).json(tokens(user));
  }

  next();
};

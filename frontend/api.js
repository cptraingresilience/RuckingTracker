// ─── API Service Layer ────────────────────────────────────────────────────────
// Centralised fetch wrapper. All network calls go through `api.*` methods.

const api = (() => {
  let _token = localStorage.getItem("rt_token") || null;

  function setToken(t) {
    _token = t;
    if (t) localStorage.setItem("rt_token", t);
    else localStorage.removeItem("rt_token");
  }

  function getToken() {
    return _token;
  }

  async function request(path, options = {}) {
    const url = CONFIG.BASE_URL + path;
    const headers = { "Content-Type": "application/json" };
    if (_token) headers["Authorization"] = "Bearer " + _token;

    const response = await fetch(url, {
      ...options,
      headers: { ...headers, ...(options.headers || {}) },
    });

    if (response.status === 401) {
      setToken(null);
      throw new APIError("Unauthorized – please sign in again.", 401);
    }

    let data;
    const ct = response.headers.get("content-type") || "";
    try {
      data = ct.includes("application/json") ? await response.json() : await response.text();
    } catch (_) {
      data = null;
    }

    if (!response.ok) {
      const msg =
        (data && (data.message || data.error)) ||
        `Server error ${response.status}`;
      throw new APIError(msg, response.status);
    }

    return data;
  }

  // Auth
  async function signUp(email, password, username) {
    const data = await request("/auth/signup", {
      method: "POST",
      body: JSON.stringify({ email, password, username }),
    });
    if (data.accessToken) setToken(data.accessToken);
    return data;
  }

  async function signIn(email, password) {
    const data = await request("/auth/signin", {
      method: "POST",
      body: JSON.stringify({ email, password }),
    });
    if (data.accessToken) setToken(data.accessToken);
    return data;
  }

  function signOut() {
    setToken(null);
  }

  // Activities
  async function getActivities(params = {}) {
    const qs = new URLSearchParams(params).toString();
    return request(`/activities${qs ? "?" + qs : ""}`);
  }

  async function getActivity(id) {
    return request(`/activities/${id}`);
  }

  async function createActivity(payload) {
    return request("/activities", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }

  async function updateActivity(id, payload) {
    return request(`/activities/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  }

  async function deleteActivity(id) {
    return request(`/activities/${id}`, { method: "DELETE" });
  }

  // Stats
  async function getStats() {
    return request("/stats");
  }

  return {
    setToken,
    getToken,
    signUp,
    signIn,
    signOut,
    getActivities,
    getActivity,
    createActivity,
    updateActivity,
    deleteActivity,
    getStats,
  };
})();

class APIError extends Error {
  constructor(message, status) {
    super(message);
    this.name = "APIError";
    this.status = status;
  }
}

// ─── RuckingTracker Web App ───────────────────────────────────────────────────

// ─── Helpers ─────────────────────────────────────────────────────────────────
const $ = (sel, ctx = document) => ctx.querySelector(sel);
const $$ = (sel, ctx = document) => [...ctx.querySelectorAll(sel)];

function el(tag, cls, html) {
  const e = document.createElement(tag);
  if (cls) e.className = cls;
  if (html !== undefined) e.innerHTML = html;
  return e;
}

function showAlert(el, msg, type = "error") {
  el.textContent = msg;
  el.className = `alert alert-${type} show`;
}

function hideAlert(el) {
  el.className = "alert";
}

function setLoading(btn, loading) {
  btn.disabled = loading;
  if (loading) {
    btn._originalText = btn.innerHTML;
    btn.innerHTML = `<span class="spinner"></span> Loading…`;
  } else {
    btn.innerHTML = btn._originalText || btn.innerHTML;
  }
}

function formatDate(iso) {
  if (!iso) return "—";
  return new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
}

function formatDuration(seconds) {
  if (!seconds && seconds !== 0) return "—";
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  return h > 0
    ? `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`
    : `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

function formatPace(pace) {
  if (!pace && pace !== 0) return "—";
  const min = Math.floor(pace);
  const sec = Math.round((pace - min) * 60);
  return `${min}:${String(sec).padStart(2, "0")} /mi`;
}

// ─── State ────────────────────────────────────────────────────────────────────
const state = {
  currentPage: "login",
  activities: [],
  user: null,
  editingActivity: null,
};

// ─── Navigation ───────────────────────────────────────────────────────────────
function navigate(page) {
  state.currentPage = page;
  $$(".page").forEach((p) => p.classList.remove("active"));
  const target = $(`#page-${page}`);
  if (target) target.classList.add("active");

  $$("header nav button").forEach((b) => {
    b.classList.toggle("active", b.dataset.page === page);
  });

  // Show/hide header nav depending on auth state
  const isAuth = page === "login" || page === "signup";
  $("#header-nav").style.display = isAuth ? "none" : "";
  $("#header-signout").style.display = isAuth ? "none" : "";

  if (page === "dashboard") loadDashboard();
  if (page === "activities") loadActivities();
}

// ─── Auth ─────────────────────────────────────────────────────────────────────
function initAuth() {
  // Sign In form
  $("#form-signin").addEventListener("submit", async (e) => {
    e.preventDefault();
    const alert = $("#signin-alert");
    const btn = $("#btn-signin");
    hideAlert(alert);

    const email = $("#signin-email").value.trim();
    const password = $("#signin-password").value;

    if (!email || !password) {
      showAlert(alert, "Email and password are required.");
      return;
    }

    try {
      setLoading(btn, true);
      const data = await api.signIn(email, password);
      state.user = data.user || null;
      navigate("dashboard");
    } catch (err) {
      showAlert(alert, err.message || "Sign in failed.");
    } finally {
      setLoading(btn, false);
    }
  });

  // Sign Up form
  $("#form-signup").addEventListener("submit", async (e) => {
    e.preventDefault();
    const alert = $("#signup-alert");
    const btn = $("#btn-signup");
    hideAlert(alert);

    const email = $("#signup-email").value.trim();
    const password = $("#signup-password").value;
    const username = $("#signup-username").value.trim();

    if (!email || !password || !username) {
      showAlert(alert, "All fields are required.");
      return;
    }
    if (password.length < 6) {
      showAlert(alert, "Password must be at least 6 characters.");
      return;
    }

    try {
      setLoading(btn, true);
      const data = await api.signUp(email, password, username);
      state.user = data.user || null;
      showAlert(alert, "Account created! Signing you in…", "success");
      setTimeout(() => navigate("dashboard"), 800);
    } catch (err) {
      showAlert(alert, err.message || "Sign up failed.");
    } finally {
      setLoading(btn, false);
    }
  });

  // Sign Out
  $("#header-signout").addEventListener("click", () => {
    api.signOut();
    state.user = null;
    state.activities = [];
    navigate("login");
  });
}

// ─── Dashboard ────────────────────────────────────────────────────────────────
async function loadDashboard() {
  const container = $("#dashboard-stats");
  container.innerHTML = `<div class="loading-state"><span class="spinner"></span></div>`;

  try {
    const stats = await api.getStats().catch(() => null);

    if (stats) {
      container.innerHTML = buildStatsHTML(stats);
    } else {
      // Derive from activities as fallback
      await ensureActivities();
      container.innerHTML = buildStatsFromActivities(state.activities);
    }
  } catch (err) {
    container.innerHTML = `<p style="color:var(--danger)">${err.message}</p>`;
  }

  // Recent activities preview
  await ensureActivities();
  const recentEl = $("#dashboard-recent");
  recentEl.innerHTML = "";
  const recent = state.activities.slice(0, 5);
  if (recent.length === 0) {
    recentEl.innerHTML = `<div class="empty-state"><div class="empty-icon">🥾</div><p>No activities yet. Log your first ruck!</p></div>`;
  } else {
    recent.forEach((a) => recentEl.appendChild(buildActivityCard(a, false)));
  }
}

function buildStatsHTML(stats) {
  const items = [
    { label: "Total Distance", value: (stats.totalDistance ?? 0).toFixed(1), unit: "mi" },
    { label: "Total Duration", value: formatDuration(stats.totalDuration), unit: "" },
    { label: "Avg Pace", value: formatPace(stats.avgPace), unit: "" },
    { label: "Total Rucks", value: stats.totalRucks ?? 0, unit: "" },
  ];
  return `<div class="stats-row">${items.map((i) => `
    <div class="stat-card">
      <div class="stat-label">${i.label}</div>
      <div class="stat-value">${i.value}</div>
      ${i.unit ? `<div class="stat-unit">${i.unit}</div>` : ""}
    </div>`).join("")}</div>`;
}

function buildStatsFromActivities(activities) {
  const totalDist = activities.reduce((s, a) => s + (a.distance ?? 0), 0);
  const totalDur = activities.reduce((s, a) => s + (a.duration ?? 0), 0);
  const avgPace = activities.length
    ? activities.reduce((s, a) => s + (a.pace ?? 0), 0) / activities.length
    : 0;
  return buildStatsHTML({
    totalDistance: totalDist,
    totalDuration: totalDur,
    avgPace,
    totalRucks: activities.length,
  });
}

// ─── Activities Page ──────────────────────────────────────────────────────────
async function ensureActivities() {
  if (state.activities.length === 0) {
    try {
      const data = await api.getActivities();
      state.activities = Array.isArray(data) ? data : data?.activities ?? [];
    } catch (_) {
      state.activities = [];
    }
  }
}

async function loadActivities() {
  const listEl = $("#activity-list");
  listEl.innerHTML = `<div class="loading-state"><span class="spinner"></span></div>`;

  try {
    const data = await api.getActivities();
    state.activities = Array.isArray(data) ? data : data?.activities ?? [];
    renderActivityList();
  } catch (err) {
    listEl.innerHTML = `<div class="empty-state"><div class="empty-icon">⚠️</div><p>${err.message}</p></div>`;
  }
}

function renderActivityList() {
  const listEl = $("#activity-list");
  listEl.innerHTML = "";
  if (state.activities.length === 0) {
    listEl.innerHTML = `<div class="empty-state"><div class="empty-icon">🥾</div><p>No activities yet. Log your first ruck!</p></div>`;
    return;
  }
  state.activities.forEach((a) => listEl.appendChild(buildActivityCard(a, true)));
}

function buildActivityCard(a, withActions) {
  const card = el("div", "activity-card");
  const dist = a.distance ? `${Number(a.distance).toFixed(2)} mi` : null;
  const dur = a.duration ? formatDuration(a.duration) : null;
  const pace = a.pace ? formatPace(a.pace) : null;
  const weight = a.packWeight ? `${a.packWeight} lb pack` : null;

  card.innerHTML = `
    <div class="ac-info">
      <div class="ac-title">${a.title || "Untitled Ruck"}</div>
      <div class="ac-meta">${formatDate(a.startedAt || a.createdAt)}${a.notes ? ` · ${a.notes.slice(0, 60)}${a.notes.length > 60 ? "…" : ""}` : ""}</div>
    </div>
    <div class="ac-chips">
      ${dist ? `<span class="chip chip-accent">${dist}</span>` : ""}
      ${dur ? `<span class="chip">${dur}</span>` : ""}
      ${pace ? `<span class="chip">${pace}</span>` : ""}
      ${weight ? `<span class="chip">${weight}</span>` : ""}
    </div>
    ${withActions ? `<div class="ac-actions">
      <button class="icon-btn edit-btn" title="Edit">✏️</button>
      <button class="icon-btn danger delete-btn" title="Delete">🗑️</button>
    </div>` : ""}
  `;

  if (withActions) {
    $(".edit-btn", card).addEventListener("click", () => openEditModal(a));
    $(".delete-btn", card).addEventListener("click", () => confirmDelete(a));
  }
  return card;
}

// ─── Add/Edit Activity Modal ──────────────────────────────────────────────────
function openAddModal() {
  state.editingActivity = null;
  resetActivityForm();
  $("#modal-title").textContent = "Log New Ruck";
  $("#activity-modal").classList.add("open");
}

function openEditModal(activity) {
  state.editingActivity = activity;
  populateActivityForm(activity);
  $("#modal-title").textContent = "Edit Ruck";
  $("#activity-modal").classList.add("open");
}

function closeActivityModal() {
  $("#activity-modal").classList.remove("open");
  state.editingActivity = null;
}

function resetActivityForm() {
  const form = $("#form-activity");
  form.reset();
  $$(".form-error", form).forEach((e) => e.classList.remove("show"));
  hideAlert($("#activity-alert"));
  // Default startedAt to now
  const now = new Date();
  now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
  $("#act-started-at").value = now.toISOString().slice(0, 16);
}

function populateActivityForm(a) {
  resetActivityForm();
  $("#act-title").value = a.title || "";
  $("#act-notes").value = a.notes || "";
  $("#act-distance").value = a.distance ?? "";
  $("#act-duration").value = a.duration ? Math.round(a.duration / 60) : "";
  $("#act-pack-weight").value = a.packWeight ?? "";
  if (a.startedAt) {
    const dt = new Date(a.startedAt);
    dt.setMinutes(dt.getMinutes() - dt.getTimezoneOffset());
    $("#act-started-at").value = dt.toISOString().slice(0, 16);
  }
}

function buildActivityPayload() {
  const title = $("#act-title").value.trim();
  const notes = $("#act-notes").value.trim();
  const distance = parseFloat($("#act-distance").value) || null;
  const durationMin = parseFloat($("#act-duration").value) || null;
  const packWeight = parseFloat($("#act-pack-weight").value) || null;
  const startedAt = $("#act-started-at").value;

  const errors = {};
  if (!title) errors.title = "Title is required.";
  if (distance !== null && distance <= 0) errors.distance = "Distance must be positive.";
  if (durationMin !== null && durationMin <= 0) errors.duration = "Duration must be positive.";
  if (!startedAt) errors.startedAt = "Date/time is required.";

  if (Object.keys(errors).length > 0) return { errors };

  const durationSeconds = durationMin ? durationMin * 60 : null;
  const pace = (distance && durationMin) ? durationMin / distance : null;
  const endedAt = startedAt
    ? new Date(new Date(startedAt).getTime() + (durationSeconds || 0) * 1000).toISOString()
    : null;

  return {
    payload: {
      title,
      notes: notes || null,
      distance,
      duration: durationSeconds,
      pace,
      packWeight,
      startedAt: new Date(startedAt).toISOString(),
      endedAt,
    },
  };
}

function initActivityModal() {
  $("#btn-add-activity").addEventListener("click", openAddModal);
  $("#btn-modal-cancel").addEventListener("click", closeActivityModal);
  $("#activity-modal").addEventListener("click", (e) => {
    if (e.target === $("#activity-modal")) closeActivityModal();
  });

  $("#form-activity").addEventListener("submit", async (e) => {
    e.preventDefault();
    const alertEl = $("#activity-alert");
    const btn = $("#btn-modal-save");
    hideAlert(alertEl);

    const result = buildActivityPayload();
    if (result.errors) {
      const firstMsg = Object.values(result.errors)[0];
      showAlert(alertEl, firstMsg);
      return;
    }

    try {
      setLoading(btn, true);
      if (state.editingActivity) {
        const updated = await api.updateActivity(state.editingActivity.id, result.payload);
        const idx = state.activities.findIndex((a) => a.id === state.editingActivity.id);
        if (idx !== -1) state.activities[idx] = updated;
        showAlert(alertEl, "Activity updated!", "success");
      } else {
        const created = await api.createActivity(result.payload);
        state.activities.unshift(created);
        showAlert(alertEl, "Activity logged!", "success");
      }
      renderActivityList();
      setTimeout(closeActivityModal, 800);
    } catch (err) {
      showAlert(alertEl, err.message || "Failed to save activity.");
    } finally {
      setLoading(btn, false);
    }
  });
}

// ─── Delete ───────────────────────────────────────────────────────────────────
function confirmDelete(activity) {
  state.deletingActivity = activity;
  $("#delete-confirm-name").textContent = activity.title || "this ruck";
  $("#delete-modal").classList.add("open");
}

function initDeleteModal() {
  $("#btn-delete-cancel").addEventListener("click", () => {
    $("#delete-modal").classList.remove("open");
  });
  $("#btn-delete-confirm").addEventListener("click", async () => {
    const btn = $("#btn-delete-confirm");
    try {
      setLoading(btn, true);
      await api.deleteActivity(state.deletingActivity.id);
      state.activities = state.activities.filter((a) => a.id !== state.deletingActivity.id);
      renderActivityList();
      $("#delete-modal").classList.remove("open");
    } catch (err) {
      alert("Delete failed: " + err.message);
    } finally {
      setLoading(btn, false);
    }
  });
}

// ─── Boot ─────────────────────────────────────────────────────────────────────
document.addEventListener("DOMContentLoaded", () => {
  initAuth();
  initActivityModal();
  initDeleteModal();

  $$("header nav button[data-page]").forEach((btn) => {
    btn.addEventListener("click", () => navigate(btn.dataset.page));
  });

  $("#link-to-signup").addEventListener("click", (e) => { e.preventDefault(); navigate("signup"); });
  $("#link-to-signin").addEventListener("click", (e) => { e.preventDefault(); navigate("login"); });

  // If we already have a token, go straight to dashboard
  if (api.getToken()) {
    navigate("dashboard");
  } else {
    navigate("login");
  }
});

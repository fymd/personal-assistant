(() => {
  const STORAGE_TOKEN = "pa_web_token";
  const STORAGE_PHONE = "pa_web_phone";
  const STORAGE_API = "pa_web_api_base";

  const $ = (id) => document.getElementById(id);

  const state = {
    token: localStorage.getItem(STORAGE_TOKEN) || "",
    phone: localStorage.getItem(STORAGE_PHONE) || "",
    apiBase: localStorage.getItem(STORAGE_API) || "",
    filter: "all",
  };

  function apiBase() {
    if (state.apiBase) return state.apiBase.replace(/\/$/, "");
    // 同源（后端挂载静态资源时）
    if (location.port === "8080" || location.pathname.startsWith("/")) {
      return "";
    }
    return "http://127.0.0.1:8080";
  }

  async function api(path, options = {}) {
    const headers = {
      "Content-Type": "application/json",
      ...(options.headers || {}),
    };
    if (state.token) headers.Authorization = `Bearer ${state.token}`;
    const res = await fetch(`${apiBase()}${path}`, {
      ...options,
      headers,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok || (data.code !== undefined && data.code !== 0)) {
      const msg = data.message || res.statusText || "请求失败";
      throw new Error(msg);
    }
    return data;
  }

  function showLogin() {
    $("view-login").classList.remove("hidden");
    $("view-main").classList.add("hidden");
  }

  function showMain() {
    $("view-login").classList.add("hidden");
    $("view-main").classList.remove("hidden");
    $("user-phone").textContent = state.phone || "";
    loadMemos();
    loadMembership();
  }

  function setLoginMsg(text, ok = false) {
    const el = $("login-msg");
    el.textContent = text || "";
    el.className = "msg" + (ok ? " ok" : "");
  }

  function setListMsg(text) {
    $("list-msg").textContent = text || "";
  }

  async function sendCode() {
    const phone = $("phone").value.trim();
    if (!phone) return setLoginMsg("请输入手机号");
    $("btn-send").disabled = true;
    try {
      await api("/api/v1/auth/send-code", {
        method: "POST",
        body: JSON.stringify({ phone }),
      });
      setLoginMsg("验证码已发送（mock 请看后端日志）", true);
    } catch (e) {
      setLoginMsg(e.message);
    } finally {
      $("btn-send").disabled = false;
    }
  }

  async function login() {
    const phone = $("phone").value.trim();
    const code = $("code").value.trim();
    if (!phone || !code) return setLoginMsg("请输入手机号和验证码");
    $("btn-login").disabled = true;
    try {
      const res = await api("/api/v1/auth/login", {
        method: "POST",
        body: JSON.stringify({ phone, code }),
      });
      state.token = res.data.token;
      state.phone = res.data.phone || phone;
      localStorage.setItem(STORAGE_TOKEN, state.token);
      localStorage.setItem(STORAGE_PHONE, state.phone);
      setLoginMsg("登录成功", true);
      showMain();
    } catch (e) {
      setLoginMsg(e.message);
    } finally {
      $("btn-login").disabled = false;
    }
  }

  function logout() {
    state.token = "";
    state.phone = "";
    localStorage.removeItem(STORAGE_TOKEN);
    localStorage.removeItem(STORAGE_PHONE);
    showLogin();
  }

  async function loadMembership() {
    try {
      const res = await api("/api/v1/membership");
      const st = res.data || {};
      const badge = $("member-badge");
      const tier = st.tier || "free";
      badge.textContent = st.active ? `${tier} · 有效` : tier;
      badge.className = "badge" + (st.active ? " pro" : "");
    } catch {
      $("member-badge").textContent = "";
    }
  }

  async function loadMemos() {
    setListMsg("加载中…");
    try {
      const q = state.filter === "all" ? "" : `?filter=${state.filter}`;
      const res = await api(`/api/v1/memos${q}`);
      const list = res.data || [];
      renderMemos(list);
      setListMsg(list.length ? "" : "暂无备忘录");
    } catch (e) {
      if (String(e.message).toLowerCase().includes("unauthorized")) {
        logout();
        setLoginMsg("登录已过期，请重新登录");
        return;
      }
      setListMsg(e.message);
    }
  }

  function renderMemos(list) {
    const ul = $("memo-list");
    ul.innerHTML = "";
    for (const m of list) {
      const li = document.createElement("li");
      li.className = "memo-item" + (m.completed ? " done" : "");
      const updated = (m.updated_at || m.created_at || "").toString().slice(0, 19).replace("T", " ");
      li.innerHTML = `
        <input type="checkbox" class="check" ${m.completed ? "checked" : ""} data-id="${m.id}" />
        <div class="body">
          <div class="title"></div>
          <div class="meta"></div>
          <div class="content"></div>
        </div>`;
      li.querySelector(".title").textContent = m.title || "(无标题)";
      li.querySelector(".meta").textContent =
        [m.tag, updated, m.starred ? "★" : ""].filter(Boolean).join(" · ");
      li.querySelector(".content").textContent = m.content || "";
      li.querySelector(".check").addEventListener("change", () => toggleComplete(m.id));
      ul.appendChild(li);
    }
  }

  async function toggleComplete(id) {
    try {
      await api(`/api/v1/memos/${id}/complete`, { method: "PATCH" });
      loadMemos();
    } catch (e) {
      setListMsg(e.message);
    }
  }

  async function createMemo(ev) {
    ev.preventDefault();
    const title = $("new-title").value.trim();
    if (!title) return;
    try {
      await api("/api/v1/memos", {
        method: "POST",
        body: JSON.stringify({ title, content: "", tag: "" }),
      });
      $("new-title").value = "";
      loadMemos();
    } catch (e) {
      setListMsg(e.message);
    }
  }

  // events
  $("btn-send").addEventListener("click", sendCode);
  $("btn-login").addEventListener("click", login);
  $("btn-logout").addEventListener("click", logout);
  $("btn-refresh").addEventListener("click", loadMemos);
  $("form-create").addEventListener("submit", createMemo);

  document.querySelectorAll(".chip").forEach((btn) => {
    btn.addEventListener("click", () => {
      document.querySelectorAll(".chip").forEach((b) => b.classList.remove("active"));
      btn.classList.add("active");
      state.filter = btn.dataset.filter || "all";
      loadMemos();
    });
  });

  $("btn-settings").addEventListener("click", () => {
    $("api-base").value = state.apiBase || apiBase() || "http://127.0.0.1:8080";
    $("dlg-settings").showModal();
  });
  $("dlg-settings").querySelector("form").addEventListener("submit", () => {
    state.apiBase = $("api-base").value.trim();
    localStorage.setItem(STORAGE_API, state.apiBase);
  });

  // boot
  if (state.token) showMain();
  else showLogin();
})();

# FrameworkPlus

**FrameworkPlus** is a lightweight, security-oriented system framework for Roblox developers.
It provides a structured, professional way to load, manage, and protect client/server systems using controlled handshakes and a centralized runtime.

Designed for **modular systems**, **clean architecture**, and **anti-abuse protection**.

---

## ✨ Features

* 🔐 **Secure system startup**

  * Systems can only be started through FrameworkPlus
  * Optional handshake validation to block direct `require()` abuse

* 🧠 **System-based architecture**

  * Each system is self-contained
  * Clear separation of logic, configuration, and effects

* 🎮 **Client / Server aware**

  * Systems declare where they are allowed to run
  * Framework enforces execution context

* 📦 **Wally-ready package**

  * Easy install via Wally
  * Versioned and dependency-safe

* 🧩 **Optional modules**

  * Systems may include optional sub-modules (effects, helpers, etc.)
  * No boilerplate required

---

## 📁 Project Structure

```text
ReplicatedStorage
└─ FrameworkPlus (ModuleScript)
   ├─ Runtime (ModuleScript)
   ├─ Guard (ModuleScript)
   ├─ Settings (ModuleScript)
   ├─ Systems (Folder)
   │  └─ ExampleSystem (ModuleScript)
   │     └─ Config (ModuleScript)
   ├─ Utils (ModuleScript)
   ├─ Reference (ModuleScript)
   ├─ VERSION (ModuleScript)
   └─ Remotes (Folder)
```

---

## 🚀 Installation (Wally)

### 1️⃣ Install Wally (once)

```bash
cargo install wally
```

or using **Foreman**:

```bash
foreman add wally
```

---

### 2️⃣ Add to `wally.toml`

```toml
[dependencies]
frameworkplus = "nionx01/frameworkplus@0.0.1"
```

Then install:

```bash
wally install
```

---

## 🧩 Creating a System

Each system **must** contain a `Config.lua`.

### Example: `Config.lua`

```lua
local Config = {}

Config.SystemName = "FirstPersonCameraSystem"
Config.RunContext = "Client"

return Config
```

---

### Example: `init.lua`

```lua
local System = {}

function System.Start(player, camera, token)
	-- your system logic
	return true
end

function System.Stop()
	-- cleanup
end

return System
```

> ⚠️ Systems **cannot** be started directly.
> They must be started via FrameworkPlus.

---

## ▶ Starting a System (Client)

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FrameworkPlus = require(ReplicatedStorage:WaitForChild("FrameworkPlus"))

FrameworkPlus:ClientStartSystem("FirstPersonCameraSystem", {
	Player = Players.LocalPlayer,
	Camera = workspace.CurrentCamera,
})
```

FrameworkPlus automatically:

* Validates execution context
* Applies security rules
* Handles handshake logic (if enabled)

---

## 🔐 Security Model (Overview)

* Systems **cannot be started directly**
* Tokens are issued internally by FrameworkPlus
* Optional handshake enforcement
* Centralized runtime control

This prevents:

* Direct `require()` abuse
* Unauthorized system startup
* Accidental double-initialization

---

## 📜 License

FrameworkPlus is licensed under the **Mozilla Public License 2.0 (MPL-2.0)**.

See [`LICENSE`](./LICENSE) for details.

---

## ❤️ Attribution (Optional but Appreciated)

FrameworkPlus is free and open-source.

Attribution is **appreciated but not required**.

If you use FrameworkPlus in your experience or application, you are kindly asked to do **one** of the following:

1. Keep the original FrameworkPlus attribution intact, **or**
2. Credit FrameworkPlus in your experience description or a DevForum post linked from it

This request is **non-binding** and does not add restrictions beyond the MPL-2.0 license.

---

## 📦 Versioning

Current version: **v0.0.1**

FrameworkPlus follows semantic versioning.

---

## 🔗 Links

* GitHub: *(add link here)*
* Wally package: *(add link here)*
* DevForum post: *(optional)*

---

## 👤 Author

**FrameworkPlus**
Created by **nionx01**
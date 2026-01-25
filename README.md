# 🚀 Conduit Manager for macOS

A **professional, lightweight, and intelligent** management tool for deploying **Psiphon Conduit** nodes on **macOS** using **Docker**.  
Built to help people access the **open internet reliably**, with **zero configuration hassle**.

---

## 🔧 Prerequisites

Before installation, make sure **Docker Desktop for macOS** is installed and running.

- Download Docker Desktop from the official website:  
  https://www.docker.com/products/docker-desktop/
- After installation, **open Docker Desktop** and ensure it is running.

> ⚠️ This tool deploys Psiphon Conduit **inside a Docker container**, so Docker Desktop is required.

---

## 📦 Quick Install

Open **Terminal** and run the following commands:

```bash
# 1. Download the script
curl -L -o conduit-mac.sh https://raw.githubusercontent.com/polamgh/conduit-manager-mac/main/conduit-mac.sh

# 2. Make it executable
chmod +x conduit-mac.sh

# 3. Run it
./conduit-mac.sh
```

---

## ✨ Features

- 🍏 **macOS-Optimized UI**  
  Clean, dashboard-style interface designed specifically for the macOS Terminal.

- 🧠 **Smart Logic**  
  Automatically detects whether the service should be installed, started, or restarted.

- 📊 **Live Dashboard**  
  Real-time monitoring of **CPU**, **RAM**, **connected users**, and **traffic usage**.

- 🛡️ **Safety Checks**  
  Verifies **Docker Desktop** status before execution to prevent runtime errors.

- ⚙️ **Easy Reconfiguration**  
  Instantly change **Max Clients** or **Bandwidth limits** via the interactive menu.

- 🚀 **Zero Extra Dependencies**  
  Works out-of-the-box using standard macOS tools and Docker Desktop.

---

## 📋 Menu Options

| Option | Function |
|------|---------|
| **1. Start / Restart** | Smart install (if new), start (if stopped), or restart (if running). |
| **2. Stop Service** | Safely stops the Conduit container. |
| **3. Live Dashboard** | Displays real-time resource usage and traffic statistics (auto-refresh). |
| **4. View Raw Logs** | Streams raw Docker logs for debugging and inspection. |
| **5. Reconfigure** | Reinstalls the container to update client or bandwidth settings. |

---

## ⚙️ Configuration Guide

| Setting | Default | Description |
|-------|---------|-------------|
| **Max Clients** | 200 | Maximum number of concurrent users. |
| **Bandwidth** | 5 Mbps | Speed limit per user connection. |

---

## 💻 Hardware Recommendations (Mac)

- **Apple Silicon (M1 / M2 / M3)**  
  Easily handles **400–800+ clients** with excellent efficiency.

- **Intel-based Macs**  
  Recommended to limit between **200–400 clients** to manage heat and performance.

---

<div dir="rtl">

# 🇮🇷 مدیریت کاندوییت (نسخه macOS)

یک ابزار **حرفه‌ای، سبک و هوشمند** برای مدیریت و راه‌اندازی نودهای **Psiphon Conduit** روی سیستم‌عامل **macOS** با استفاده از **Docker**.

---

## 🔧 پیش‌نیازها

قبل از نصب، مطمئن شوید که **Docker Desktop برای macOS** روی سیستم شما نصب و اجرا شده است.

- دانلود Docker Desktop از سایت رسمی:  
  https://www.docker.com/products/docker-desktop/
- پس از نصب، حتماً **Docker Desktop را اجرا کنید**.

> ⚠️ این ابزار نود سایفون کاندوییت را **داخل Docker** اجرا می‌کند، بنابراین وجود Docker Desktop الزامی است.

---

## 📦 نصب سریع

```bash
# ۱. دانلود اسکریپت
curl -L -o conduit-mac.sh https://raw.githubusercontent.com/polamgh/conduit-manager-mac/main/conduit-mac.sh

# ۲. دادن دسترسی اجرا
chmod +x conduit-mac.sh

# ۳. اجرا
./conduit-mac.sh
```

---

## ✨ ویژگی‌ها

- رابط کاربری مخصوص مک با داشبورد خوانا  
- تشخیص هوشمند وضعیت سرویس  
- نمایش زنده مصرف منابع و کاربران  
- بررسی فعال بودن Docker Desktop  
- تغییر سریع تنظیمات کاربران و سرعت  
- بدون پیش‌نیاز اضافی

---

## ⚙️ تنظیمات پیش‌فرض

| تنظیم | مقدار پیش‌فرض |
|------|---------------|
| Max Clients | 200 |
| Bandwidth | 5 Mbps |

---

## 💻 توصیه سخت‌افزاری

- تراشه‌های اپل: تا ۸۰۰ کاربر یا بیشتر  
- مک‌های اینتلی: ۲۰۰ تا ۴۰۰ کاربر

</div>


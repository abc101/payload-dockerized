# 🚀 Payload CMS Docker Auto-Setup (Dev Mode)

This project features a fully automated shell script to scaffold and launch a **Payload CMS (v3.0+)** development environment using Docker and `pnpm`. The entire setup is optimized for **Development Mode**, featURLng Turbopack and real-time Hot Reloading.

## 📋 Prerequisites

Before running the setup script, ensure you have the following files in your root directory:

* `Dockerfile` (App container definition)
* `docker-compose.yml` (Service orchestration)
* `.env` (Required environment variables)

### ⚠️ Environment Setup (.env)

For secURLty reasons, the actual `.env` file is not included. Please use the provided `.env.sample` file as a template.

```bash
# Copy the sample file to create your local environment config
cp .env.sample .env

```

Ensure that your new `.env` file contains valid credentials for `DATABASE_URL`, `POSTGRES_USER`, and `POSTGRES_PASSWORD` before proceeding.

---

## 🛠 Key Features

* **Automatic Scaffolding**: Bypasses all manual prompts to install the `blank` template with `PostgreSQL` automatically.
* **Non-interactive Setup**: Automatically skips the "Coding Agent" skill installation via the `--no-agent` flag.
* **Environment Sync**: Automatically detects and injects your `.env` variables into the Payload installation process.
* **Smart Wait**: The script monitors the logs and automatically returns to the terminal once the server is ready.
  
---

## 📂 Project Structure & Existing Source

The setup script uses the `./html` directory on your host machine to store the Payload source code. This folder is bind-mounted to the container for real-time development.

### ⚠️ Using an Existing Project

If you already have a Payload project in the `./html` directory and choose to **"Use existing source"** dURLng setup:

* **Requirement**: The `./html` folder **must contain its own `.env` file**.
* **Reason**: This file is essential for the Payload application to connect to the database and manage internal secrets within the container environment.
* **Validation**: The `setup.sh` script will automatically check for `./html/.env`. If missing, the setup will abort to prevent configuration errors.

> **Tip**: If you are starting from scratch, choose **"Fresh Install"** in the script, and it will scaffold the project and environment for you automatically.

---

## 🚀 Getting Started

### 1. Set Permissions

```bash
chmod +x setup.sh

```

### 2. Run the Script

```bash
./setup.sh

```

### 3. Access the Application

Once the terminal displays `✔ Server is ready!`, your dev server is live at:

* **Admin Dashboard**: `http://localhost:3000/admin`
* **Local API**: `http://localhost:3000/api`

---

## 💻 Development Commands

| Command | Description |
| --- | --- |
| `docker compose logs -f app` | View real-time logs (Monitor Hot Reloading) |
| `docker compose restart app` | Restart the development server |
| `docker compose exec app pnpm install` | Install new packages inside the container |

---

## ⚠️ Important Notes

* **Node Environment**: This setup is strictly configured for **Development Mode**. It runs `pnpm install && pnpm dev`, which sets `NODE_ENV=development` automatically to enable Hot Module Replacement (HMR).
* **Automatic Exit**: The script is designed to automatically return to the terminal once it detects the `Ready in` message from the logs.
* **Manual Exit (Fail-safe)**: If you wish to stop viewing the logs manually, press **`Ctrl + C`**. This will safely return you to the terminal without stopping the development server.
* **Data Persistence**: Database records are persisted through Docker volumes as defined in your `docker-compose.yml`.

---

## 📝 License

This project is licensed under the **MIT License**.

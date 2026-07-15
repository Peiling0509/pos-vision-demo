# 🛒 Smart POS Vision: AI-Enhanced Inventory Management

<div align="center">
  <img src="docs/thumbnail.jpg" alt="POS NOW PRO Thumbnail" width="100%">
</div>

<br>

<div align="center">
  <!-- Tech Stack Badges -->
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white" />
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" />
  <img src="https://img.shields.io/badge/Python_YOLO-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/OpenAI_RAG-412991?style=for-the-badge&logo=openai&logoColor=white" />
</div>

<br>

> A Point of Sale (POS) ecosystem designed to modernize retail inventory management. This project bridges traditional operations with AI by combining standard SKU barcode scanning with computer vision (YOLO) to instantly quantify shelf stock, alongside a dynamic RAG-powered SQL Agent for instant database querying.

## ✨ Key Features

*   **Neumorphic UI Experience:** A fully custom, highly responsive Flutter mobile interface featuring fluid animations and localized stateful loading indicators.
*   **Hybrid Workflow (SKU + Vision):** Pairs qualitative SKU barcode scanning with quantitative YOLO-based computer vision to ensure absolute database integrity.
*   **Structured Data RAG Assistant:** An integrated LangChain SQL Agent that dynamically queries the live MySQL POS database, providing real-time, data-driven responses without AI hallucinations.
*   **Comprehensive Admin Dashboard:** Built with Filament PHP for real-time inventory tracking, pricing, and product categorization.

---

## 🏗️ System Architecture

Smart POS Vision operates on a decoupled, microservice-inspired architecture:

1.  **Frontend (Mobile):** Built with **Flutter & GetX** for reactive state management. Handles the Neumorphic UI and camera interactions.
2.  **Core API (Backend):** A **Laravel** framework enforcing strict data validation, managing SKU-based inventory transactions, and hosting the Filament admin panel.
3.  **Vision & AI Engine (Microservice):** A **FastAPI** Python server that runs the YOLO computer vision model for image processing, and orchestrates the LangChain SQL Agent for intelligent LLM chat.

---

## 🧠 Engineering Challenges & Solutions

Building a hybrid AI/traditional software system presented unique challenges. Here is how I solved them:

### 1. Combating AI Hallucinations in the Database
**Problem:** Relying solely on AI vision for inventory updates resulted in "ghost records" (e.g., creating a new item called `Dutch Lady` instead of updating the existing `Dutch Lady 1L` SKU). 
**Solution:** Architected a strict **"SKU-First" Hybrid Workflow**. The system forces the user to scan the definitive SKU barcode first, using the AI camera strictly as a quantitative counter bound to that specific SKU, entirely eliminating duplicate and missing records.

### 2. Inconsistent Object Detection in Real-World Scenarios
**Problem:** The initial YOLO model occasionally struggled to recognize products under varying real-world store conditions, such as poor lighting or unusual camera angles.
**Solution:** Implemented extensive **Data Augmentation** techniques. By synthetically expanding the training dataset with varied brightness levels, rotations, scaling, and perspectives, the model's robustness and inference accuracy significantly improved across diverse environments.

### 3. Managing UI State During Asynchronous Operations
**Problem:** Users were prematurely navigating away from the vision confirmation screen before the Laravel backend had fully synced the new inventory quantities.
**Solution:** Refactored the result list into independent `StatefulWidgets`. This provided localized, dynamic loading indicators for each detected item, visually locking the action until a successful `200 OK` response was received from the server.

---

## 📸 Gallery & Demo

*(Include GIFs or screenshots of the app in action here)*

| Mobile Dashboard | AI Vision Counter | RAG Chat Assistant |
| :---: | :---: | :---: |
| <img src="docs/frontend_1.jpg" width="250"> | <img src="docs/frontend_2.jpg" width="250"> | <img src="docs/frontend_3.jpg" width="250"> |

| Web Admin Panel | Web Inventory Details |
| :---: | :---: |
| <img src="docs/backend_1.jpg" width="400"> | <img src="docs/backend_2.jpg" width="400"> |

**🎥 [Watch the full Demo Video here](docs/demo-video.mp4)**

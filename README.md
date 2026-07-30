# 🛒 Smart POS Vision: AI-Enhanced Inventory Management (Demo)

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

> Smart POS Vision is an end-to-end commercial retail solution that seamlessly merges traditional Point of Sale workflows with cutting-edge Artificial Intelligence. Built with a stunning Neumorphic Flutter UI, it leverages YOLOv8 computer vision for automated stock counting and a LangGraph-powered Agent for real-time, stateful data insights.

## ✨ Key Features

*   **📱 Neumorphic UI Experience:** A fully custom, highly responsive Flutter mobile interface featuring fluid animations and localized stateful loading indicators.
*   **📸 Hybrid AI Vision Engine:** Architected a strict "SKU-First" workflow that pairs exact barcode scanning with YOLO-based computer vision quantification—guaranteeing 100% database integrity and eliminating AI hallucinations (ghost records).
*   **🧠 Real-Time AI Retail Agent:** Engineered a LangGraph SQL Agent featuring ChromaDB RAG. It dynamically queries live MySQL data to answer complex inventory questions, delivering a ChatGPT-like "typing effect" via highly optimized Server-Sent Events (SSE) streaming.
*   **🏢 Enterprise-Grade Admin Ecosystem:** Backed by a robust Laravel API and a comprehensive Filament PHP dashboard for real-time inventory tracking, pricing, and product knowledge management.

---

## 🏗️ Microservice Architecture

The ecosystem operates on a decoupled, highly scalable architecture:

1.  **Frontend (Mobile):** **Flutter & GetX** — Handles reactive state management, camera interactions, and SSE stream parsing.
2.  **Core Backend (API & Admin):** **Laravel & Filament PHP** — Acts as the secure gateway, enforcing strict data validation and managing SKU transactions.
3.  **AI Microservice (Vision & LLM):** **Python & FastAPI** — Runs the robust, data-augmented YOLOv8 model and orchestrates the LangGraph AI workflows.

---

## 🏗️ System Architecture

Smart POS Vision follows an end-to-end AI application architecture combining computer vision, LLM agents, RAG pipelines, and full-stack services.

![Smart POS Vision AI-Enhanced Inventory Management Architecture](docs/architecture.png)


## 📸 Gallery & Demo

Dashboard | AI Vision Counter | RAG Chat Assistant (Streaming) |
| :---: | :---: | :---: |
<img src="https://github.com/user-attachments/assets/7c60fa0b-a327-489d-9fc8-67fb12510a10" height="500"/> | <img src="https://github.com/user-attachments/assets/7c2ae3db-47be-49c0-9c18-d9f15987eeb2" height="500"/> | <img src="https://github.com/user-attachments/assets/3ff9dcba-b8c3-445e-bab9-0b0b67a3ea5f" height="500"/> |

| Product Knowledge | Web Inventory Details |
| :---: | :---: |
| <img src="https://github.com/user-attachments/assets/206880a6-d6b6-47e7-9320-428ab7e21a40" width="450"/> | <img src="https://github.com/user-attachments/assets/7502c587-33ed-4425-a835-af9948ad405e" width="450"/> |


**🎥 [Watch the full Demo Video here](docs/demo-video.mp4)**

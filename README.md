# Welcome to Javelin 👋
> Javelin is a fire-and-forget .NET event streaming API that captures UI, API, and database events — publishing them to Kafka topics for any downstream service to consume.

## Overview
 
EventStream API is a lightweight observability backbone designed to capture events across your entire stack — from a user clicking a button, to a slow database query — and stream them into Kafka topics. Any microservice can produce events with near-zero overhead, and any consumer can subscribe independently without coupling.

## High Level Architecture
<img width="1149" height="483" alt="image" src="https://github.com/user-attachments/assets/644f13c9-8b36-4659-98bc-d1fce8c5d4e3" />

The Kafka-Based .NET Core Application is a comprehensive project that leverages the power of Apache Kafka for messaging and .NET Core for building scalable and efficient applications. The API follows a fire-and-forget pattern, ensuring minimal impact on application performance. Events are accepted, validated, enriched with contextual metadata, and immediately published to Kafka topics. Consumer applications can independently subscribe to relevant topics and process event streams in real-time without creating dependencies between systems.

 
## 🚀 Consumer Use Cases
 
### UI Events
 
- **Button & interaction analytics** — count clicks on specific CTAs, detect rage-clicks, and find dead zones across your interface
- **Funnel & drop-off analysis** — pinpoint where users abandon checkout or the pricing page; correlate events to understand the exact reason
- **Heatmaps & session replay** — feed scroll and click streams into heatmap tools to visualise user interaction across every page
- **Feature adoption tracking** — measure rollout adoption by counting interactions with new UI elements across user segments
- **Live user presence & DAU** — derive active user counts from `load` and `render` events to power real-time dashboards
- **A/B test measurement** — track `accept` and `submit` rates per variant without instrumenting each test separately
### API Events
 
- **Error rate monitoring** — aggregate 4xx/5xx responses and trigger alerts on spikes in real time
- **Latency & SLA tracking** — compute P95/P99 response times per endpoint and verify SLA compliance
- **Throughput visibility** — measure request volumes across services to support capacity planning
- **Security & anomaly detection** — flag unusual request bursts, detect brute-force patterns from repeated failures, and audit sensitive routes
- **Dependency mapping** — track which services call which endpoints to generate live service dependency graphs
### Database Events
 
- **Slow query detection** — surface long-running `SELECT` and `INSERT` operations and alert on query budget overruns
- **N+1 pattern identification** — detect query storms caused by ORM misuse across request cycles
- **Write auditing & compliance** — log every `UPDATE` and `DELETE` with metadata for security audits and regulatory trails
- **Cost attribution** — tie expensive queries back to specific API routes and user actions to find true infrastructure cost drivers
- **Table-level activity monitoring** — track read/write ratios per table to inform indexing and partitioning strategies
---

## 🛠️ Tech Stack
* **.NET Core**: The application is built on top of .NET Core, utilizing the framework's performance, scalability, and reliability features.
* **Apache Kafka**: The application leverages Apache Kafka for messaging, enabling high-throughput and fault-tolerant data processing.
* **JSON Serialization**: The application uses JSON serialization for data exchange, providing a lightweight and efficient format for data transmission.
* **Logging Frameworks**: The application utilizes logging frameworks, such as Serilog, for robust logging and monitoring capabilities.

## 📦 Installation
To get started with the Kafka-Based .NET Core Application, follow these steps:
1. **Prerequisites**: Ensure that you have Docker Desktop installed on your system.
2. **Clone the Repository**: Clone the repository to your local machine using Git.
3. Start up Javelin by running the following cmd in your preferred terminal

```bash
git clone https://github.com/KeanuKapank/Javelin.git
docker compose up -d
```

## 📸 Screenshots
<img width="2542" height="1274" alt="image" src="https://github.com/user-attachments/assets/602292f3-a4cf-4a4e-8829-5bdc8cc9610f" />


## 🤝 Contributing
To contribute to the Kafka-Based .NET Core Application, please follow these steps:
1. **Fork the Repository**: Fork the repository to your local machine using Git.
2. **Create a Branch**: Create a new branch for your feature or bug fix.
3. **Make Changes**: Make changes to the code, following the project's coding standards and guidelines.
4. **Commit Changes**: Commit your changes using a descriptive commit message.
5. **Create a Pull Request**: Create a pull request to merge your branch into the main repository.

## 📝 License
The Kafka-Based .NET Core Application is licensed under the Unlicensed License.

## 📬 Contact
For more information or to report issues, please contact us at [support@example.com](mailto:keanukapank06@gmail.com).


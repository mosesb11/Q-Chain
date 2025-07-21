# ⚛️ Q-Chain

**Q-Chain** is a decentralized marketplace for quantum computing power. It enables quantum hardware providers to list their computational resources and allows users to book and run quantum jobs in a secure, transparent, and token-integrated environment.

---

## 🚀 Features

* **Quantum Resource Listing**
  Providers can register quantum resources with defined computational power and pricing.

* **Secure Booking & Payments**
  Users can book available compute units using STX and get real-time usage billed.

* **Balance Management**
  Users can deposit and withdraw funds, tracked securely on-chain.

* **Demand-Aware Pricing**
  Prices are dynamically adjusted based on a global demand factor.

* **Job Lifecycle Support**
  Users can queue jobs, and oracles can update job statuses like `queued`, `processing`, or `complete`.

* **Oracle Support for Real-Time Updates**
  Trusted off-chain oracles can modify global variables like job status and demand factor.

---

## 📦 Contract Components

| Component            | Description                                                        |
| -------------------- | ------------------------------------------------------------------ |
| `quantum-resources`  | A map storing listed compute resources by provider and resource ID |
| `user-balances`      | Tracks STX deposits per user                                       |
| `next-resource-id`   | Monotonically increasing ID tracker for resources                  |
| `job-status`         | Stores the current status of a user's job                          |
| `demand-factor`      | Global variable influencing pricing based on demand                |
| `total-market-value` | Accumulates the total value of listed compute power                |

---

## 🔐 Error Codes

| Code   | Meaning                         |
| ------ | ------------------------------- |
| `u100` | Unauthorized (owner only)       |
| `u101` | Resource not found              |
| `u102` | Resource already listed         |
| `u103` | Insufficient user balance       |
| `u104` | Insufficient funds for withdraw |
| `u105` | Invalid input data              |

---

## 🔧 Example Flows

### ➕ Listing a Resource

```clarity
(list-resource u200 u50)
```

Lists a resource with 200 units of compute power at 50 STX/unit.

### 💰 Depositing Funds

```clarity
(deposit u500)
```

Deposits 500 STX to the caller's balance.

### 🧠 Booking Compute

```clarity
(book-resource 'provider-principal u2 u1)
```

Books 1 unit from provider's resource with ID `2`.

### 📈 Updating Demand Factor

```clarity
(update-demand-factor u150)
```

Sets demand factor to 150% (only callable by contract owner/oracle).

---

## 📜 Deployment Notes

* Contract owner is initialized as the deployer (`tx-sender`).
* All STX transactions are routed through the contract itself (`as-contract tx-sender`).
* Job queueing and lifecycle updates rely on off-chain infrastructure (e.g., oracles).

---

## 🧠 Use Cases

* Quantum computing time-sharing
* Scientific computation networks
* Decentralized AI model training (on quantum backends)
* Quantum-as-a-Service (QaaS) infrastructure layer

---

## 📄 License

MIT License

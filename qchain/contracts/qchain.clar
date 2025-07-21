;; Quantum Computing Power Marketplace

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-resource-not-found (err u101))
(define-constant err-duplicate-listing (err u102))
(define-constant err-low-balance (err u103))
(define-constant err-inadequate-funds (err u104))
(define-constant err-bad-input (err u105))

;; Define data maps
(define-map quantum-resources 
  { provider: principal, resource-id: uint }
  { compute-power: uint, unit-price: uint, available: bool })

(define-map user-balances principal uint)

;; Define variables
(define-data-var next-resource-id uint u1)
(define-data-var job-status (string-ascii 20) "queued")
(define-data-var demand-factor uint u100)
(define-data-var total-market-worth uint u0)

;; List a quantum computing resource
(define-public (list-asset (compute-power uint) (unit-price uint))
  (if (or (is-eq compute-power u0) (is-eq unit-price u0))
      err-bad-input
      (let
        ((resource-id (var-get next-resource-id))
         (resource-value (* compute-power unit-price)))
        (map-insert quantum-resources 
          { provider: tx-sender, resource-id: resource-id }
          { compute-power: compute-power, unit-price: unit-price, available: true })
        (var-set next-resource-id (+ resource-id u1))
        (var-set total-market-worth (+ (var-get total-market-worth) resource-value))
        (ok resource-id))))

;; Update resource availability
(define-public (update-asset-accessibility (resource-id uint) (available bool))
  (let
    ((resource (unwrap! (map-get? quantum-resources { provider: tx-sender, resource-id: resource-id }) err-resource-not-found)))
    (map-set quantum-resources
      { provider: tx-sender, resource-id: resource-id }
      (merge resource { available: available }))
    (ok true)))

;; Book a quantum computing resource
(define-public (reserve-asset (provider principal) (resource-id uint) (amount uint))
  (if (is-eq amount u0)
      err-bad-input
      (let
        ((resource (unwrap! (map-get? quantum-resources { provider: provider, resource-id: resource-id }) err-resource-not-found))
         (total-cost (* (get unit-price resource) amount)))
        (asserts! (get available resource) err-resource-not-found)
        (asserts! (<= total-cost (default-to u0 (map-get? user-balances tx-sender))) err-low-balance)
        (map-set user-balances tx-sender (- (default-to u0 (map-get? user-balances tx-sender)) total-cost))
        (map-set user-balances provider (+ (default-to u0 (map-get? user-balances provider)) total-cost))
        (ok true))))

;; Deposit balance
(define-public (deposit (amount uint))
  (if (is-eq amount u0)
      err-bad-input
      (let
        ((caller tx-sender))
        (try! (stx-transfer? amount caller (as-contract tx-sender)))
        (map-set user-balances 
          caller 
          (+ (default-to u0 (map-get? user-balances caller)) amount))
        (ok true))))

;; Withdraw balance
(define-public (withdraw (amount uint))
  (let
    ((caller tx-sender)
     (available-funds (default-to u0 (map-get? user-balances caller))))
    (asserts! (>= available-funds amount) err-inadequate-funds)
    (try! (as-contract (stx-transfer? amount tx-sender caller)))
    (map-set user-balances
      caller
      (- available-funds amount))
    (ok true)))

;; Queue a job
(define-public (queue-task (provider principal) (resource-id uint) (job-data (string-ascii 1000)))
  (begin
    (try! (reserve-asset provider resource-id u1))
    (var-set job-status "queued")
    (print job-data)
    (ok true)))

;; Update job status (called by an authorized off-chain oracle)
(define-public (update-task-state (updated-status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (var-set job-status updated-status)
    (ok true)))

;; Get job status
(define-read-only (get-task-state)
  (ok (var-get job-status)))

;; Update demand factor (called periodically by an authorized off-chain oracle)
(define-public (update-market-demand (updated-demand uint))
  (if (is-eq updated-demand u0)
      err-bad-input
      (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (var-set demand-factor updated-demand)
        (ok true))))

;; Get current price for a resource
(define-read-only (get-current-cost (provider principal) (resource-id uint))
  (let
    ((resource (unwrap! (map-get? quantum-resources { provider: provider, resource-id: resource-id }) err-resource-not-found))
     (original-price (get unit-price resource))
     (active-demand (var-get demand-factor)))
    (ok (* original-price (/ active-demand u100)))))

;; Get user balance
(define-read-only (get-funds (user principal))
  (ok (default-to u0 (map-get? user-balances user))))

;; Get resource details for a specific provider and resource ID
(define-read-only (get-asset-details (provider principal) (resource-id uint))
  (map-get? quantum-resources { provider: provider, resource-id: resource-id }))

;; Calculate total market value (using cumulative tracking)
(define-read-only (get-aggregate-market-value)
  (ok (var-get total-market-worth)))
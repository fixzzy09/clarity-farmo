;; Farmo Transfer Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-product (err u101))

;; Maps
(define-map transfer-events
  { event-id: uint }
  {
    product-id: uint,
    from: principal,
    to: principal, 
    timestamp: uint,
    status: (string-ascii 20)
  }
)

(define-data-var event-counter uint u0)

;; Public functions
(define-public (transfer-ownership 
  (product-id uint)
  (new-owner principal))
  (let ((current-owner (unwrap! (contract-call? .farmo-registry get-product-owner product-id) err-invalid-product)))
    (if (is-eq tx-sender current-owner)
      (begin
        (try! (contract-call? .farmo-registry update-product-owner product-id new-owner))
        (try! (log-transfer-event product-id "completed"))
        (ok true))
      err-not-authorized)))

(define-public (log-transfer-event
  (product-id uint)
  (status (string-ascii 20)))
  (let ((event-id (+ (var-get event-counter) u1)))
    (map-insert transfer-events
      { event-id: event-id }
      {
        product-id: product-id,
        from: tx-sender,
        to: contract-caller,
        timestamp: block-height,
        status: status
      })
    (var-set event-counter event-id)
    (ok event-id)))

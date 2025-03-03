;; Farmo Certification Contract

;; Constants
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-product (err u101))
(define-constant err-invalid-expiry (err u102))
(define-constant err-invalid-certification (err u103))

;; Data Variables
(define-data-var certification-counter uint u0)
(define-data-var metric-counter uint u0)

;; Maps
(define-map certifications
  { certification-id: uint }
  {
    product-id: uint,
    certifier: principal,
    certification-type: (string-ascii 32),
    expiry: uint,
    active: bool
  }
)

(define-map quality-metrics
  { metric-id: uint }
  {
    product-id: uint,
    metric-name: (string-ascii 32),
    value: uint,
    timestamp: uint
  }
)

;; Public functions
(define-public (add-certification
  (product-id uint)
  (certification-type (string-ascii 32))
  (expiry uint))
  (begin
    (try! (contract-call? .farmo-registry get-product-owner product-id))
    (let ((cert-id (+ (var-get certification-counter) u1)))
      (if (> expiry block-height)
        (begin
          (map-insert certifications
            { certification-id: cert-id }
            {
              product-id: product-id,
              certifier: tx-sender,
              certification-type: certification-type,
              expiry: expiry,
              active: true
            })
          (var-set certification-counter cert-id)
          (ok cert-id))
        err-invalid-expiry))))

(define-public (revoke-certification
  (certification-id uint))
  (let ((cert (unwrap! (map-get? certifications { certification-id: certification-id }) 
                      err-invalid-certification)))
    (if (is-eq tx-sender (get certifier cert))
      (begin
        (map-set certifications
          { certification-id: certification-id }
          (merge cert { active: false }))
        (ok true))
      err-not-authorized)))

(define-public (add-quality-metric
  (product-id uint)
  (metric-name (string-ascii 32))
  (value uint))
  (begin
    (try! (contract-call? .farmo-registry get-product-owner product-id))
    (let ((metric-id (+ (var-get metric-counter) u1)))
      (map-insert quality-metrics
        { metric-id: metric-id }
        {
          product-id: product-id,
          metric-name: metric-name,
          value: value,
          timestamp: block-height
        })
      (var-set metric-counter metric-id)
      (ok metric-id))))

;; Read only functions
(define-read-only (get-certification (certification-id uint))
  (map-get? certifications { certification-id: certification-id }))

;; Farmo Registry Contract

;; Data Variables
(define-map products 
  { product-id: uint }
  {
    name: (string-utf8 64),
    owner: principal,
    origin: (string-utf8 64),
    timestamp: uint,
    active: bool
  }
)

(define-map participants
  { participant-id: principal }
  {
    role: (string-ascii 20),
    verified: bool,
    active: bool
  }
)

(define-data-var product-counter uint u0)

;; Error constants
(define-constant err-not-authorized (err u100))
(define-constant err-already-registered (err u101))
(define-constant err-invalid-product (err u102))

;; Public functions
(define-public (register-product 
  (name (string-utf8 64))
  (origin (string-utf8 64)))
  (let
    ((product-id (+ (var-get product-counter) u1)))
    (map-insert products
      { product-id: product-id }
      {
        name: name,
        owner: tx-sender,
        origin: origin,
        timestamp: block-height,
        active: true
      })
    (var-set product-counter product-id)
    (ok product-id)))

(define-public (register-participant 
  (role (string-ascii 20)))
  (if (map-get? participants { participant-id: tx-sender })
    err-already-registered
    (begin
      (map-insert participants
        { participant-id: tx-sender }
        {
          role: role,
          verified: false,
          active: true
        })
      (ok true))))

;; Read only functions
(define-read-only (get-product (product-id uint))
  (map-get? products { product-id: product-id }))

(define-read-only (get-product-owner (product-id uint))
  (match (map-get? products { product-id: product-id })
    product (ok (get owner product))
    (err "Product not found")))

(define-public (update-product-owner (product-id uint) (new-owner principal))
  (if (is-some (map-get? products { product-id: product-id }))
    (begin
      (map-set products
        { product-id: product-id }
        (merge (unwrap-panic (map-get? products { product-id: product-id }))
              { owner: new-owner }))
      (ok true))
    err-invalid-product))

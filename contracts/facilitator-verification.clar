;; Facilitator Verification Contract
;; Manages verification and credentials of consciousness DNA activation facilitators

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))

;; Data structures
(define-map facilitators
  { facilitator: principal }
  {
    verified: bool,
    certification-level: uint,
    activation-count: uint,
    reputation-score: uint,
    verified-at: uint
  }
)

(define-map certification-requirements
  { level: uint }
  {
    min-activations: uint,
    min-reputation: uint,
    required-training: (string-ascii 100)
  }
)

;; Initialize certification levels
(map-set certification-requirements { level: u1 }
  { min-activations: u0, min-reputation: u50, required-training: "Basic Consciousness Training" })
(map-set certification-requirements { level: u2 }
  { min-activations: u10, min-reputation: u75, required-training: "Advanced DNA Activation" })
(map-set certification-requirements { level: u3 }
  { min-activations: u50, min-reputation: u90, required-training: "Master Facilitator Program" })

;; Public functions
(define-public (register-facilitator (facilitator principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? facilitators { facilitator: facilitator })) ERR_ALREADY_VERIFIED)
    (ok (map-set facilitators { facilitator: facilitator }
      {
        verified: true,
        certification-level: u1,
        activation-count: u0,
        reputation-score: u50,
        verified-at: block-height
      }))
  )
)

(define-public (update-facilitator-stats (facilitator principal) (new-reputation uint))
  (let ((current-data (unwrap! (map-get? facilitators { facilitator: facilitator }) ERR_NOT_FOUND)))
    (ok (map-set facilitators { facilitator: facilitator }
      (merge current-data {
        reputation-score: new-reputation,
        activation-count: (+ (get activation-count current-data) u1)
      })
    ))
  )
)

(define-public (upgrade-certification (facilitator principal) (new-level uint))
  (let ((current-data (unwrap! (map-get? facilitators { facilitator: facilitator }) ERR_NOT_FOUND))
        (requirements (unwrap! (map-get? certification-requirements { level: new-level }) ERR_NOT_FOUND)))
    (asserts! (>= (get activation-count current-data) (get min-activations requirements)) ERR_UNAUTHORIZED)
    (asserts! (>= (get reputation-score current-data) (get min-reputation requirements)) ERR_UNAUTHORIZED)
    (ok (map-set facilitators { facilitator: facilitator }
      (merge current-data { certification-level: new-level })
    ))
  )
)

;; Read-only functions
(define-read-only (get-facilitator-info (facilitator principal))
  (map-get? facilitators { facilitator: facilitator })
)

(define-read-only (is-verified-facilitator (facilitator principal))
  (match (map-get? facilitators { facilitator: facilitator })
    facilitator-data (get verified facilitator-data)
    false
  )
)

(define-read-only (get-certification-requirements (level uint))
  (map-get? certification-requirements { level: level })
)

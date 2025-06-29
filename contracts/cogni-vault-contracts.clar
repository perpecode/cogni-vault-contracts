;; Cogni Vault Systems: Advanced Digital Asset Repository with Granular Permission Framework
;; Engineered for secure cataloging and controlled access to proprietary digital materials

;; ================================================================================
;; PERSISTENT STORAGE MAPPINGS
;; ================================================================================

;; Primary registry for cataloged digital materials
(define-map digital-asset-registry
  { asset-identifier: uint }
  {
    asset-designation: (string-ascii 80),
    proprietor-address: principal,
    content-magnitude: uint,
    cataloging-timestamp: uint,
    descriptive-summary: (string-ascii 256),
    classification-tags: (list 8 (string-ascii 40))
  }
)

;; Authorization matrix for asset accessibility
(define-map authorization-permissions
  { asset-identifier: uint, requesting-entity: principal }
  { viewing-privilege: bool }
)

;; ================================================================================
;; MUTABLE STATE VARIABLES
;; ================================================================================

;; Sequential identifier generator for new assets
(define-data-var next-asset-identifier uint u0)

;; ================================================================================
;; IMMUTABLE CONSTANTS AND ERROR DEFINITIONS
;; ================================================================================

;; System administrator designation
(define-constant REPOSITORY-ADMINISTRATOR tx-sender)

;; Comprehensive error code definitions
(define-constant ERR_INSUFFICIENT_PRIVILEGES (err u300))
(define-constant ERR_ASSET_NOT_FOUND (err u301))
(define-constant ERR_DUPLICATE_ASSET_ENTRY (err u302))
(define-constant ERR_MALFORMED_ASSET_DESIGNATION (err u303))
(define-constant ERR_INVALID_CONTENT_MAGNITUDE (err u304))
(define-constant ERR_PERMISSION_DENIED (err u305))

;; ================================================================================
;; ASSET REGISTRATION AND CATALOGING FUNCTIONS
;; ================================================================================

;; Primary asset registration mechanism with comprehensive validation
(define-public (catalog-digital-asset 
                (designation (string-ascii 80)) 
                (magnitude uint) 
                (summary (string-ascii 256)) 
                (tags (list 8 (string-ascii 40))))
  (let
    (
      (new-asset-id (+ (var-get next-asset-identifier) u1))
    )
    ;; Comprehensive input parameter validation
    (asserts! (> (len designation) u0) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (< (len designation) u81) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (> magnitude u0) ERR_INVALID_CONTENT_MAGNITUDE)
    (asserts! (< magnitude u2000000000) ERR_INVALID_CONTENT_MAGNITUDE)
    (asserts! (> (len summary) u0) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (< (len summary) u257) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (validate-classification-tags tags) ERR_MALFORMED_ASSET_DESIGNATION)

    ;; Insert new asset record into primary registry
    (map-insert digital-asset-registry
      { asset-identifier: new-asset-id }
      {
        asset-designation: designation,
        proprietor-address: tx-sender,
        content-magnitude: magnitude,
        cataloging-timestamp: block-height,
        descriptive-summary: summary,
        classification-tags: tags
      }
    )

    ;; Establish initial access privileges for asset creator
    (map-insert authorization-permissions
      { asset-identifier: new-asset-id, requesting-entity: tx-sender }
      { viewing-privilege: true }
    )

    ;; Increment identifier counter and return new asset ID
    (var-set next-asset-identifier new-asset-id)
    (ok new-asset-id)
  )
)

;; Enhanced asset registration with improved error handling
(define-public (register-proprietary-content 
                (designation (string-ascii 80)) 
                (magnitude uint) 
                (summary (string-ascii 256)) 
                (tags (list 8 (string-ascii 40))))
  (let
    (
      (allocated-identifier (+ (var-get next-asset-identifier) u1))
    )
    ;; Rigorous input validation procedures
    (asserts! (> (len designation) u0) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (< (len designation) u81) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (> magnitude u0) ERR_INVALID_CONTENT_MAGNITUDE)
    (asserts! (< magnitude u2000000000) ERR_INVALID_CONTENT_MAGNITUDE)
    (asserts! (> (len summary) u0) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (< (len summary) u257) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (validate-classification-tags tags) ERR_MALFORMED_ASSET_DESIGNATION)

    ;; Asset metadata persistence operation
    (map-insert digital-asset-registry
      { asset-identifier: allocated-identifier }
      {
        asset-designation: designation,
        proprietor-address: tx-sender,
        content-magnitude: magnitude,
        cataloging-timestamp: block-height,
        descriptive-summary: summary,
        classification-tags: tags
      }
    )

    ;; Proprietor access privilege establishment
    (map-insert authorization-permissions
      { asset-identifier: allocated-identifier, requesting-entity: tx-sender }
      { viewing-privilege: true }
    )

    ;; Counter advancement and successful response
    (var-set next-asset-identifier allocated-identifier)
    (ok allocated-identifier)
  )
)

;; ================================================================================
;; ASSET MODIFICATION AND MAINTENANCE FUNCTIONS
;; ================================================================================

;; Comprehensive metadata modification function
(define-public (modify-asset-metadata 
                (asset-identifier uint) 
                (updated-designation (string-ascii 80)) 
                (updated-magnitude uint) 
                (updated-summary (string-ascii 256)) 
                (updated-tags (list 8 (string-ascii 40))))
  (let
    (
      (asset-record (unwrap! (map-get? digital-asset-registry { asset-identifier: asset-identifier }) ERR_ASSET_NOT_FOUND))
    )
    ;; Asset existence and ownership verification
    (asserts! (asset-exists-in-registry? asset-identifier) ERR_ASSET_NOT_FOUND)
    (asserts! (is-eq (get proprietor-address asset-record) tx-sender) ERR_PERMISSION_DENIED)

    ;; Updated metadata validation procedures
    (asserts! (> (len updated-designation) u0) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (< (len updated-designation) u81) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (> updated-magnitude u0) ERR_INVALID_CONTENT_MAGNITUDE)
    (asserts! (< updated-magnitude u2000000000) ERR_INVALID_CONTENT_MAGNITUDE)
    (asserts! (> (len updated-summary) u0) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (< (len updated-summary) u257) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (validate-classification-tags updated-tags) ERR_MALFORMED_ASSET_DESIGNATION)

    ;; Execute metadata update operation
    (map-set digital-asset-registry
      { asset-identifier: asset-identifier }
      (merge asset-record { 
        asset-designation: updated-designation, 
        content-magnitude: updated-magnitude, 
        descriptive-summary: updated-summary, 
        classification-tags: updated-tags 
      })
    )
    (ok true)
  )
)

;; Permanent asset removal function
(define-public (expunge-asset-permanently (asset-identifier uint))
  (let
    (
      (asset-record (unwrap! (map-get? digital-asset-registry { asset-identifier: asset-identifier }) ERR_ASSET_NOT_FOUND))
    )
    ;; Asset existence and ownership verification
    (asserts! (asset-exists-in-registry? asset-identifier) ERR_ASSET_NOT_FOUND)
    (asserts! (is-eq (get proprietor-address asset-record) tx-sender) ERR_PERMISSION_DENIED)

    ;; Execute permanent asset removal
    (map-delete digital-asset-registry { asset-identifier: asset-identifier })
    (ok true)
  )
)

;; ================================================================================
;; OPTIMIZED DATA RETRIEVAL FUNCTIONS
;; ================================================================================

;; Essential asset information retrieval
(define-public (fetch-asset-fundamentals (asset-identifier uint))
  (let
    (
      (asset-record (unwrap! (map-get? digital-asset-registry { asset-identifier: asset-identifier }) ERR_ASSET_NOT_FOUND))
    )
    ;; Return core metadata for efficient access
    (ok {
      asset-designation: (get asset-designation asset-record),
      proprietor-address: (get proprietor-address asset-record),
      content-magnitude: (get content-magnitude asset-record)
    })
  )
)

;; Minimal asset data retrieval for maximum efficiency
(define-public (fetch-asset-basics (asset-identifier uint))
  (let
    (
      (asset-record (unwrap! (map-get? digital-asset-registry { asset-identifier: asset-identifier }) ERR_ASSET_NOT_FOUND))
    )
    ;; Return minimal identification data
    (ok {
      asset-designation: (get asset-designation asset-record),
      proprietor-address: (get proprietor-address asset-record)
    })
  )
)

;; Comprehensive asset information retrieval
(define-public (fetch-complete-asset-profile (asset-identifier uint))
  (let
    (
      (asset-record (unwrap! (map-get? digital-asset-registry { asset-identifier: asset-identifier }) ERR_ASSET_NOT_FOUND))
    )
    ;; Generate comprehensive asset profile
    (ok {
      designation: (get asset-designation asset-record),
      proprietor: (get proprietor-address asset-record),
      magnitude: (get content-magnitude asset-record),
      summary: (get descriptive-summary asset-record),
      tags: (get classification-tags asset-record)
    })
  )
)

;; Isolated summary retrieval function
(define-public (extract-asset-summary (asset-identifier uint))
  (let
    (
      (asset-record (unwrap! (map-get? digital-asset-registry { asset-identifier: asset-identifier }) ERR_ASSET_NOT_FOUND))
    )
    (ok (get descriptive-summary asset-record))
  )
)

;; ================================================================================
;; INPUT VALIDATION AND VERIFICATION FUNCTIONS
;; ================================================================================

;; Comprehensive asset submission validation
(define-public (verify-asset-submission (designation (string-ascii 80)) (magnitude uint) (summary (string-ascii 256)) (tags (list 8 (string-ascii 40))))
  (begin
    ;; Designation validation checks
    (asserts! (> (len designation) u0) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (< (len designation) u81) ERR_MALFORMED_ASSET_DESIGNATION)
    ;; Magnitude validation checks
    (asserts! (> magnitude u0) ERR_INVALID_CONTENT_MAGNITUDE)
    (asserts! (< magnitude u2000000000) ERR_INVALID_CONTENT_MAGNITUDE)
    ;; Summary validation checks
    (asserts! (> (len summary) u0) ERR_MALFORMED_ASSET_DESIGNATION)
    (asserts! (< (len summary) u257) ERR_MALFORMED_ASSET_DESIGNATION)
    ;; Classification tags validation
    (asserts! (validate-classification-tags tags) ERR_MALFORMED_ASSET_DESIGNATION)
    (ok true)
  )
)

;; ================================================================================
;; PRIVATE UTILITY AND HELPER FUNCTIONS
;; ================================================================================

;; Asset existence verification utility
(define-private (asset-exists-in-registry? (asset-identifier uint))
  (is-some (map-get? digital-asset-registry { asset-identifier: asset-identifier }))
)

;; Asset ownership verification utility
(define-private (verify-asset-proprietorship (asset-identifier uint) (proprietor principal))
  (match (map-get? digital-asset-registry { asset-identifier: asset-identifier })
    asset-data (is-eq (get proprietor-address asset-data) proprietor)
    false
  )
)

;; Asset magnitude extraction utility
(define-private (extract-asset-magnitude (asset-identifier uint))
  (default-to u0 
    (get content-magnitude 
      (map-get? digital-asset-registry { asset-identifier: asset-identifier })
    )
  )
)

;; Classification tags validation utility
(define-private (validate-classification-tags (tags (list 8 (string-ascii 40))))
  (and
    (> (len tags) u0)
    (<= (len tags) u8)
    (is-eq (len (filter validate-individual-tag tags)) (len tags))
  )
)

;; Individual tag validation utility
(define-private (validate-individual-tag (tag (string-ascii 40)))
  (and 
    (> (len tag) u0)
    (< (len tag) u41)
  )
)

;; ================================================================================
;; USER INTERFACE GENERATION FUNCTIONS
;; ================================================================================

;; Interactive dashboard generation function
(define-public (generate-asset-control-panel (asset-identifier uint))
  (let
    (
      (asset-record (unwrap! (map-get? digital-asset-registry { asset-identifier: asset-identifier }) ERR_ASSET_NOT_FOUND))
    )
    ;; Generate user interface compatible structure
    (ok {
      interface-designation: "Digital Asset Control Panel",
      asset-designation: (get asset-designation asset-record),
      proprietor-address: (get proprietor-address asset-record),
      descriptive-summary: (get descriptive-summary asset-record),
      classification-tags: (get classification-tags asset-record)
    })
  )
)


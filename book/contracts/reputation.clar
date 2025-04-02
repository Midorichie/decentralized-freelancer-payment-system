;; reputation.clar - Track freelancer ratings and reviews
(define-map freelancer-ratings principal
  { total-ratings: uint,
    total-score: uint,
    job-count: uint,
    verified: bool })
 
(define-map reviews
  { freelancer: principal, client: principal, job-id: uint }
  { rating: uint,
    comment: (string-utf8 500),
    timestamp: uint })
 
(define-data-var next-job-id uint u1)

;; Helper function to validate principal (using a basic check)
(define-private (validate-principal (user principal))
  (not (is-eq user (as-contract tx-sender))))  ;; Simple check to ensure principal isn't contract itself
 
;; Add a new review for a freelancer
(define-public (add-review (freelancer principal) (rating uint) (job-id uint) (comment (string-utf8 500)))
  (begin
    ;; Rating must be between 1 and 5
    (asserts! (and (>= rating u1) (<= rating u5)) (err "Rating must be between 1 and 5"))
    
    ;; Validate freelancer principal
    (asserts! (validate-principal freelancer) (err "Invalid freelancer principal"))
    
    ;; Prevent self-review
    (asserts! (not (is-eq tx-sender freelancer)) (err "Cannot review yourself"))
    
    ;; Validate comment
    (asserts! (<= (len comment) u500) (err "Comment too long"))
    
    ;; Store the review with timestamp
    (let ((review-key { freelancer: freelancer, client: tx-sender, job-id: job-id }))
      ;; Check if review already exists
      (asserts! (is-none (map-get? reviews review-key)) (err "Review already exists"))
     
      ;; Add the review with validated inputs
      (map-set reviews review-key
        { rating: rating,
          comment: comment,
          timestamp: block-height })
         
      ;; Update the freelancer's overall rating
      (match (map-get? freelancer-ratings freelancer)
        existing-rating
          (map-set freelancer-ratings freelancer
            { total-ratings: (+ (get total-ratings existing-rating) u1),
              total-score: (+ (get total-score existing-rating) rating),
              job-count: (+ (get job-count existing-rating) u1),
              verified: (get verified existing-rating) })
        ;; If no existing rating, create new entry
        (map-set freelancer-ratings freelancer
          { total-ratings: u1,
            total-score: rating,
            job-count: u1,
            verified: false }))
           
      (ok rating))))
 
;; Verify a freelancer (can only be done by contract owner or trusted verifiers)
(define-public (verify-freelancer (freelancer principal))
  (begin
    ;; Validate freelancer principal
    (asserts! (validate-principal freelancer) (err "Invalid freelancer principal"))
    
    ;; Add authorization check (you may want to customize this)
    ;; For example, check if tx-sender is the contract owner or a trusted verifier
    ;; (asserts! (is-eq tx-sender contract-owner) (err "Not authorized"))
    
    (match (map-get? freelancer-ratings freelancer)
      existing-rating
        (begin
          (map-set freelancer-ratings freelancer
            { total-ratings: (get total-ratings existing-rating),
              total-score: (get total-score existing-rating),
              job-count: (get job-count existing-rating),
              verified: true })
          (ok true))
      (err "Freelancer not found"))))
 
;; Get a freelancer's average rating
(define-read-only (get-average-rating (freelancer principal))
  (match (map-get? freelancer-ratings freelancer)
    existing-rating
      (let ((total-ratings (get total-ratings existing-rating))
            (total-score (get total-score existing-rating)))
        (if (> total-ratings u0)
          (ok (/ (* total-score u100) total-ratings)) ;; Return with 2 decimal precision (multiply by 100)
          (ok u0)))
    (ok u0))) ;; Return 0 if freelancer not found
 
;; Get a freelancer's full profile
(define-read-only (get-freelancer-profile (freelancer principal))
  (match (map-get? freelancer-ratings freelancer)
    existing-rating (ok existing-rating)
    (ok { total-ratings: u0, total-score: u0, job-count: u0, verified: false })))
 
;; Get a specific review
(define-read-only (get-review (freelancer principal) (client principal) (job-id uint))
  (map-get? reviews { freelancer: freelancer, client: client, job-id: job-id }))
 
;; Register a new job (typically called by the escrow contract)
(define-public (register-job (freelancer principal))
  (begin
    ;; Validate freelancer principal
    (asserts! (validate-principal freelancer) (err "Invalid freelancer principal"))
    
    (let ((job-id (var-get next-job-id)))
      (var-set next-job-id (+ job-id u1))
      (ok job-id))))

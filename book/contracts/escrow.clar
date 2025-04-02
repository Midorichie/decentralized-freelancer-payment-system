;; escrow.clar - Enhanced version with bug fixes and security improvements
(define-data-var client principal tx-sender)
(define-data-var freelancer principal 'SP000000000000000000002Q6VF78) ;; set a default for now
(define-data-var payment-amount uint u0)
(define-data-var work-verified bool false)
(define-data-var escrow-funded bool false)
(define-data-var funds-locked uint u0)  ;; Track actual locked funds
(define-data-var contract-active bool true)  ;; Allow contract deactivation in case of disputes

;; Initialize the escrow contract.
(define-public (init-escrow (freelancer-address principal) (amount uint))
  (begin
    ;; Bug fix: The original contract didn't check if escrow was already initialized
    (asserts! (and (is-eq tx-sender (var-get client)) (is-eq u0 (var-get payment-amount))) 
             (err "Escrow already initialized or unauthorized"))
    ;; Security enhancement: Add validations for inputs
    (asserts! (> amount u0) (err "Amount must be greater than zero"))
    (asserts! (not (is-eq freelancer-address tx-sender)) (err "Freelancer cannot be the same as client"))
    (asserts! (not (is-eq freelancer-address 'SP000000000000000000002Q6VF78)) (err "Invalid freelancer address"))
    
    (var-set freelancer freelancer-address)
    (var-set payment-amount amount)
    (ok "Escrow initialized")))

;; Deposit funds into the escrow.
(define-public (deposit)
  (begin
    ;; Bug fix and security: Multiple validations to ensure proper deposit flow
    (asserts! (var-get contract-active) (err "Contract is no longer active"))
    (asserts! (is-eq tx-sender (var-get client)) (err "Only client can deposit funds"))
    (asserts! (not (var-get escrow-funded)) (err "Escrow already funded"))
    (asserts! (> (var-get payment-amount) u0) (err "Escrow not initialized properly"))
    
    ;; Security enhancement: Use actual STX transfer function instead of just setting a flag
    (let ((amount (var-get payment-amount)))
      ;; Fixed: Use match instead of try! to handle the response correctly
      (match (stx-transfer? amount tx-sender (as-contract tx-sender))
        success (begin 
                  (var-set funds-locked amount)
                  (var-set escrow-funded true)
                  (ok "Funds deposited"))
        error (err "Failed to transfer funds")))))

;; Verify that the work is complete.
(define-public (verify-work)
  (begin
    (asserts! (var-get contract-active) (err "Contract is no longer active"))
    (asserts! (is-eq tx-sender (var-get client)) (err "Only client can verify work"))
    (asserts! (var-get escrow-funded) (err "Escrow not funded yet"))
    
    (var-set work-verified true)
    (ok "Work verified")))

;; Release funds to the freelancer if conditions are met.
(define-public (release-payment)
  (begin
    (asserts! (var-get contract-active) (err "Contract is no longer active"))
    ;; Security enhancement: Allow either client or freelancer to trigger payment release
    (asserts! (or (is-eq tx-sender (var-get client)) (is-eq tx-sender (var-get freelancer))) 
              (err "Only client or freelancer can release payment"))
    (asserts! (var-get escrow-funded) (err "Escrow not funded"))
    (asserts! (var-get work-verified) (err "Work not verified yet"))
    
    ;; Security enhancement: Actually transfer the funds
    (let ((amount (var-get funds-locked)))
      ;; Fixed: Use match instead of try! here as well for consistent error handling
      (match (as-contract (stx-transfer? amount tx-sender (var-get freelancer)))
        success (begin
                  (var-set funds-locked u0)
                  (var-set escrow-funded false)
                  (var-set contract-active false)  ;; Prevent reuse of this escrow instance after payment
                  (ok "Payment released to freelancer"))
        error (err "Failed to transfer funds to freelancer")))))

;; Security enhancement: Allow cancellation by client before work verification
(define-public (cancel-escrow)
  (begin
    (asserts! (var-get contract-active) (err "Contract is no longer active"))
    (asserts! (is-eq tx-sender (var-get client)) (err "Only client can cancel escrow"))
    (asserts! (var-get escrow-funded) (err "No funds to return"))
    (asserts! (not (var-get work-verified)) (err "Cannot cancel after work verification"))
    
    ;; Return funds to client
    (let ((amount (var-get funds-locked)))
      ;; Fixed: Use match instead of try!
      (match (as-contract (stx-transfer? amount tx-sender (var-get client)))
        success (begin
                  (var-set funds-locked u0)
                  (var-set escrow-funded false)
                  (var-set contract-active false)
                  (ok "Escrow cancelled and funds returned to client"))
        error (err "Failed to return funds to client")))))

;; Security enhancement: Allow client to set a new freelancer if needed
(define-public (change-freelancer (new-freelancer principal))
  (begin
    (asserts! (var-get contract-active) (err "Contract is no longer active"))
    (asserts! (is-eq tx-sender (var-get client)) (err "Only client can change freelancer"))
    (asserts! (not (var-get work-verified)) (err "Cannot change freelancer after work verification"))
    (asserts! (not (is-eq new-freelancer (var-get client))) (err "Freelancer cannot be the client"))
    
    (var-set freelancer new-freelancer)
    (ok "Freelancer updated successfully")))

;; Read-only functions for contract status
(define-read-only (get-escrow-status)
  (ok {
    client: (var-get client),
    freelancer: (var-get freelancer),
    amount: (var-get payment-amount),
    funded: (var-get escrow-funded),
    verified: (var-get work-verified),
    locked-funds: (var-get funds-locked),
    active: (var-get contract-active)
  }))

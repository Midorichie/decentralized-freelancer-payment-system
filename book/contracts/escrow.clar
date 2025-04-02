;; escrow.clar
(define-data-var client principal tx-sender)
(define-data-var freelancer principal 'SP000000000000000000002Q6VF78) ;; set a default for now
(define-data-var payment-amount uint u0)
(define-data-var work-verified bool false)
(define-data-var escrow-funded bool false)

;; Initialize the escrow contract.
(define-public (init-escrow (freelancer-address principal) (amount uint))
  (begin
    (if (is-eq tx-sender (var-get client))
      (begin
        (var-set freelancer freelancer-address)
        (var-set payment-amount amount)
        (ok "Escrow initialized"))
      (err "Only client can initialize the escrow"))))

;; Deposit funds into the escrow.
(define-public (deposit)
  (if (is-eq tx-sender (var-get client))
      (begin
         (if (>= (stx-get-balance tx-sender) (var-get payment-amount))
             (begin
               (var-set escrow-funded true)
               (ok "Funds deposited"))
             (err "Insufficient funds")))
      (err "Only client can deposit funds")))

;; Verify that the work is complete.
(define-public (verify-work)
  (if (is-eq tx-sender (var-get client))
      (begin
         (var-set work-verified true)
         (ok "Work verified"))
      (err "Only client can verify work")))

;; Release funds to the freelancer if conditions are met.
(define-public (release-payment)
  (if (and (var-get escrow-funded) (var-get work-verified))
      (begin
         ;; Here you would add the code to transfer tokens or STX.
         ;; Note: For simplicity, we return a success message.
         (ok "Payment released to freelancer"))
      (err "Escrow conditions not met")))

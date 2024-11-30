;; Learning Rewards System Smart Contract
;; Author: Your Name
;; Description: A comprehensive system for managing learning achievements and rewards

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_ACHIEVEMENT (err u101))
(define-constant ERR_PREREQUISITES_NOT_MET (err u102))
(define-constant ERR_ALREADY_SUBMITTED (err u103))
(define-constant ERR_TIMELOCK_NOT_EXPIRED (err u104))
(define-constant ERR_ALREADY_CLAIMED (err u105))
(define-constant ERR_NOT_COMPLETED (err u106))

;; Define the reward token
(define-fungible-token skill-token)

;; Data Maps

;; Achievement Definition
(define-map achievements 
    { achievement-id: uint }
    {
        name: (string-ascii 64),
        description: (string-ascii 256),
        reward-amount: uint,
        timelock-period: uint,
        prerequisites: (list 5 uint),
        required-evidence: (list 3 (string-ascii 64)),
        max-submissions: uint
    }
)

;; User Achievement Progress
(define-map user-achievements
    { user: principal, achievement-id: uint }
    {
        status: (string-ascii 20),           ;; "not-started", "in-progress", "completed", "claimed"
        submission-count: uint,
        last-submission-time: uint,
        evidence-hashes: (list 3 (buff 32)),
        completion-time: (optional uint),
        reviewer: (optional principal)
    }
)

;; User Stats
(define-map user-stats
    { user: principal }
    {
        total-achievements: uint,
        total-rewards: uint,
        rank: (string-ascii 20),
        join-date: uint
    }
)

;; Administrative Functions

(define-public (create-achievement (name (string-ascii 64))
                                 (description (string-ascii 256))
                                 (reward-amount uint)
                                 (timelock-period uint)
                                 (prerequisites (list 5 uint))
                                 (required-evidence (list 3 (string-ascii 64)))
                                 (max-submissions uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (let ((achievement-id (+ u1 (default-to u0 (get-last-achievement-id)))))
            (map-set achievements
                { achievement-id: achievement-id }
                {
                    name: name,
                    description: description,
                    reward-amount: reward-amount,
                    timelock-period: timelock-period,
                    prerequisites: prerequisites,
                    required-evidence: required-evidence,
                    max-submissions: max-submissions
                }
            )
            (ok achievement-id)
        )
    )
)

;; User Interaction Functions

;; Start an achievement
(define-public (start-achievement (achievement-id uint))
    (let ((achievement (unwrap! (map-get? achievements { achievement-id: achievement-id })
                               ERR_INVALID_ACHIEVEMENT)))
        (asserts! (check-prerequisites tx-sender (get prerequisites achievement))
                 ERR_PREREQUISITES_NOT_MET)
        (map-set user-achievements
            { user: tx-sender, achievement-id: achievement-id }
            {
                status: "in-progress",
                submission-count: u0,
                last-submission-time: block-height,
                evidence-hashes: (list),
                completion-time: none,
                reviewer: none
            }
        )
        (ok true)
    )
)

;; Submit evidence for achievement
(define-public (submit-evidence (achievement-id uint) 
                              (evidence-hashes (list 3 (buff 32))))
    (let ((user-achievement (unwrap! (map-get? user-achievements 
                                              { user: tx-sender, achievement-id: achievement-id })
                                    ERR_INVALID_ACHIEVEMENT))
          (achievement (unwrap! (map-get? achievements { achievement-id: achievement-id })
                              ERR_INVALID_ACHIEVEMENT)))
        
        ;; Verify submission count
        (asserts! (< (get submission-count user-achievement) 
                    (get max-submissions achievement))
                 ERR_ALREADY_SUBMITTED)
        
        ;; Update submission
        (map-set user-achievements
            { user: tx-sender, achievement-id: achievement-id }
            (merge user-achievement {
                submission-count: (+ (get submission-count user-achievement) u1),
                last-submission-time: block-height,
                evidence-hashes: evidence-hashes
            })
        )
        (ok true)
    )
)

;; Reviewer Functions

;; Mark achievement as completed
(define-public (mark-completed (user principal) 
                             (achievement-id uint))
    (begin
        (asserts! (is-authorized-reviewer tx-sender) ERR_NOT_AUTHORIZED)
        (let ((user-achievement (unwrap! (map-get? user-achievements 
                                                  { user: user, achievement-id: achievement-id })
                                        ERR_INVALID_ACHIEVEMENT)))
            (map-set user-achievements
                { user: user, achievement-id: achievement-id }
                (merge user-achievement {
                    status: "completed",
                    completion-time: (some block-height),
                    reviewer: (some tx-sender)
                })
            )
            (ok true)
        )
    )
)

;; Reward Claim Function

(define-public (claim-reward (achievement-id uint))
    (let ((user-achievement (unwrap! (map-get? user-achievements 
                                              { user: tx-sender, achievement-id: achievement-id })
                                    ERR_INVALID_ACHIEVEMENT))
          (achievement (unwrap! (map-get? achievements { achievement-id: achievement-id })
                              ERR_INVALID_ACHIEVEMENT)))
        
        ;; Verify completion and timelock
        (asserts! (is-eq (get status user-achievement) "completed") 
                 ERR_NOT_COMPLETED)
        (asserts! (>= block-height (+ (unwrap! (get completion-time user-achievement) 
                                              ERR_NOT_COMPLETED)
                                     (get timelock-period achievement)))
                 ERR_TIMELOCK_NOT_EXPIRED)
        
        ;; Mint and transfer rewards
        (try! (ft-mint? skill-token 
                        (get reward-amount achievement)
                        tx-sender))
        
        ;; Update achievement status
        (map-set user-achievements
            { user: tx-sender, achievement-id: achievement-id }
            (merge user-achievement { status: "claimed" })
        )
        
        ;; Update user stats
        (update-user-stats tx-sender (get reward-amount achievement))
        
        (ok true)
    )
)

;; Helper Functions

(define-private (is-authorized-reviewer (reviewer principal))
    (default-to false (get-authorized-reviewer reviewer))
)

(define-private (check-prerequisites (user principal) (prerequisites (list 5 uint)))
    (fold check-prerequisite prerequisites true)
)

(define-private (check-prerequisite (achievement-id uint) (prev-result bool))
    (and prev-result
         (match (map-get? user-achievements 
                         { user: tx-sender, achievement-id: achievement-id })
             achievement (is-eq (get status achievement) "claimed")
             false))
)

(define-private (update-user-stats (user principal) (reward-amount uint))
    (let ((stats (default-to 
                    { total-achievements: u0,
                      total-rewards: u0,
                      rank: "beginner",
                      join-date: block-height }
                    (map-get? user-stats { user: user }))))
        (map-set user-stats
            { user: user }
            (merge stats {
                total-achievements: (+ (get total-achievements stats) u1),
                total-rewards: (+ (get total-rewards stats) reward-amount),
                rank: (calculate-new-rank 
                        (+ (get total-achievements stats) u1)
                        (+ (get total-rewards stats) reward-amount))
            })
        )
    )
)

(define-private (calculate-new-rank (achievements uint) (rewards uint))
    (if (>= achievements u10)
        (if (>= rewards u10000)
            "expert"
            "intermediate")
        "beginner")
)

(define-private (get-last-achievement-id)
    (fold check-achievement-id (sequence "uint" u1 u1000) none)
)

(define-private (check-achievement-id (id uint) (last-id (optional uint)))
    (match (map-get? achievements { achievement-id: id })
        prev-achievement (some id)
        last-id
    )
)

;; Read-Only Functions

(define-read-only (get-achievement-details (achievement-id uint))
    (map-get? achievements { achievement-id: achievement-id })
)

(define-read-only (get-user-achievement-status (user principal) (achievement-id uint))
    (map-get? user-achievements { user: user, achievement-id: achievement-id })
)

(define-read-only (get-user-stats (user principal))
    (map-get? user-stats { user: user })
)
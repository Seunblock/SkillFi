# Learning Rewards System Smart Contract - README

Key features include:

- **Achievement Tracking**: Users can track their progress on various achievements.
- **Rewarding System**: Users earn rewards upon completing achievements.
- **Review Process**: Authorized reviewers can validate user achievements.
- **Practical Interaction**: Users can start, submit evidence, and claim rewards for achievements.
- **Role-based Permissions**: Specific functions are restricted to authorized roles, such as contract owner and reviewers.

This contract is built using the Clarity language and is ideal for educational platforms, gamified learning systems, or incentive-based learning apps.

## Features

- **Achievements**: Create, start, and track achievements with rewards.
- **Evidence Submission**: Users can submit evidence of completed tasks.
- **Review & Approval**: Reviewers validate and approve the completion of achievements.
- **Claiming Rewards**: After validation, users can claim their rewards in the form of fungible tokens.
- **Statistics**: Track user stats including total achievements, rewards, and rank.

---

## Smart Contract Structure

The contract includes the following key components:

### Constants
- **CONTRACT_OWNER**: The principal (address) of the contract owner (administrator).
- **Error Codes**: Predefined errors used across the contract to handle various failure scenarios.

### Data Structures
- **Achievements**: Stores the definitions of achievements with details like name, description, reward amount, and prerequisites.
- **User Achievements**: Tracks the progress and submission history of each user for every achievement.
- **User Stats**: Tracks user statistics including total achievements, total rewards, and rank.
- **Authorized Reviewers**: A list of authorized reviewers who can validate achievements.

### Fungible Token
- **skill-token**: The token used to reward users for completing achievements.

---

## Key Functions

### Administrative Functions
- **`create-achievement`**: Creates a new achievement, defining its properties like name, description, reward amount, and prerequisites.
- **`set-authorized-reviewer`**: Sets or removes a principal as an authorized reviewer.
  
### User Interaction Functions
- **`start-achievement`**: Allows a user to begin working on an achievement after verifying prerequisites.
- **`submit-evidence`**: Allows users to submit evidence to fulfill an achievement. Evidence is stored as a hash for validation.
- **`claim-reward`**: Allows a user to claim their reward after completing an achievement and meeting all conditions.

### Reviewer Functions
- **`mark-completed`**: Allows authorized reviewers to mark a user's achievement as completed.

### Helper Functions
- **`is-authorized-reviewer`**: Checks if a principal is authorized as a reviewer.
- **`check-prerequisites`**: Verifies if a user has completed all prerequisites before starting an achievement.
- **`update-user-stats`**: Updates a user's achievement count, rewards, and rank after claiming a reward.

---

## Usage Guide

### Creating an Achievement
To create an achievement, the contract owner must call the `create-achievement` function, passing the required parameters:

```clarity
(create-achievement 
  "Python Programming Basics" 
  "Complete a course on Python Programming Basics" 
  1000 
  30 
  [0, 1] 
  ["hash1", "hash2", "hash3"] 
  3)
```

### Starting an Achievement
To start an achievement, the user calls `start-achievement`, providing the `achievement-id`:

```clarity
(start-achievement 1)
```

### Submitting Evidence
Users submit evidence via the `submit-evidence` function, including the evidence hashes:

```clarity
(submit-evidence 1 ["evidence-hash1", "evidence-hash2", "evidence-hash3"])
```

### Claiming a Reward
Once an achievement is marked as completed by a reviewer, users can claim their reward:

```clarity
(claim-reward 1)
```

### Marking an Achievement as Completed
An authorized reviewer can mark an achievement as completed for a user:

```clarity
(mark-completed user-achievement-id)
```

---

## Permissions & Roles

- **Contract Owner**: The principal who deployed the contract. Only they can create achievements and set authorized reviewers.
- **Authorized Reviewer**: Reviewers who are allowed to mark achievements as completed. Their status is managed by the contract owner.
- **Users**: Individuals who can participate in achievements, submit evidence, and claim rewards.

---

## Example Transactions

### Creating an Achievement
A contract owner creates an achievement for learning Python programming:

```clarity
(create-achievement "Python Programming Basics" 
                    "Complete a Python basics course"
                    1000 
                    30 
                    [1] 
                    ["hash1", "hash2", "hash3"] 
                    3)
```

### Starting an Achievement
A user starts working on the Python Programming Basics achievement:

```clarity
(start-achievement 1)
```

### Submitting Evidence
The user submits evidence of their progress:

```clarity
(submit-evidence 1 ["evidence-hash1", "evidence-hash2", "evidence-hash3"])
```

### Marking Completion
A reviewer marks the achievement as completed:

```clarity
(mark-completed user-achievement-id)
```

### Claiming a Reward
Once the achievement is completed, the user claims their reward:

```clarity
(claim-reward 1)
```

---

## Error Codes

- **ERR_NOT_AUTHORIZED**: Raised when an unauthorized principal attempts to perform an action.
- **ERR_INVALID_ACHIEVEMENT**: Raised when the achievement ID is invalid or does not exist.
- **ERR_PREREQUISITES_NOT_MET**: Raised when the user has not completed the necessary prerequisites.
- **ERR_ALREADY_SUBMITTED**: Raised when a user exceeds the maximum number of submissions for an achievement.
- **ERR_TIMELOCK_NOT_EXPIRED**: Raised when a user tries to claim a reward before the timelock period has passed.
- **ERR_ALREADY_CLAIMED**: Raised when a reward has already been claimed for the achievement.
- **ERR_NOT_COMPLETED**: Raised when the achievement is not marked as completed.

---

## Limitations & Considerations

- The contract assumes that the reward system is fungible and that tokens are appropriately minted and transferred via an external system.
- Evidence is stored as a hash. The actual evidence should be stored externally in a decentralized file storage system.
- The contract supports a maximum of 5 prerequisites and 3 pieces of evidence per achievement. 
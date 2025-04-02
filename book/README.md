# Decentralized Freelancer Payment System

A blockchain-based escrow system for secure freelancer payments built on the Stacks blockchain.

## Overview

This project implements a smart contract escrow system to facilitate trustless transactions between clients and freelancers. It ensures that:

1. Clients can safely deposit payments
2. Funds are only released after work verification
3. The entire process is transparent and decentralized

## Project Structure

```
decentralized-freelancer-payment-system/
├── contracts/
│   └── escrow.clar       # Main escrow smart contract
├── tests/
│   └── escrow-test.clar  # Test cases for the escrow contract
├── README.md             # This file
└── Clarinet.toml         # Project configuration for Clarinet
```

## Smart Contract Functionality

The escrow contract (`escrow.clar`) provides the following core functions:

- `init-escrow`: Initialize a new escrow with a specified freelancer and payment amount
- `deposit`: Allow the client to deposit funds into the escrow
- `verify-work`: Client confirms work completion
- `release-payment`: Release the payment to the freelancer once conditions are met

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- [Stacks Wallet](https://www.hiro.so/wallet) (for mainnet/testnet deployment)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/midorichie/decentralized-freelancer-payment-system.git
   cd decentralized-freelancer-payment-system
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run tests with Clarinet:
   ```bash
   clarinet test
   ```

## Usage Example

Here's a basic workflow for using the contract:

1. Client initializes an escrow with a freelancer address and payment amount:
   ```clarity
   (contract-call? .escrow init-escrow 'STFREELANC3RADDRESS123456789012345 u1000000)
   ```

2. Client deposits the agreed payment amount:
   ```clarity
   (contract-call? .escrow deposit)
   ```

3. After work is completed, client verifies the work:
   ```clarity
   (contract-call? .escrow verify-work)
   ```

4. Once verified, the payment can be released to the freelancer:
   ```clarity
   (contract-call? .escrow release-payment)
   ```

## Future Improvements

- Add dispute resolution mechanisms
- Support for milestone-based payments
- Integration with decentralized reputation systems
- Support for various token types beyond STX
- Time-based auto-release of funds

## Testing

Run the test suite using Clarinet:

```bash
clarinet test
```

Test cases verify the core functionality:
- Contract initialization
- Payment deposit mechanism
- Work verification process
- Payment release conditions

## Deployment

To deploy to the Stacks testnet or mainnet:

1. Build the contract:
   ```bash
   clarinet build
   ```

2. Deploy using the Stacks CLI or Hiro Wallet

## License

[MIT License](LICENSE)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

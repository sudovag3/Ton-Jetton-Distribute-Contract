# TON and Jetton Distribution Contract (Blazing Bot Tech Task)

## Contract Description

### Distribution Contract
- **Receive TON**: The contract can receive TON tokens.
- **Distribute TON**: A function to distribute a specified amount of TON to multiple addresses in a single transaction. The distribution can be either a fixed amount or a percentage.
- **Distribute Jettons**: A function to distribute a specified amount of Jettons to multiple addresses. The distribution can be either a fixed amount or a percentage.

### API Requirements
- **Trigger Distribution**: An API endpoint to trigger the distribution of TON.
- **Accept JSON Payload**: The API accepts a JSON payload containing the list of addresses and the amounts to be distributed.

## Deployed Contract

- **TON Testnet Contract**: [https://testnet.tonviewer.com/kQCbVMWAMeUXQzW-ANL7X794p8EYcmNedACqXL4bMBSzR-Jr](#) 

### URL of a Successful Transaction: [https://testnet.tonviewer.com/transaction/992653b538d12992f495099a6be88b1c451ba3e378980f085b215a6987687dcc](#)

### Screenshot of a Successful Transaction
![https://github.com/sudovag3/TAO/blob/main/2024-06-08%2013.16.52.jpg?raw=true](#)

## Usage Instructions

### 1. Clone the Repository
```bash
git clone <repository_url>
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Run Tests
```bash
npm run test
```

### 4. Run Tests
Modify the transferBatchSender.ts script with the necessary data for the distribution.

### 5. Execute the Script
Run the script to execute the distribution:
```bash
npm run start
```
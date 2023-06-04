# Auction Platform

The Auction Platform is a university project for the Programming Scalable Systems course, developed in Elixir, leveraging OTP (Open Telecom Platform) patterns such as GenServers, Supervisors, and Dynamic Supervisors. It provides a scalable and fault-tolerant solution for conducting auctions of skins from the game Counter-Strike: Global Offensive.

## Prerequisites

To run the Auction Platform, ensure you have the following prerequisites installed:

- Elixir (minimum version 1.14.3)
- PostgreSQL (minimum version 0.0.0)
- EctoSQL (version 3.0) 

All dependencies required by the Auction Platform can be obtained by running the following command:

```bash
mix deps.get
```

## Installation

To set up the Auction Platform locally, follow these steps:

1. Clone the repository:
  ```bash
  git clone https://github.com/your-username/auction-system.git
  ```

2. Install dependencies:
```bash
cd auction-system
mix deps.get
```
3. Configure the system:
- Modify the config/config.exs file set up your PostgreSQL databse connection details.

4. Create the database:
```bash
mix ecto.create
```
5. Migrate the database:
```bash
mix ecto.migrate
```
6. Start the application and interact with it using the Elixir interactive shell:
```bash
iex -S mix
```
Now you can explore and interact with the Auction Platform through the Elixir interactive shell (iex). The system should be up and running, allowing you to perform actions like creating auctions, placing bids, and managing the skins being auctioned.

# OTP Patterns Used
The Auction Platform utilizes the following OTP patterns:

- Supervisors: used to monitor and restart processes in case of failures, ensuring high availability of the application.
- GenServers: employed for attending users requests and implementing permanent services.
- Dynamic Supervisors: used to delegate tasks and spawn child processes for the most demanding tasks, providing scalability and flexibility.

# Testing
To run the test suite and ensure the system functions correctly, execute the following command:
```bash
mix test
```

# License
The Auction Platform is released under the MIT License.
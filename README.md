A smart contract, including JavaScript that handles more complex voting for groups.

In detail, this smart contract handles:

- Timeout of the contract after X days (can be set externally)
- Contract stages to allow for revealing results with automatic transition after 30 days
- One voter can only vote once
- Votes can be cast for candidates for multiple category groups
- Only contract creator can set some essential settings
- Ownership of contract can be changed
- Candidates and categories are added onChain

- The frontend will only show the voting dialog as long as the contract is open.
- Once conctract is closed, voting results will automatically show up for candidates grouped into categories

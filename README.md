# MiniTeller

Teller bank api engineering challenge

## Solution

`MiniTeller.Client.Live.enroll()`, should go through the entire enrollment flow and return a tuple with:

`{account_number, account_balance, account_details}`

## Limitations

- A new `device_id` is issued for each new browser session, I was unable
to create a client that can fetch a `device_id` per session. It is hard-coded.

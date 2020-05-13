## A Standard Banking DB Schema 

### Instructions to set up the data base:
 - Create a Database and call it ChannelAssist_BankDB
 - Run the SQL Query it will initial add data as well.
To See the list of Accounts and their balance run `GetAllAccountsBalance`
To search an account by FirstName/ last name or FirsName LastName run `GetAccountBalanceByName`

 - Each Stored procedure has a short description with a sample params to run at the beginning of it. 

### Implementation Approach

 - We have a Bank Account which is our Bank,  the value of bank is always negative and is equal to sum of all the other accounts. 
 - Bank Takes the money from Customers and it becomes negative as much as it’s taken. 
 - in Our Data base we have two recoreds A and B A has $10 and B has $20, so Bank has -$30 it goes:  -30 + 10 + 20 = 0   This is an even balance; 
 - Banks close their account at the end of each day if this is zero. I’ve initialized with some sample data.  

### Transfering Funds 

 - Stored procedure to transfer funds between to accounts: `InsTransferBillingAmmount`
 - Example: `Exec InsTransferBillingAmmount 3,8, 2,2, 5.25, 2,'Transfer From B to A $5.25'`
 - It Transfer funds and runs a select query to show the result, you can keep running it till you get the error. 
 - We have a scalar function to check the balance.
 ```
   FROM Customer 3 of their account number 8
   TO Customer 2 to their Account ID: 2 
   Amount: $5.25
   Transaction Type: 2 
   Also has a Comment (Adds it automatically.) 
```
### Reseting Data
 - To reset data delete every thing that does not start with Deposit or withdraw from BillingTransaction

### Transaction Definition
Each Transaction defines two records: 
+ Billing Amount Deposited to the Destination Account (Positive amount + ) 
- Billing Amount Withdrawn from the Source Account ( Negative amount - ) 
 
IF we can Transfer will show the overall balance of all (I put it this way to make it easier to review) 
The `Even` condition with Bank over all Balance should be always true.
	
### Error on Not Enough Fund. 
IF you request to transfer more than remaining balance it raises error. 
 



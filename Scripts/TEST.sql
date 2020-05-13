
--------------- Customer Account Status With IDs-------------------
Select  CS.FirstName, CS.LastName, CA.AccountNumber, CS.CustomerId, CA.FK_AccountId,
		Sum(BT.BillingAmount) [AccountBalance]
			From Customer CS
		Inner Join Customer_Account CA
			On CA.FK_CustomerId = CS.CustomerId
		Inner Join BillingTransaction BT 
			On BT.FK_CustomerId = CS.CustomerId
--		Where CS.IsActive = 1 and CS.FirstName Like '%A%' 

		Group by CS.FirstName, CS.LastName , CA.AccountNumber, CS.CustomerId, CA.FK_AccountId			
		Order by CA.AccountNumber


---------------  Check Balance  -------------------
Exec	[dbo].[GetAllAccountsBalance]	

--------------- Transfer Billing Amount ------------------

/*
From Customer ID
From Account ID

To Customer ID 
To Account ID

Billing Amount
Transaction Type
Comments

*/
Exec InsTransferBillingAmmount 3,8, 2,2, 1.5, 2,'Transfer From B to A $1.5'


------------------ Check Balance ----------------
Exec	[dbo].[GetAllAccountsBalance]	




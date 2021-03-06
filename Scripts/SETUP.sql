USE [ChannelAssist_BankDB]
GO
/****** Object:  StoredProcedure [dbo].[GetAccountBalanceByName]    Script Date: 2020-05-12 11:00:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ali Hakak	
-- Create date: 2020-05-12
-- Description:	 Get Account Info. by FirstName And/Or Last Name
-- Exec GetAllAccountsBalanceByName 'XXX'
-- =============================================
CREATE PROCEDURE [dbo].[GetAccountBalanceByName]
@CustomerName nvarchar(128)
AS
BEGIN

Select  CS.FirstName, CS.LastName, CA.AccountNumber, 
		CA.AccountNumber [AccountNumber], Sum(BT.BillingAmount) [AccountBalance]
			From Customer CS
		Inner Join Customer_Account CA
			On CA.FK_CustomerId = CS.CustomerId
		Inner Join BillingTransaction BT 
			On BT.FK_CustomerId = CS.CustomerId
		Where CS.IsActive = 1 And 
				(	CS.FirstName Like @CustomerName 
					OR  CS.LastName Like @CustomerName 
					OR (CS.FirstName + ' '+ CS.LastName Like @CustomerName)
				)

		Group by CS.FirstName, CS.LastName , CA.AccountNumber			
		Order by CA.AccountNumber
							
END

GO
/****** Object:  StoredProcedure [dbo].[GetAllAccountsBalance]    Script Date: 2020-05-12 11:00:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ali Hakak	
-- Create date: 2020-05-12
-- Description:	Simple report for all accounts and their balance
-- =============================================
CREATE PROCEDURE [dbo].[GetAllAccountsBalance]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		Select  CS.FirstName, CS.LastName, CA.AccountNumber, 
				CA.AccountNumber [AccountNumber], Sum(BT.BillingAmount) [AccountBalance]
					From Customer CS
				Inner Join Customer_Account CA
					On CA.FK_CustomerId = CS.CustomerId
				Inner Join BillingTransaction BT 
					On BT.FK_CustomerId = CS.CustomerId
				Group by CS.FirstName, CS.LastName , CA.AccountNumber
				Order by CA.AccountNumber
			
END

GO
/****** Object:  StoredProcedure [dbo].[InsTransferBillingAmmount]    Script Date: 2020-05-12 11:00:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ali Hakak
-- Create date: May/12/2020
-- Description:	Performes a Billing Transaction between 2 accounts
-- Exec InsTransferBillingAmmount 3,8, 2,2, 5.25, 2,'Transfer From B to A $4.5'
-- =============================================
CREATE PROCEDURE [dbo].[InsTransferBillingAmmount]
	-- Add the parameters for the stored procedure here
	@FromCustomerId int, @FromAccountId int, 
	@ToCustomerId int , @ToAccountId int, 
	@BillingAmount money, 
	@TxTypeId int, @Comments nvarchar(128)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	Declare @CurrentBalance money
	Set @CurrentBalance = dbo.ReturnAccountBalanceById(@FromAccountId) 

	If( (@CurrentBalance - @BillingAmount) >= 0)
		Begin --if
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		Begin Transaction 
			 BEGIN TRY
			  -- Widthraw from Source Account
     			Insert Into BillingTransaction 
							(FK_CustomerId, FK_AccountId, FK_TxTypeId, TxDateTime, BillingAmount, Comments) 
					Values (@FromCustomerId, @FromAccountId, @TxTypeId, getdate(),-@BillingAmount,'Withdrawal: ' + @Comments)
				  -- Deposit to Destination Account
				Insert Into BillingTransaction (FK_CustomerId, FK_AccountId, FK_TxTypeId, TxDateTime, BillingAmount, Comments) 
					Values (@ToCustomerId,@ToAccountId,@TxTypeId,getdate(), @BillingAmount,'Deposit: ' + @Comments)
			
			Exec	[dbo].[GetAllAccountsBalance]	
			Commit Transaction
		   END TRY
		   BEGIN CATCH
			  PRINT 'The error message is: ' + error_message()
			  RollBack Transaction
		   END CATCH
		 End -- if
		ELSE 
	
		 PRINT 'NOT Enough Funds! Current Balance: ' + convert(varchar, cast(@CurrentBalance as money))    
			+' < Requested Transfer: ' + convert(varchar, cast(@BillingAmount as money))   
END

GO
/****** Object:  UserDefinedFunction [dbo].[ReturnAccountBalanceById]    Script Date: 2020-05-12 11:00:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Ali Hakak
-- Create date: May/12/2020
-- Description:	Return Account Balance by Account ID
-- =============================================
CREATE FUNCTION [dbo].[ReturnAccountBalanceById]
(
	-- Add the parameters for the function here
	@AccountId int
)
RETURNS decimal(18,3)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @AccountBalance decimal(18,3) 

	-- Add the T-SQL statements to compute the return value here
	Select  @AccountBalance = Sum(BT.BillingAmount) 
			From Customer CS
		Inner Join Customer_Account CA
			On CA.FK_CustomerId = CS.CustomerId
		Inner Join BillingTransaction BT 
			On BT.FK_CustomerId = CS.CustomerId
		Where CS.IsActive = 1 and CA.CustomerAccountId = @AccountId

		Group by CS.FirstName, CS.LastName , CA.AccountNumber, CS.CustomerId, CA.FK_AccountId			
		Order by CA.AccountNumber

	-- Return the result of the function
	RETURN @AccountBalance

END

GO
/****** Object:  Table [dbo].[Account]    Script Date: 2020-05-12 11:00:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Account](
	[AccountId] [smallint] IDENTITY(1,1) NOT NULL,
	[AccountName] [nvarchar](64) NULL,
	[AccountDescription] [nvarchar](128) NULL,
 CONSTRAINT [PK_AccountType] PRIMARY KEY CLUSTERED 
(
	[AccountId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[BillingTransaction]    Script Date: 2020-05-12 11:00:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BillingTransaction](
	[TxId] [uniqueidentifier] NOT NULL,
	[FK_CustomerId] [int] NOT NULL,
	[FK_AccountId] [int] NOT NULL,
	[FK_TxTypeId] [smallint] NULL,
	[TxDateTime] [datetime] NOT NULL,
	[BillingAmount] [money] NOT NULL,
	[Comments] [nvarchar](128) NULL,
 CONSTRAINT [PK_BillingTransaction] PRIMARY KEY CLUSTERED 
(
	[TxId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Customer]    Script Date: 2020-05-12 11:00:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Customer](
	[CustomerId] [int] IDENTITY(1,1) NOT NULL,
	[FirstName] [nvarchar](64) NULL,
	[LastName] [nvarchar](64) NULL,
	[CreateDate] [datetime] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_Customer] PRIMARY KEY CLUSTERED 
(
	[CustomerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Customer_Account]    Script Date: 2020-05-12 11:00:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Customer_Account](
	[CustomerAccountId] [int] IDENTITY(1,1) NOT NULL,
	[FK_AccountId] [smallint] NOT NULL,
	[FK_CustomerId] [int] NOT NULL,
	[AccountNumber] [varchar](16) NULL,
	[IsActive] [bit] NOT NULL,
	[CreateDate] [timestamp] NOT NULL,
 CONSTRAINT [PK_Customer_Account] PRIMARY KEY CLUSTERED 
(
	[CustomerAccountId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TransactionType]    Script Date: 2020-05-12 11:00:08 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TransactionType](
	[TxTypeId] [smallint] NOT NULL,
	[TxType] [nvarchar](128) NOT NULL,
 CONSTRAINT [PK_TransationType] PRIMARY KEY CLUSTERED 
(
	[TxTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET IDENTITY_INSERT [dbo].[Account] ON 

GO
INSERT [dbo].[Account] ([AccountId], [AccountName], [AccountDescription]) VALUES (1, N'Bank Cash Warehouse', N'Bank Acount , Fees , Rewards etc.')
GO
INSERT [dbo].[Account] ([AccountId], [AccountName], [AccountDescription]) VALUES (2, N'Checking Acount', N'Customer Cash Deposit')
GO
SET IDENTITY_INSERT [dbo].[Account] OFF
GO
INSERT [dbo].[BillingTransaction] ([TxId], [FK_CustomerId], [FK_AccountId], [FK_TxTypeId], [TxDateTime], [BillingAmount], [Comments]) VALUES (N'dc469dd2-5ea7-4838-9aab-32d83689d368', 2, 2, 1, CAST(0x0000ABB90143040E AS DateTime), 10.0000, N'Cash Deposit to Account')
GO
INSERT [dbo].[BillingTransaction] ([TxId], [FK_CustomerId], [FK_AccountId], [FK_TxTypeId], [TxDateTime], [BillingAmount], [Comments]) VALUES (N'1ef3e941-5111-4ff7-a982-40b19f8305b7', 3, 2, 1, CAST(0x0000ABB901537ECE AS DateTime), 20.0000, N'Cash Deposit to Account')
GO
INSERT [dbo].[BillingTransaction] ([TxId], [FK_CustomerId], [FK_AccountId], [FK_TxTypeId], [TxDateTime], [BillingAmount], [Comments]) VALUES (N'65aebf53-c8b5-469c-94b7-42baa274ff4b', 1, 1, 1, CAST(0x0000ABB901537ECE AS DateTime), -20.0000, N'Customer Deposit Cash to Bank')
GO
INSERT [dbo].[BillingTransaction] ([TxId], [FK_CustomerId], [FK_AccountId], [FK_TxTypeId], [TxDateTime], [BillingAmount], [Comments]) VALUES (N'557a1628-0d2a-46c3-b5fe-42e808c793ad', 1, 1, 1, CAST(0x0000ABB90143040E AS DateTime), -10.0000, N'Customer Deposit Cash to Bank')
GO
SET IDENTITY_INSERT [dbo].[Customer] ON 

GO
INSERT [dbo].[Customer] ([CustomerId], [FirstName], [LastName], [CreateDate], [IsActive]) VALUES (1, N'Bank', N'Bank', CAST(0x00000000000007E1 AS DateTime), 0)
GO
INSERT [dbo].[Customer] ([CustomerId], [FirstName], [LastName], [CreateDate], [IsActive]) VALUES (2, N'A', N'XXX', CAST(0x00000000000007E4 AS DateTime), 1)
GO
INSERT [dbo].[Customer] ([CustomerId], [FirstName], [LastName], [CreateDate], [IsActive]) VALUES (3, N'B', N'YYY', CAST(0x00000000000007E5 AS DateTime), 1)
GO
SET IDENTITY_INSERT [dbo].[Customer] OFF
GO
SET IDENTITY_INSERT [dbo].[Customer_Account] ON 

GO
INSERT [dbo].[Customer_Account] ([CustomerAccountId], [FK_AccountId], [FK_CustomerId], [AccountNumber], [IsActive]) VALUES (1, 1, 1, N'00-00-000', 1)
GO
INSERT [dbo].[Customer_Account] ([CustomerAccountId], [FK_AccountId], [FK_CustomerId], [AccountNumber], [IsActive]) VALUES (2, 2, 2, N'01-01-002', 1)
GO
INSERT [dbo].[Customer_Account] ([CustomerAccountId], [FK_AccountId], [FK_CustomerId], [AccountNumber], [IsActive]) VALUES (8, 2, 3, N'01-01-003', 1)
GO
SET IDENTITY_INSERT [dbo].[Customer_Account] OFF
GO
INSERT [dbo].[TransactionType] ([TxTypeId], [TxType]) VALUES (1, N'Cash Deposit')
GO
INSERT [dbo].[TransactionType] ([TxTypeId], [TxType]) VALUES (2, N'Transfer')
GO
INSERT [dbo].[TransactionType] ([TxTypeId], [TxType]) VALUES (3, N'Fees')
GO
INSERT [dbo].[TransactionType] ([TxTypeId], [TxType]) VALUES (4, N'Rewards')
GO
INSERT [dbo].[TransactionType] ([TxTypeId], [TxType]) VALUES (5, N'Interest')
GO
ALTER TABLE [dbo].[BillingTransaction] ADD  CONSTRAINT [DF_BillingTransaction_TxId]  DEFAULT (newid()) FOR [TxId]
GO
ALTER TABLE [dbo].[BillingTransaction] ADD  CONSTRAINT [DF_BillingTransaction_TxDateTime]  DEFAULT (getdate()) FOR [TxDateTime]
GO
ALTER TABLE [dbo].[Customer] ADD  CONSTRAINT [DF_Customer_CreateDate]  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[BillingTransaction]  WITH CHECK ADD  CONSTRAINT [FK_BillingTransaction_Customer] FOREIGN KEY([FK_CustomerId])
REFERENCES [dbo].[Customer] ([CustomerId])
GO
ALTER TABLE [dbo].[BillingTransaction] CHECK CONSTRAINT [FK_BillingTransaction_Customer]
GO
ALTER TABLE [dbo].[BillingTransaction]  WITH CHECK ADD  CONSTRAINT [FK_BillingTransaction_Customer_Account] FOREIGN KEY([FK_AccountId])
REFERENCES [dbo].[Customer_Account] ([CustomerAccountId])
GO
ALTER TABLE [dbo].[BillingTransaction] CHECK CONSTRAINT [FK_BillingTransaction_Customer_Account]
GO
ALTER TABLE [dbo].[BillingTransaction]  WITH CHECK ADD  CONSTRAINT [FK_BillingTransaction_TransationType] FOREIGN KEY([FK_TxTypeId])
REFERENCES [dbo].[TransactionType] ([TxTypeId])
GO
ALTER TABLE [dbo].[BillingTransaction] CHECK CONSTRAINT [FK_BillingTransaction_TransationType]
GO
ALTER TABLE [dbo].[Customer_Account]  WITH CHECK ADD  CONSTRAINT [FK_Customer_Account_Customer] FOREIGN KEY([FK_CustomerId])
REFERENCES [dbo].[Customer] ([CustomerId])
GO
ALTER TABLE [dbo].[Customer_Account] CHECK CONSTRAINT [FK_Customer_Account_Customer]
GO
ALTER TABLE [dbo].[Customer_Account]  WITH CHECK ADD  CONSTRAINT [FK_Customer_BankAccount_AccountType] FOREIGN KEY([FK_AccountId])
REFERENCES [dbo].[Account] ([AccountId])
GO
ALTER TABLE [dbo].[Customer_Account] CHECK CONSTRAINT [FK_Customer_BankAccount_AccountType]
GO

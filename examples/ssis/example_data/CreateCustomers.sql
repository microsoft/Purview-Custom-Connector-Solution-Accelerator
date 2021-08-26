USE [purview-sqlmi-db]
GO

/****** Object:  Table [dbo].[MovCustomers]    Script Date: 7/27/2021 3:56:43 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MovCustomers](
	[Customer_ID] [nchar](255) NULL,
	[Last_Name] [nchar](255) NULL,
	[First_Name] [nchar](255) NULL,
	[Addr_1] [nchar](255) NULL,
	[Addr_2] [nchar](255) NULL,
	[City] [nchar](255) NULL,
	[State] [nchar](255) NULL,
	[Zip_Code] [nchar](255) NULL,
	[Phone_Number] [nchar](255) NULL,
	[Created_Date] [smalldatetime] NULL,
	[Updated_Date] [smalldatetime] NULL
) ON [PRIMARY]
GO
USE [purview-sqlmi-db]
GO

/****** Object:  Table [dbo].[MovMovies]    Script Date: 7/27/2021 3:50:47 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[MovMovies](
	[MovieID] [nvarchar](255) NULL,
	[MovieTitle] [nvarchar](255) NULL,
	[Category] [nvarchar](255) NULL,
	[Rating] [nvarchar](255) NULL,
	[RunTimeMin] [nvarchar](255) NULL,
	[ReleaseDate] [nvarchar](255) NULL
) ON [PRIMARY]
GO
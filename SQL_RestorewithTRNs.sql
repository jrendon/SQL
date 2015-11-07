/* 
	Restore a Database and TRN logs 
	This script will crawl your backup folder and create a Restore script for you to use in a SQL Query window
	JRendon@peakstate.net - special thanks to the internet for code snippets for this script
	
	Note: You will need xp_cmdshell enabled, see bottom for script to enable this
*/

USE Master; 
GO  
SET NOCOUNT ON 

/* Variable declaration */
	DECLARE @dbName sysname 
	DECLARE @dbRestoreName NVARCHAR(50)
	DECLARE @backupPath NVARCHAR(500) 
	DECLARE @cmd NVARCHAR(500) 
	DECLARE @fileList TABLE (backupFile NVARCHAR(255)) 
	DECLARE @lastFullBackup NVARCHAR(500) 
	DECLARE @lastDiffBackup NVARCHAR(500) 
	DECLARE @backupFile NVARCHAR(500) 

/* Initialize variables */
    SET @dbName = 'BackupDatabaseName'
	SET @dbRestoreName = 'RestoredDatabaseName'
    SET @backupPath = 'V:\Backup\' + @dbName + '\' --The path to your backup files

/* Get list of backup and TRN files */
	SET @cmd = 'DIR /b ' + @backupPath 

	INSERT INTO @fileList(backupFile) 
	EXEC master.sys.xp_cmdshell @cmd 

/* Determine latest full backup */
	SELECT @lastFullBackup = MAX(backupFile)  
	FROM @fileList  
	WHERE backupFile LIKE '%.BAK'  
	   AND backupFile LIKE @dbName + '%' 

	/* Restore with same Database name */
		--SET @cmd = 'RESTORE DATABASE ' + @dbName + ' FROM DISK = '''  
		--	   + @backupPath + @lastFullBackup + ''' WITH NORECOVERY, REPLACE' 
		--PRINT @cmd 

	/* Restore with different Database name */
		SET @cmd = 'RESTORE DATABASE ' + @dbRestoreName + ' FROM DISK = '''  
			   + @backupPath + @lastFullBackup + ''' WITH FILE = 1,  MOVE N''' + @dbName + '_Data'' TO N''X:\DATA\' + @dbRestoreName + '.mdf'', MOVE N''' + @dbName + '_Log'' TO N''Y:\Logs\' + @dbRestoreName + '_1.ldf'', NORECOVERY, REPLACE'
		PRINT @cmd 

/* Find latest diff backup */
	SELECT @lastDiffBackup = MAX(backupFile)  
	FROM @fileList  
	WHERE backupFile LIKE '%.DIF'  
	   AND backupFile LIKE @dbName + '%' 
	   AND backupFile > @lastFullBackup 

	/* Check to make sure there is a diff backup */
		IF @lastDiffBackup IS NOT NULL 
		BEGIN 
		   SET @cmd = 'RESTORE DATABASE ' + @dbRestoreName + ' FROM DISK = '''  
			   + @backupPath + @lastDiffBackup + ''' WITH NORECOVERY' 
		   PRINT @cmd 
		   SET @lastFullBackup = @lastDiffBackup 
		END 

/* Check for log backups */
	DECLARE backupFiles CURSOR FOR  
	   SELECT backupFile  
	   FROM @fileList 
	   WHERE backupFile LIKE '%.TRN'  
	   AND backupFile LIKE @dbName + '%' 
	   AND backupFile > @lastFullBackup 

	OPEN backupFiles  

	/* Loop through all the files for the database  */
		FETCH NEXT FROM backupFiles INTO @backupFile  

		WHILE @@FETCH_STATUS = 0  
		BEGIN  
		   SET @cmd = 'RESTORE LOG ' + @dbRestoreName + ' FROM DISK = '''  
			   + @backupPath + @backupFile + ''' WITH NORECOVERY' 
		   PRINT @cmd 
		   FETCH NEXT FROM backupFiles INTO @backupFile  
		END 

		CLOSE backupFiles  
		DEALLOCATE backupFiles  

/* Put database in a useable state */
	SET @cmd = 'RESTORE DATABASE ' + @dbRestoreName + ' WITH RECOVERY' 
	PRINT @cmd 

/* END */


--/* To allow xp_cmdshell to work */

--		/* Show advanced options */
--			EXEC sp_configure 'show advanced options', 1;
--			GO
--		/* To update the currently configured value for advanced options. */
--			RECONFIGURE;
--			GO
--		/* To enable the feature. */
--			EXEC sp_configure 'xp_cmdshell', 1;
--			GO
--		/* To update the currently configured value for this feature. */
--			RECONFIGURE;
--			GO

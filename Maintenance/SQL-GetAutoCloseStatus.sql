/* Is AutoClose enabled */
	SELECT  name ,
			state_desc ,
			is_auto_close_on
	FROM    sys.databases
	WHERE   is_auto_close_on = '1'

/* How to disable AutoClose*/
    USE [master]
    ALTER DATABASE [DatabaseName] SET AUTO_CLOSE OFF;
	

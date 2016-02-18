/* SQL_GetDatabaseRolePermissions.sql */

DECLARE @RoleName NVARCHAR(128);
SET @RoleName = 'NameOfDBRole';

SELECT  'GRANT ' + Perms.permission_name + ' ON OBJECT::' + Perms.[Schema]
        + '.' + Perms.ObjectName + ' TO ' + Perms.RoleName + ';' AS [Permissions Granted]
FROM    ( SELECT    [Schema] = OBJECT_SCHEMA_NAME(major_id) ,
                    [ObjectName] = OBJECT_NAME(major_id) ,
                    [RoleName] = USER_NAME(grantee_principal_id) ,
                    permission_name
          FROM      sys.database_permissions p
          WHERE     p.class = 1
                    AND OBJECTPROPERTY(major_id, 'IsMSSHipped') = 0
        ) Perms
WHERE   [RoleName] = @RoleName
ORDER BY Perms.[Schema] ,
        Perms.ObjectName ,
        Perms.permission_name;

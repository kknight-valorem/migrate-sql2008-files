# Create-Load.ps1 - create load on the SQL 2008 AdventureWorks database
<#
    This is a simple PowerShell script that generates load on a SQL 2008 AdventureWorks database.
    The database was restored from https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks2008r2/adventure-works-2008r2-lt.bak

How it works
    It works by creating AdverntureWorks order detail records starting with Quantity 101 and incrementing.

Note: Invoke-Sqlcmd commandlet was developed post PowerShell 3.0 which is what gets installed on SQL Server 2008 so this code 
    is designed to run on the older version of PowerShell.
#>

Set-ExecutionPolicy Unrestricted -Force

Write-Output " "
Write-Output " "
Write-Output "Welcome to the SQL 2008 AdventureWorks load generator"
Write-Output "******************************************************"

# Configuration 
$wait       = 20;
$dbadmin    = "contosoadmin"
$dbpassword = "Passw0rd0000"
$database   = "AdventureWorksLT2008R2"
$table      = "[$database].[SalesLT].[SalesOrderDetail]"
$columns    = "(SalesOrderID,OrderQty,ProductID,UnitPrice,UnitPriceDiscount,rowguid,ModifiedDate)"
$connectionString = "Data Source=localhost,1433; " +`
                    "Database=$database; " +`
                    "User Id=$dbadmin; " +`
                    "Password=$dbpassword; "


Write-Output "Working against database $database, table $table"
Write-Output " "

# Connect to localhost AdventureWorks database
Write-Output "Connecting ... "
$connection = new-object system.data.SqlClient.SQLConnection($connectionString)
$connection.Open()
Write-Output "Connected. "

# Clean-up any prior runs
Write-Output "Cleaning up records if any from prior runs.";
$sqlCommand = "DELETE FROM $table WHERE (OrderQty > 100);";
$command = New-Object system.data.sqlclient.sqlcommand($sqlCommand,$connection);
$adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command;
$dataset = New-Object System.Data.DataSet;
$adapter.Fill($dataSet);
Write-Output "Cleaned.";

# Disable trigger on OrderDetail just in case
Write-Output "Disable trigger on OrderDetail.";
$sqlCommand = "ALTER TABLE $table DISABLE TRIGGER iduSalesOrderDetail";
$command = New-Object system.data.sqlclient.sqlcommand($sqlCommand,$connection);
$adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command;
$dataset = New-Object System.Data.DataSet;
$adapter.Fill($dataSet);
Write-Output "Trigger disabled.";

#############################################
# Load generating loop
#############################################
$i=101;
Write-Output "---------------------------------------------------------";
Write-Output "Generating load starting from $i every $wait seconds against $database";
DO {
    $time = (get-date).ToString('u');
    $time = $time.Substring(0,$time.Length-1)
    $guid = [guid]::NewGuid();
    $values = "('71774','$i','836','356.898','0.00','$guid','$time')";
    $sqlCommand = "INSERT INTO $table $columns VALUES $values";

    $command = New-Object system.data.sqlclient.sqlcommand($sqlCommand,$connection);
    $adapter = New-Object System.Data.sqlclient.sqlDataAdapter $command;
    $dataset = New-Object System.Data.DataSet;
    $adapter.Fill($dataSet);

    Write-Output "Created Order Detail recored with Quantity $i"
    Start-Sleep -Seconds $wait;
    $i=$i+1;
} While ($true);

$connection.Close()
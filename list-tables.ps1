$path = 'z:\Franc\Pagina Destek Soporte\database_01_schema.sql'
$tables = @{}
Select-String -Path $path -Pattern 'CREATE TABLE' | ForEach-Object {
  $line = $_.Line
  if ($line -match 'CREATE TABLE(?:\s+IF NOT EXISTS)?\s+(?:public\.)?(\w+)') {
    $name = $matches[1]
    if ($name -notin @('only')) { $tables[$name] = $true }
  }
}
$tables.Keys | Sort-Object | ForEach-Object { Write-Host $_ }

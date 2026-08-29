$envFile = 'z:\Franc\Pagina Destek Soporte\.env.local'
if (Test-Path $envFile) {
  Write-Host '--- .env.local (valores enmascarados) ---' -ForegroundColor Cyan
  Get-Content $envFile | ForEach-Object {
    $line = $_
    if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) {
      Write-Host $line
    } elseif ($line -match '^([^=]+)=(.*)$') {
      $name = $matches[1].Trim()
      $val  = $matches[2].Trim()
      if ($val.Length -gt 14) {
        $mask = $val.Substring(0,10) + '...' + $val.Substring($val.Length-4)
      } else {
        $mask = '***'
      }
      Write-Host ("{0} = {1}" -f $name, $mask)
    }
  }
} else {
  Write-Host 'NO EXISTE .env.local' -ForegroundColor Red
}

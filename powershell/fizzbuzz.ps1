param (
    [int]$Start = 1,
    [int]$End = 100
)

$moduloFizz = 3
$moduloBuzz = 5

if ($Start -lt $End) {
    for ($i = $Start; $i -le $End; $i++) {
        $result = ""
        if ($i % $moduloFizz -eq 0) {
            $result += "Fizz"
        }
        if ($i % $moduloBuzz -eq 0) {
            $result += "Buzz"
        }
        if ($result -eq "") {
            $result = $i.ToString()
        }
        Write-Output $result
    }
    exit 0
}
else {
    Write-Error "Start $Start is greater than or equal to max $End."
    exit 1
}

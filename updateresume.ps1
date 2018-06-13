param (
    [Parameter(Mandatory=$true)] [string]$token
)

$base = 'https://api.hh.ru'


function Result-FromHH{
param (
    [Parameter(Mandatory=$True)][string]$uri,
    $method = "Get"
)

    $access_token = @{
        "Authorization" = "Bearer {0}" -f $token
    }

    try {
        $result = (Invoke-WebRequest -uri $uri -method $method -Headers $access_token).Content | ConvertFrom-Json
    }
    catch {
        $result = $false
    }
    return $result
}


DO 
{
    #Step one: Check auth token
    $uri = "$base/me"
    if (-not (Result-FromHH ( $uri ))) {
        throw "Something go wrong, maybe your auth token failed. Check your token!"
    }

    $uri = "$base/resumes/mine"

    foreach ( $resumeurl in $(Result-FromHH( $uri )).items.url) {
        $uri = "$resumeurl"
        $resumeurl = Result-FromHH( $uri )
        if ((Get-date) -ge (Get-date $resumeurl.next_publish_at)){
            Start-Sleep -Seconds 60
            $uri = "$uri/publish"
            if (-not $(Result-FromHH -uri $uri -method "POST")) {
                Write-Output "Unknown answer, ignore this."
            } 
            else { 
                write-output "Success, time to sleep."
            }
        }
        else {
            if ((Get-date $resumeurl.next_publish_at) -ge $time ) {
                $time = $((Get-date $resumeurl.next_publish_at).AddMinutes(60))
            }
        }
    }
    
    write-output "Sleep until $time`. Zzzzz"
    if ((New-TimeSpan -end $time).TotalSeconds -le 0) {
        $time = (get-date).AddHours(1)
    }
    Sleep -second (New-TimeSpan -end $time).TotalSeconds
    
} WHILE( $true )
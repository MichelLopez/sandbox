$releasesUri = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
$StoreURL = "https://www.microsoft.com/en-us/p/app-installer/9nblggh4nns1"
$URI = "https://store.rg-adguard.net/api/GetFiles"
$SavePathRoot=((Get-Location).path)
$wchttp=[System.Net.WebClient]::new()
$myParameters = "type=url&url=$($StoreURL)"
$wchttp.Headers[[System.Net.HttpRequestHeader]::ContentType]="application/x-www-form-urlencoded"
$HtmlResult = $wchttp.UploadString($URI, $myParameters)
$Start=$HtmlResult.IndexOf("<p>The links were successfully received from the Microsoft Store server.</p>")
$TableEnd=($HtmlResult.LastIndexOf("</table>")+8)
$SemiCleaned=$HtmlResult.Substring($start,$TableEnd-$start)
$newHtml=New-Object -ComObject "HTMLFile"
try {
    $newHtml.IHTMLDocument2_write($SemiCleaned)
}
catch {
    $src = [System.Text.Encoding]::Unicode.GetBytes($SemiCleaned)
    $newHtml.write($src)
}
$ToDownload=$newHtml.getElementsByTagName("a") | Select-Object textContent, href
Foreach ($Download in $ToDownload)
{
    If ($Download  -like '*x64*'  -AND $Download  -like '*appx*')
    {
    if ($Download -like "*Desktop*"){
        $UWPDesktop = $Download.textContent
    }else {
        $VCLibs= $Download.textContent
    }
    $wchttp.DownloadFile($Download.href, "$SavePathRoot\$($Download.textContent)")
    }
}
$downloadUri = ((Invoke-RestMethod -Method GET -Uri $releasesUri).assets | Where-Object name -like "*.appxbundle" ).browser_download_url
Invoke-WebRequest -Uri $downloadUri -Out ($SavePathRoot+'\'+(($downloadUri.Substring($downloadUri.LastIndexOf("/") + 1))))
Add-AppxPackage -Path (($downloadUri.Substring($downloadUri.LastIndexOf("/") + 1))) -DependencyPath $VCLibs,$UWPDesktop
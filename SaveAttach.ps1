Add-Type -assembly "Microsoft.Office.Interop.Outlook"
$sReportPath = "C:\example"

Function fSaveAttachment {
    Param(
        $oAttachment
    )

    [string]$sFilePath = "C:\example\" + $oAttachment.FileName
    $oAttachment.SaveAsFile($sFilePath)

    Return $sFilePath
}
Function fSaveAttachmentOSZH {
    Param(
        $oAttachment
    )
    $unic_suf = Get-Date -Format "yyyyMMddHHmmss"
    [string]$sFilePath = "C:\example\file_example_" + $unic_suf + ".xlsx"
    $oAttachment.SaveAsFile($sFilePath)
    copy $sFilePath "C:\example\ARC"
    move $sFilePath "i:\example\"
    Return $sFilePath
}

Function fProcessReports {

    [bool]$bReady = $true

    Write-Output " "
    Write-Output "$(Get-Date) ЗАПУСК ПРОЦЕССА ОБРАБОТКИ"
    Write-Output "$(Get-Date) ======================================="
    
    try {
        $oOutlook = New-Object -com Outlook.Application
        $oOutlookProcess = Get-Process Outlook
        $oNamespace = $oOutlook.GetNameSpace("MAPI")
        $oInboxFolder = $oNamespace.GetDefaultFolder(6) 
        $oExplorer = $oInboxFolder.GetExplorer()
    }
    Catch {
        $bReady = $false
        Write-Output "$(Get-Date) !Ошибка создания объекта Outlook"
    }

   :loop1 while($bReady) {
        Write-Output "$(Get-Date) "
        
        [bool]$bExitStatus = fCheckExitStatus $oOutlook $oNamespace $oInboxFolder
        if($bExitStatus -eq $true) {
            break loop1
        }

        Write-Output "$(Get-Date) !Новый цикл обработки"

        try {
            Write-Output "$(Get-Date) !Попытка cохранения из письма вложения"
            fDoWork $oOutlook $oNamespace $oInboxFolder
        }
        Catch {
            Write-Output "$(Get-Date) !Ошибка сохранения файла!"    
        }
    }
  
}



Function fCheckExitStatus {
    Param(
        $oOutlook,
        $oNamespace,
        $oInboxFolder
    )

    [bool]$bNeedExit = $false

    $oInboxItems = $oInboxFolder.items
    foreach($oInboxItem in $oInboxItems) {
        if($oInboxItem.To -eq "PFI") {
            if($oInboxItem.Subject -eq "StopProcessReports") {
                fMoveReportMessage $oOutlook $oInboxFolder $oInboxItem "Exits"
                $bNeedExit = $true
                break;
            }
        }
    }

    Return $bNeedExit
}

Function fDoWork {
    Param(
        $oOutlook,
        $oNamespace,
        $oInboxFolder
    )

    $oInboxItems = $oInboxFolder.items
    if($oInboxItems -ne $NULL) {
        foreach($oInboxItem in $oInboxItems) {
            Start-Sleep -Seconds 5
            [string]$sInboxItemSubject = $oInboxItem.Subject.ToUpper()
            [string]$sInboxItemAddress = $oInboxItem.SenderName.ToUpper()
            if($oInboxItem.To -eq "pfi") {
                    if($sInboxItemSubject -eq "LIBOR") {
                        Write-Output ("$(Get-Date)  Начало обработки данных " + "example")
                        if($oInboxItem.Attachments.Count -gt 0) {
                                foreach($oAttachment in $oInboxItem.Attachments) {
                                    [string]$sFileName = $oAttachment.FileName
                                    Write-Output ("$(Get-Date)   Сохранение из письма вложения " + $sFileName)
                                    [string]$sReportPath = fSaveAttachment $oAttachment  
                                    fMoveFileToARC $sReportPath                         
                                }
                                fMoveReportMessage $oOutlook $oInboxFolder $oInboxItem "example"
                        }
                    }                
            }elseif($sInboxItemSubject -eq "КЛИЕНТ example"){
                Write-Output ("$(Get-Date)  Начало обработки данных " + "example")
                if($oInboxItem.Attachments.Count -gt 0) {
                    foreach($oAttachment in $oInboxItem.Attachments) {
                        if($oAttachment.FileName -match ".xlsx"){
                        [string]$sFileName = $oAttachment.FileName
                        Write-Output ("$(Get-Date)   Сохранение из письма вложения " + $sFileName)
                        [string]$sReportPath = fSaveAttachmentOSZH $oAttachment
                        }else{
                            Write-Output ("$(Get-Date) " + $oAttachment.FileName  + " не является XLSX файлом. ")
                        }                         
                    }
                    fMoveReportMessage $oOutlook $oInboxFolder $oInboxItem "example"
                }  
            }
        Write-Output ("$(Get-Date)   В письме отсутствуют файлы для сохранения.")
        Write-Output ("$(Get-Date)   Архивирование письма.")
        fMoveReportMessage $oOutlook $oInboxFolder $oInboxItem "БезВложений"
        }
    }else {
        Write-Output "$(Get-Date) !Отсутствуют файлы для сохранения." 
        Write-Output "$(Get-Date) !Ожидание 1 минута."
        Start-Sleep -Seconds 60   
    }
}

Function fMoveFileToARC {
    Param(
        $sFilePath
    )

    $oFile = Get-ChildItem $sFilePath
    [string]$sDate = Get-Date -format yyyyMMddHHmm
    [string]$sARCFilePath = $oFile.DirectoryName + "\ARC\" + $oFile.BaseName + "_" + $sDate + $oFile.Extension
    [string]$sINfilePath = "I:\IN\" + $oFile.BaseName + $oFile.Extension
    Copy-Item $sFilePath -Destination "I:\IN\"
    Move-Item $sFilePath $sARCFilePath
}

Function fMoveReportMessage {
    Param(
        $oOutlook,
        $oInboxFolder,
        $oInboxItem,
        $sForm
    )

    $oTargetFolder = $oInboxFolder.Folders.Item($sForm)
    [void]$oInboxItem.Move($oTargetFolder)
}

fProcessReports
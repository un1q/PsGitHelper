Function String-To-FileInfo {
    Param(
        [parameter(ValueFromPipeline)][String] $Path
    )
    Begin {
        pwd | % { [IO.Directory]::SetCurrentDirectory($_.path) }
    }
    Process {
        if ($Path -match '^\".*\"$') {
            [System.IO.FileInfo]($Path -replace '^"(.*)"$','$1')
        } else {
            [System.IO.FileInfo]($Path -replace '^(.*)$','$1')
        }
    }
}

Function Git-Status {
    Param(
        [parameter(ValueFromRemainingArguments)][String[]]$args
    )
    Begin {
        pwd | % { [IO.Directory]::SetCurrentDirectory($_.path) }
        $__index=0
    }
    Process {
        $GitArgs = @()
        if ($Args) {
            $GitArgs += $Args
        }
        &git status -s $GitArgs | % {
            if ($_ -match '^.. (.*)->(.*)$') {
                $fileOrigin = String-To-FileInfo ($_ -replace '^.. (.*)->(.*)$','$1')
                $file = String-To-FileInfo ($_ -replace '^.. (.*)->(.*)$','$2')
            } else {
                $file = String-To-FileInfo ($_ -replace '^.. (.*)','$1')
                $fileOrigin = ""
            }
            [PSCustomObject]@{
                Id=$__index
                Index=$_ -replace "^(.). (.*)$",'$1'
                WorkTree=$_ -replace "^.(.) (.*)$",'$1'
                #filePath=$fp
                FileOrigin = $fileOrigin
                File = $file
            }
            $__index++
        }
    }
}

Function Git-Add {
    Param(
        [parameter(ValueFromPipelineByPropertyName)] [System.IO.FileInfo[]]$File,
        [parameter(ValueFromPipeline)] [String[]]$FilePath,
        [parameter(ValueFromRemainingArguments)] [String]$otherArgs
    )
    Begin {
        pwd | % { [IO.Directory ]::SetCurrentDirectory($_.path) }
    }
    Process {
        if ($File) {
            $p = $File.FullName
        } else {
            $p = $FilePath
        }
        git add $otherArgs $p
    }
}

Function Git-Diff {
    Param(
        [parameter(ValueFromPipelineByPropertyName)] [System.IO.FileInfo[]]$File,
        [parameter(Mandatory=$false)] [Switch]$PathsFromPipeline,
        [parameter(ValueFromPipeline)] [String[]]$_PathsFromPipeline,
        [parameter(ValueFromPipelineByPropertyName, Mandatory=$false)] [String]$Commit,
        [parameter(ValueFromPipelineByPropertyName, Mandatory=$false)] [String]$Commit2,
        [parameter(ValueFromRemainingArguments)] [String]$OtherArgs
    )
    Begin {
        pwd | % { [IO.Directory ]::SetCurrentDirectory($_.path) }
    }
    Process {
        if ($File) {
            $p = $File.FullName
        } elseif ($PathsFromPipeline) {
            $p = $_PathsFromPipeline
        }
        $GitArgs = @()
        if ($OtherArgs) {
            $GitArgs += $OtherArgs
        }
        if ($Commit2) {
            $GitArgs += $Commit2
        }
        if ($Commit) {
            $GitArgs += $Commit
        }
        &git diff $GitArgs -- $p
    }
}

Function Git-Log {
    Param(
        [parameter(Mandatory=$false)][Switch] $Pretty,
        [parameter(Mandatory=$false)][Switch] $PrettyString,
        [parameter(Mandatory=$false)][Switch] $AsRange,
        [parameter(Mandatory=$false)][Switch] $AsOneRange,
        [parameter(ValueFromRemainingArguments)][String] $Args
    )
    Process {
        $format = "H%hH P%pP D%adD @@@@%an@@@@ %s"
        $regexPattern = "^H([^H]+)H P([^P]+)P D([^D]+)D @@@@(.*)@@@@ (.*)$"
        $regexCommit1 = '$1'
        $regexCommit2 = '$2'
        $regexDate    = '$3'
        $regexAuthor  = '$4'
        $regexDesc    = '$5'
        if ($AsOneRange) {
            $logs = git log --pretty=format:$format --date=short $Args
            [PSCustomObject]@{
                Id  = 0;
                Commit =  $logs[0]              -replace $regexPattern,$regexCommit1;
                Commit2=  $logs[$logs.Count-1]  -replace $regexPattern,$regexCommit2;
                Desc   = ($logs[0]              -replace $regexPattern,$regexDesc) +
                          ' .. ' +
                         ($logs[$logs.Count-1]  -replace $regexPattern,$regexDesc);
            }
        } elseif ($PrettyString) {
            (git log --oneline --graph --decorate $Args)
        } elseif ($Pretty) {
            git log --oneline --graph --decorate $Args
        } else {
            $__index = 0
            git log --pretty=format:$format --date=short $Args | % {
                if ($AsRange) {
                    [PSCustomObject]@{
                        Id  = $__index++;
                        Commit =$_ -replace $regexPattern,$regexCommit1;
                        Commit2=$_ -replace $regexPattern,$regexCommit2;
                        Date   =$_ -replace $regexPattern,$regexDate;
                        Author =$_ -replace $regexPattern,$regexAuthor;
                        Desc   =$_ -replace $regexPattern,$regexDesc
                    }
                } else {
                    [PSCustomObject]@{
                        Id  = $__index++;
                        Commit =$_ -replace $regexPattern,$regexCommit1;
                        Date   =$_ -replace $regexPattern,$regexDate;
                        Author =$_ -replace $regexPattern,$regexAuthor;
                        Desc   =$_ -replace $regexPattern,$regexDesc
                    }
               }
            }
        }
    }
}

Function Git-Commit {
    Param(
        [parameter(ValueFromRemainingArguments)][String[]] $Args,
        [parameter(Mandatory=$false)][Alias("M")][String] $Message,
        [parameter(Mandatory=$false)][Alias("A")][Switch] $All,
        [parameter(Mandatory=$false)][Switch] $Amend
    )
    Begin {
        pwd | % { [IO.Directory]::SetCurrentDirectory($_.path) }
        $GitArgs = @()
        if ($Args) {
            $GitArgs += $Args
        }
        if ($Message) {
            $GitArgs += "-m"
            $GitArgs += $Message
        }
        if ($Amend) {
            $GitArgs += "--amend"
        }
        if ($All) {
            $GitArgs += "--all"
        }
        &git commit $GitArgs
    }
}

Function Git-Show {
    Param(
        [parameter(ValueFromPipelineByPropertyName)][String] $Commit,
        [parameter(Mandatory=$false)][Switch] $NamesOnly,
        [parameter(ValueFromRemainingArguments)][String[]] $Args
    )
    Begin {
        pwd | % { [IO.Directory ]::SetCurrentDirectory($_.path) }
    }
    Process {
        $GitArgs = @()
        if ($Args) {
            $GitArgs += $Args
        }
        if ($NamesOnly) {
            $GitArgs += "--name-only"
        }
        &git show $Commit $GitArgs
    }
}

Function Git-Diff-Tree {
    Param(
        [parameter(ValueFromPipelineByPropertyName)][String] $Commit,
        [parameter(Mandatory=$false)][Switch] $NamesOnly,
        [parameter(Mandatory=$false)][Alias("R")][Switch] $Recurency,
        [parameter(ValueFromRemainingArguments)][String[]] $Args
    )
    Begin {
        pwd | % { [IO.Directory ]::SetCurrentDirectory($_.path) }
    }
    Process {
        $GitArgs = @()
        if ($Args) {
            $GitArgs += $Args
        }
        if ($NamesOnly) {
            $GitArgs += "--name-only"
        }
        if ($Recurency) {
            $GitArgs += "-r"
        }
        &git diff-tree $Commit $GitArgs
    }
}

Function Git-Rebase {
    Param (
        [parameter(ValueFromPipelineByPropertyName)][String] $Commit,
        [parameter(Mandatory=$false)][Alias("I")][Switch] $Interactive,
        [parameter(ValueFromRemainingArguments)][String[]] $Args
    )
    Begin {
        pwd | % { [IO.Directory]::SetCurrentDirectory($_.path) }
    }
    Process {
        $GitArgs = @()
        if ($Args) {
            $GitArgs += $Args
        }
        if ($Interactive) {
            $GitArgs += "-i"
        }
        &git rebase $Commit $GitArgs
    }
}

Function Git-Checkout {
    Param (
        [parameter(ValueFromPipelineByPropertyName)] [System.IO.FileInfo[]]$File,
        [parameter(Mandatory=$false)][Alias("b")][String] $Branch,
        [parameter(Mandatory=$false)][String] $Path,
        [parameter(ValueFromRemainingArguments)][String[]] $Args
    )
    Begin {
        if ($File -and $Path){
            Write-Error -Message "Git-Checkout needs files in pipeline OR file in Path argument - not both!"
            exit
        }
        pwd | % { [IO.Directory]::SetCurrentDirectory($_.path) }
    }
    Process {
        $GitArgs = @()
        if ($Args) {
            $GitArgs += $Args
        }
        if ($Branch) {
            $GitArgs += "-b"
            $GitArgs += $Branch
        }
        if ($File) {
            $GitArgs += "--"
            $GitArgs += $File.FullName
        }
        if ($Path){
            $GitArgs += "--"
            $GitArgs += $Path
        }
        ">>> $GitArgs"
        &git checkout $GitArgs
    }
}

"Git helper commandlets added"
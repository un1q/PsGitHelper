Function String-To-FileInfo {
    Param(
        [parameter(ValueFromPipeline)][String] $Path
    )
    Begin {
        pwd | % { [IO.Directory]::SetCurrentDirectory($_.path) }
    }
    Process {
        if ($Path -match '^.. \".*\"$') {
            [System.IO.FileInfo]($Path -replace '^.. "(.*)"$','$1')
        } else {
            [System.IO.FileInfo]($Path -replace '^.. (.*)$','$1')
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
        if (!$args) {
            $args = @()
        }
        &git status -s $args | % {
            if ($_ -match '^(.*)->(.*)$') {
                $fileOrigin = String-To-FileInfo ($_ -replace '^(.*)->(.*)$','$1')
                $file = String-To-FileInfo ($_ -replace '^(.*)->(.*)$','$2')
            } else {
                $file = String-To-FileInfo $_
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
        git diff $otherArgs $p
    }
}

Function Git-Log {
    Param(
        [parameter(Mandatory=$false)][Switch] $Pretty,
        [parameter(ValueFromRemainingArguments)][String] $Args
    )
    Process {
        if ($Pretty) {
            git log --oneline --graph --decorate $Args
        } else {
            $__index = 0
            git log --pretty=format:"%h %ad %s" --date=short $Args | % {
                [PSCustomObject]@{
                    Id  = $__index++;
                    Hash=$_ -replace "^([^\s]+) ([^\s]+) (.*)$",'$1';
                    Date=$_ -replace "^([^\s]+) ([^\s]+) (.*)$",'$2';
                    Desc=$_ -replace "^([^\s]+) ([^\s]+) (.*)$",'$3'
                }
            }
        }
    }
}

Function Git-Commit {
    Param(
        [parameter(ValueFromRemainingArguments)][String[]] $Args,
        [parameter(Mandatory=$false)][Alias("M")][String] $Message,
        [parameter(Mandatory=$false)][Switch] $Amend
    )
    Begin {
        pwd | % { [IO.Directory]::SetCurrentDirectory($_.path) }
        if (!$Args) {
            $Args = @()
        }
        if ($Message) {
            $Args += "-m"
            $Args += $Message
        }
        if ($Amend) {
            $Args += "--amend"
        }
        &git commit $Args
    }
}

Function Git-Show {
    Param(
        [parameter(ValueFromPipelineByPropertyName)][String] $Hash,
        [parameter(Mandatory=$false)][Switch] $NamesOnly,
        [parameter(ValueFromRemainingArguments)][String[]] $Args
    )
    Begin {
        pwd | % { [IO.Directory ]::SetCurrentDirectory($_.path) }
    }
    Process {
        if (!$Args) {
            $Args = @()
        }
        if ($NamesOnly) {
            $Args += "--name-only"
        }
        &git show $Hash $Args
    }
}

Function Git-Diff-Tree {
    Param(
        [parameter(ValueFromPipelineByPropertyName)][String] $Hash,
        [parameter(Mandatory=$false)][Switch] $NamesOnly,
        [parameter(Mandatory=$false)][Alias("R")][Switch] $Recurency,
        [parameter(ValueFromRemainingArguments)][String[]] $Args
    )
    Begin {
        pwd | % { [IO.Directory ]::SetCurrentDirectory($_.path) }
    }
    Process {
        if (!$Args) {
            $Args = @()
        }
        if ($NamesOnly) {
            $Args += "--name-only"
        }
        if ($Recurency) {
            $Args += "-r"
        }
        &git diff-tree $Hash $Args
    }
}

Function Git-Rebase {
    Param (
        [parameter(ValueFromPipelineByPropertyName)][String] $Hash,
        [parameter(Mandatory=$false)][Alias("I")][Switch] $Interactive,
        [parameter(ValueFromRemainingArguments)][String[]] $Args
    )
    Begin {
        pwd | % { [IO.Directory]::SetCurrentDirectory($_.path) }
    }
    Process {
        if (!$Args) {
            $Args = @()
        }
        if ($Interactive) {
            $Args += "-i"
        }
        &git rebase $Hash $Args
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
        if (!$Args) {
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
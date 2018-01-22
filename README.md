# PsGitHelper
Powershell scripts for git. All it does, is parsing git output into c# objects.

## Why?

Because I'd like to do this:

```
Git-Status | ? {$_.File -like '*Achiev*'} | Git-Add ; Git-Commit
```

or this:

```
Git-Log -20 | Select-Object -Index 8 | Git-Rebase -i
```

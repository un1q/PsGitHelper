# PsGitHelper
Powershell scripts for git. All it does, is parsing git output into c# objects.

## Why?

Because I'd like to do this:

```
Git-Status | Select-Object -Index 0 | Git-Add ; Git-Commit -m 'awsome change'
```

or this:

```
Git-Status | ? {$_.File -like '*Achiev*'} | Git-Add ; Git-Commit
```

or this:

```
Git-Log -20 | Select-Object -Index 8 | Git-Rebase -i
```

or this:

```
Git-Log -5 | Git-Diff-Tree -NamesOnly -r | Sort-Object -Unique
```

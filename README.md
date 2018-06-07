# PsGitHelper
Powershell scripts for git.
All it does, is parsing git output into c# objects and receives that objects on input,
so you can use output of one commandlet as input for another.

## Why?

Because I'd like to do this:

```
#Get files deleted in work tree
Git-Status | ? {$_.WorkTree -eq 'D'} | Format-Table
```

```
#Add only first element received with Git-Status and then commit
Git-Status | Select-Object -Index 0 | Git-Add ; Git-Commit -m 'awsome change'
```

or this:

```
#Add and commit files that changed and have Achiev in name
Git-Status | ? {$_.File -like '*Achiev*'} | Git-Add ; Git-Commit
```

or this:

```
#Rebase last 8 commits
Git-Log -8 | Select-Object -Last 1 | Git-Rebase -i
```

or this:

```
#Show changed files in last 5 commits and sort them by name
Git-Log -5 | Git-Diff-Tree -NamesOnly -r | Sort-Object -Unique
```

or this:

```
#Show differences in file in last 4 commits
Git-Log -4 -AsRange | Git-Diff -FilePath my/awesome/script.cs
```

# PsGitHelper
Powershell scripts for git.
All it does, is parsing git output into .NET objects and also it can use those objects on the input.

## Why?

One of the most neat feature of powershell is that you can send whole objects through pipeline.

Examples:

Git-Status: you can use output from Git-Status as input to Git-Add

```
#Get files deleted in work tree - one can filter all statuses by work tree od index state:
Git-Status | ? {$_.WorkTree -eq 'D'} | Format-Table
```

```
#Add only first element received with Git-Status and then commit - one can send filtered output from Git-Status to Git-Add:
Git-Status | Select-Object -Index 0 | Git-Add ; Git-Commit -m 'awsome change'
```

```
#Add and commit files that changed and have Achiev in name - one can filter status by file names and add only filtered files:
Git-Status | ? {$_.File -like '*Achiev*'} | Git-Add ; Git-Commit
```

Git-Log: you can use output from Git-Log as input to Git-Rebase, Git-Diff or Git-Diff-Tree

Use -pretty attribute if you want to get graph, but don't use it as input for other commandlets in this project

Use -AsOneRange if you want to get range of commits, not list of commits (you can use it as Git-Diff input)

Use -AsRange if you want to get list of commits, each as two-commits range (you can use it as Git-Diff input)

```
#Rebase last 8 commits - one can use Git-Log output as input to Git-Rebase
Git-Log -8 | Select-Object -Last 1 | Git-Rebase -i
```

```
#Show changed files in last 5 commits and sort them by name - one can use Git-Log output as input to Git-Diff-Tree
Git-Log -5 | Git-Diff-Tree -NamesOnly -r | Sort-Object -Unique
```

```
#Show differences in file in last 4 commits - one can use Git-Log output as input to Git-Diff
Git-Log -4 -AsOneRange | Git-Diff -FilePath my/awesome/script.cs
```

```
#Show differences in file in last 4 commits step by step - one can use Git-Log output as input to Git-Diff
Git-Log -4 -AsRange | Git-Diff -FilePath my/awesome/script.cs
```

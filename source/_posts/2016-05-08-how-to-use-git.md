---
layout: post
title: "如何使用git"
date: 2016-05-08 07:48:51 -0700
comments: true
categories: 读书笔记
---

git 作为版本控制工具，已被广泛使用，公司从去年开始陆续将版本控制系统从 Perforce 向 git 转移。[《Pro Git》](https://git-scm.com/book/en/v2)作为官方推荐的学习 git 书籍，不可不读，而且该书已经有[中文版](https://git-scm.com/book/zh)。这篇就将记录自己学习使用 git 的过程。
<!--more-->

开发项目时，使用 git 主要的全过程可以大体概况为如下三个步骤：

	1. 使用 git clone 命令从远程服务器上拉取源代码到本地。
	
	2. 按照自己的需要，本地修改从步骤 1 拉取下来的代码。
	
	3. 将修改好的代码 git push 到远程服务器上。
	
###拉取源码
---
以 octopress 为例，使用 `git clone` 命令从远程服务器拉起代码的命令一般如下：

```
$ git clone git@github.com:imathis/octopress.git octopress
```
此时，该命令就会将 octopress 的源码拉取到本地，并命名为 octopress 文件夹。如果使用 `git branch` 命令查看 branch 名称时，默认 branch 会是 `master` 。如果使用 `git remote -v` 来查看远程服务器名称时，默认名称会是 `origin`。

```
binglis-Mac:octopress bingli$ git branch
* master
binglis-Mac:octopress bingli$ git remote -v
origin	git@github.com:imathis/octopress.git (fetch)
origin	git@github.com:imathis/octopress.git (push)
```
`git clone` 是 clone 仓库，它主要用于在服务器端已经存在源码目录的情况，该方法在程序开发过程中非常有用。但如果一开始并没有这样的远程仓库，而需要我们从头开始呢？`git init` 正是在现有目录中初始化仓库，该命令创建一个名为 `.git` 的子仓库，这个子目录含有你初始化的 Git 仓库中所有的必须文件。

###修改代码
---
git 仓库里的源码一共有 4 种状态，分别是：`Untracked` `Unmodified` `Modified` `Staged`。仓库里哪些文件处于哪些状态可以通过 `git status` 命令来查看。

```
binglis-Mac:octopress bingli$ git status
On branch source
Your branch is based on 'origin/master', but the upstream is gone.
  (use "git branch --unset-upstream" to fixup)
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git checkout -- <file>..." to discard changes in working directory)

	modified:   source/_posts/2016-05-08-how-to-use-git.md

no changes added to commit (use "git add" and/or "git commit -a")
```

`git status` 不仅可以查看状态，还能够提示如果变更某些文件的状态，如上面的 `2016-05-08-how-to-use-git.md` 处于 `modified` 状态，可以使用 `git add` 或 `git checkout` 命令修改它的状态。



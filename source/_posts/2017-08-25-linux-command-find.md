---
layout: post
title: "Linux常用命令之Find"
date: 2017-08-25 08:39:05 -0700
comments: true
categories: 编程工具
---
* list element with functor item
{:toc}

本文主要记录 Linux 中常用命令之一Find 的使用方法。

<!--more-->

## Find 命令概述

Linux 中的 Find 命令是 Linux 系统中最重要最常用的命令之一。它是用来在指定目录下查找文件的，并对查找到的文件进行处理。它的使用格式如下：

> $find <指定目录> <指定条件> <指定动作>

* 指定目录:所要搜索的目录，比如默认为当前目录，或指定特定的目录。
* 指定条件:所要搜索的文件特征比如文件名称、文件大小、文件属性等。
* 指定动作:对搜索结果进行特定的处理，比如对搜索到的结果删除、将搜索结果放到特定文件中。

任何位于参数之前的字符串都被视为搜索目录。
它可以根据不同的命令参数选择不同的搜索方式，常用的参数选项有：

* -name <filename>:指定搜索文件名称。
* -type <filetype>:指定搜索文件的类型。
* -size <filesize>:指定搜索文件的大小。
* -user <username>:指定特定用户。
* -group <groupname>:指定特定组。
* -maxdepth/mindepth <num>:指定搜索目录级别。
* -exec <command>:假设 find 指令的回传值为 TRUE，就执行 command 指令。

## Find 命令示例

查看当前目录及其子目录下的所有文件。

```
find
```

根据名字查找文件。

```
//find [dir-path] -name [filename]
$ find . -name testfile1.txt
$ find /home -name testfile1.txt
```

查找某种特定类型的文件。

```
$find . -name "*.txt"
```

忽视大小写来查找文件。

```
//find -iname [filename]
$ find -iname testfile1.txt
```

查找与搜索模式不匹配的文件。

```
$find . -not -name "*.txt"
$find . ! -name "*.txt"
```

限定搜索目录级别。

```
$find . -maxdepth 3 -name "*.txt"
$find . -mindepth 3 -name "*.txt"
$find . -mindepth 2 -maxdepth 4 -name "*.txt"
```

显示所有的空文件。

```
$find . -empty
```

查找某个特定组的文件。

```
$find . -group bing -name "*.txt"
```

查找某个特定用户的文件。

```
$find . -user bing -name "*.txt"
```

查找最近修改过的文件。

```
$find . -mmin 1 -name "*.txt"
```

查找特定类型的文件。

```
// find -type <filetype>
$find -type d //查找目录文件
```

查找两种类型的文件。

```
$find . \( -name a.out -o -name '*.o' -o name 'core' \) -exec rm {} \;
```

对查找到的文件执行某些命令。

```
$find $HOME/. -name *.txt -exec head -n 1 -v {} \; > report.txt
```

## 参考资料

1. [Find Command Wiki](https://en.wikipedia.org/wiki/Find)  
2. [Find Command Man Page](http://man7.org/linux/man-pages/man1/find.1.html)
3. [14 Practical Examples of Linux Find Command for Beginners](https://www.howtoforge.com/tutorial/linux-find-command/)
4. [使用 UNIX find 命令的高级技术](https://www.ibm.com/developerworks/cn/aix/library/es-unix-find.html)


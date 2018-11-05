---
layout: post
title: "linux 使用小技巧总结"
date: 2017-05-01 19:03:52 -0700
comments: true
categories: 总结积累
---

* list element with functor item
{:toc}

Linux 使用过程中，有些特殊的小技巧能够很好地提高效率。在此记录使用过程中的惊艳的小技巧。  

<!--more-->

## 快速搜索命令

Linux 使用大部分是在命令行下进行的，某些命令是前面使用到的，此时我们不想重新完整的输入命令，而是想根据命令中的某些关键字搜索到该命令，然后直接执行。
此时第一个想到的方法可能是`history`命令，然后复制粘贴，其实还有一个更智能的命令搜索命令`Ctrl+r`。执行完`Ctrl+r`后，可直接输出要查找的命令中的某个
关键字。然后直接回车即可！非常方便，尤其是命令行比较长的时候。  

## 命令行快捷键

Linux 命令行经常遇到输入错误，需要修改的时候，此时如果命令行特别长，想要用方向键或退格键来进行修改删除，速度会特别慢，其实 Linux 命令行也有
很多快捷键可以使用。具体有如下几个：

* `Ctrl+a` 移至命令行行首
* `Ctrl+e` 移至命令行行尾
* `Ctrl+u` 从光标处删除至命令行行首
* `Ctrl+k` 从光标处删除至命令行行尾

{% img /images/linux_tips/linuxcommandshortcut.png %}

## 清理虚拟机vmdk文件大小

MacOS 虚拟机在使用过程中，占用空间越来越大，分配的40G竟然有点卡了，找了好多办法都没成功，最后还是通过`VMVare Tools`工具瘦身成功的，节省了接近 15G 的空间。方法很简单，只需要一条命令即可：  

```
sudo  /Library/Application\ Support/VMware\ Tools/vmware-tools-cli disk shrink  /
```

## 其他技巧


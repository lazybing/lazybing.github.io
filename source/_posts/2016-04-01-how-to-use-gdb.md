---
layout: post
title: "How To Use GDB"
date: 2016-04-01 07:48:51 -0700
commit: true
categories: 编程工具
---

* list element with functor item
{:toc}

[GDB](https://www.gnu.org/software/gdb/), The GNU Project debugger, allows you to see what is going on inside another program while it executes -- or what another program was doing at the moment it crashed.

<!--more-->

### 前期准备

GDB 一般用于调试`C/C++`程序，要想能够使用`GDB`调试`C/C++`程序，首先必须将调试信息添加到可执行程序中。使用`gcc/g++`的`-g`参数可以做到这一点。如：

```
gcc -g programe.c -o programe
```
此时，可执行程序`programe`中就包含了调试需要的各种信息，如程序函数名、变量名等。

### 启动GDB



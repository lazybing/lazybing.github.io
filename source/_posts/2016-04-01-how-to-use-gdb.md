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
对于 MAC OSX 系统，调试信息会包含在另外一个`programe.dSYM`（debug symbols）文件夹下面，可以使用`dwarfdump programe.dSYM`直接查看各符号信息。

### 启动GDB

```
gdb programe
```

### 查看源码

```
list linenum  //查看linenum行的源码
list function //查看function的源码
```

### 断点break 使用

设置断点的方法
```
break linenum  //在 linenum 处设置断点
break function //在进入指定 function 时停住
break filename:linenum  //在源文件 filename 的 linenum 行处停住
break filename:function //在源文件 filename 的 function 函数的入口处停住
break *address          //在程序运行的内存地址处停住
```

查看断点信息
```
info break    //查看所有 break 的信息
info break n //查看 n 断点号的信息
```

### 查看运行时数据

当运行程序到某个位置时，我们希望看看此时程序的状态，比如某个变量的值是否按照预期改变、某块内存的值是否被改。此时就需要用到查看程序运行数据的集中方法。

查看格式 `print <expr>`或`print /<f> <expr>`，其中`<expr>`是要查看的表达式，可以是一个变量、数组、表达式等，`<f>`是输出时的格式，比如想要按照 16 进制输出，就使用`/x`。

可以使用 examine 命令查看内存地址中的值。格式是`x /<n/f/u> <addr>`，其中`<addr>`是内存地址。


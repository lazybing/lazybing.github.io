---
layout: post
title: "系统内存检测工具Valgrind入门"
date: 2017-10-05 19:07:13 -0700
comments: true
categories: 编程工具
---

* list element with functor item
{:toc}

`Valgrind`是一个很好地内存检测工具，本文记录如何开始`Valgrind`的使用。  

<!--more-->

## Valgrind 工具简介

`Valgrind`工具提供了很多`Debugging`和`Profiling`工具，来帮助开发者开发出更好快更正确的程序。其中最常用的工具是`内存检测`。它可以
检测到`C/C++`中内存相关的错误，这些错误可能会导致系统崩溃`Crashes`或者其他莫名其妙的行为。  

## Valgrind 前期准备

编译程序时，使用`-g`选项，用来包含`Debugging`信息，使得`Memcheck`工具在检测错误时，给出更具体的信息。如果可以容忍性能的降低，也可以添加`-O0`编译选择。

## Valgrind 执行程序

假设执行程序时，使用如下命令：  

```
myprog arg1 arg2
```

使用`Valgrind`命令行如下：  

```
valgrind --lead-check=yes myprog arg1 arg2
```

`Memcheck`是默认的工具，所以`--leak-check`选项可以省略。使用`Valgrind`会使得程序变慢，并使用更多的内存，`Memcheck`
会检测到内存错误、内存泄漏。  

## Valgrind 使用示例

下面是一段`C 示例`，该段代码内有内存错误和内存泄漏。  

{% codeblock lang:c mem_file.c %}
#include <stdlib.h>
void f(void)
{
    int *x = malloc(10 * sizeof(int));
    x[10]  = 0;         //problem 1: heap block overrun
                        //problem 2: memory leak -- x not freed
}

int main(void)
{
    f();
    return 0;
}
{% endcodeblock %}

编译该程序  

```
gcc -g -o mem_file mem_file.c
```

使用`valgrind`运行该程序:  

```
valgrind --leak-check=full ./mem_file
```

运行`valgring`后，输出的`Debug`信息如下：  

```
bing@ubuntu:~/work$ valgrind --leak-check=full ./mem_file   
==10566== Memcheck, a memory error detector    
==10566== Copyright (C) 2002-2015, and GNU GPL'd, by Julian Seward et al.  
==10566== Using Valgrind-3.11.0 and LibVEX; rerun with -h for copyright info  
==10566== Command: ./mem_file  
==10566==   
==10566== Invalid write of size 4  
==10566==    at 0x400544: f (mem_file.c:6)  
==10566==    by 0x400555: main (mem_file.c:12)  
==10566==  Address 0x5204068 is 0 bytes after a block of size 40 alloc'd  
==10566==    at 0x4C2DB8F: malloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)  
==10566==    by 0x400537: f (mem_file.c:5)  
==10566==    by 0x400555: main (mem_file.c:12)  
==10566==   
==10566==   
==10566== HEAP SUMMARY:  
==10566==     in use at exit: 40 bytes in 1 blocks  
==10566==   total heap usage: 1 allocs, 0 frees, 40 bytes allocated  
==10566==   
==10566== 40 bytes in 1 blocks are definitely lost in loss record 1 of 1  
==10566==    at 0x4C2DB8F: malloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)  
==10566==    by 0x400537: f (mem_file.c:5)  
==10566==    by 0x400555: main (mem_file.c:12)  
==10566==   
==10566== LEAK SUMMARY:  
==10566==    definitely lost: 40 bytes in 1 blocks  
==10566==    indirectly lost: 0 bytes in 0 blocks  
==10566==      possibly lost: 0 bytes in 0 blocks  
==10566==    still reachable: 0 bytes in 0 blocks  
==10566==         suppressed: 0 bytes in 0 blocks  
==10566==   
==10566== For counts of detected and suppressed errors, rerun with: -v  
==10566== ERROR SUMMARY: 2 errors from 2 contexts (suppressed: 0 from 0)  
   
```

大多数`valgrind`的输出格式就是这样的。

* `10566`是进城ID，命令行下，该值不是特别重要。  
* `Invalid write of size 4`这一行指示错误类型。
* 错误类型后紧跟着的是调用栈，告诉开发者问题出在某个函数的某一行。  
* `0x400544`地址，通常不是很重要，但它也会指示问题地址，帮助开发者追踪问题。  
* 一些错误还会有更多的信息描述内存地址。上面的例子展示了写入内存超出了分配内存块，该内存块是在`example.c`中的第 5 行分配的。  

内存泄漏格式如下：  

```

==10566==    at 0x4C2DB8F: malloc (in /usr/lib/valgrind/vgpreload_memcheck-amd64-linux.so)    
==10566==    by 0x400537: f (mem_file.c:5)    
==10566==    by 0x400555: main (mem_file.c:12) 
   
```

该调用信息告知开发者泄漏的内存的分配位置。`Memcheck`不会告知开发者为什么出现内存泄漏。内存的泄漏可以分配两类：  

* `definitely lost`:程序出现内存泄漏，必须修复。
* `probably lost`:程序出现内存泄漏，只有在开发者使用指针做一些事情时才会发生。 

`Memcheck`对未初始化变量，同样会有错误提示，通常提示信息为`Conditional jump or move depends on uninitialised value(s)`。这类错误的`roo cause`比较难发现，使用`--track-origins=yes`来获取更多信息。
该选项虽会使`Memcheck`运行更慢但额外信息会使开发者更容易的找到未初始化变量的位置。 

## Valgrind 内存错误类型  

* Illegal read/Illegal write errors  
* Use of Uninitialised values  
* Use of uninitialised or unaddressable values in system calls  
* Illegal frees  
* When a heap block is freed with an inappropriate deallocation function  
* Overlapping source and destination blocks  
* Fishy argument values  
* Memory leak detection  

## Valgrind 学习参考  

[Valgrind_mannual](http://valgrind.org/docs/manual/valgrind_manual.pdf)  

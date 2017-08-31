---
layout: post
title: "如何使用 GDB"
date: 2016-04-01 07:48:51 -0700
commit: true
categories: 编程工具
---

* list element with functor item
{:toc}

[GDB](https://www.gnu.org/software/gdb/), The GNU Project debugger, allows you to see what is going on inside another program while it executes -- or what another program was doing at the moment it crashed.

<!--more-->

GDB 主要完成以下四件事：  

1. 启动程序，指定影响程序运行的条件。  
2. 使程序在特定的条件下停止。  
3. 程序停止时，检查程序锁发生的事。  
4. 动态的改变程序的执行环境。  

### 前期准备

GDB 一般用于调试`C/C++`程序，要想能够使用`GDB`调试`C/C++`程序，首先必须将调试信息添加到可执行程序中。使用`gcc/g++`的`-g`参数可以做到这一点。如：

```
gcc -g programe.c -o programe
```
此时，可执行程序`programe`中就包含了调试需要的各种信息，如程序函数名、变量名等。
对于 MAC OSX 系统，调试信息会包含在另外一个`programe.dSYM`（debug symbols）文件夹下面，可以使用`dwarfdump programe.dSYM`直接查看各符号信息。

### 启动GDB方法

1. gdb <programe> program就是执行的文件，一般在当前目录下。  
2. gdb <programe> core 用GDB同事调试一个运行程序和 core 文件，core 是程序非法执行后 core dump 后产生的文件。  
3. gdb <programe> <PID> 如果程序是一个服务程序，则可以指定服务程序运行时的进程ID。gdb 自动 attach 上去，并调试它。 program 应该在 PATH 环境变量中搜索得到。  

如果出现`Segment Fault`，可以通过方法 2 来进行 Debug 程序，启动方式为`gdb {executable} {dump file}`,如果没有产生 core 文件，需要在执行 executable 之前先执行如下命令：  

```
$ulimit -c unlimited
```

### 设置运行参数

set args 可指定运行时参数。(如：set args 10 20 30)    
show args 命令可以查看设置好的运行参数。  

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

### 运行程序

运行程序如下
```
next //单步执行
continue //继续执行程序，直到程序结束或遇到下一个断点
```

### 查看运行时数据

```
print parm //打印变量parm的值
bt         //查看函数堆栈信息
```

当运行程序到某个位置时，我们希望看看此时程序的状态，比如某个变量的值是否按照预期改变、某块内存的值是否被改。此时就需要用到查看程序运行数据的集中方法。

查看格式 `print <expr>`或`print /<f> <expr>`，其中`<expr>`是要查看的表达式，可以是一个变量、数组、表达式等，`<f>`是输出时的格式，比如想要按照 16 进制输出，就使用`/x`。

可以使用 examine 命令查看内存地址中的值。格式是`x /<n/f/u> <addr>`，其中`<addr>`是内存地址。

### 查看内存数据

在调试代码时，经常需要查看某块内存的数据，此时就需要使用`GDB`中的[Examining memory](http://www.delorie.com/gnu/docs/gdb/gdb_56.html)。  
可以使用命令`x`(即`examine`)来检查任意格式的内存数据，不管你的程序数据类型。使用的格式为：

```
x  /nfu addr
x addr  
```

其中n/f/u 是选项参数，指定内存的大小及显示格式；addr 指定显示的内存的起始地址。n 是十进制的整数，指定小时内存的大小；f 指定显示的格式，它的使用与 GDB 中的 print 使用的格式一样，如`x`指定使用 16 进制显示，
`d`按十进制格式显示等；u 是指每个显示单元的大小，如`b`是指每个显示单元为 byte，`h`是指每个显示单元为半字（两个 byte）等；addr 指定要显示的内存的起始地址。  

如果需要查看的数据比较多，比如我们需要 dump 一块 buffer 的数据，与特定的数据进行比较，上面提到的`examine`就很难实现了。此时需要将块内存 dump 出来。使用到的命令是 `dump`或`append`或`restore`。此处主要介绍`dump`命令。  
它的格式为:  

```
dump [format] memory filename start_addr end_addr
```

从格式可以看出，它的含义是从`start_addr`开始到`end_addr`结束的 memory dump 到 指定的文件 filename 中。  

### 分割窗口

layout 用于分割窗口，可以一边查看代码，一边测试。主要有以下几种用法：  

* layout src:显示源代码窗口
* layout asm:显示汇编窗口
* layout regs:显示源代码汇编和寄存器窗口
* layout split:显示源代码和汇编窗口
* layout next:显示下一个 layout
* layout prev:显示上一个 layout
* Ctrl+L:刷新窗口
* Ctrl+x,再按1：单窗口模式，显示一个窗口
* Ctrl+x,再按2：双窗口模式，显示两个窗口
* Ctrl+x,再按a：回到传统模式，即退出 layout, 回到执行 layout 之前的调试窗口

### 参考文献

1. [GNU Debugger Tutorial](http://www.tutorialspoint.com/gnu_debugger/index.htm)  
2. [GDB: The GNU Project Debugger](https://sourceware.org/gdb/)  
3. [GNU Debugger](https://en.wikipedia.org/wiki/GNU_Debugger)  
4. [How to Debug Using GDB](http://cs.baylor.edu/~donahoo/tools/gdb/tutorial.html)  
5. [Debugging with GDB](http://web.mit.edu/gnu/doc/html/gdb_toc.html)   
6. [用GDB调试程序](http://blog.csdn.net/haoel/article/details/2879)  
7. [Debugging with GDB: The GNU Source-Level Debugger](https://www.amazon.com/Debugging-GDB-GNU-Source-Level-Debugger/dp/1882114884/httpwwwtuto0a-20)  
8. [GDB Pocket Reference: Debugging Quickly & Painlessly with GDB](https://www.amazon.com/GDB-Pocket-Reference-OReilly/dp/0596100272/httpwwwtuto0a-20)  
9. [The Art of Debugging with GDB, DDD, and Eclipse](https://www.amazon.com/Art-Debugging-GDB-DDD-Eclipse/dp/1593271743/ref=sr_1_fkmr1_1?s=books&ie=UTF8&qid=1488032361&sr=1-1-fkmr1&keywords=3.%09The+Art+of+Debugging+with+GDB%2C+DDD%2C+and+Eclipse)  


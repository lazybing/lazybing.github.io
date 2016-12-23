---
layout: post
title: "addr2line 的介绍与使用"
date: 2016-12-22 07:26:02 -0800
comments: true
categories: 编程工具
---

* list element with functor item
{:toc}

`addr2line`的作用是将地址转化为文件名和行号。  
<!--more-->

## addr2line 简介
在编写程序时，经常会遇到出现程序 crax 的情况，此时如果有 core stack 打印出来还好，但如果没有 core stack 的话，debug 就会比较困难。addr2line 可以很好地解决这个问题。  

`addr2line`能够将地址转换为文件名和行号。给定一个可执行文件的地址或者一个可重定位目标的目标偏移，addr2line 就会利用 debug 信息来计算出与该地址关联的文件名和行号。  

使用的可执行文件或可重定位目标使用`-e`选项来指定、可重定位目标的部分使用`-j`选项来指定。

`addr2line`有两种操作模式：  
1. 在命令行下，直接指定十六进制的地址，addr2line 为每个地址显示文件名和行号。  
2. addr2line 从标准输入中读取十六进制地址，并且为每个地址输出文件名和行号到标准输出中。  

输出格式为`FILENAME:LINENO`，默认情况下，每个输入地址对应一行输出。  


## addr2line 的使用示例
{% codeblock lang:c %}
#include <stdio.h>

int div(int numerator, int denominator)
{
    return numerator / denominator;
}

int main(int argc, char **argv)
{
    int numerator   = 10;
    int denominator = 0;

    return div(numerator, denominator);
}
{% endcodeblock %}

编译：gcc -o div -g div.c
生成可执行文件`div`后，执行该文件：./div 得到如下error:  
```
Floating point exception (core dumped)
```

此时并没有任何其他提示信息，我们可以通过`dmesg`查看信息：  
```
[ 4709.210137] traps: div[2500] trap divide error ip:400524 sp:7ffcd27fd630 error:0 in div[400000+1000]
```
通过该信息可以看出，ip 指向的地址为`400524`，得到该地址后，我们就可以使用 addr2line 来定位出错的位置。 
`addr2line -e div 400524` 得到结果如下：  
```
/home/bing/work/study/div.c:5
```

可以很直观的显示，该 core  dump 信息是在`div.c`的 line 5。  

## addr2line 的原理
`addr2line`之所以能够利用可执行文件将地址信息转换为行号，是因为在可执行 ELF 文件中存有这些对应的信息。可以使用`readelf`来查看这些信息。例如上面的`div`文件，通过readelf div 可以看到如下信息：
```
 Line Number Statements:
  [0x00000026]  Extended opcode 2: set Address to 0x400516
  [0x00000031]  Special opcode 8: advance Address by 0 to 0x400516 and Line by 3 to 4
  [0x00000032]  Special opcode 146: advance Address by 10 to 0x400520 and Line by 1 to 5
  [0x00000033]  Special opcode 104: advance Address by 7 to 0x400527 and Line by 1 to 6
  [0x00000034]  Special opcode 36: advance Address by 2 to 0x400529 and Line by 3 to 9
  [0x00000035]  Special opcode 216: advance Address by 15 to 0x400538 and Line by 1 to 10
  [0x00000036]  Special opcode 104: advance Address by 7 to 0x40053f and Line by 1 to 11
  [0x00000037]  Special opcode 105: advance Address by 7 to 0x400546 and Line by 2 to 13
  [0x00000038]  Special opcode 216: advance Address by 15 to 0x400555 and Line by 1 to 14
  [0x00000039]  Advance PC by 2 to 0x400557
  [0x0000003b]  Extended opcode 1: End of Sequence
```
从上面可以看出到 addr 在 0x400520-0x400527之间时，行号为5. 



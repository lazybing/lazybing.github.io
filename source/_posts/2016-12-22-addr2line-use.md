---
layout: post
title: "addr2line 的介绍与使用"
date: 2016-12-22 07:26:02 -0800
comments: true
categories: 编程工具
---

`addr2line`的作用是将地址转化为文件名和行号。  
<!--more-->

在编写程序时，经常会遇到出现程序 crax 的情况，此时如果有 core stack 打印出来还好，但如果没有 core stack 的话，debug 就会比较困难。addr2line 可以很好地解决这个问题。  

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



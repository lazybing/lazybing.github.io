---
layout: post
title: "如何使用gprof"
date: 2016-09-22 09:52:06 -0700
comments: true
categories: 编程工具
---

[Gprof](https://en.wikipedia.org/wiki/Gprof) 是一个 Unix 应用程序性能分析工具。
<!--more-->

[Profiling](https://sourceware.org/binutils/docs/gprof/index.html) 可以使我们看到程序运行时程序的调用关系、函数的消耗时长等。这些信息可以使我们了解程序中那块代码耗时高于预期。

使用 Profiling 主要包括如下三步：

* 编译链接程序时要使能 profiling 。

* 执行编译处的可执行文件，产生 profile 数据文件。

* 使用 gpro 分析 profile 数据。


根据产生的 profile ，可以产生各种不同实行的分析输出。如 The Flat Profile、The Call Graph、The Annotated Source Listing。

示例分析：
{% codeblock lang:c %}

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

void fun2()
{
    sleep(3);
}

void fun1()
{
    int index = 0;

    sleep(10);
    for(index = 0; index < 5; index++)
        fun2();
}

int main(int argc, char **argv)
{
    int index = 0;
    for(index = 0; index < 10; index++)
    {
        fun1(); 
    }
}

{% endcodeblock %}

编译，注意要添加`-pg`选项，这样才能与后面的 gprof 结合使用。

```
gcc -pg -o test test.c
```

执行, 执行完毕后，会生成 gmon.out 文件，用于性能分析的文件。

```
./test
```

分析, 使用 gprof 分析。
```
gprof test gmon.out > analysis.txt
```

此时生成的分析文件 analysis.txt 中有两种形式的分析数据。

Flat Profile 如图：

<img src="/images/gprof/Flat_profile.png">

Call Graph 如图：

<img src="/images/gprof/Call_graph.png">



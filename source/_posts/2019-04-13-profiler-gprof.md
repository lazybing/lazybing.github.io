---
layout: post
title: "性能优化之性能分析工具gprof"
date: 2019-04-13 09:52:06 -0700
comments: true
categories: 性能优化
---

[Gprof](https://en.wikipedia.org/wiki/Gprof) 是一个 Unix 应用程序性能分析工具。
<!--more-->

## gprof 概述

[Profiling](https://sourceware.org/binutils/docs/gprof/index.html) 可以使我们看到程序运行时程序的调用关系、函数的消耗时长等。这些信息可以使我们了解程序中那块代码耗时高于预期。

使用 Profiling 主要包括如下三步：

* 编译链接程序时要使能 profiling 。

* 执行编译处的可执行文件，产生 profile 数据文件。

* 使用 gpro 分析 profile 数据。


根据产生的 profile ，可以产生各种不同实行的分析输出。如 The Flat Profile、The Call Graph、The Annotated Source Listing。

## gprof 示例代码

示例分析：
{% codeblock lang:c %}

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

void fun2()
{
    int i = 0;
    int j = 0;
    int sum = 0;
    for(i = 0; i < 1024; i++)
        for(j = 0; j < 10240; j++)
            sum = i + j;
}

void fun1()
{
    int i = 0;
    int j = 0;
    int sum = 0;
    int index = 0;

    for(index = 0; index < 4; index++)
        fun2();
    for(i = 0; i < 2048*2; i++)
        for(j = 0; j < 1024; j++)
            sum = i + j;
}

int main(int argc, char **argv)
{
    int index = 0;
    for(index = 0; index < 3; index++)
        fun1(); 

    exit(1)
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

### Flat Profile 示例图

Flat Profile 如图：

<img src="/images/gprof/Flat_profile.png">

| 标注 | 释义 |
| :----: | :----: |
| %time | 每个函数占用的时间比例，所有函数占比和为100% |
| cumulative seconds | 函数及其调用函数执行累计占用时间 |
| self seconds | 单独函数执行累计占用时间 |
| calls | 函数调用次数 |
| self ms/call |每次调用函数花费的时间,单位毫秒, 不包含调用函数运行的时间|
| total ms/call | 每次调用函数花费的时间,单位毫秒,包括调用函数运行的时间|
| name | 函数名称|  

### Call Graph 示例图

Call Graph 如图：

<img src="/images/gprof/Call_graph.png">

| 标注 | 释义 |
| :----: | :----: |
| index | 每个函数第一次出现时分配一个编号，根据编号可以方便查找函数的具体分析数据 |
| %time | 函数以及调用子函数所占用的总运行时间的百分比 |
| self  | 函数的总运行时间 |
| children | 子函数执行的总时间 |
| called | 函数被调用的次数，不包括递归调用 |
| name | 函数名称, name 列中，可查看函数之间的调用关系| 

## 参考资料
1. [Performance Analysis Tools](https://computing.llnl.gov/tutorials/performance_tools/)  
2. [GNU gprof](https://sourceware.org/binutils/docs/gprof/)  




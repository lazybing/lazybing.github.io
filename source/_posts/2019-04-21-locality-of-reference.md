---
layout: post
title: "性能优化之利用局部性原理"
date: 2019-04-21 02:56:40 -0700
comments: true
categories: 性能优化
---

* list element with functor item
{:toc}

局部性原理是指程序通常倾向于引用邻近于其最近引用过的数据项的数据项，或最近引用过的数据本身。

<!--more-->

## 局部性示例

先看下面两个对数组访问的示例，

{% codeblock lang:c %}
#define ARRAY_ROW_SIZE 1000
#define ARRAY_COL_SIZE 1000

void access_array_col(int array1[ARRAY_ROW_SIZE][ARRAY_COL_SIZE])
{
    for (int i = 0; i < ARRAY_ROW_SIZE; i++)
        for (int j = 0; j < ARRAY_COL_SIZE; j++)
            array1[j][i] = 1;
}

void access_array_row(int array1[ARRAY_ROW_SIZE][ARRAY_COL_SIZE])
{
    for (int i = 0; i < ARRAY_ROW_SIZE; i++)
        for (int j = 0; j < ARRAY_COL_SIZE; j++)
            array1[i][j] = 1;
}

{% endcodeblock %}

| used time | 1 | 2 | 3 |
| :----: | :----: | :----: | :----: |
| access_array_row | 3521 | 4287 | 4741 |
| access_array_col | 12389 | 10713 | 11985 |

从上面的例子可以看出，同样是访问一个数组，采用列访问和采用行访问，事件相差非常大，原因就是`access_array_row`利用局部性原理。 

## 局部性原理

局部性主要包括两种形式，时间局部性和空间局部性。 

* 时间局部性：被引用过一次的存储器位置很可能在不远的将来再被多次引用。  
* 空间局部性：如果一个存储器位置被引用了一次，那么程序很可能在不远的将来引用附近的一个存储器位置。  

有良好局部性的程序比局部性差的程序运行得更快，计算机系统设计中，局部性原理在硬件和软件中都有应用，硬件层上，采用了**高速缓存存储器**充分利用了局部性原理；软件层上，操作系统用主存来缓存硬盘文件系统。  

## 存储器层次结构

局部性原理在存储器中使用特别频繁。

{% img /images/locality/locality.png %}



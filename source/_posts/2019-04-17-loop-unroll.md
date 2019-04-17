---
layout: post
title: "性能优化之循环展开"
date: 2019-04-17 07:36:49 -0700
comments: true
categories: 性能优化
---

* list element with functor item
{:toc}

循环展开是通过增加每次迭代计算的元素的数量，减少循环的迭代次数。循环展开只能针对整形加法和乘法的性能改进。

<!--more-->

循环展开从两个方面改变程序的性能：

1. 减少不直接有助于程序结果的操作的数量，如循环索引计算和条件分支。
2. 提供了一种方法，可以进一步变换代码，减少整个计算中关键路径上的操作数量。

## 示例分析

## 总结

## 参考资料
1. [循环展开](https://zh.wikipedia.org/wiki/%E5%BE%AA%E7%8E%AF%E5%B1%95%E5%BC%80)
2. [Loop Unrolling](https://en.wikipedia.org/wiki/Loop_unrolling)
3. [Generalized Loop-Unrolling: a Method for Program Speed-Up](http://www2.cs.uh.edu/~jhuang/JCH/JC/loop.pdf)
1. [C++性能榨汁机之循环展开](https://zhuanlan.zhihu.com/p/37582101)
2. [Computer Systems - A Programmer's Perspective](https://github.com/shihyu/CSAPP2e/blob/master/Computer%20Systems%20-%20A%20Programmer's%20Perspective%20(2nd).pdf)

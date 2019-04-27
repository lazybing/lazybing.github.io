---
layout: post
title: "性能优化之分支预测"
date: 2019-04-26 08:58:32 -0700
comments: true
categories: 性能优化
---

* list element with functor item
{:toc}

分支预测是在分支指令执行结束之前猜测哪一路分支将会被执行，以提高处理器的指令流水线的性能。使用分支预测器的目的，在于改善指令管线化的流程。

<!--more-->

## 预测种类

* 静态预测：最简单的分支预测技术，不依赖于代码执行的动态历史信息。静态预测可以再次细分，有的是总是预测条件跳转不发生，有的假定向后分支将会发生，向前的分支不发生。向后分支是指跳转到的新地址总比当前地址要低。

## 程序示例

{% codeblock lang:c %}
#include <vector>
#include <chrono>
#include <cstdlib>
#include <algorithm>
#include <iostream>

using namespace std;

int main()
{
    const unsigned arraySize = 32768;
    int data[arraySize];

    for(unsigned c = 0; c < arraySize; ++c){
        data[c] = std::rand() % 256;
    } 

    std::sort(data, data + arraySize);

    auto start = chrono::system_clock::now();
    long long sum = 0;
    for (unsigned i = 0; i < 100000; ++i) {
        for (unsigned c = 0; c < arraySize; ++c){
            if (data[c] >= 128) {
               sum += data[c];
            }
        }
    }
    auto end = chrono::system_clock::now();

    auto duration = chrono::duration_cast<chrono::microseconds>(end - start);
    double elapsed = double(duration.count())*chrono::microseconds::period::num/chrono::microseconds::period::den;
    std::cout << "const total " << elapsed << " sec" << std::endl;
    std::cout << "sum = " << sum << std::endl; 
}
{% endcodeblock %}

| 代码结构 | 耗时 | 
| :-----: |  :----: |
| 不排序 | 26.27s |
| 排序| 0.87s |
| 不分支预测 | 10.97s |





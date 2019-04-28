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

* 双模特预测器：该预测器是一种有 4 个状态的状态机：强不选择、弱不选择、弱选择、强选择。当一个分支命令被求值，对应的状态机被修改。分支不采纳，则向“强不选择”方向降低状态值；如果分支被采纳，则向“强选择”方向提高状态值。

{% img /images/branch_predictor/saturating_counter-dia.png %}

* 两级自适应预测器：对于一条分支指令，如果每 2 次执行发生一次条件跳转，或者其他的规则发生模式，那么用上文提到的双模态预测器就很难预测了。如图所示，一种两级自适应预测器可以记住过去 n 次执行指令时的分支情况的历史，可能的 2^n 种历史模式的每一种都有 1 个专用的双模态预测器，用来表示如果刚刚过去的 n 次执行历史是此种情况，那么根据这个双模态预测器预测为跳转还是不跳转。

{% img /images/branch_predictor/Two-level_branch_prediction.png %}

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

上面的双重 for 循环，如果对数组不排序、或者修改循环体内的条件语句为

{% codeblock lang:c %}
for (unsigned i = 0; i < 100000; ++i) {
    for (unsigned c = 0; c < arraySize; ++c) {
        int t = (data[c] - 128) >> 31;
        sum += ~t & data[c];
    }
}
{% endcodeblock %}

三种相同功能的代码，耗时如下所示：

| 代码结构 | 耗时 | 
| :-----: |  :----: |
| 不排序 | 26.27s |
| 排序| 9.87s |
| 不分支预测 | 10.97s |





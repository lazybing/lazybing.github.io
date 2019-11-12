---
layout: post
title: "Doxygen和graphviz使用"
date: 2019-07-11 06:24:57 -0700
comments: true
categories: 总结积累
---

`Doxygen`可以从一套归档源文件开始，生成HTML格式的在线浏览器，`Graphviz`是一个图形化可视化软件。Doxygen 使用 Graphviz 生成各种图形，如类的继承关系图、合作图，头文件包含关系图等。

<!--more-->

| EXTRACT_ALL | 输出所有的函数，但 private 和 static 函数不属于其管制|
| :---: | :---: |
| EXTRACT_PRIVATE | 输出 private 函数 |
| EXTRACT_STATIC | 输出 static 函数，同时还有几个 EXTRACT，相应查看文档即可|
| HAVE_DOT | |

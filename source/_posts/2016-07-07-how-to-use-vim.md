---
layout: post
title: "Vim 使用技巧"
date: 2016-07-07 08:17:10 -0700
comments: true
categories: 编程工具
---

* list element with functor item
{:toc}

Vim 是一个学习成本比较高的编辑器。
<!--more-->

## Mac OSX 下安装 gvim

{% codeblock %}
brew install macvim
{% endcodeblock %}

##基本设置

显示行号，在`.vimrc`中添加`set nu`

## vim 寄存器

使用 vim 时，不管是复制、删除或粘贴，在 vim 中都是借助 register 实现的，vim 共有 9 类寄存器。


寄存器种类         |  寄存器  |寄存器描述
:----------------:|:--------:|:---------------------:
无名寄存器         |  ""           |缓存最后一个操作内容
数字寄存器         |  "0~"9        |缓存最近操作内容
行内寄存器         |  "-           |缓存行内删除内容
具名寄存器         |  "a~"z或"A~"Z | 指定时可用
只读寄存器         |  ":,".,"%,"#  |分别缓存最近命令，最近插入文本，当前文件名，当前交替文件名
表达式寄存器       |  "=           |只读，用于执行表达式命令
选择及拖拽寄存器    |  "*,"+,"~  |存取GUI选择文本
黑洞寄存器         |  "_        | 不缓存操作内容
模式寄存器         |  "/        |缓存最近的搜索模式


## vim 分屏功能

<image src="/images/vim_split_screen.png">

vim 同时打开多个文件。

```
vim -o file1 file2              //小写 o 参数来水平分屏
vim -O file1 file2              //大写 O 参数来垂直分屏
```

vim 在多窗口打开。

```
:vs path/file       //在新的垂直分屏中打开文件
:sv path/file       //在新的水平分屏中打开文件
```

多窗口间切换的3方法：`Ctrl+w+方向键` `Ctrl+w+h/j/k/l` `Ctrl+ww`。

移动分屏的方法：`Ctrl+w L`向右移动分屏；`Ctrl+w H`向左移动分屏；`Ctrl+w K`向上移动分屏；`Ctrl+w J`向下移动分屏。

## vim 插件安装 

首先安装插件管理插件

```
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
```

其次在`.vimrc`下增加配置信息如下。

```
" vundle 环境设置
filetype off
set rtp+=~/.vim/bundle/Vundle.vim
" vundle 管理的插件列表必须位于 vundle#begin() 和 vundle#end() 之间
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'altercation/vim-colors-solarized'
Plugin 'tomasr/molokai'
Plugin 'vim-scripts/phd'
Plugin 'Lokaltog/vim-powerline'
Plugin 'octol/vim-cpp-enhanced-highlight'
Plugin 'nathanaelkane/vim-indent-guides'
Plugin 'derekwyatt/vim-fswitch'
Plugin 'kshenoy/vim-signature'
Plugin 'vim-scripts/BOOKMARKS—Mark-and-Highlight-Full-Lines'
Plugin 'majutsushi/tagbar'
Plugin 'vim-scripts/indexer.tar.gz'
Plugin 'vim-scripts/DfrankUtil'
Plugin 'vim-scripts/vimprj'
Plugin 'dyng/ctrlsf.vim'
Plugin 'terryma/vim-multiple-cursors'
Plugin 'scrooloose/nerdcommenter'
Plugin 'vim-scripts/DrawIt'
Plugin 'SirVer/ultisnips'
Plugin 'Valloric/YouCompleteMe'
Plugin 'derekwyatt/vim-protodef'
Plugin 'scrooloose/nerdtree'
Plugin 'fholgado/minibufexpl.vim'
Plugin 'gcmt/wildfire.vim'
Plugin 'sjl/gundo.vim'
Plugin 'Lokaltog/vim-easymotion'
Plugin 'suan/vim-instant-markdown'
Plugin 'lilydjwg/fcitx.vim'
" 插件列表结束
call vundle#end()
filetype plugin indent on`
```

最后，进入`vim`执行

```
:PluginInstall
```

## vim 浏览代码

## vim 浏览代码

vim 浏览代码一般会与 `catgs` `cscope` `taglist` 等一起使用。


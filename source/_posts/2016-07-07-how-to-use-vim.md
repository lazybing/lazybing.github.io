---
layout: post
title: "将vim打造成IDE"
date: 2016-07-07 08:17:10 -0700
comments: true
categories: 编程工具
---

* list element with functor item
{:toc}

`Vim` 是一个学习成本比较高的编辑器。本文主要记录对于编辑浏览代码时，如何配置`vim`才能更高效的编辑、浏览代码。

<!--more-->

## Mac OSX 下安装 gvim

{% codeblock %}
brew install macvim
{% endcodeblock %}

## 基本设置

配置信息都放到了`~/.vimrc`文件中：  
显示行号，在`.vimrc`中添加`set nu`    
开启文件类型侦测, `filetype on`  
根据侦测到的不同类型加载对应的插件， `filetype plugin on`  
开启实时搜索功能， 

## vim 对单个字符的操作

> To err is human. To really foul up you need a computer.  

### 删除某个字符

删除字符命令非常简单，就是单个字符`x`,例如上面的一行code，如果将光标至于`really`的`r`处执行`x`命令，就会将 `r` 删除。

### 替换某个字符

替换字符的命令`rx`将光标下的字符 replace 成字符`x`。如果发现连个相邻的字符颠倒了，可以直接在前一个字符处执行`xp`命令即可，其中的`x`时删除光标下的字符，`p`时黏贴。

### 移动到某个字符

`fx`命令在一行中向前搜索单个字符`x`。速记：`f`此处是`Find`的简写。  

例如，你现在处于上面 code 的开头处，假设你想将光标移动到`human`中的`h`字符处。此时你只需要简单的执行`fh`，光标将会跳转到`h`: 

	To err is human.  To really foul up you need a computer. ~
	---------->--------------->
	    fh		 fy

上面命令也显示了`fy`移动光标到`really`的`y`处。当然，此时你也可以在命令前添加执行次数，可以用`3fl`命令跳转光标到`foult`的`l`处：  

	To err is human.  To really foul up you need a computer. ~
		  --------------------->
			   3fl

与`f`相对应的`F`命令会向左搜索：  

	To err is human.  To really foul up you need a computer. ~
		  <---------------------
			    Fh

除了`fx`命令用于搜索一行中的某个特定字符外，还有`tx`命令，`tx`命令会停在搜索的字符`x`前。速记：`t`时`To`的简写。与`Fx`相对应的是`Tx`。  

	To err is human.  To really foul up you need a computer. ~
		   <------------  ------------->
			Th		tn

`fx``Fx``tx``Tx`这四个命令可以用`;`命令重复，`,`向相反的方向执行。  

上面的移动命令虽然很好用，但有如果一行中存在多个我们想要查找的字符，我们要么人肉看一下搜索的字符位于第几个位置，要么要一直重复执行相同的移动命令。非常影响思维连贯性。例如想要从上面一行的开头找到`computer`中的`o`。
此时我们可以借助插件来完成，`easymotion`即可帮助我们，它会把所有满足条件的位置用[A-Za-z]间的标签字符标出来，找到你想要去的位置再键入对应标签字符即可快速到达。
比如，上面的例子，假设关闭在行首，我只需要键入<Leader><Leader>fo,所有字符a都被重新标记成a、b、c、d等等标签（原始内容不变），直接键入标签字母即可到达需要到达的地方。


## vim 对单字的操作

### 删除某个单字

删除某个单字非常简单，只需要在单字的开始执行`dw`即可。速记：`d`是`deleate`的简写。  

### 修改某个单字

修改某个单字时，只需要在单字的开始执行`cxxxxx`即可，`c`是`change`的简写，`xxxxx`即代表要修改的单字。

### 移动到某个单字

想要移动光标大下一个单字，使用`w`命令。跟很多`vim`命令一样，可以在命令前添加一个执行次数。比如,`3w`就是移动 3 个单字。下面展示它是如何工作的：  

	This is a line with example text ~
	  --->-->->----------------->
	   w  w  w    3w

注意，`w`命令会移动到下一个单字的起始处。  
`b`命令向前移动到前一个单字的起始处。  

	This is a line with example text ~
	<----<--<-<---------<---
	   b   b b    2b      b

与`w``b`对应的有`e`和`ge`命令分别向后和向前移动到单字的末尾：  

	This is a line with example text ~
	   <-   <--- ----->   ---->
	   ge    ge     e       e

如果光标位于一行的最后一个单字，`w`命令会带你到下一行的第一个单字处。因此你可以使用`w`命令来在一行中移动。

## vim 对整行的操作

### 移动到行首或行尾

`$`命令移动光标到一行的结尾，与`<End>`键作用相同。`^`命令移动到一行的第一个非空白字符处。`0`命令移动到一行的最前面第一个字符处，与`<Home>`键作用相同。  

		  ^
	     <------------
	.....This is a line with example text ~
	<-----------------   --------------->
		0		   $

(....指空白符)  



### 移动到指定行

C/C++ 程序员应该经常能遇到程序出错时，会有类似如下的提示信息：  

	prog.c:33: j   undeclared (first use in this function) ~

这就提示我们该跳转到 33 行 fix 掉错误，此时可以使用`G`命令：`33G`即可跳转到 33 行。
另一种方法是在`shell`命令行下执行`:33<Enter>`。
上面的两种方法都是假设你想要移动到某个特定的行，而不管该行是否可见。假如你想要移动到屏幕的中间或者起始行时，该如何操作呢？  

			+---------------------------+
		H -->	| text sample text	    |
			| sample text		    |
			| text sample text	    |
			| sample text		    |
		M -->	| text sample text	    |
			| sample text		    |
			| text sample text	    |
			| sample text		    |
		L -->	| text sample text	    |
			+---------------------------+

速记：`H`是`Home`的简写，`M`是`Middle`的简写，`L`是`Last`的简写。

### 使用标签记录并跳转到某行

在介绍标签之前，先了解另外两个命令`CTRL-O`和`CTRL-I`，其中`CTRL-O`是回到之前的位置，`CTRL-I`是回到下一个位置。例如：

	     |	example text   ^	     |
	33G  |	example text   |  CTRL-O     | CTRL-I
	     |	example text   |	     |
	     V	line 33 text   ^	     V
	     |	example text   |	     |
       /^The |	example text   |  CTRL-O     | CTRL-I
	     V	There you are  |	     V
		example text

注意：CTRL-I 是和 <Tab> 相同的。

`vim`可以使你定义自己的标签。命令`ma`标记当前光标所在的位置。\`{mark} 和 '{mark}都可以跳回到标签处。不同的是\`{mark} 跳回的是光标所在行的原来那一列，'{mark}跳回的是光标所在哪一行的起始位置。

## vim 对单个文件的浏览

### vim 滚动屏幕命令

`CTRL-U`和`CTRL-D`命令向上或向下滚动半个屏幕。  
`CTRL-E`和`CTRL-Y`分别向上和向下滚动一行。  
`CTRL-F`和`CTRL-B`分别向前和向后滚动整个屏幕。
有时当执行多个`j`命令时，光标会在屏幕的最底部，此时如果想让光标所在行位于中间位置，可以使用`zz`命令,`zt`命令将光标所在行至于顶部，`zb`命令将光标所在行至于底部。  

### vim 切分窗口

切分新窗口最简单的命令是`:split`，该命令可以使我们在两个窗口中查看同一个文件，比如可以使用第一个窗口显示变量声明，另一个窗口展示该变量的使用。
`CTRL-W w`命令可用于两个窗口间的跳转。垂直切分窗口命令是`:vsplitw`。窗口直接的切换命令如下：

	CTRL-W h	move to the window on the left
	CTRL-W j	move to the window below
	CTRL-W k	move to the window above
	CTRL-W l	move to the window on the right

	CTRL-W t	move to the TOP window
	CTRL-W b	move to the BOTTOM window

## vim 替换文本

简单替换表达式`:[range]s/from/to/[flags]`  

* range:搜索范围，如果没有指定范围，则作用于当前行。 

1. `:1,10s/from/to/`表示在第 1 到第 10 行（包含第 1，第 10 行）之间搜索替换。  
2. `:10s/from/to/`表示只在第 10 行搜索替换。  
3. `:%s/from/to/`表示在所有行中搜索替换。  
4. `1,$s/from/to/`同上。  

* `flags`有如下四个选项：  

1. `c`confirm,每次替换前询问。  
2. `e`error,不显示错误。  
3. `g`globe,不询问，整行替换。如果不加`g`选项，则只替换每行的第一个匹配到的字符串。  
4. `i`ignore,忽略大小写。

这些选项可以合并使用，如`cgi`表示不区分大小写，整行替换，替换前询问。  

## vim 对多个文件的操作

### 工程文件浏览

在项目工程中，经常要用到插件，此处介绍一个插件`NERDTree`，通过`NERDtree`插件可以查看文件列表，要打开哪个文件，
光标选中后回车即可在新`buffer`中打开。  

常用操作：回车，打开选中文件;`r`刷新工程目录文件列表；`I`显示/影藏文件；`m`出现创建/删除/剪切/拷贝操作列表。键入<leader>fl后，右边子窗口为工程项目文件列表。

### 多文档编辑
`vim`的多文档编辑涉及三个概念:buffer、window、tab。vim把加载进内存的文件叫做buffer,buffer不一定可见；
若要buffer可见，则必须通过window作为载体呈现；同个看面上的多个window组合成一个tab。  

vim中每打开一个文件，vim就对应的创建一个buffer,多个文件就有多个 buffer, 但默认你只能看到最后buffer对应
window，通过插件`MiniBufExplorer`可以把所有 buffer 罗列出来，并且可以显示多个 buffer 对应的Window。  

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

{% img /images/vim_split_screen.png %}  

`vim`同时打开多个文件。

```
vim -o file1 file2              //小写 o 参数来水平分屏
vim -O file1 file2              //大写 O 参数来垂直分屏
```

`vim`在多窗口打开。

```
:vs path/file       //在新的垂直分屏中打开文件
:sv path/file       //在新的水平分屏中打开文件
```

多窗口间切换的3方法`Ctrl+w+方向键`或`Ctrl+w+h/j/k/l`或`Ctrl+ww`。  

移动分屏的方法：`Ctrl+w L`向右移动分屏；`Ctrl+w H`向左移动分屏；`Ctrl+w K`向上移动分屏；`Ctrl+w J`向下移动分屏。  

## vim 插件安装

### vundle 插件管理插件

vim 默认的安装需要将插件的帮助文档和插件脚本文件分别放到`.vim`目录下的`doc`和`plugin`子目录下面，当要安装的插件较多时会非常繁琐并且
相似功能的插件名称可能相同，导致插件安装难以处理，为此我们找到了专门用于管理插件的插件`vundle`，它会自动的将插件以插件名的形式安装到`.vim/bundle`子目录下面，
如果想要删除或者升级某个插件，只需要使用一个命令即可完成，不需手动删除重装。  

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

使用方法非常简单，只需在`vundle#begin()`和`vundle#end()`中间，加入需要安装的插件名称，进入`~/.vimrc`执行

```
:PluginInstall
```

即可完成插件的安装。执行

```
:PluginUpdate
```

即可完成插件的升级。想要卸载某个插件，只需要先在`.vimrc`中注释或删除对应插件的配置信息，然后执行

```
:PluginClean
```

即可完成。  

### solarized/molokai/phd 主题风格插件

素雅的[solarized](https://github.com/altercation/vim-colors-solarized)、多彩的[molokai](https://github.com/tomasr/molokai)、复古的[phd](http://www.vim.org/scripts/script.php?script_id=3139),这三种
vim 主题风格是比较流行的三种，插件完成后，可以在`.vimrc`中选用某个主题，每个主题又有亮色系和暗色系两种,具体设置如下：  

```
“ 配色方案  
set background=dark
"set background=light
colorscheme solarized
"colorscheme molokai
"colorscheme phd
```

### vim-fswitch(接口与实现快速切换)插件  

[vim-fswitch](https://github.com/derekwyatt/vim-fswitch) 插件可以实现接口文件(*.h)和实现文件(*.cpp)中来回切换的操作，安装完该插件后，还需要增加配置信息：  

```
" *.cpp 和 *.h 间切换
nmap <silent> <Leader>sw :FSHere<cr>
```

此时只要键入`;sw`就可实现文件和接口文件间切换。  

### vim-protodef(接口快速生成实现)插件

在 *.h 中写成语函数的声明后，然后手动在 *.cpp 中写成员函数的定义，效率非常低。[vim-protodef](https://github.com/derekwyatt/vim-protodef) 可以快速完成此功能，即它可以根据类声明自动生成类实现的代码框架。注意该插件会依赖`FSwitch`，需要一起安装。安装完后，需要设置如下信息：  

```
" 设置 pullproto.pl 脚本路径
let g:protodefprotogetter='~/.vim/bundle/vim-protodef/pullproto.pl'  
" 成员函数的实现顺序与声明顺序一致  
let g:disable_protodef_sorting=1
```

`pullproto.pl`是 protodef 自带的 perl 脚本。它的使用方法有下面两种：  

```
nmap <buffer> <silent> <leader> ;PP
nmap <buffer> <silent> <leader> ;PN
```

## vim 浏览代码

vim 浏览代码一般会与 `catgs` `cscope` `taglist` 等一起使用。  

多窗口间切换的3方法：`Ctrl+w+方向键` `Ctrl+w+h/j/k/l` `Ctrl+ww`。  


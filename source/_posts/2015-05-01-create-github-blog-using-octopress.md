---
layout: post
title: "使用Octopress 搭建个人博客"
date: 2015-05-01 19:47:37 -0700
comments: true
categories: 总结积累
---
* list element with functor item
{:toc}

详细记录使用`Octopress`的搭建和使用过程中遇到的问题。
<!--more-->

##安装octorpess

首先，安装`git``ruby`,注册 github 账号。  

然后，在终端(Terminal)下执行如下命令：  
```
git clone git://github.com/imathis/octopress.git octopress
cd octopress
gem install bundler
bundle install
rake install // 安装默认主题
```
本地安装完毕后，通过`rake preview`预览安装效果。执行完`rake preview`后，在浏览器
中输入`http://localhost:4000`即可查看搭建效果。  

##部署octopress

登录注册的 github 账号，选择`New Repository`,进入新建库页面后，
在`Repository name`一栏填`[your_username].github.io`,[your_username]
是 github 上的用户名，此处的格式一定要正确，否则部署会失败。
之后点击`Create repository`按钮提交。  

如果创建仓库成功，会有一个 SSH 地址，形如`git@github.com:[your_name]/[your_name].github.io.git`,后面会用到该地址。  

终端下执行如下命令:  
```
cd octopress
rake setup_github_pages
```
执行完上面两条命令后，需要把刚刚生成的 SSH 地址粘贴到此处。
继续执行：  

```
rake generate
rake deploy
```
其中`rake generate`用来生成页面，`rake deploy`用来部署页面。上述完成后，
即可使用`http://[your_username].github.io`来访问页面。  

最后要记得把源文件全部发布到`source`分支下面。通过下面命令完成:  
```
git add .
git commit -m "commit message"
git push origin source
```

##发布新帖

发布新帖的两种方法:  
方法一是在命令行下执行如下命令：  
```
cd octopress
rake new_post["Post Title"]
```
其中的`Post Title`就是你想要的文章标题，然后会有一个名为`yyyy-mm-dd-Post_Title.markdown`的文件在`octopress/source_posts`目录下生成，其中`yyy-mm-dd`是当时的日期。之后打开文件，即可编辑博客。

方法二是直接在`octopress/source_posts`文件下，生成一个格式相同的文件即可。

生成的文件格式头如下  
```
---
layout: post
title: "使用Octopress 搭建个人博客"
date: 2015-05-01 19:47:37 -0700
comments: true
categories: 总结积累
---

```

##基本配置

`_config.yml`用于基本配置，包括域名、网站标题、作者等等信息。

{% codeblock _config.yml %}
url: http://yhoursite.com
title: My Octopress Blog
subtitle: A blogging framework for hackeers.
author: Your Name
simple_search: https://www.google.com/search
description: 
{% endcodeblock %}

汉化"Categories", 在`_config.yml`文件中，添加下面一行代码：
```
category_tile_prefix: “分类：”
```


汉化“Read On->”按钮:当文章只是显示摘要，点击"Read on->"
后才可查看全文时，可以通过在文章中插入如下内容：
```
<!--more-->
```

在文章中找到如下一行，把其中的"Read on"改为"继续阅读"。
```
excerpt_link:"Read on"
```

##主题修改

网站底部：一般来讲网站底部会有一些网站的描述信息，比如版权声明、网站
主题，网站使用的系统等等，要修改这部分内容，直接打开`source/_includes/custom/foot.html`修改相应部分即可。

##添加图片

在写 blog 的过程中，经常需要用到插入图片。示例如下：

1. 把图片 `meinv.png` copy 到 `source/images`下。

2. 在需要的位置添加代码.

{% codeblock %}
{% img /images/meinvp.png %}
{% endcodeblock %}

{% img /images/meinvping.png %}

更多技巧，请参见 Octopress 官网提供的[技术支持](http://octopress.org/docs/plugins/image-tag/)。

##添加文章目录

文章一旦长了之后，想要找某个点就需要目录来索引。添加文章目录方法：

首先，使用 kramdown 作为 Octopress 作为 Markdown 解析器。

①  在`Gemfile`中添加如下代码.
```
gem 'kramdown'
```

②  端执行如下命令。

```
bundle install
```

③  修改`_config.yml`文件中相关内容如下。

```
markdown: kramdown
kramdown:
    user_coderay: true
    coderay:
        coderay_line_numbers: table
        coderay_css: class
```

其次，在想要插入目录的地方，插入如下代码即可。

```
* list element with functor item
{:toc}
```

再次,在目录前自动添加`本页目录`,修改`sass/custom/_style.scss`,代码如下.

```
#markdown-toc:before{
    content: "本页目录";
    font-weitht: bold;
}
```
最后，为防止显示摘要时出现目录，在`sass/custom/_style.scss`添加代码。

```
.blog-index #markdown-toc{
    display: none;
}
```

参考博文：[Octopress 精益修改](http://shengmingzhiqing.com/blog/octopress-lean-modification-5.html/#section-1) 和 [Table Of Contents in Octopress](http://blog.riemann.cc/2013/04/10/table-of-contents-in-octopress/)

## 添加表格

语法说明：  

* `|``-``:`之间的多余空格会被忽略，不影响布局。
* 默认标题栏居中对齐，内容居左对齐。
* `-:`表示内容和标题栏居右对齐，`:-`表示内容和标题栏居左对齐，`:-:`表示内容和标题栏居中对齐。
* 内容和`|`之间的多余空格会被忽略，每行第一个`|`和最后一个`|`可以省略，`-`的数量至少一个。


```
| 左对齐标题 | 右对齐标题 | 居中对齐标题 |
| :--------  | ---------: | :----------: |
| 短文本 | 中等文本 | 稍微长一点的文本 |
| 稍微长一点的文本 | 短文本 | 中等文本 |
```

| 左对齐标题 | 右对齐标题 | 居中对齐标题 |
| :--------  | ---------: | :----------: |
| 短文本 | 中等文本 | 稍微长一点的文本 |
| 稍微长一点的文本 | 短文本 | 中等文本 |

##多台Mac上同时使用

### 在新的Mac上创建 ssh key 并添加到 github 中。

创建`ssh-key`。
```
$ ssh-keygen -t rsa -b 4096 -C "libinglimit@gmail.com"
```
把生成的`key`添加到`ssh-agent`中。
```
$ ssh-add ~/.ssh/id_rsa
```
把添加的`key`放到`github`中。

本地重建Octopress仓库。clone`source`分支/`master`分支：
```
$ git clone -b source git@github.com:lazybing/lazybing.github.io octopress
$ cd octopress
$ git clone git@github.com:lazybing/lazybing.github.io _deploy
```
参见 github 官方[帮助文档](https://help.github.com/articles/checking-for-existing-ssh-keys/#platform-mac)。

### 配置环境。

执行以下命令配置环境：
```
$ gem install bundler
$ rbenv rehash    # If you use rbenv, rehash to be able to run the bundle command
$ bundle install
$ rake setup_github_pages 
```

### 使用技巧

及时提交本地修改
```
$ rake generate
$ rake deploy
```
第一条命令会使用本地的修改生成最新的`blog`网站，并且生成的`blog`会存放到`Octopress`根目录下的`public/`目录下；

第二条命令主要做了两件事：

*用`generate`命令生成在`public/`目录下的内容覆盖`_deploy/`目录下内容；

*将`_deploy/`目录下的修改`add` 、 `commit`到`git`，并`push`到`git`的`master`分支。

除此之外，还需要把`source`分支中做到的修改提交到`git`仓库中，执行以下命令：
```
$ git add .
$ git commit -am "Some comment here." 
$ git push origin source  # update the remote source branch 
```
修改前先更新到最新的版本。
```
$ cd octopress
$ git pull origin source  # update the local source branch
$ cd ./_deploy
$ git pull origin master  # update the local master branch
```

参考博文:[让Octopress博客在多台Mac上同时使用](http://foggry.com/blog/2014/04/02/ru-he-pei-zhi-rang-ni-de-octopressbo-ke-zai-duo-tai-macshang-tong-shi-shi-yong/)


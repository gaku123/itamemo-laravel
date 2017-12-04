# はじめに

## この記事の目的
  * Laravelの環境構築
  * 構成管理ツールItamaeが使えるになる

## Itamemo
Itamemoとは主にサーバで環境構築をした際に、軽量なサーバ構成管理ツール[Itamae](https://github.com/itamae-kitchen/itamae)で何となくコード化した際にできる副産物のことです。

## 前提
  * ロールバック(vagrant sandbox rollback)ができるので、Vagrant+Virtual Boxで、mvbcoding/awslinuxを使っています。
  * EC2　（Amazon Linux）でも同じようにできると思います。
  * 本当は以下で紹介する手順でメモを取っていません。（作った後に、Qiitaに投稿を考えたので)

# 準備

メモを取る準備をします。

```
$ mkdir laravel-itamae-memo
$ cd laravel-itamae-memo/
$ bundle init
$ bundle vim Gemfile
```

# 環境構築

Gemfileを編集。

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem "itamae"
```
Itamaeをインストール。

```
$ bundle install
Fetching gem metadata from https://rubygems.org/...........
Resolving dependencies...
略
```

とりあえずNginxで動かそうと思ったので、以下を書く。

```
$ itamae g cookbook nginx
      create
      create  default.rb
      create  files/.keep
      create  templates/.keep
```

itamaeはCUIはThorでできているようなので、`itamae help`とかでコマンドの説明ができてきます。
itamae gのgはgenerateのgです。

nginxをインストール、起動の記述した結果は以下となります。

```
$ cat cookbooks/nginx/default.rb
package 'nginx' do
  user 'root'
  action :install
end

service 'nginx' do
  user 'root'
  action [:enable, :start]
end
```

phpやphp-fpmも入れます。

```
$ itamae g cookbook php
      create
      create  default.rb
      create  files/.keep
      create  templates/.keep
$ itamae g cookbook php-fpm
      create
      create  default.rb
      create  files/.keep
      create  templates/.keep
```

中身は以下

```
$ cat cookbooks/php/default.rb
package 'php71' do
  user 'root'
end

package 'php71-mbstring' do
  user 'root'
end
$ cat cookbooks/php-fpm/default.rb
package 'php71-fpm' do
  user 'root'
end

service 'php-fpm' do
  user 'root'
  action [:enable, :start]
end
```
LaravelはComposerで入れるらしいです。

```
$ itamae g cookbook composer
      create
      create  default.rb
      create  files/.keep
      create  templates/.keep
```

Composerの導入の仕方も初めて知りました。

```
$ cat cookbooks/composer/default.rb
execute "setup composer" do
  user "root"
  command "php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\" && php composer-setup.php --install-dir=/usr/local/bin --filename=composer && export PATH=$HOME/.composer/vendor/bin:$PATH"
  not_if "/usr/local/bin/composer -V"
end
```

これらを読み込むレシピを書いて実行。

```
$ mkdir roles
$ vim roles/laravel.rb # 編集
$ cat roles/laravel.rb
include_recipe "../cookbooks/php/default.rb"
include_recipe "../cookbooks/composer/default.rb"
include_recipe "../cookbooks/nginx/default.rb"
$ itamae local roles/laravel.rb # 実行
```

laravelのインストール。(システムワイドにインストールしたいな..。)

```
$ itamae g cookbook laravel
      create
      create  default.rb
      create  files/.keep
      create  templates/.keep
$ cat cookbooks/laravel/default.rb
execute "install laravel" do
  command "composer global require 'laravel/installer'"
  not_if "laravel -V"
end
$ laravel -V
Laravel Installer 1.4.1
```

# 動作確認

適当なアプリを作り、

```
$ cd
$ laravel new myapp
$ chmod -R 777 myapp/storage
```

nginxとphp-fpmを設定しつつ、
itamaeの方に持ってきます。

```
$ cd laravel-itamae-memo
itamae g cookbook nginx/myapp
      create
      create  default.rb
      create  files/.keep
      create  templates/.keep
$ mkdir -p cookbooks/nginx/myapp/files/nginx/
$ cp /etc/nginx/nginx.conf cookbooks/nginx/myapp/files/nginx/
$ cat cookbooks/nginx/myapp/default.rb
remote_file "/etc/nginx/nginx.conf"
$ itamae g cookbook php-fpm/myapp
      create
      create  default.rb
      create  files/.keep
      create  templates/.keep
$ mkdir -p cookbooks/php-fpm/myapp/files/etc/php-fpm.d
$ cp /etc/php-fpm.d/www.conf cookbooks/php-fpm/myapp/files/etc/php-fpm.d/
$ cat cookbooks/php-fpm/myapp/default.rb
remote_file "/etc/php-fpm.d/www.conf"
```

myappのレシピは分けます。

```
$ cat roles/myapp.rb
include_recipe "../cookbooks/nginx/myapp/default.rb"
include_recipe "../cookbooks/php-fpm/myapp/default.rb"
$ itamae local roles/myapp.rb # 実行
$ sudo service nginx restart
$ sudo service php-fpm restart
```

これで、アクセスすればLaravelのトップページが見れるはず。




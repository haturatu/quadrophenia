# quadrophenia
<img width="1181" height="634" alt="image" src="https://github.com/user-attachments/assets/353af750-7e43-47c7-a99c-c77390454378" />  

# なにこれ
自分用にサーバで自己ホストしているWeb Appsにアクセスしやすいようしたフロントエンドです。
使う方いれば、パブリックに公開されているとよろしくないのでPort 4567番がパブリックにOpenではないこと確認して使ってください。


# Usage
標準ライブラリで動くようにはしたはずなので、Rubyが動く環境であれば動くはずです。
`.ruby-version`は気が向いたら追加します。
```bash
$ ruby -v
ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [x86_64-linux-gnu]
```

## Install & Run
```bash
git clone https://github.com/haturatu/quadrophenia.git
cd quadrophenia
ruby main.rb
```

`supervisor`とかでプロセス管理しておくとよいかも。


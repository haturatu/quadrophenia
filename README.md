# quadrophenia
<img width="1181" height="634" alt="image" src="https://github.com/user-attachments/assets/353af750-7e43-47c7-a99c-c77390454378" />  

# なにこれ
自分用にサーバで自己ホストしているWeb Appsにアクセスしやすいようしたフロントエンドです。
使う方いれば、パブリックに公開されているとよろしくないのでPort 4567番がパブリックにOpenではないこと確認して使ってください。


# Usage
## Install & Run
依存関係のインストール
```bash
gem install webrick
gem install erb
```

```bash
git clone https://github.com/haturatu/quadrophenia.git
cd quadrophenia
ruby main.rb
```

`supervisor`とかでプロセス管理しておくとよいかも。


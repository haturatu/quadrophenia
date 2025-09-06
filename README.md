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

# supervisor example
`/etc/supervisor/conf.d/quadrophenia.conf`: 

```ini
[program:quadrophenia]
directory=/home/teto/git/quadrophenia
command=/usr/bin/ruby main.rb -p 4567 -h 0.0.0.0
autostart=true
autorestart=true
startsecs=3
stopwaitsecs=5
stderr_logfile=/var/log/quadrophenia.err.log
stderr_logfile_maxbytes=1MB
stdout_logfile=/var/log/quadrophenia.out.log
stdout_logfile_maxbytes=1MB
user=teto
environment=RACK_ENV="production",HOME="/home/teto",RBENV_ROOT="/home/teto/.rbenv",PATH="/home/teto/.rbenv/shims:/home/teto/.rbenv/bin:/usr/local/bin:/usr/bin:/bin"
```
上記実行ユーザ、環境変数は適宜書き換えてください。

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start quadrophenia
```

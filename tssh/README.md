ref http://blog.yuuk.io/entry/tmux-ssh-mackerel

sshconfig の設定を優先させるため、`$SSH_OPTION $USER` を省略するように手を加えているよ

```
$ tssh server00{1,2,3,}
```

とかで、tmux が立ち上がり、引数のサーバへ ssh login が開く。さらに synchronize-panes on 状態になっているよと言う代物。便利。

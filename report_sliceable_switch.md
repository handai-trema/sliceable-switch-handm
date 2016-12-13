#Report: スライス機能の拡張
Submission: &nbsp; Nov./30/2016<br>
Branch: &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; develop<br>


##目次
* [提出者](#submitter)
* [課題内容](#assignment)
* [スライスの可視化](#visualize)
* [REST APIの追加](#add_api)
* [関連リンク](#links)



##<a name="submitter">提出者: H&Mグループ
###メンバー
<table>
  <tr>
    <td><B>氏名</B></td>
    <td><B>学籍番号</B></td>
    <td><B>所属研究室</B></td>
  </tr>
  <tr>
    <td>阿部修也</td>
    <td>33E16002</td>
    <td>松岡研究室</td>
  </tr>
  <tr>
    <td>信家悠司</td>
    <td>33E16017</td>
    <td>松岡研究室</td>
  </tr>
  <tr>
    <td>満越貴志</td>
    <td>33E16019</td>
    <td>長谷川研究室</td>
  </tr>
  <tr>
    <td>辻　健太</td>
    <td>33E16012</td>
    <td>長谷川研究室</td>
  </tr>
</table>




##<a name="assignment">課題内容
```
課題 (スライス機能の拡張)

・スライスの分割・結合
  ・スライスの分割と結合機能を追加する
・スライスの可視化
  ・ブラウザでスライスの状態を表示
・REST APIの追加
  ・分割・統合のできるAPIを追加
```


##<a name="visualize">スライスの可視化
スライスの状態をウェブブラウザで見ることができるようにした。方法としては前回、前々回と同じくvis.jsを利用してJavaScriptで記述するが、JavaScriptファイルはrubyで書き出す。
スイッチ間の接続であったりホスト・スイッチ間の接続はスライスの状況と関係がなく表示する領域に余裕が無いために省略した。

JavaScriptを含むhtmlファイルを生成するプログラムをhtml.rbとし、slice.rbよりrequireならびに、updateメソッドを適宜呼び出す。

スライス一覧はまず左側にまとめて表示しており、その凡例にしたがって、表示されているホスト(Mac address)のアイコンの色が決まっている。これにより所属スライスが把握可能である。次の図0が、適当にホストをスライスに分割した際の表示である。

|<img src="/lib/view/result0.png" width="420px">|  
|:------------------------------------------------------------------------------------------------------------:|  
|                                                      図0                                                  |  


|<img src="/lib/view/result1.png" width="420px">|  
|:------------------------------------------------------------------------------------------------------------:|  
|                                                      図1                                                  |  


|<img src="/lib/view/result2.png" width="420px">|  
|:------------------------------------------------------------------------------------------------------------:|  
|                                                      図2                                                  |  


|<img src="/lib/view/result3.png" width="420px">|  
|:------------------------------------------------------------------------------------------------------------:|  
|                                                      図3                                                  |  




##<a name="add_api">REST APIの追加
REST APIは
[lib/rest_api.rb](lib/rest_api.rb)
において，追加方法は以下のブロックを加筆することにより追加できる．<br>
```
desc 'APIの説明'
params do
  requires :変数名, type: 変数のタイプ, desc: '変数の説明'
  (複数の変数を要求できるが省略する．)
end
get '指定するURL' do
  rest_api do
    APIに対する処理
  end
end
```
そして，localでは，`./bit/rackup`コマンドによってでサーバを立ち上げた上で，
以下のコマンドを実行することによりAPIを利用できる．<br>
```
curl -sS -X 通信メソッド（GET / POST） 'http://localhost:9292/指定したURL'
```

加えて，次の２つのAPIを加えた．<br>
###① Sliceの分割
このAPIはlocalでは以下のコマンドにより利用できる．<br>
そして，`slice_a`スライスを`slice_a-1`スライスおよび`slice_a-2`スライスに分割する．<br>
```
curl -sS -X GET 'http://localhost:9292/slice_id/slice_a/split_slice_id_a-1/slice_a-1/split_slice_id_2/slice_a-2'
```
###② Sliceの統合
このAPIはlocalでは以下のコマンドにより利用できる．<br>
そして，`slice_a`スライスおよび`slice_b`スライスを`slice_c`スライスとして統合する．<br>
```
curl -sS -X GET 'http://localhost:9292/slice_id_1/slice_a/slice_id_2/slice_b/merged_slice_id/slice_c'
```



##実行結果
スライスの分割と結合機能が正しく動作することを、実機におけるテストで確認した。<br>
まず、実機に２つのホスト(ipアドレスはそれぞれ、192.168.11と192.168.1.12)をそれぞれ異なるスイッチに接続し、その２つのスイッチ間にパスができるようにリンク（ケーブル）をつなぐ。そして、以下のコマンドでsliceable-switchを起動させる。<br>
```
bundle exec trema run lib/routing_switch.rb -- --slicing
```
次に、２つのホストを同一のスライスに所属させるため、スライス(slice1)を作成し、２つのホストをスライスに追加する。<br>
```
./bin/slice add slice1
./bin/slice add_host --port 0x9:27 --mac 00:1f:16:39:1a:97 --slice slice1
./bin/slice add_host --port 0x2:4 --mac 04:20:9a:40:47:c2 --slice slice1
```
この状態で、一方のホスト(192.168.1.11)から他方のホスト(192.168.1.12)にpingを送信すると、以下のようにpingが通っている(ホスト間で通信が行える)ことが確認できた。<br>
```
~$ ping 192.168.1.12
PING 192.168.1.12 (192.168.1.12) 56(84) bytes of data.
64 bytes from 192.168.1.12: icmp_seq=1 ttl=128 time=291 ms
64 bytes from 192.168.1.12: icmp_seq=2 ttl=128 time=505 ms
64 bytes from 192.168.1.12: icmp_seq=3 ttl=128 time=609 ms
64 bytes from 192.168.1.12: icmp_seq=4 ttl=128 time=499 ms
64 bytes from 192.168.1.12: icmp_seq=5 ttl=128 time=556 ms
64 bytes from 192.168.1.12: icmp_seq=6 ttl=128 time=311 ms
^C
--- 192.168.1.12 ping statistics ---
6 packets transmitted, 6 received, 0% packet loss, time 5001ms
rtt min/avg/max/mdev = 291.435/462.309/609.816/119.474 ms
```
ここで、今回の課題において実装したスライスの分割機能(splitコマンド)により、以下のようにslice1をslice2とslice3に分割する。slice1に所属していた２つのホストは、それぞれ別のスライスへと所属させる。<br>
```
./bin/slice split slice1 slice2:04:20:9a:40:47:c2 slice3:00:1f:16:39:1a:97
```
２つのホストはそれぞれ異なるスライスに所属しているため、互いに通信は行えない。実際、一方のホスト(192.168.1.11)から他方のホスト(192.168.1.12)にpingを送信しても、以下のようにpingは通らなかった。<br>
```
~$ ping 192.168.1.12
PING 192.168.1.12 (192.168.1.12) 56(84) bytes of data.
From 192.168.1.11 icmp_seq=1 Destination Host Unreachable
From 192.168.1.11 icmp_seq=2 Destination Host Unreachable
From 192.168.1.11 icmp_seq=3 Destination Host Unreachable
From 192.168.1.11 icmp_seq=4 Destination Host Unreachable
From 192.168.1.11 icmp_seq=5 Destination Host Unreachable
From 192.168.1.11 icmp_seq=6 Destination Host Unreachable
^C
--- 192.168.1.12 ping statistics ---
7 packets transmitted, 0 received, +6 errors, 100% packet loss, time 6032ms
pipe 3
```
splitコマンドで分割した２つのスライスslice2とslice3を、今回の課題で実装したもう１つの機能である結合機能(mergeコマンド)により結合する。以下のコマンドを実行すると、分割されていたslice2とslice3が１つのスライスmergedに結合された。
```
./bin/slice merge slice3 slice2 merged
```
slice2とslice3の別々のスライスに所属していた２つのホストが同一のスライスに所属することになるため、上と同様に一方のホスト(192.168.1.11)から他方のホスト(192.168.1.12)にpingを送信すると、以下のようにpingが通っている(ホスト間で通信が行える)ことが確認できた。<br>
```
~$ ping 192.168.1.12
PING 192.168.1.12 (192.168.1.12) 56(84) bytes of data.
64 bytes from 192.168.1.12: icmp_seq=1 ttl=128 time=632 ms
64 bytes from 192.168.1.12: icmp_seq=2 ttl=128 time=464 ms
64 bytes from 192.168.1.12: icmp_seq=3 ttl=128 time=380 ms
64 bytes from 192.168.1.12: icmp_seq=4 ttl=128 time=422 ms
64 bytes from 192.168.1.12: icmp_seq=5 ttl=128 time=478 ms
64 bytes from 192.168.1.12: icmp_seq=6 ttl=128 time=546 ms
^C
--- 192.168.1.12 ping statistics ---
7 packets transmitted, 6 received, 14% packet loss, time 6007ms
rtt min/avg/max/mdev = 380.296/487.597/632.126/82.319 ms
```

##<a name="links">関連リンク
* [課題 (スライス機能の拡張)](https://github.com/handai-trema/deck/blob/develop/week8/assignment_sliceable_switch.md)
* [lib/rest_api.rb](lib/rest_api.rb)

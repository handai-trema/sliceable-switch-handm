#Report: スライス機能の拡張
Submission: &nbsp; Dec./13/2016<br>
Branch: &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; develop<br>


##目次
* [提出者](#submitter)
* [課題内容](#assignment)
* [スライスの分割・結合](#add_function)
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

##<a name="add_function">スライスの分割・結合
スライスの分割及び結合における共通の仕様を述べる．

1. 属するホストのない，空のスライスを許容する
2. 分割あるいは結合処理を行う前にあったスライスを，これらの処理によって削除することはない
3. 分割あるいは結合処理を行うことにより，スライスに属していたホストがいずれのスライスにも属さなくなる，ということはない

以上の仕様に従って，スライスの分割及び結合を実装した．
以下ではそれぞれの実装内容を述べる．

###スライスの分割
スライスの分割に関する仕様を以下のように定めた．

1. 一度の実行により1つのスライスを2つに分割できる
2. 分割後，新たに2つのスライスが生成され，分割前のスライスは削除されない
3. 分割前のスライスに属するホストを，分割後の2つのスライスのいずれかに所属させることができる
4. 所属の変更を指定しなかったホストについては，分割処理実行後も分割元のスライスに所属させることとする

上記の仕様に従ってスライスの分割処理を実装した．

スライスslice0に含まれる，Macアドレスが11:11:11:11:11:11及び22:22:22:22:22:22のホストの所属を新たなスライスslice1に，33:33:33:33:33:33のホストの所属を新たなスライスslice2に変更するという
分割処理は以下のように実行する．
```
bin/slice split slice0 slice1:11:11:11:11:11:11,22:22:22:22:22:22 slice2:33:33:33:33:33:33
```

以下では，実装時に変更したバイナリファイルおよびSliceクラスファイルという2つのファイルについて説明を述べる．

####バイナリファイル（bin/slice）の変更点
バイナリファイルはサブコマンド`split`を用いてスライスの分割処理を実行するためのプログラムである．

以下のように，splitというサブコマンドを実装した．
```ruby
  desc 'Split slice'
  arg_name 'org_slise slice1 slice2'
  command :split do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      fail 'wrong num of args.' if args.size != 3
      org_slice = args[0]
      slice1 = args[1]
      slice2 = args[2]
      slice(options[:socket_dir]).split(org_slice, slice1, slice2)
    end
  end
```
引数には分割前のスライス名であるorg_slice，分割後のスライス名とそのスライスに属するホストのMacアドレスを表す文字列であるslice1及びslice2をとり，
これをSliceクラスのメソッドsplitに渡している．

####Sliceクラス（lib/slice.rb）の変更点
バイナリファイルによって呼び出されるメソッドsplitを追加した．
引数には分割前のスライス名であるorg_slice，分割後のスライス名とそのスライスに属するホストのMacアドレスを表す文字列であるslice1及びslice2をとる．

slice1及びslice2は，それぞれのスライス名とそのスライスに所属させるホストのMacアドレスを，
コロン（":"）を区切り文字として連結した文字列である．ただし，分割後のスライスに複数のホストを所属させる場合はそのMacアドレスをカンマ（","）を区切り文字として連結して記述する．
（例）slice_a:11:11:11:11:11:11,22:22:22:22:22:22

簡易なアルゴリズムは以下のようになる．

1. 引数を分割し，スライス分割後のスライス名及びそのスライスに所属させるホストのMacアドレスの配列を生成する
2. 分割後のスライス名がすでに利用されていないかをチェックし，利用されていれば終了する
3. 分割後のスライス2つを作成する
4. 分割前のスライスにおける全Macアドレスの中から，分割後のスライスに所属を変更させるものを探索する
5. 該当するホストに関する情報（接続しているスイッチのdpid及びポート番号）を分割後のスライスのインスタンスに追加する
6. 該当するホストに関する情報を分割前のスライスのインスタンスから削除する
7. スライスの状況が変化したことを，Htmlクラスに通知する（updateメソッド）

以下が実装コードである．
```ruby
  def self.split(org_slice, slice1, slice2)
      slice1, hosts1 = slice1.split(":",2)
      slice2, hosts2 = slice2.split(":",2)
      hosts1 = hosts1.split(",")
      hosts2 = hosts2.split(",")
      if find_by(name: slice1)
        fail SliceAlreadyExistsError, "Slice #{slice1} already exists"
      end
      if find_by(name: slice2)
        fail SliceAlreadyExistsError, "Slice #{slice2} already exists"
      end
      create(slice1)
      create(slice2)
      org_slice = find_by!(name: org_slice)
      slice1 = find_by!(name: slice1)
      slice2 = find_by!(name: slice2)
      hosts1.each do |each|
        org_slice.ports.each do |each2|
          if org_slice.find_mac_address(each2, each)
            slice1.add_mac_address(each, each2)
            org_slice.delete_mac_address(each, each2)
            org_slice.delete_port(each2)
          end
        end
      end
      hosts2.each do |each|
        org_slice.ports.each do |each2|
          if org_slice.find_mac_address(each2, each)
            slice2.add_mac_address(each, each2)
            org_slice.delete_mac_address(each, each2)
            org_slice.delete_port(each2)
          end
        end
      end
    Html.update(Slice.all)
  end
```

###スライスの結合
スライスの結合に関する仕様を以下のように定めた．

1. 一度の実行により2つのスライスをそれぞれのスライスとは異なる1つのスライスに結合できる
2. 分割後，新たに1つのスライスが生成され，結合前のスライスは削除されない
3. 結合前の2つのスライスに属していたホストは，結合処理によってすべて結合後のスライスに所属を変更する

上記の仕様に従ってスライスの結合処理を実装した．

スライスslice1とスライスslice2に含まれる全ホストの所属を新たなスライスmerged_sliceに変更する，
スライスの結合処理は以下のように実行する．
```
bin/slice merge slice1 slice2 merged_slice
```

以下では，実装時に変更したバイナリファイルおよびSliceクラスファイルという2つのファイルについて説明を述べる．

####バイナリファイル（bin/slice）の変更点
バイナリファイルはサブコマンド`merge`を用いてスライスの分割処理を実行するためのプログラムである．

以下のように，mergeというサブコマンドを実装した．
```ruby
  desc 'Merge slice'
  arg_name 'slice1 slice2 merged_slice'
  command :merge do |c|
    c.desc 'Location to find socket files'
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      fail 'wrong num of args.' if args.size != 3
      slice1 = args[0]
      slice2 = args[1]
      merged_slice = args[2]
      slice(options[:socket_dir]).merge(slice1, slice2, merged_slice)
    end
  end
```
引数には結合前のスライス名であるslice1及びslice2，結合後のスライス名であるmerged_sliceをとり，
これをSliceクラスのメソッドmergeに渡している．

####Sliceクラス（lib/slice.rb）の変更点
バイナリファイルによって呼び出されるメソッドmergeを追加した．
引数には結合前のスライス名であるslice1及びslice2，結合後のスライス名であるmerged_sliceをとる．

簡易なアルゴリズムは以下のようになる．

1. 結合後のスライス名がすでに利用されていないかをチェックし，利用されていれば終了する
2. 結合後のスライス2つを作成する
3. 結合前のスライスに属する全ホストに関する情報（接続しているスイッチのdpid及びポート番号）を結合後のスライスのインスタンスに追加する
4. 結合前のスライスに属する全ホストに関する情報を，結合前のスライスのインスタンスから削除する
5. スライスの状況が変化したことを，Htmlクラスに通知する（updateメソッド）

以下が実装コードである．
```ruby
 def self.merge(slice1, slice2, merged_slice)
      if find_by(name: merged_slice)
        fail SliceAlreadyExistsError, "Slice #{merged_slice} already exists"
      end
      create(merged_slice)
      merged_slice = find_by!(name: merged_slice)
      slice1 = find_by!(name: slice1)
      slice2 = find_by!(name: slice2)
      slice1.ports.each do |each|
        slice1.mac_addresses(each).each do |each2|
          merged_slice.add_mac_address(each2, each)
          slice1.delete_port(each)
        end
      end
      slice2.ports.each do |each|
        slice2.mac_addresses(each).each do |each2|
          merged_slice.add_mac_address(each2, each)
          slice2.delete_port(each)
        end
      end
    Html.update(Slice.all)
  end
```


##<a name="visualize">スライスの可視化
スライスの状態をウェブブラウザで見ることができるようにした。方法としては前回、前々回と同じくvis.jsを利用してJavaScriptで記述するが、JavaScriptファイルはrubyで書き出す。
スイッチ間の接続であったりホスト・スイッチ間の接続はスライスの状況と関係がなく表示する領域に余裕が無いために省略した。

JavaScriptを含むhtmlファイルを生成するプログラムをhtml.rbとし、slice.rbよりrequireならびに、updateメソッドを適宜呼び出す。

スライス一覧はまず左側にまとめて表示しており、その凡例にしたがって、表示されているホスト(Mac address)のアイコンの色が決まっている。これにより所属スライスが把握可能である。次の図0が、適当にホストをスライスに分割した際の表示である。

|<img src="/lib/view/result0.png" width="420px">|  
|:------------------------------------------------------------------------------------------------------------:|  
|                                                      図0                                                  |  

今回は、JavaScriptの機能で頻繁にページ更新を行うことで、自動的に最新の状況に表示を変化させることとした。



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
そして，localでは，`./bin/rackup`コマンドによってでサーバを立ち上げた上で，
以下のコマンドを実行することによりAPIを利用できる．<br>
```
curl -sS -X 通信メソッド（GET / POST） 'http://localhost:9292/指定したURL'
```

加えて，次の２つのAPIを加えた．<br>
###① Sliceの分割
このAPIはlocalでは以下のコマンドにより利用できる．<br>
そして，`slice_a`スライスを`slice_a-1`スライスおよび`slice_a-2`スライスに分割する．
このとき，`slice_a`中のホストのうち，macアドレスが11:11:11:11:11:11のホストを`slice_a-1`に，22:22:22:22:22:22のホストを`slice_a-2`に移動する．
<br>
```
curl -sS -X GET 'http://localhost:9292/org_slice/slice_a/split_slice1/slice_a-1:11:11:11:11:11:11/split_slice2/slice_a-2:22:22:22:22:22:22'
```
###② Sliceの統合
このAPIはlocalでは以下のコマンドにより利用できる．<br>
そして，`slice_a`スライスおよび`slice_b`スライスを`slice_c`スライスとして統合する．<br>
```
curl -sS -X GET 'http://localhost:9292/slice1/slice_a/slice2/slice_b/merged_slice_id/slice_c'
```



##実行結果
###スライスの分割と結合
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

このときの可視化したスライスの状況は、図1のようになっている。

|<img src="/lib/view/result1.png" width="420px">|  
|:------------------------------------------------------------------------------------------------------------:|  
|                                                      図1                                                  |  

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

このときの可視化の結果は図2のようになり、確かに異なるスライスに所属していることがわかる。

|<img src="/lib/view/result2.png" width="420px">|  
|:------------------------------------------------------------------------------------------------------------:|  
|                                                      図2                                                  |  



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

最終的な可視化の結果は図3のようになり、確かに共にmergedに所属していることがわかる。

|<img src="/lib/view/result3.png" width="420px">|  
|:------------------------------------------------------------------------------------------------------------:|  
|                                                      図3                                                  |  


###REST_API
REST_APIが正しく動作することを、実機のテストで確認した。テスト環境は上記のテストにおけるものと同一である（２つのホストが異なるスイッチに接続されており、それらの間にパスができるようにリンクが存在する状況）。  
まず、sliceable-switchを起動し、別の端末から以下のコマンドを用いてREST_API用のサーバを立ち上げる。
```
./bin/rackup
```
そして、２つのホストを同一のスライスに所属させるため、新しくスライス(slice0)を作成し、２つのホストをスライスに加える。このとき、ホスト間で通信が行えていることを、pingコマンドを用いて確認した。  
ここで、作成したスライスをREST_APIを用いて分割する。以下のように、curlコマンドを用いてWebサーバにメッセージを送った。
```
curl -sS -X GET 'http://localhost:9292/org_slice/slice0/split_slice1/slice1:00:1f:16:39:1a:97/split_slice2/slice2:04:20:9a:40:47:c2'
```
メッセージを受け取ったWebサーバは、以下のように200のステータスコードを返していた。
```
127.0.0.1 - - [13/Dec/2016:16:09:59 +0900] "GET /org_slice/slice0/split_slice1/slice1:00:1f:16:39:1a:97/split_slice2/slice2:04:20:9a:40:47:c2 HTTP/1.1" 200 21 0.9260
```
下記の通り、スライスの分割が正しく行われており、ホスト間では通信が行えなかった。
```
slice1
[switch] 0x9:27, [host] 00:1f:16:39:1a:97
slice2
[switch] 0x2:4, [host] 04:20:9a:40:47:c2
```
次に、分割したスライスをREST_APIを用いて結合する。以下のように、curlコマンドを用いてWebサーバにメッセージを送った。
```
curl -sS -X GET 'http://localhost:9292/slice1/slice1/slice2/slice2/merged_slice/merge'
```
メッセージを受け取ったWebサーバは、以下のように200のステータスコードを返していた。
```
127.0.0.1 - - [13/Dec/2016:16:10:15 +0900] "GET /slice1/slice1/slice2/slice2/merged_slice/merge HTTP/1.1" 200 44 0.0040
```
下記の通り、スライスの結合が正しく行えており、ホスト間で通信が行える（pingが通る）ことが確認できた。
```
merge
[switch] 0x9:27, [host] 00:1f:16:39:1a:97
[switch] 0x2:4, [host] 04:20:9a:40:47:c2
```

##<a name="links">関連リンク
* [課題 (スライス機能の拡張)](https://github.com/handai-trema/deck/blob/develop/week8/assignment_sliceable_switch.md)
* [lib/rest_api.rb](lib/rest_api.rb)

#Report: スライス機能の拡張
Submission: &nbsp; Nov./30/2016<br>
Branch: &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; develop<br>


##目次
* [提出者](#submitter)
* [課題内容](#assignment)
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
そして，`./bit/rackup`コマンドを実行することでサーバを立ち上げ，
localでは以下のコマンドによりAPIを利用できる．<br>
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



##<a name="links">関連リンク
* [課題 (スライス機能の拡張)](https://github.com/handai-trema/deck/blob/develop/week8/assignment_sliceable_switch.md)
* [lib/rest_api.rb](lib/rest_api.rb)

# graphite


## openFrameworksを目指して

C++のライブラリである[openFrameworks](http://www.openframeworks.cc/)をD言語から使いたい！という需要に対して供給を行うプロジェクトです。

はっきり言うと、無謀な気がしますが、ぼちぼちやれば1年～2年ぐらいでできそうです。
つまり、私が院試頑張ってるころにはできてそうです。

現在の方針は、
* C++のラッパーとして書けるならそっちのほうが良い
* しかし、書けないならD言語で実装していこう


## graphiteという名前について

図形や文字を書くには鉛筆や筆が必要ですね。
つまり炭や墨である炭素は必須です。

グラファイト(graphite; 石墨)は炭素Cのみから成る黒い鉱物ですが、スペルもgraphicsに似ています。
というのも、グラファイト(graphite)という名前は「書く」という意味のギリシャ語grapheinに由来しているそうです。

(90%くらいは後付)


## 命名規則

openFrameworksでは、何にでも`of`を付けたがるようですが、graphiteではその`of`は取り除きましょう。

(C++には名前空間あるし`of`の必要性とは？---たぶん初心者にも取っ付きやすくするため)


## どのパッケージから手を付けるか？

`graphite.utils, graphite.types, graphite.math, graphite.gl`ぐらいから書いていくのが良いかと思います。
`graphite.libs`などのC言語系ヘッダーを書くのもよいでしょうが、大体のCのヘッダーは`htod`によって簡単に変換可能です。


## setterとgetterについて

openFrameworksと同様の機能をそのまま実装した場合、`set~`, `get~`というメソッドがいたるところに出現するので、理想的にはプロパティも一緒に実装しておいてください。

例:

~~~~d
class C
{
    void setA(int a);
    int getA();

    void a(int a) @property { this.setA(a); }
    int a() @property { return this.getA(); }
}
~~~~~